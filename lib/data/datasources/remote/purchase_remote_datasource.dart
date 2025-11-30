import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../../models/purchase_model.dart';
import '../../../core/constants/firebase_constants.dart';

abstract class PurchaseRemoteDataSource {
  Future<List<PurchaseModel>> getPurchasesForProduct(String userId, String productId);
  Future<String> addPurchase(String userId, PurchaseModel purchase);
  Stream<List<PurchaseModel>> watchPurchases(String userId);
  Future<void> processReturn(String userId, String purchaseId, double returnQuantity);
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
        
        // إضافة الكمية المشتراة + الكمية المجانية إلى المخزون
        final newStock = (currentStock).toDouble() + purchase.quantity + purchase.freeQuantity;

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

  // --- دالة معالجة المرتجعات (تم التحديث لإضافة شرط المخزون) ---
  @override
  Future<void> processReturn(String userId, String purchaseId, double returnQuantity) async {
    try {
      final purchaseRef = _purchasesCollection(userId).doc(purchaseId);

      await firestore.runTransaction((transaction) async {
        // 1. قراءة الفاتورة الحالية
        final purchaseSnapshot = await transaction.get(purchaseRef);
        if (!purchaseSnapshot.exists) {
          throw Exception('Purchase not found');
        }

        final purchaseData = purchaseSnapshot.data() as Map<String, dynamic>;
        final purchase = PurchaseModel.fromJson(purchaseData);

        // 2. قراءة المنتج لتحديث المخزون والتحقق منه
        final productDocRef = _productsCollection(userId).doc(purchase.productId);
        final productSnapshot = await transaction.get(productDocRef);
        if (!productSnapshot.exists) {
           throw Exception('Product associated with purchase not found');
        }
        
        final currentStock = (productSnapshot.data() as Map<String, dynamic>?)?['stock'] as num? ?? 0.0;

        // 3. التحقق المزدوج (الشرط الجديد + الشرط القديم)
        
        // أ) التحقق من أن الكمية المرتجعة لا تتجاوز الكمية المتاحة في الفاتورة الأصلية
        final totalPurchasedAmount = purchase.quantity + purchase.freeQuantity;
        final alreadyReturned = purchase.returnedQuantity;
        if ((alreadyReturned + returnQuantity) > totalPurchasedAmount) {
          throw Exception('الكمية المراد إرجاعها تتجاوز الكمية في الفاتورة');
        }

        // ب) التحقق من أن الكمية المرتجعة لا تتجاوز المخزون الحالي للمنتج
        // (لا يمكن إرجاع بضاعة تم بيعها بالفعل)
        if (returnQuantity > currentStock) {
           throw Exception('لا يمكن إرجاع الكمية لأن المخزون الحالي أقل من المطلوب (تم بيع جزء من البضاعة)');
        }
        
        // 4. خصم الكمية المرتجعة من المخزون
        final newStock = (currentStock).toDouble() - returnQuantity;

        // 5. تنفيذ التحديثات
        transaction.update(purchaseRef, {
          'returned_quantity': alreadyReturned + returnQuantity,
          'updated_at': DateTime.now().toIso8601String(),
        });

        transaction.update(productDocRef, {
          'stock': newStock,
          'updated_at': DateTime.now().toIso8601String(),
        });
      });
    } catch (e) {
      developer.log('processReturn failed', name: 'PurchaseRemoteDataSource', error: e);
      // إعادة رمي الخطأ ليتم عرضه للمستخدم في الواجهة
      rethrow;
    }
  }
}