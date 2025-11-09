import 'package:dartz/dartz.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../datasources/local/product_local_datasource.dart';
import '../datasources/remote/product_remote_datasource.dart';
import '../models/product_model.dart';
import '../../core/network/sync_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource localDataSource;
  final ProductRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final SyncManager syncManager;
  final FirebaseAuth firebaseAuth;

  ProductRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
    required this.syncManager,
    required this.firebaseAuth,
  });

  String get _userId => firebaseAuth.currentUser?.uid ?? '';
  bool get _isAuthenticated => firebaseAuth.currentUser != null;

  @override
  Future<Either<Failure, List<Product>>> getAllProducts() async {
    try {
      developer.log('getAllProducts called', name: 'ProductRepository');
      developer.log('currentUser uid', name: 'ProductRepository', error: firebaseAuth.currentUser?.uid);
      final localProducts = await localDataSource.getAllProducts();

      if (await networkInfo.isConnected) {
        try {
          developer.log('Attempting remote fetch for products', name: 'ProductRepository');
          developer.log('userId', name: 'ProductRepository', error: _userId);
          if (!_isAuthenticated) {
            return Right(localProducts);
          }
          final remoteProducts = await remoteDataSource.getAllProducts(_userId);

          // If remote returned no results but local has data, keep local to avoid
          // wiping the UI with an empty remote result.
          if (remoteProducts.isEmpty && localProducts.isNotEmpty) {
            developer.log('Remote empty, preserving local products', name: 'ProductRepository');
            return Right(localProducts);
          }

          for (var product in remoteProducts) {
            await localDataSource.insertProduct(product);
          }
          return Right(remoteProducts);
        } catch (e) {
          developer.log('Remote fetch products failed', name: 'ProductRepository', error: e);
          return Right(localProducts);
        }
      }

      return Right(localProducts);
    } catch (e) {
      return Left(DatabaseFailure('Failed to fetch products'));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    try {
      developer.log('getProductById called', name: 'ProductRepository');
      developer.log('currentUser uid', name: 'ProductRepository', error: firebaseAuth.currentUser?.uid);
      final product = await localDataSource.getProductById(id);
      
      if (product == null) {
        if (await networkInfo.isConnected) {
          try {
            developer.log('Attempting remote getProductById', name: 'ProductRepository', error: _userId);
            if (!_isAuthenticated) {
              return Left(AuthenticationFailure('User not authenticated'));
            }
            final remoteProduct = await remoteDataSource.getProductById(_userId, id);
            await localDataSource.insertProduct(remoteProduct);
            return Right(remoteProduct);
          } catch (e) {
            developer.log('Remote getProductById failed', name: 'ProductRepository', error: e);
            return Left(NotFoundFailure('Product not found'));
          }
        }
        return Left(NotFoundFailure('Product not found'));
      }

      return Right(product);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    String category,
  ) async {
    try {
      final products = await localDataSource.getProductsByCategory(category);
      return Right(products);
    } catch (e) {
      return Left(DatabaseFailure('Failed to fetch products by category'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getLowStockProducts() async {
    try {
      final products = await localDataSource.getLowStockProducts();
      return Right(products);
    } catch (e) {
      return Left(DatabaseFailure('Failed to fetch low stock products'));
    }
  }

  @override
  Future<Either<Failure, String>> addProduct(Product product) async {
    try {
      final productModel = ProductModel.fromEntity(product);
      
      await localDataSource.insertProduct(productModel);

      await syncManager.queueSync(
        entityType: 'product',
        entityId: product.id,
        operation: 'create',
        data: productModel.toJson(),
      );

      if (await networkInfo.isConnected) {
        try {
          if (_isAuthenticated) {
            await remoteDataSource.addProduct(_userId, productModel);
            await syncManager.markAsSynced('product', product.id);
          }
        } catch (e) {
          // Will be synced later
        }
      }

      return Right(product.id);
    } catch (e) {
      return Left(DatabaseFailure('Failed to add product'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(Product product) async {
    try {
      final productModel = ProductModel.fromEntity(product);
      
      await localDataSource.updateProduct(productModel);

      await syncManager.queueSync(
        entityType: 'product',
        entityId: product.id,
        operation: 'update',
        data: productModel.toJson(),
      );

      if (await networkInfo.isConnected) {
        try {
          if (_isAuthenticated) {
            await remoteDataSource.updateProduct(_userId, productModel);
            await syncManager.markAsSynced('product', product.id);
          }
        } catch (e) {
          // Will be synced later
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update product'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      await localDataSource.deleteProduct(id);

      await syncManager.queueSync(
        entityType: 'product',
        entityId: id,
        operation: 'delete',
        data: {'id': id},
      );

      if (await networkInfo.isConnected) {
        try {
          if (_isAuthenticated) {
            await remoteDataSource.deleteProduct(_userId, id);
            await syncManager.markAsSynced('product', id);
          }
        } catch (e) {
          // Will be synced later
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete product'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProductStock(String id, double stock) async {
    try {
      await localDataSource.updateProductStock(id, stock);

      if (await networkInfo.isConnected) {
        final product = await localDataSource.getProductById(id);
        if (product != null) {
          if (_isAuthenticated) {
            await remoteDataSource.updateProduct(_userId, product);
          }
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update product stock'));
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
              developer.log('Permission denied watching products', name: 'ProductRepository', error: e);
              throw AuthenticationFailure('Insufficient permissions to read products');
            }
            throw e;
          });
    } catch (e) {
      return Stream.value(Left(ServerFailure('Failed to watch products')));
    }
  }
}