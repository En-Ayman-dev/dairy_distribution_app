import 'package:dartz/dartz.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/product_remote_datasource.dart';
import '../models/product_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  Future<Either<Failure, List<Product>>> getAllProducts() async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      developer.log('getAllProducts called (Remote Only)', name: 'ProductRepository');
      final remoteProducts = await remoteDataSource.getAllProducts(_userId);
      return Right(remoteProducts);
    } catch (e) {
      developer.log('Failed to fetch products from remote', error: e, name: 'ProductRepository');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final remoteProduct = await remoteDataSource.getProductById(_userId, id);
      return Right(remoteProduct);
    } catch (e) {
      return Left(NotFoundFailure('Product not found'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProductsByCategory(String category) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      // In-Memory filtering
      final allProducts = await remoteDataSource.getAllProducts(_userId);
      // استخدام المقارنة النصية لأن Category في الكائن قد تكون Enum أو String حسب التنفيذ
      // هنا نعتمد على أن التحويل تم في Model
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
      final allProducts = await remoteDataSource.getAllProducts(_userId);
      
      final lowStockProducts = allProducts.where((p) {
        // --- تصحيح الخطأ هنا ---
        // استخدام p.stock بدلاً من p.currentStock
        // ومقارنتها بـ p.minStock الموجودة في النموذج
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
      await remoteDataSource.addProduct(_userId, productModel);
      return Right(product.id);
    } catch (e) {
      return Left(ServerFailure('Failed to add product'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(Product product) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final productModel = ProductModel.fromEntity(product);
      await remoteDataSource.updateProduct(_userId, productModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to update product'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      await remoteDataSource.deleteProduct(_userId, id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete product'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProductStock(String id, double stock) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      // Fetch current state
      // نحتاج لتحويل الـ Entity إلى Model لاستخدام copyWith
      // بما أن getProductById ترجع Entity (Product)، نحتاج للتأكد من التحويل
      final currentProductEntity = await remoteDataSource.getProductById(_userId, id);
      final currentProductModel = ProductModel.fromEntity(currentProductEntity);
      
      // --- تصحيح الخطأ هنا ---
      // استخدام stock: بدلاً من currentStock:
      final updatedProduct = currentProductModel.copyWith(stock: stock);
      
      await remoteDataSource.updateProduct(_userId, updatedProduct);
      return const Right(null);
    } catch (e) {
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
            throw e;
          });
    } catch (e) {
      return Stream.value(Left(ServerFailure('Failed to watch products')));
    }
  }
}