// ignore_for_file: unused_import

import 'package:dartz/dartz.dart';
import '../../domain/entities/distribution.dart';
import '../../domain/entities/distribution_item.dart';
import '../../domain/repositories/distribution_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/distribution_remote_datasource.dart';
import '../datasources/remote/customer_remote_datasource.dart';
import '../datasources/remote/product_remote_datasource.dart';
import '../models/distribution_model.dart';
// لا نحتاج لاستيراد نماذج المنتج والعميل بشكل صريح إذا كانت تأتي من Datasources،
// ولكن للتأكد من copyWith، يفترض أن النماذج تعرف خصائصها.
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class DistributionRepositoryImpl implements DistributionRepository {
  final DistributionRemoteDataSource remoteDataSource;
  final CustomerRemoteDataSource customerRemoteDataSource;
  final ProductRemoteDataSource productRemoteDataSource;
  final FirebaseAuth firebaseAuth;

  DistributionRepositoryImpl({
    required this.remoteDataSource,
    required this.customerRemoteDataSource,
    required this.productRemoteDataSource,
    required this.firebaseAuth,
  });

  String get _userId => firebaseAuth.currentUser?.uid ?? '';
  bool get _isAuthenticated => firebaseAuth.currentUser != null;

  @override
  Future<Either<Failure, List<Distribution>>> getAllDistributions() async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final remoteDistributions = await remoteDataSource.getAllDistributions(_userId);
      // Enrich distributions with missing customer/product names when necessary
      final enriched = await Future.wait<Distribution>(remoteDistributions.map((d) => _enrichDistributionWithNames(d)).toList());
      return Right(enriched);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Distribution>> getDistributionById(String id) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final distribution = await remoteDataSource.getDistributionById(_userId, id);
      final enriched = await _enrichDistributionWithNames(distribution);
      return Right(enriched);
    } catch (e) {
      return Left(NotFoundFailure('Distribution not found'));
    }
  }

  @override
  Future<Either<Failure, List<Distribution>>> getDistributionsByCustomer(String customerId) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final allDistributions = await remoteDataSource.getAllDistributions(_userId);
      final customerDistributions = allDistributions.where((d) => d.customerId == customerId).toList();
      final enriched = await Future.wait<Distribution>(customerDistributions.map((d) => _enrichDistributionWithNames(d)).toList());
      return Right(enriched);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch customer distributions'));
    }
  }

  @override
  Future<Either<Failure, List<Distribution>>> getDistributionsByDateRange(DateTime start, DateTime end) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final allDistributions = await remoteDataSource.getAllDistributions(_userId);
      final rangeDistributions = allDistributions.where((d) {
        return d.distributionDate.isAfter(start.subtract(const Duration(days: 1))) && 
               d.distributionDate.isBefore(end.add(const Duration(days: 1)));
      }).toList();
      final enriched = await Future.wait<Distribution>(rangeDistributions.map((d) => _enrichDistributionWithNames(d)).toList());
      return Right(enriched);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch distributions by date range'));
    }
  }

  @override
  Future<Either<Failure, String>> createDistribution(Distribution distribution) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      // 1. Update Product Stocks (Remote)
      for (var item in distribution.items) {
        final productModel = await productRemoteDataSource.getProductById(_userId, item.productId);
        
        // تصحيح: استخدام .stock بدلاً من .currentStock
        final updatedStock = productModel.stock - item.quantity;
        
        // تصحيح: استخدام معامل stock في copyWith
        final updatedProduct = productModel.copyWith(stock: updatedStock);
        
        await productRemoteDataSource.updateProduct(_userId, updatedProduct);
      }

      // 2. Update Customer Balance (Remote)
      final customerModel = await customerRemoteDataSource.getCustomerById(_userId, distribution.customerId);
      final updatedBalance = customerModel.balance + distribution.pendingAmount;
      final updatedCustomer = customerModel.copyWith(balance: updatedBalance);
      
      await customerRemoteDataSource.updateCustomer(_userId, updatedCustomer);

      // 3. Create Distribution (Remote)
      final distributionModel = DistributionModel.fromEntity(distribution);
      await remoteDataSource.createDistribution(_userId, distributionModel);

      return Right(distribution.id);
    } catch (e) {
      return Left(ServerFailure('Failed to create distribution: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateDistribution(Distribution distribution) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final distributionModel = DistributionModel.fromEntity(distribution);
      await remoteDataSource.updateDistribution(_userId, distributionModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to update distribution'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDistribution(String id) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final distribution = await remoteDataSource.getDistributionById(_userId, id);

      // 1. Revert Product Stocks (Remote)
      for (var item in distribution.items) {
        final productModel = await productRemoteDataSource.getProductById(_userId, item.productId);
        // تصحيح: استخدام .stock
        final updatedStock = productModel.stock + item.quantity; 
        // تصحيح: استخدام stock:
        final updatedProduct = productModel.copyWith(stock: updatedStock);
        await productRemoteDataSource.updateProduct(_userId, updatedProduct);
      }

      // 2. Revert Customer Balance (Remote)
      final customerModel = await customerRemoteDataSource.getCustomerById(_userId, distribution.customerId);
      final updatedBalance = customerModel.balance - distribution.pendingAmount;
      final updatedCustomer = customerModel.copyWith(balance: updatedBalance);
      await customerRemoteDataSource.updateCustomer(_userId, updatedCustomer);

      // 3. Delete Distribution (Remote)
      await remoteDataSource.deleteDistribution(_userId, id);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete distribution'));
    }
  }

  @override
  Future<Either<Failure, void>> recordPayment(String distributionId, double amount) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      // 1. Fetch Distribution
      final distribution = await remoteDataSource.getDistributionById(_userId, distributionId);
      
      final newPaidAmount = distribution.paidAmount + amount;
      
      // تصحيح: استخدام Enum بدلاً من String
      PaymentStatus paymentStatus = PaymentStatus.pending;
      if (newPaidAmount >= distribution.totalAmount) {
        paymentStatus = PaymentStatus.paid;
      } else if (newPaidAmount > 0) {
        paymentStatus = PaymentStatus.partial;
      }

      // استخدام copyWith الجديد الذي يقبل PaymentStatus
      final updatedDistribution = DistributionModel.fromEntity(distribution).copyWith(
        paidAmount: newPaidAmount,
        paymentStatus: paymentStatus,
      );

      // 2. Update Distribution (Remote)
      await remoteDataSource.updateDistribution(_userId, updatedDistribution);

      // 3. Update Customer Balance (Remote)
      final customerModel = await customerRemoteDataSource.getCustomerById(_userId, distribution.customerId);
      final updatedBalance = customerModel.balance - amount;
      final updatedCustomer = customerModel.copyWith(balance: updatedBalance);
      
      await customerRemoteDataSource.updateCustomer(_userId, updatedCustomer);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to record payment'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDistributionStats(DateTime start, DateTime end) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final allDistributions = await remoteDataSource.getAllDistributions(_userId);
      final distributions = allDistributions.where((d) {
        return d.distributionDate.isAfter(start.subtract(const Duration(days: 1))) && 
               d.distributionDate.isBefore(end.add(const Duration(days: 1)));
      }).toList();

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
      return Left(ServerFailure('Failed to calculate distribution stats'));
    }
  }

  @override
  Future<Either<Failure, List<Distribution>>> getFilteredDistributions({
    required DateTime startDate,
    required DateTime endDate,
    String? customerId,
    List<String>? productIds,
  }) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final allDistributions = await remoteDataSource.getAllDistributions(_userId);
      
      final filtered = allDistributions.where((d) {
        bool matchDate = d.distributionDate.isAfter(startDate.subtract(const Duration(days: 1))) && 
                         d.distributionDate.isBefore(endDate.add(const Duration(days: 1)));
        bool matchCustomer = customerId == null || d.customerId == customerId;
        
        bool matchProduct = productIds == null || productIds.isEmpty || 
                            d.items.any((item) => productIds.contains(item.productId));
                            
        return matchDate && matchCustomer && matchProduct;
      }).toList();

      final enriched = await Future.wait<Distribution>(filtered.map((d) => _enrichDistributionWithNames(d)).toList());
      return Right(enriched);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch filtered distributions'));
    }
  }

  Future<Distribution> _enrichDistributionWithNames(Distribution dist) async {
    var updated = dist;
    try {
      if (updated.customerName.trim().isEmpty) {
        try {
          final customerModel = await customerRemoteDataSource.getCustomerById(_userId, updated.customerId);
          developer.log('Enriching distribution ${updated.id} with customer name from remote: ${customerModel.name}', name: 'DistributionRepositoryImpl');
          updated = updated.copyWith(customerName: customerModel.name);
        } catch (_) {}
      }

      final items = <DistributionItem>[];
      for (var it in updated.items) {
        if (it.productName.trim().isEmpty) {
          try {
            final productModel = await productRemoteDataSource.getProductById(_userId, it.productId);
            developer.log('Enriching distribution item ${it.id} with product name: ${productModel.name}', name: 'DistributionRepositoryImpl');
            items.add(it.copyWith(productName: productModel.name));
          } catch (_) {
            items.add(it);
          }
        } else {
          items.add(it);
        }
      }
      updated = updated.copyWith(items: items);
    } catch (_) {
      // ignore
    }
    return updated;
  }

  
  
}