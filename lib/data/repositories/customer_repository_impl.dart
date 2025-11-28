// ignore_for_file: unnecessary_import

import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/customer_remote_datasource.dart';
import '../models/customer_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// التحقق من أخطاء الشبكة أو انتهاء المهلة
  bool _isOfflineError(Object e) {
    if (e is TimeoutException) return true;
    if (e is FirebaseException && (e.code == 'unavailable' || e.code == 'unknown')) {
      return true;
    }
    final s = e.toString().toLowerCase();
    return s.contains('unavailable') || 
           s.contains('unknownhostexception') || 
           s.contains('network') ||
           s.contains('failed to resolve name');
  }

  // --- ثوابت الأداء (Performance Tuning) ---
  // مهلة قصيرة جداً للكتابة (300ms) لضمان استجابة فورية للواجهة
  static const Duration _writeTimeout = Duration(milliseconds: 300);
  
  // مهلة متوسطة للقراءة (3s) لعدم تعليق الواجهة في حالة ضعف الشبكة
  static const Duration _readTimeout = Duration(seconds: 3);

  @override
  Future<Either<Failure, List<Customer>>> getAllCustomers() async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final remoteCustomers = await remoteDataSource.getAllCustomers(_userId)
          .timeout(_readTimeout); // تطبيق مهلة القراءة
      return Right(remoteCustomers);
    } catch (e) {
      if (_isOfflineError(e)) {
        return Left(ServerFailure('Offline: Could not sync customers.'));
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Customer>> getCustomerById(String id) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final customer = await remoteDataSource.getCustomerById(_userId, id)
          .timeout(_readTimeout);
      return Right(customer);
    } catch (e) {
      if (_isOfflineError(e)) {
        return Left(ServerFailure('Offline: Customer not found in cache.'));
      }
      return Left(NotFoundFailure('Customer not found'));
    }
  }

  @override
  Future<Either<Failure, List<Customer>>> getCustomersByStatus(String status) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final allCustomers = await remoteDataSource.getAllCustomers(_userId)
          .timeout(_readTimeout);
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
      final allCustomers = await remoteDataSource.getAllCustomers(_userId)
          .timeout(_readTimeout);
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
      
      // استخدام المهلة القصيرة (Write Timeout)
      await remoteDataSource.addCustomer(_userId, customerModel)
          .timeout(_writeTimeout);
          
      return Right(customer.id);
    } catch (e) {
      if (_isOfflineError(e)) {
        developer.log('Offline/Timeout during Add Customer. Optimistic success.', name: 'CustomerRepository');
        return Right(customer.id);
      }
      return Left(ServerFailure('Failed to add customer: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomer(Customer customer) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final customerModel = CustomerModel.fromEntity(customer);
      
      await remoteDataSource.updateCustomer(_userId, customerModel)
          .timeout(_writeTimeout);
          
      return const Right(null);
    } catch (e) {
      if (_isOfflineError(e)) {
        developer.log('Offline/Timeout during Update Customer. Optimistic success.', name: 'CustomerRepository');
        return const Right(null);
      }
      return Left(ServerFailure('Failed to update customer'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      await remoteDataSource.deleteCustomer(_userId, id)
          .timeout(_writeTimeout);
          
      return const Right(null);
    } catch (e) {
      if (_isOfflineError(e)) {
        developer.log('Offline/Timeout during Delete Customer. Optimistic success.', name: 'CustomerRepository');
        return const Right(null);
      }
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
      // القراءة نمنحها وقتاً أطول قليلاً، أو نستخدم نفس مهلة الكتابة إذا أردنا سرعة قصوى
      final currentCustomerModel = await remoteDataSource.getCustomerById(_userId, id)
          .timeout(_readTimeout);
          
      final updatedCustomer = currentCustomerModel.copyWith(balance: balance);
      
      await remoteDataSource.updateCustomer(_userId, updatedCustomer)
          .timeout(_writeTimeout);
          
      return const Right(null);
    } catch (e) {
      if (_isOfflineError(e)) {
        developer.log('Offline/Timeout during Update Balance. Optimistic success.', name: 'CustomerRepository');
        return const Right(null);
      }
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
            if (_isOfflineError(e)) {
               developer.log('Stream offline error ignored', name: 'CustomerRepository');
            } else {
               throw e;
            }
          });
    } catch (e) {
      return Stream.value(Left(ServerFailure('Failed to watch customers')));
    }
  }
}