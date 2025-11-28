import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../../models/distribution_model.dart';
import '../../models/distribution_item_model.dart';
import '../../../core/constants/firebase_constants.dart';

abstract class DistributionRemoteDataSource {
  Future<List<DistributionModel>> getAllDistributions(String userId);
  Future<DistributionModel> getDistributionById(String userId, String distributionId);
  Future<String> createDistribution(String userId, DistributionModel distribution);
  Future<void> updateDistribution(String userId, DistributionModel distribution);
  Future<void> deleteDistribution(String userId, String distributionId);
}

class DistributionRemoteDataSourceImpl
    implements DistributionRemoteDataSource {
  final FirebaseFirestore firestore;

  DistributionRemoteDataSourceImpl(this.firestore);

  CollectionReference _distributionsCollection(String userId) {
    return firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .collection(FirebaseConstants.distributionsCollection);
  }

  CollectionReference _distributionItemsCollection(
      String userId, String distributionId) {
    return _distributionsCollection(userId)
        .doc(distributionId)
        .collection(FirebaseConstants.distributionItemsCollection);
  }

  @override
  Future<List<DistributionModel>> getAllDistributions(String userId) async {
    try {
      final snapshot = await _distributionsCollection(userId)
          .orderBy('distribution_date', descending: true)
          .get();

      List<DistributionModel> distributions = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final items = await _getDistributionItems(userId, doc.id);
        developer.log('Read remote distribution doc: id=${doc.id} data=$data', name: 'DistributionRemoteDataSource');
        distributions.add(DistributionModel.fromJson(data, items));
      }
      return distributions;
    } catch (e) {
      developer.log('getAllDistributions failed (remote)', name: 'DistributionRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<DistributionModel> getDistributionById(
      String userId, String distributionId) async {
    try {
      final doc = await _distributionsCollection(userId).doc(distributionId).get();
      if (!doc.exists) {
        throw Exception('Distribution not found');
      }
        final items = await _getDistributionItems(userId, distributionId);
        developer.log('Read remote distribution by id=$distributionId', name: 'DistributionRemoteDataSource');
      return DistributionModel.fromJson(
          doc.data() as Map<String, dynamic>, items);
    } catch (e) {
      developer.log('getDistributionById failed (remote)', name: 'DistributionRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<String> createDistribution(
      String userId, DistributionModel distribution) async {
    try {
      final batch = firestore.batch();

      // Add distribution
      final distributionRef =
          _distributionsCollection(userId).doc(distribution.id);
      final distributionJson = distribution.toJson();
      developer.log('Creating distribution remote: id=${distribution.id} json=$distributionJson', name: 'DistributionRemoteDataSource');
      batch.set(distributionRef, distributionJson);

      // Add distribution items
      for (var item in distribution.items) {
        final itemModel = DistributionItemModel.fromEntity(item);
        final itemRef =
            _distributionItemsCollection(userId, distribution.id).doc(item.id);
        batch.set(itemRef, itemModel.toJson());
      }

      await batch.commit();
      return distribution.id;
    } catch (e) {
      developer.log('createDistribution failed (remote)', name: 'DistributionRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updateDistribution(
      String userId, DistributionModel distribution) async {
    try {
      final batch = firestore.batch();

      // Update distribution
      final distributionRef =
          _distributionsCollection(userId).doc(distribution.id);
      batch.update(distributionRef, distribution.toJson());

      // Delete old items
      final oldItems =
          await _distributionItemsCollection(userId, distribution.id).get();
      for (var doc in oldItems.docs) {
        batch.delete(doc.reference);
      }

      // Add new items
      for (var item in distribution.items) {
        final itemModel = DistributionItemModel.fromEntity(item);
        final itemRef =
            _distributionItemsCollection(userId, distribution.id).doc(item.id);
        batch.set(itemRef, itemModel.toJson());
      }

      await batch.commit();
    } catch (e) {
      developer.log('updateDistribution failed (remote)', name: 'DistributionRemoteDataSource', error: e);
      rethrow;
    }
  }

  @override
  Future<void> deleteDistribution(String userId, String distributionId) async {
    try {
      final batch = firestore.batch();

      // Delete items
      final items = await _distributionItemsCollection(userId, distributionId).get();
      for (var doc in items.docs) {
        batch.delete(doc.reference);
      }

      // Delete distribution
      final distributionRef =
          _distributionsCollection(userId).doc(distributionId);
      batch.delete(distributionRef);

      await batch.commit();
    } catch (e) {
      developer.log('deleteDistribution failed (remote)', name: 'DistributionRemoteDataSource', error: e);
      rethrow;
    }
  }

  Future<List<DistributionItemModel>> _getDistributionItems(
      String userId, String distributionId) async {
    try {
    final snapshot =
      await _distributionItemsCollection(userId, distributionId).get();
      return snapshot.docs
          .map((doc) =>
              DistributionItemModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('_getDistributionItems failed (remote)', name: 'DistributionRemoteDataSource', error: e);
      rethrow;
    }
  }
}