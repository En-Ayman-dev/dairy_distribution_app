import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../../models/purchase_model.dart';
import '../../models/purchase_item_model.dart'; 
import '../../../core/constants/firebase_constants.dart';

abstract class PurchaseRemoteDataSource {
  Future<List<PurchaseModel>> getPurchasesForProduct(String userId, String productId);
  Future<String> addPurchase(String userId, PurchaseModel purchase);
  Stream<List<PurchaseModel>> watchPurchases(String userId);
  Future<void> processReturn(String userId, String purchaseId, String productId, double returnQuantity);
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
      final snapshot = await _purchasesCollection(userId)
          .where('product_ids', arrayContains: productId)
          .get();
      
      return snapshot.docs
          .map((doc) => PurchaseModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
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
        // --- 1. مرحلة القراءة (Read Phase) ---
        // نقوم بجمع كل المراجع (References) للمنتجات أولاً
        // وقراءتها جميعاً قبل القيام بأي عملية كتابة
        Map<String, DocumentSnapshot> productSnapshots = {};

        for (var item in purchase.items) {
          final productDocRef = _productsCollection(userId).doc(item.productId);
          final snapshot = await transaction.get(productDocRef);
          productSnapshots[item.productId] = snapshot;
        }

        // --- 2. مرحلة الكتابة (Write Phase) ---
        // الآن نقوم بالحسابات والتحديثات بناءً على البيانات التي قرأناها
        for (var item in purchase.items) {
          final snapshot = productSnapshots[item.productId];
          
          if (snapshot == null || !snapshot.exists) {
            throw Exception('Product ${item.productId} not found');
          }

          final productDocRef = _productsCollection(userId).doc(item.productId);
          final currentStock = (snapshot.data() as Map<String, dynamic>?)?['stock'] as num? ?? 0.0;
          
          // حساب المخزون الجديد
          final newStock = (currentStock).toDouble() + item.quantity + item.freeQuantity;

          // تنفيذ التحديث (Write)
          transaction.update(productDocRef, {
            'stock': newStock,
            'price': item.price, 
            'updated_at': DateTime.now().toIso8601String(),
          });
        }

        // وأخيراً حفظ الفاتورة (Write)
        final purchaseData = purchase.toJson();
        purchaseData['product_ids'] = purchase.items.map((e) => e.productId).toList();

        transaction.set(docRef, purchaseData);
      });
      
      return purchase.id;
    } catch (e) {
      developer.log('addPurchase failed', name: 'PurchaseRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Stream<List<PurchaseModel>> watchPurchases(String userId) {
    return _purchasesCollection(userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PurchaseModel.fromJson(doc.data() as Map<String, dynamic>))
              .toList(),
        ).handleError((e) {
      developer.log('watchPurchases stream error', name: 'PurchaseRemoteDataSource', error: e);
      throw e;
    });
  }

  @override
  Future<void> processReturn(String userId, String purchaseId, String productId, double returnQuantity) async {
    try {
      final purchaseRef = _purchasesCollection(userId).doc(purchaseId);

      await firestore.runTransaction((transaction) async {
        // 1. قراءة الفاتورة (Read)
        final purchaseSnapshot = await transaction.get(purchaseRef);
        if (!purchaseSnapshot.exists) {
          throw Exception('Purchase invoice not found');
        }

        final purchaseData = purchaseSnapshot.data() as Map<String, dynamic>;
        final purchase = PurchaseModel.fromJson(purchaseData);

        // 2. قراءة المنتج (Read)
        final productDocRef = _productsCollection(userId).doc(productId);
        final productSnapshot = await transaction.get(productDocRef);
        if (!productSnapshot.exists) {
           throw Exception('Product document not found');
        }

        // --- انتهت مرحلة القراءة، نبدأ المنطق والحسابات ---

        // العثور على العنصر المستهدف
        final itemIndex = purchase.items.indexWhere((item) => item.productId == productId);
        if (itemIndex == -1) {
          throw Exception('Product not found in this invoice');
        }
        final targetItem = purchase.items[itemIndex];

        // التحقق من الكميات
        final totalItemQuantity = targetItem.quantity + targetItem.freeQuantity;
        final availableToReturn = totalItemQuantity - targetItem.returnedQuantity;
        
        if (returnQuantity > availableToReturn) {
          throw Exception('الكمية المراد إرجاعها تتجاوز الكمية المتاحة في الفاتورة لهذا الصنف');
        }

        final currentStock = (productSnapshot.data() as Map<String, dynamic>?)?['stock'] as num? ?? 0.0;
        
        if (returnQuantity > currentStock) {
           throw Exception('لا يمكن إرجاع الكمية لأن المخزون الحالي أقل من المطلوب (تم بيع جزء من البضاعة)');
        }

        // --- 3. مرحلة الكتابة (Write) ---

        // تحديث العنصر في الذاكرة
        final updatedItem = PurchaseItemModel.fromEntity(targetItem).copyWith(
          returnedQuantity: targetItem.returnedQuantity + returnQuantity,
        );
        
        final List<PurchaseItemModel> updatedItems = List.from(purchase.items.map((e) => PurchaseItemModel.fromEntity(e)));
        updatedItems[itemIndex] = PurchaseItemModel.fromEntity(updatedItem);

        // تحديث الفاتورة في قاعدة البيانات
        transaction.update(purchaseRef, {
          'items': updatedItems.map((e) => e.toJson()).toList(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // تحديث مخزون المنتج
        transaction.update(productDocRef, {
          'stock': (currentStock).toDouble() - returnQuantity,
          'updated_at': DateTime.now().toIso8601String(),
        });
      });
    } catch (e) {
      developer.log('processReturn failed', name: 'PurchaseRemoteDataSource', error: e);
      rethrow;
    }
  }
}