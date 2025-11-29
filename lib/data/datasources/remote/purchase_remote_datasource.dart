import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../../models/purchase_model.dart';
import '../../../core/constants/firebase_constants.dart';

abstract class PurchaseRemoteDataSource {
  Future<List<PurchaseModel>> getPurchasesForProduct(String userId, String productId);
  Future<String> addPurchase(String userId, PurchaseModel purchase);
  Stream<List<PurchaseModel>> watchPurchases(String userId);
}

class PurchaseRemoteDataSourceImpl implements PurchaseRemoteDataSource {
  final FirebaseFirestore firestore;

  PurchaseRemoteDataSourceImpl(this.firestore);

  CollectionReference _purchasesCollection(String userId) {
    return firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .collection(FirebaseConstants.purchasesCollection);
  }

  CollectionReference _productsCollection(String userId) {
    return firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .collection(FirebaseConstants.productsCollection);
  }

  @override
  Future<List<PurchaseModel>> getPurchasesForProduct(String userId, String productId) async {
    try {
      final snapshot = await _purchasesCollection(userId).where('product_id', isEqualTo: productId).get();
      return snapshot.docs.map((doc) => PurchaseModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      developer.log('getPurchasesForProduct failed', name: 'PurchaseRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<String> addPurchase(String userId, PurchaseModel purchase) async {
    try {
      final docRef = _purchasesCollection(userId).doc(purchase.id);

      await firestore.runTransaction((transaction) async {
        final productDocRef = _productsCollection(userId).doc(purchase.productId);
        final productSnapshot = await transaction.get(productDocRef);
        if (!productSnapshot.exists) {
          throw Exception('Product not found');
        }

        final currentStock = (productSnapshot.data() as Map<String, dynamic>?)?['stock'] as num? ?? 0.0;
        final newStock = (currentStock).toDouble() + purchase.quantity;

        // update product's stock and price (update price to latest purchase price)
        transaction.set(docRef, purchase.toJson());
        transaction.update(productDocRef, {
          'stock': newStock,
          'price': purchase.price,
          'updated_at': DateTime.now().toIso8601String(),
        });
      });
      return purchase.id;
    } catch (e) {
      developer.log('addPurchase failed', name: 'PurchaseRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Stream<List<PurchaseModel>> watchPurchases(String userId) {
    return _purchasesCollection(userId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => PurchaseModel.fromJson(doc.data() as Map<String, dynamic>))
              .toList(),
        ).handleError((e) {
      developer.log('watchPurchases stream error', name: 'PurchaseRemoteDataSource', error: e);
      throw e;
    });
  }
}
