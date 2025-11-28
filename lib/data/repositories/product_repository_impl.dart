// ignore_for_file: unnecessary_import

import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/product_remote_datasource.dart';
import '../models/product_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final FirebaseAuth firebaseAuth;

  ProductRepositoryImpl({
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
  static const Duration _writeTimeout = Duration(milliseconds: 300);
  static const Duration _readTimeout = Duration(seconds: 3);

  @override
  Future<Either<Failure, List<Product>>> getAllProducts() async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      developer.log('getAllProducts called (Remote Only)', name: 'ProductRepository');
      final remoteProducts = await remoteDataSource.getAllProducts(_userId)
          .timeout(_readTimeout);
      return Right(remoteProducts);
    } catch (e) {
      developer.log('Failed to fetch products from remote', error: e, name: 'ProductRepository');
      if (_isOfflineError(e)) {
        return Left(ServerFailure('Offline: Could not sync products.'));
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final remoteProduct = await remoteDataSource.getProductById(_userId, id)
          .timeout(_readTimeout);
      return Right(remoteProduct);
    } catch (e) {
      if (_isOfflineError(e)) {
        return Left(ServerFailure('Offline: Product not found in cache.'));
      }
      return Left(NotFoundFailure('Product not found'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProductsByCategory(String category) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final allProducts = await remoteDataSource.getAllProducts(_userId)
          .timeout(_readTimeout);
      final filteredProducts = allProducts.where((p) => p.category.toString().split('.').last == category.toLowerCase() || p.category.toString() == category).toList();
      return Right(filteredProducts);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch products by category'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getLowStockProducts() async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final allProducts = await remoteDataSource.getAllProducts(_userId)
          .timeout(_readTimeout);
      
      final lowStockProducts = allProducts.where((p) {
        return p.stock <= p.minStock; 
      }).toList();
      
      return Right(lowStockProducts);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch low stock products'));
    }
  }

  @override
  Future<Either<Failure, String>> addProduct(Product product) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final productModel = ProductModel.fromEntity(product);
      
      await remoteDataSource.addProduct(_userId, productModel)
          .timeout(_writeTimeout);
          
      return Right(product.id);
    } catch (e) {
      if (_isOfflineError(e)) {
        developer.log('Offline/Timeout during Add Product. Optimistic success.', name: 'ProductRepository');
        return Right(product.id);
      }
      return Left(ServerFailure('Failed to add product: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(Product product) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final productModel = ProductModel.fromEntity(product);
      
      await remoteDataSource.updateProduct(_userId, productModel)
          .timeout(_writeTimeout);
          
      return const Right(null);
    } catch (e) {
      if (_isOfflineError(e)) {
        developer.log('Offline/Timeout during Update Product. Optimistic success.', name: 'ProductRepository');
        return const Right(null);
      }
      return Left(ServerFailure('Failed to update product'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      await remoteDataSource.deleteProduct(_userId, id)
          .timeout(_writeTimeout);
          
      return const Right(null);
    } catch (e) {
      if (_isOfflineError(e)) {
        developer.log('Offline/Timeout during Delete Product. Optimistic success.', name: 'ProductRepository');
        return const Right(null);
      }
      return Left(ServerFailure('Failed to delete product'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProductStock(String id, double stock) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final currentProductEntity = await remoteDataSource.getProductById(_userId, id)
          .timeout(_readTimeout);
          
      final currentProductModel = ProductModel.fromEntity(currentProductEntity);
      
      final updatedProduct = currentProductModel.copyWith(stock: stock);
      
      await remoteDataSource.updateProduct(_userId, updatedProduct)
          .timeout(_writeTimeout);
          
      return const Right(null);
    } catch (e) {
      if (_isOfflineError(e)) {
        developer.log('Offline/Timeout during Update Product Stock. Optimistic success.', name: 'ProductRepository');
        return const Right(null);
      }
      return Left(ServerFailure('Failed to update product stock'));
    }
  }

  @override
  Stream<Either<Failure, List<Product>>> watchProducts() {
    if (!_isAuthenticated) {
      return Stream.value(Left(AuthenticationFailure('User not authenticated')));
    }

    try {
      return remoteDataSource.watchProducts(_userId).map(
            (products) => Right<Failure, List<Product>>(products),
          ).handleError((e) {
            if (e is FirebaseException && e.code == 'permission-denied') {
              throw AuthenticationFailure('Insufficient permissions to read products');
            }
            if (_isOfflineError(e)) {
               developer.log('Stream offline error ignored', name: 'ProductRepository');
            } else {
               throw e;
            }
          });
    } catch (e) {
      return Stream.value(Left(ServerFailure('Failed to watch products')));
    }
  }
}