import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../../models/supplier_model.dart';
import '../../models/supplier_payment_model.dart'; // استيراد موديل الدفعات
import '../../../core/constants/firebase_constants.dart';

abstract class SupplierRemoteDataSource {
  Future<List<SupplierModel>> getAllSuppliers(String userId);
  Future<SupplierModel> getSupplierById(String userId, String supplierId);
  Future<String> addSupplier(String userId, SupplierModel supplier);
  Future<void> updateSupplier(String userId, SupplierModel supplier);
  Future<void> deleteSupplier(String userId, String supplierId);
  Stream<List<SupplierModel>> watchSuppliers(String userId);

  // --- دوال الدفعات الجديدة ---
  Future<String> addPayment(String userId, SupplierPaymentModel payment);
  Future<List<SupplierPaymentModel>> getSupplierPayments(String userId, String supplierId);
  Stream<List<SupplierPaymentModel>> watchSupplierPayments(String userId, String supplierId);
}

class SupplierRemoteDataSourceImpl implements SupplierRemoteDataSource {
  final FirebaseFirestore firestore;

  SupplierRemoteDataSourceImpl(this.firestore);

  CollectionReference _suppliersCollection(String userId) {
    return firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .collection(FirebaseConstants.suppliersCollection);
  }

  // دالة مساعدة للوصول لمجموعة المدفوعات الفرعية
  CollectionReference _paymentsCollection(String userId, String supplierId) {
    return _suppliersCollection(userId)
        .doc(supplierId)
        .collection('payments');
  }

  @override
  Future<List<SupplierModel>> getAllSuppliers(String userId) async {
    try {
      final snapshot = await _suppliersCollection(userId).get();
      return snapshot.docs
          .map((doc) => SupplierModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('getAllSuppliers failed', name: 'SupplierRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<SupplierModel> getSupplierById(String userId, String supplierId) async {
    try {
      final doc = await _suppliersCollection(userId).doc(supplierId).get();
      if (!doc.exists) throw Exception('Supplier not found');
      return SupplierModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      developer.log('getSupplierById failed', name: 'SupplierRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<String> addSupplier(String userId, SupplierModel supplier) async {
    try {
      final docRef = _suppliersCollection(userId).doc(supplier.id);
      await docRef.set(supplier.toJson());
      return supplier.id;
    } catch (e) {
      developer.log('addSupplier failed', name: 'SupplierRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updateSupplier(String userId, SupplierModel supplier) async {
    try {
      await _suppliersCollection(userId).doc(supplier.id).update(supplier.toJson());
    } catch (e) {
      developer.log('updateSupplier failed', name: 'SupplierRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<void> deleteSupplier(String userId, String supplierId) async {
    try {
      await _suppliersCollection(userId).doc(supplierId).delete();
    } catch (e) {
      developer.log('deleteSupplier failed', name: 'SupplierRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Stream<List<SupplierModel>> watchSuppliers(String userId) {
    return _suppliersCollection(userId).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => SupplierModel.fromJson(doc.data() as Map<String, dynamic>)).toList()).handleError((e) {
      developer.log('watchSuppliers stream error', name: 'SupplierRemoteDataSource', error: e);
      throw e;
    });
  }

  // --- تنفيذ دوال الدفعات ---

  @override
  Future<String> addPayment(String userId, SupplierPaymentModel payment) async {
    try {
      // نستخدم supplierId الموجود داخل كائن الدفعة لتحديد المسار الصحيح
      final docRef = _paymentsCollection(userId, payment.supplierId).doc(payment.id);
      await docRef.set(payment.toJson());
      return payment.id;
    } catch (e) {
      developer.log('addPayment failed', name: 'SupplierRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<List<SupplierPaymentModel>> getSupplierPayments(String userId, String supplierId) async {
    try {
      final snapshot = await _paymentsCollection(userId, supplierId)
          .orderBy('payment_date', descending: true) // الأحدث أولاً
          .get();
          
      return snapshot.docs
          .map((doc) => SupplierPaymentModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('getSupplierPayments failed', name: 'SupplierRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Stream<List<SupplierPaymentModel>> watchSupplierPayments(String userId, String supplierId) {
    return _paymentsCollection(userId, supplierId)
        .orderBy('payment_date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupplierPaymentModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList())
        .handleError((e) {
      developer.log('watchSupplierPayments stream error', name: 'SupplierRemoteDataSource', error: e);
      throw e;
    });
  }
}