import 'package:dartz/dartz.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/network_info.dart';
import '../datasources/local/customer_local_datasource.dart';
import '../datasources/remote/customer_remote_datasource.dart';
import '../models/customer_model.dart';
import '../../core/network/sync_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerLocalDataSource localDataSource;
  final CustomerRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final SyncManager syncManager;
  final FirebaseAuth firebaseAuth;

  CustomerRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
    required this.syncManager,
    required this.firebaseAuth,
  });

  String get _userId => firebaseAuth.currentUser?.uid ?? '';
  bool get _isAuthenticated => firebaseAuth.currentUser != null;

  @override
  Future<Either<Failure, List<Customer>>> getAllCustomers() async {
    try {
      developer.log('getAllCustomers called', name: 'CustomerRepository');
      developer.log('currentUser uid', name: 'CustomerRepository', error: firebaseAuth.currentUser?.uid);
      // Always fetch from local first (offline-first approach)
      final localCustomers = await localDataSource.getAllCustomers();

      // If online, sync with remote
      if (await networkInfo.isConnected) {
          try {
            developer.log('Attempting remote fetch for customers', name: 'CustomerRepository');
            developer.log('userId', name: 'CustomerRepository', error: _userId);
          if (!_isAuthenticated) {
            // If not authenticated, return local data
            return Right(localCustomers);
          }

          final remoteCustomers = await remoteDataSource.getAllCustomers(_userId);

          // If remote returned no results but local has data, keep local to avoid
          // wiping the UI with an empty remote result.
          if (remoteCustomers.isEmpty && localCustomers.isNotEmpty) {
            developer.log('Remote empty, preserving local customers', name: 'CustomerRepository');
            return Right(localCustomers);
          }

          // Update local database with remote data
          for (var customer in remoteCustomers) {
            await localDataSource.insertCustomer(customer);
          }

          return Right(remoteCustomers);
        } catch (e) {
          // If remote fails, log the error and return local data
          developer.log('Remote fetch failed', name: 'CustomerRepository', error: e);
          return Right(localCustomers);
        }
      }

      return Right(localCustomers);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to fetch customers from local database'));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Customer>> getCustomerById(String id) async {
    try {
      developer.log('getCustomerById called', name: 'CustomerRepository');
      developer.log('currentUser uid', name: 'CustomerRepository', error: firebaseAuth.currentUser?.uid);
      final customer = await localDataSource.getCustomerById(id);
      
      if (customer == null) {
        if (await networkInfo.isConnected) {
          try {
            developer.log('Attempting remote getCustomerById', name: 'CustomerRepository', error: _userId);
            if (!_isAuthenticated) {
              return Left(AuthenticationFailure('User not authenticated'));
            }
            final remoteCustomer = await remoteDataSource.getCustomerById(_userId, id);
            await localDataSource.insertCustomer(remoteCustomer);
            return Right(remoteCustomer);
          } catch (e) {
            developer.log('Remote getCustomerById failed', name: 'CustomerRepository', error: e);
            return Left(NotFoundFailure('Customer not found'));
          }
        }
        return Left(NotFoundFailure('Customer not found'));
      }

      return Right(customer);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Customer>>> getCustomersByStatus(String status) async {
    try {
      final customers = await localDataSource.getCustomersByStatus(status);
      return Right(customers);
    } catch (e) {
      return Left(DatabaseFailure('Failed to fetch customers by status'));
    }
  }

  @override
  Future<Either<Failure, List<Customer>>> searchCustomers(String query) async {
    try {
      final customers = await localDataSource.searchCustomers(query);
      return Right(customers);
    } catch (e) {
      return Left(DatabaseFailure('Failed to search customers'));
    }
  }

  @override
  Future<Either<Failure, String>> addCustomer(Customer customer) async {
    try {
      final customerModel = CustomerModel.fromEntity(customer);
      
      // Save to local database first
      await localDataSource.insertCustomer(customerModel);

      // Queue for sync if online or offline
      await syncManager.queueSync(
        entityType: 'customer',
        entityId: customer.id,
        operation: 'create',
        data: customerModel.toJson(),
      );

      // If online, sync immediately
      if (await networkInfo.isConnected) {
        try {
          if (_isAuthenticated) {
            await remoteDataSource.addCustomer(_userId, customerModel);
            await syncManager.markAsSynced('customer', customer.id);
          }
        } catch (e) {
          // Will be synced later
        }
      }

      return Right(customer.id);
    } catch (e) {
      return Left(DatabaseFailure('Failed to add customer'));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomer(Customer customer) async {
    try {
      final customerModel = CustomerModel.fromEntity(customer);
      
      await localDataSource.updateCustomer(customerModel);

      await syncManager.queueSync(
        entityType: 'customer',
        entityId: customer.id,
        operation: 'update',
        data: customerModel.toJson(),
      );

      if (await networkInfo.isConnected) {
        try {
          if (_isAuthenticated) {
            await remoteDataSource.updateCustomer(_userId, customerModel);
            await syncManager.markAsSynced('customer', customer.id);
          }
        } catch (e) {
          // Will be synced later
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update customer'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      await localDataSource.deleteCustomer(id);

      await syncManager.queueSync(
        entityType: 'customer',
        entityId: id,
        operation: 'delete',
        data: {'id': id},
      );

      if (await networkInfo.isConnected) {
        try {
          if (_isAuthenticated) {
            await remoteDataSource.deleteCustomer(_userId, id);
            await syncManager.markAsSynced('customer', id);
          }
        } catch (e) {
          // Will be synced later
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete customer'));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomerBalance(
    String id,
    double balance,
  ) async {
    try {
      await localDataSource.updateCustomerBalance(id, balance);

      if (await networkInfo.isConnected) {
        final customer = await localDataSource.getCustomerById(id);
        if (customer != null) {
          if (_isAuthenticated) {
            await remoteDataSource.updateCustomer(_userId, customer);
          }
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update customer balance'));
    }
  }

  @override
  Stream<Either<Failure, List<Customer>>> watchCustomers() {
    if (!_isAuthenticated) {
      return Stream.value(Left(AuthenticationFailure('User not authenticated')));
    }

    try {
      return remoteDataSource.watchCustomers(_userId).map(
            (customers) => Right<Failure, List<Customer>>(customers),
          ).handleError((e) {
            // Map Firebase permission errors to Failure
            if (e is FirebaseException && e.code == 'permission-denied') {
              throw AuthenticationFailure('Insufficient permissions to read customers');
            }
            throw e;
          });
    } catch (e) {
      return Stream.value(Left(ServerFailure('Failed to watch customers')));
    }
  }
}