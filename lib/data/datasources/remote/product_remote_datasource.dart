import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../../models/product_model.dart';
import '../../../core/constants/firebase_constants.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getAllProducts(String userId);
  Future<ProductModel> getProductById(String userId, String productId);
  Future<String> addProduct(String userId, ProductModel product);
  Future<void> updateProduct(String userId, ProductModel product);
  Future<void> deleteProduct(String userId, String productId);
  Stream<List<ProductModel>> watchProducts(String userId);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final FirebaseFirestore firestore;

  ProductRemoteDataSourceImpl(this.firestore);

  CollectionReference _productsCollection(String userId) {
    return firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .collection(FirebaseConstants.productsCollection);
  }

  @override
  Future<List<ProductModel>> getAllProducts(String userId) async {
    try {
      final snapshot = await _productsCollection(userId).get();
      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('getAllProducts failed', name: 'ProductRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<ProductModel> getProductById(String userId, String productId) async {
    try {
      final doc = await _productsCollection(userId).doc(productId).get();
      if (!doc.exists) {
        throw Exception('Product not found');
      }
      return ProductModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      developer.log('getProductById failed', name: 'ProductRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<String> addProduct(String userId, ProductModel product) async {
    try {
      final docRef = _productsCollection(userId).doc(product.id);
      await docRef.set(product.toJson());
      return product.id;
    } catch (e) {
      developer.log('addProduct failed', name: 'ProductRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updateProduct(String userId, ProductModel product) async {
    try {
      await _productsCollection(userId).doc(product.id).update(product.toJson());
    } catch (e) {
      developer.log('updateProduct failed', name: 'ProductRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(String userId, String productId) async {
    try {
      await _productsCollection(userId).doc(productId).delete();
    } catch (e) {
      developer.log('deleteProduct failed', name: 'ProductRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Stream<List<ProductModel>> watchProducts(String userId) {
    return _productsCollection(userId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  ProductModel.fromJson(doc.data() as Map<String, dynamic>))
              .toList(),
        ).handleError((e) {
      developer.log('watchProducts stream error', name: 'ProductRemoteDataSource', error: e);
      throw e;
    });
  }
}