import 'package:dartz/dartz.dart';
import '../../domain/entities/distribution.dart';
import '../../domain/repositories/distribution_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../datasources/local/distribution_local_datasource.dart';
import '../datasources/remote/distribution_remote_datasource.dart';
import '../datasources/local/customer_local_datasource.dart';
import '../datasources/local/product_local_datasource.dart';
import '../models/distribution_model.dart';
import '../../core/network/sync_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class DistributionRepositoryImpl implements DistributionRepository {
  final DistributionLocalDataSource localDataSource;
  final DistributionRemoteDataSource remoteDataSource;
  final CustomerLocalDataSource customerLocalDataSource;
  final ProductLocalDataSource productLocalDataSource;
  final NetworkInfo networkInfo;
  final SyncManager syncManager;
  final FirebaseAuth firebaseAuth;

  DistributionRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.customerLocalDataSource,
    required this.productLocalDataSource,
    required this.networkInfo,
    required this.syncManager,
    required this.firebaseAuth,
  });

  String get _userId => firebaseAuth.currentUser?.uid ?? '';
  bool get _isAuthenticated => firebaseAuth.currentUser != null;

  @override
  Future<Either<Failure, List<Distribution>>> getAllDistributions() async {
    try {
      developer.log('getAllDistributions called', name: 'DistributionRepository');
      developer.log('currentUser uid', name: 'DistributionRepository', error: firebaseAuth.currentUser?.uid);
      final localDistributions = await localDataSource.getAllDistributions();

      if (await networkInfo.isConnected) {
        try {
          developer.log('Attempting remote fetch for distributions', name: 'DistributionRepository', error: _userId);
          if (!_isAuthenticated) {
            return Right(localDistributions);
          }
          final remoteDistributions = await remoteDataSource.getAllDistributions(_userId);
          developer.log('Remote distributions fetched: ${remoteDistributions.length}', name: 'DistributionRepository');

          // If remote returned no results but we have local data, prefer local to avoid
          // wiping visible data on the client when remote is empty (possible when
          // server-side collections differ or during partial syncs).
          if (remoteDistributions.isEmpty && localDistributions.isNotEmpty) {
            developer.log('Remote empty, preserving local distributions', name: 'DistributionRepository');
            return Right(localDistributions);
          }

          for (var distribution in remoteDistributions) {
            await localDataSource.insertDistribution(distribution);
            developer.log('Inserted distribution into local DB: ${distribution.id}', name: 'DistributionRepository');
          }
          return Right(remoteDistributions);
        } catch (e) {
          developer.log('Remote fetch distributions failed', name: 'DistributionRepository', error: e);
          return Right(localDistributions);
        }
      }

      return Right(localDistributions);
    } catch (e) {
      return Left(DatabaseFailure('Failed to fetch distributions'));
    }
  }

  @override
  Future<Either<Failure, Distribution>> getDistributionById(String id) async {
    try {
      final distribution = await localDataSource.getDistributionById(id);
      
      if (distribution == null) {
        return Left(NotFoundFailure('Distribution not found'));
      }

      return Right(distribution);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Distribution>>> getDistributionsByCustomer(
    String customerId,
  ) async {
    try {
      final distributions =
          await localDataSource.getDistributionsByCustomer(customerId);
      return Right(distributions);
    } catch (e) {
      return Left(DatabaseFailure('Failed to fetch customer distributions'));
    }
  }

  @override
  Future<Either<Failure, List<Distribution>>> getDistributionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final distributions =
          await localDataSource.getDistributionsByDateRange(start, end);
      return Right(distributions);
    } catch (e) {
      return Left(DatabaseFailure('Failed to fetch distributions by date range'));
    }
  }

  @override
  Future<Either<Failure, String>> createDistribution(
    Distribution distribution,
  ) async {
    try {
      final distributionModel = DistributionModel.fromEntity(distribution);
      
      // Insert distribution
      await localDataSource.insertDistribution(distributionModel);

      // Update product stocks
      for (var item in distribution.items) {
        final product = await productLocalDataSource.getProductById(item.productId);
        if (product != null) {
          await productLocalDataSource.updateProductStock(
            item.productId,
            product.stock - item.quantity,
          );
        }
      }

      // Update customer balance
      final customer =
          await customerLocalDataSource.getCustomerById(distribution.customerId);
      if (customer != null) {
        await customerLocalDataSource.updateCustomerBalance(
          distribution.customerId,
          customer.balance + distribution.pendingAmount,
        );
      }

      // Queue for sync
      await syncManager.queueSync(
        entityType: 'distribution',
        entityId: distribution.id,
        operation: 'create',
        data: distributionModel.toJson(),
      );

      if (await networkInfo.isConnected) {
        try {
          if (_isAuthenticated) {
            await remoteDataSource.createDistribution(_userId, distributionModel);
            await syncManager.markAsSynced('distribution', distribution.id);
          }
        } catch (e) {
          // Will be synced later
        }
      }

      return Right(distribution.id);
    } catch (e) {
      return Left(DatabaseFailure('Failed to create distribution'));
    }
  }

  @override
  Future<Either<Failure, void>> updateDistribution(
    Distribution distribution,
  ) async {
    try {
      final distributionModel = DistributionModel.fromEntity(distribution);
      
      await localDataSource.updateDistribution(distributionModel);

      await syncManager.queueSync(
        entityType: 'distribution',
        entityId: distribution.id,
        operation: 'update',
        data: distributionModel.toJson(),
      );

      if (await networkInfo.isConnected) {
        try {
          if (_isAuthenticated) {
            await remoteDataSource.updateDistribution(_userId, distributionModel);
            await syncManager.markAsSynced('distribution', distribution.id);
          }
        } catch (e) {
          // Will be synced later
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update distribution'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDistribution(String id) async {
    try {
      // Get distribution before deleting
      final distribution = await localDataSource.getDistributionById(id);
      if (distribution == null) {
        return Left(NotFoundFailure('Distribution not found'));
      }

      // Restore product stocks
      for (var item in distribution.items) {
        final product = await productLocalDataSource.getProductById(item.productId);
        if (product != null) {
          await productLocalDataSource.updateProductStock(
            item.productId,
            product.stock + item.quantity,
          );
        }
      }

      // Update customer balance
      final customer =
          await customerLocalDataSource.getCustomerById(distribution.customerId);
      if (customer != null) {
        await customerLocalDataSource.updateCustomerBalance(
          distribution.customerId,
          customer.balance - distribution.pendingAmount,
        );
      }

      await localDataSource.deleteDistribution(id);

      await syncManager.queueSync(
        entityType: 'distribution',
        entityId: id,
        operation: 'delete',
        data: {'id': id},
      );

      if (await networkInfo.isConnected) {
        try {
          if (_isAuthenticated) {
            await remoteDataSource.deleteDistribution(_userId, id);
            await syncManager.markAsSynced('distribution', id);
          }
        } catch (e) {
          // Will be synced later
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete distribution'));
    }
  }

  @override
  Future<Either<Failure, void>> recordPayment(
    String distributionId,
    double amount,
  ) async {
    try {
      final distribution = await localDataSource.getDistributionById(distributionId);
      if (distribution == null) {
        return Left(NotFoundFailure('Distribution not found'));
      }

      final newPaidAmount = distribution.paidAmount + amount;
      String paymentStatus = 'pending';
      
      if (newPaidAmount >= distribution.totalAmount) {
        paymentStatus = 'paid';
      } else if (newPaidAmount > 0) {
        paymentStatus = 'partial';
      }

      await localDataSource.updatePaymentStatus(
        distributionId,
        newPaidAmount,
        paymentStatus,
      );

      // Update customer balance
      final customer =
          await customerLocalDataSource.getCustomerById(distribution.customerId);
      if (customer != null) {
        await customerLocalDataSource.updateCustomerBalance(
          distribution.customerId,
          customer.balance - amount,
        );
      }

      if (await networkInfo.isConnected) {
        try {
          final updatedDistribution =
              await localDataSource.getDistributionById(distributionId);
          if (updatedDistribution != null) {
            if (_isAuthenticated) {
              await remoteDataSource.updateDistribution(
                _userId,
                DistributionModel.fromEntity(updatedDistribution),
              );
            }
          }
        } catch (e) {
          // Will be synced later
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to record payment'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDistributionStats(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final distributions =
          await localDataSource.getDistributionsByDateRange(start, end);

      double totalSales = 0;
      double totalPaid = 0;
      double totalPending = 0;
      int totalDistributions = distributions.length;

      for (var distribution in distributions) {
        totalSales += distribution.totalAmount;
        totalPaid += distribution.paidAmount;
        totalPending += distribution.pendingAmount;
      }

      return Right({
        'total_sales': totalSales,
        'total_paid': totalPaid,
        'total_pending': totalPending,
        'total_distributions': totalDistributions,
        'average_sale': totalDistributions > 0 ? totalSales / totalDistributions : 0,
      });
    } catch (e) {
      return Left(DatabaseFailure('Failed to calculate distribution stats'));
    }
  }
}