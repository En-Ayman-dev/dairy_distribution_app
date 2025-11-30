import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/purchase_remote_datasource.dart';
import '../models/purchase_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class PurchaseRepositoryImpl implements PurchaseRepository {
  final PurchaseRemoteDataSource remoteDataSource;
  final FirebaseAuth firebaseAuth;

  PurchaseRepositoryImpl({required this.remoteDataSource, required this.firebaseAuth});

  String get _userId => firebaseAuth.currentUser?.uid ?? '';
  bool get _isAuthenticated => firebaseAuth.currentUser != null;

  @override
  Future<Either<Failure, String>> addPurchase(Purchase purchase) async {
    if (!_isAuthenticated) return Left(AuthenticationFailure('User not authenticated'));
    try {
      final model = PurchaseModel.fromEntity(purchase);
      final id = await remoteDataSource.addPurchase(_userId, model);
      return Right(id);
    } catch (e) {
      developer.log('Failed to add purchase', error: e, name: 'PurchaseRepository');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Purchase>>> getPurchasesForProduct(String productId) async {
    if (!_isAuthenticated) return Left(AuthenticationFailure('User not authenticated'));
    try {
      final remotePurchases = await remoteDataSource.getPurchasesForProduct(_userId, productId);
      return Right(remotePurchases);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Purchase>>> watchPurchases() {
    if (!_isAuthenticated) return Stream.value(Left(AuthenticationFailure('User not authenticated')));
    try {
      return remoteDataSource.watchPurchases(_userId).map((purchases) => Right<Failure, List<Purchase>>(purchases)).handleError((e) {
        developer.log('watchPurchases stream error', name: 'PurchaseRepository', error: e);
        throw e;
      });
    } catch (e) {
      return Stream.value(Left(ServerFailure('Failed to watch purchases')));
    }
  }

  // --- تنفيذ الدالة الجديدة للمرتجعات ---
  @override
  Future<Either<Failure, void>> processReturn(String purchaseId, double quantity) async {
    if (!_isAuthenticated) return Left(AuthenticationFailure('User not authenticated'));
    try {
      await remoteDataSource.processReturn(_userId, purchaseId, quantity);
      return const Right(null);
    } catch (e) {
      developer.log('Failed to process return', error: e, name: 'PurchaseRepository');
      return Left(ServerFailure(e.toString()));
    }
  }
}