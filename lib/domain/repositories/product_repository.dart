import 'package:dartz/dartz.dart';
import '../entities/product.dart';
import '../../core/errors/failures.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getAllProducts();
  Future<Either<Failure, Product>> getProductById(String id);
  Future<Either<Failure, List<Product>>> getProductsByCategory(String category);
  Future<Either<Failure, List<Product>>> getLowStockProducts();
  Future<Either<Failure, String>> addProduct(Product product);
  Future<Either<Failure, void>> updateProduct(Product product);
  Future<Either<Failure, void>> deleteProduct(String id);
  Future<Either<Failure, void>> updateProductStock(String id, double stock);
  Stream<Either<Failure, List<Product>>> watchProducts();
}