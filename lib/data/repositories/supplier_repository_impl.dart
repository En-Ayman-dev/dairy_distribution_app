import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/entities/supplier_payment.dart'; // استيراد كيان الدفعات
import '../../domain/repositories/supplier_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/supplier_remote_datasource.dart';
import '../models/supplier_model.dart';
import '../models/supplier_payment_model.dart'; // استيراد موديل الدفعات
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class SupplierRepositoryImpl implements SupplierRepository {
  final SupplierRemoteDataSource remoteDataSource;
  final FirebaseAuth firebaseAuth;

  SupplierRepositoryImpl({required this.remoteDataSource, required this.firebaseAuth});

  String get _userId => firebaseAuth.currentUser?.uid ?? '';
  bool get _isAuthenticated => firebaseAuth.currentUser != null;

  @override
  Future<Either<Failure, List<Supplier>>> getAllSuppliers() async {
    if (!_isAuthenticated) return Left(AuthenticationFailure('User not authenticated'));
    try {
      final remoteSuppliers = await remoteDataSource.getAllSuppliers(_userId);
      return Right(remoteSuppliers);
    } catch (e) {
      developer.log('Failed to fetch suppliers', error: e, name: 'SupplierRepository');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Supplier>> getSupplierById(String id) async {
    if (!_isAuthenticated) return Left(AuthenticationFailure('User not authenticated'));
    try {
      final s = await remoteDataSource.getSupplierById(_userId, id);
      return Right(s);
    } catch (e) {
      return Left(NotFoundFailure('Supplier not found'));
    }
  }

  @override
  Future<Either<Failure, String>> addSupplier(Supplier supplier) async {
    if (!_isAuthenticated) return Left(AuthenticationFailure('User not authenticated'));
    try {
      final model = SupplierModel.fromEntity(supplier);
      await remoteDataSource.addSupplier(_userId, model);
      return Right(supplier.id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSupplier(Supplier supplier) async {
    if (!_isAuthenticated) return Left(AuthenticationFailure('User not authenticated'));
    try {
      final model = SupplierModel.fromEntity(supplier);
      await remoteDataSource.updateSupplier(_userId, model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSupplier(String id) async {
    if (!_isAuthenticated) return Left(AuthenticationFailure('User not authenticated'));
    try {
      await remoteDataSource.deleteSupplier(_userId, id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Supplier>>> watchSuppliers() {
    if (!_isAuthenticated) return Stream.value(Left(AuthenticationFailure('User not authenticated')));
    try {
      return remoteDataSource.watchSuppliers(_userId).map((suppliers) => Right<Failure, List<Supplier>>(suppliers)).handleError((e) {
        developer.log('watchSuppliers stream error', name: 'SupplierRepository', error: e);
        throw e;
      });
    } catch (e) {
      return Stream.value(Left(ServerFailure('Failed to watch suppliers')));
    }
  }

  // --- تنفيذ دوال الدفعات ---

  @override
  Future<Either<Failure, String>> addPayment(SupplierPayment payment) async {
    if (!_isAuthenticated) return Left(AuthenticationFailure('User not authenticated'));
    try {
      final model = SupplierPaymentModel.fromEntity(payment);
      final id = await remoteDataSource.addPayment(_userId, model);
      return Right(id);
    } catch (e) {
      developer.log('Failed to add payment', error: e, name: 'SupplierRepository');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SupplierPayment>>> getSupplierPayments(String supplierId) async {
    if (!_isAuthenticated) return Left(AuthenticationFailure('User not authenticated'));
    try {
      final remotePayments = await remoteDataSource.getSupplierPayments(_userId, supplierId);
      return Right(remotePayments);
    } catch (e) {
      developer.log('Failed to fetch payments', error: e, name: 'SupplierRepository');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<SupplierPayment>>> watchSupplierPayments(String supplierId) {
    if (!_isAuthenticated) return Stream.value(Left(AuthenticationFailure('User not authenticated')));
    try {
      return remoteDataSource.watchSupplierPayments(_userId, supplierId)
          .map((payments) => Right<Failure, List<SupplierPayment>>(payments))
          .handleError((e) {
        developer.log('watchSupplierPayments stream error', name: 'SupplierRepository', error: e);
        throw e;
      });
    } catch (e) {
      return Stream.value(Left(ServerFailure('Failed to watch supplier payments')));
    }
  }
}