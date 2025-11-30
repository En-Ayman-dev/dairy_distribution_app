import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/purchase.dart';

abstract class PurchaseRepository {
  Future<Either<Failure, List<Purchase>>> getPurchasesForProduct(String productId);
  Future<Either<Failure, String>> addPurchase(Purchase purchase);
  Stream<Either<Failure, List<Purchase>>> watchPurchases();
  
  Future<Either<Failure, void>> processReturn(String purchaseId, double quantity);
}