import 'dart:async';

// This is a command-line migration script meant to be executed by a developer
// with the proper Firebase credentials. It converts existing product stock and
// price fields into Purchase documents and creates a legacy supplier.

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  // IMPORTANT: You must run this with valid firebase credentials in your
  // development environment.
  print('Initializing Firebase...');
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;

  // The script expects to be run as an admin / with a user authenticated.
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('Please sign in with Firebase to run migration.');
    return;
  }

  final uid = user.uid;
  print('Migrating products for user: $uid');

  final productsCollection = firestore.collection('users').doc(uid).collection('products');
  final suppliersCollection = firestore.collection('users').doc(uid).collection('suppliers');
  final purchasesCollection = firestore.collection('users').doc(uid).collection('purchases');

  // Ensure the 'legacy' supplier exists
  final legacySupplierDoc = suppliersCollection.doc('legacy');
  final legacySupplier = await legacySupplierDoc.get();
  if (!legacySupplier.exists) {
    await legacySupplierDoc.set({
      'id': 'legacy',
      'name': 'Legacy Supplier',
      'contact': null,
      'address': null,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    print('Created legacy supplier');
  }

  final snapshot = await productsCollection.get();
  for (final doc in snapshot.docs) {
    final data = doc.data();
    final stock = (data['stock'] as num?)?.toDouble() ?? 0.0;
    final price = (data['price'] as num?)?.toDouble() ?? 0.0;
    if (stock > 0 || price > 0) {
      final purchaseDoc = purchasesCollection.doc();
      await firestore.runTransaction((transaction) async {
        transaction.set(purchaseDoc, {
          'id': purchaseDoc.id,
          'product_id': doc.id,
          'supplier_id': 'legacy',
          'quantity': stock,
          'price': price,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      });
      print('Created purchase for ${doc.id} stock=$stock price=$price');
      // Optionally set product stock to 0 if you want to move stock responsibility
      // await productsCollection.doc(doc.id).update({
      //   'stock': 0.0,
      //   'updated_at': DateTime.now().toIso8601String(),
      // });
    }
  }

  print('Migration completed.');
}
