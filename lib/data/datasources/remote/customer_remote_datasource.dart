import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../../models/customer_model.dart';
import '../../../core/constants/firebase_constants.dart';

abstract class CustomerRemoteDataSource {
  Future<List<CustomerModel>> getAllCustomers(String userId);
  Future<CustomerModel> getCustomerById(String userId, String customerId);
  Future<String> addCustomer(String userId, CustomerModel customer);
  Future<void> updateCustomer(String userId, CustomerModel customer);
  Future<void> deleteCustomer(String userId, String customerId);
  Stream<List<CustomerModel>> watchCustomers(String userId);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final FirebaseFirestore firestore;

  CustomerRemoteDataSourceImpl(this.firestore);

  CollectionReference _customersCollection(String userId) {
    return firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .collection(FirebaseConstants.customersCollection);
  }

  @override
  Future<List<CustomerModel>> getAllCustomers(String userId) async {
    try {
      final snapshot = await _customersCollection(userId).get();
      return snapshot.docs
          .map((doc) => CustomerModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('getAllCustomers failed (remote)', name: 'CustomerRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<CustomerModel> getCustomerById(String userId, String customerId) async {
    try {
      final doc = await _customersCollection(userId).doc(customerId).get();
      if (!doc.exists) {
        throw Exception('Customer not found');
      }
      return CustomerModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      developer.log('getCustomerById failed (remote)', name: 'CustomerRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<String> addCustomer(String userId, CustomerModel customer) async {
    try {
      final docRef = _customersCollection(userId).doc(customer.id);
      await docRef.set(customer.toJson());
      return customer.id;
    } catch (e) {
      developer.log('addCustomer failed (remote)', name: 'CustomerRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updateCustomer(String userId, CustomerModel customer) async {
    try {
      await _customersCollection(userId).doc(customer.id).update(customer.toJson());
    } catch (e) {
      developer.log('updateCustomer failed (remote)', name: 'CustomerRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<void> deleteCustomer(String userId, String customerId) async {
    try {
      await _customersCollection(userId).doc(customerId).delete();
    } catch (e) {
      developer.log('deleteCustomer failed (remote)', name: 'CustomerRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Stream<List<CustomerModel>> watchCustomers(String userId) {
    return _customersCollection(userId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  CustomerModel.fromJson(doc.data() as Map<String, dynamic>))
              .toList(),
        ).handleError((e) {
      developer.log('watchCustomers stream error', name: 'CustomerRemoteDataSource', error: e);
      throw e;
    });
  }
}