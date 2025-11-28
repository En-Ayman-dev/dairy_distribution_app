import 'package:dartz/dartz.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/customer_remote_datasource.dart';
import '../models/customer_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;
  final FirebaseAuth firebaseAuth;

  CustomerRepositoryImpl({
    required this.remoteDataSource,
    required this.firebaseAuth,
  });

  String get _userId => firebaseAuth.currentUser?.uid ?? '';
  bool get _isAuthenticated => firebaseAuth.currentUser != null;

  @override
  Future<Either<Failure, List<Customer>>> getAllCustomers() async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      developer.log('getAllCustomers called (Remote Only)', name: 'CustomerRepository');
      final remoteCustomers = await remoteDataSource.getAllCustomers(_userId);
      return Right(remoteCustomers);
    } catch (e) {
      developer.log('Failed to fetch customers from remote', error: e, name: 'CustomerRepository');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Customer>> getCustomerById(String id) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final customer = await remoteDataSource.getCustomerById(_userId, id);
      return Right(customer);
    } catch (e) {
      return Left(NotFoundFailure('Customer not found'));
    }
  }

  @override
  Future<Either<Failure, List<Customer>>> getCustomersByStatus(String status) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      // Currently fetching all and filtering in memory since we are removing local DB.
      // Optimization: This should be moved to a Firestore Query in RemoteDataSource later.
      final allCustomers = await remoteDataSource.getAllCustomers(_userId);
      final filteredCustomers = allCustomers.where((c) => c.status == status).toList();
      return Right(filteredCustomers);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch customers by status'));
    }
  }

  @override
  Future<Either<Failure, List<Customer>>> searchCustomers(String query) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      // Currently fetching all and filtering in memory.
      // Optimization: This works fine for small datasets but should be optimized for scale.
      final allCustomers = await remoteDataSource.getAllCustomers(_userId);
      final filteredCustomers = allCustomers.where((c) {
        return c.name.toLowerCase().contains(query.toLowerCase()) ||
               c.phone.contains(query);
      }).toList();
      return Right(filteredCustomers);
    } catch (e) {
      return Left(ServerFailure('Failed to search customers'));
    }
  }

  @override
  Future<Either<Failure, String>> addCustomer(Customer customer) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final customerModel = CustomerModel.fromEntity(customer);
      await remoteDataSource.addCustomer(_userId, customerModel);
      return Right(customer.id);
    } catch (e) {
      return Left(ServerFailure('Failed to add customer'));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomer(Customer customer) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final customerModel = CustomerModel.fromEntity(customer);
      await remoteDataSource.updateCustomer(_userId, customerModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to update customer'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      await remoteDataSource.deleteCustomer(_userId, id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete customer'));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomerBalance(
    String id,
    double balance,
  ) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      // Since we don't have local state, we fetch fresh data first to ensure consistency,
      // then update. Ideally, RemoteDataSource should have a specific atomic 'updateField' method.
      final currentCustomerModel = await remoteDataSource.getCustomerById(_userId, id);
      
      final updatedCustomer = currentCustomerModel.copyWith(balance: balance);
      
      await remoteDataSource.updateCustomer(_userId, updatedCustomer);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to update customer balance'));
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