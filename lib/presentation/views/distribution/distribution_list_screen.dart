
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import '../../../core/utils/service_locator.dart';
import '../../../data/datasources/local/distribution_local_datasource.dart';
import '../../viewmodels/distribution_viewmodel.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/product_model.dart';
import '../../../domain/entities/product.dart';
import '../../../data/datasources/local/customer_local_datasource.dart';
import '../../../data/datasources/local/product_local_datasource.dart';
import '../../../l10n/app_localizations.dart';

class DistributionListScreen extends StatefulWidget {
  const DistributionListScreen({super.key});

  @override
  State<DistributionListScreen> createState() => _DistributionListScreenState();
}

class _DistributionListScreenState extends State<DistributionListScreen> {
  @override
  void initState() {
    super.initState();
    developer.log('DistributionListScreen: initState', name: 'DistributionListScreen');
    // Trigger load of distributions from the viewmodel (local first, then remote)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<DistributionViewModel>().loadDistributions();
        developer.log('Requested DistributionViewModel.loadDistributions', name: 'DistributionListScreen');
      } catch (e) {
        developer.log('Error requesting loadDistributions: $e', name: 'DistributionListScreen');
      }
    });
  }

  @override
  void dispose() {
    developer.log('DistributionListScreen: dispose', name: 'DistributionListScreen');
    super.dispose();
  }

  Future<void> _testFirestoreAccess(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    developer.log('DistributionListScreen: testFirestoreAccess started', name: 'DistributionListScreen');
    if (uid == null) {
      developer.log('Not authenticated', name: 'DistributionListScreen');
      messenger.showSnackBar(SnackBar(content: Text(t.notAuthenticated)));
      return;
    }

    try {
      final q = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('distributions')
          .limit(1);
      final snapshot = await q.get();
      developer.log('Firestore read succeeded', name: 'DistributionListScreen', error: 'docs=${snapshot.docs.length}');
      final content = snapshot.docs.isEmpty
          ? 'No documents found under users/$uid/distributions (read succeeded).'
          : 'Found ${snapshot.docs.length} document(s). First id: ${snapshot.docs.first.id}';

      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.firestoreReadResult),
          content: Text(content),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.ok)),
          ],
        ),
      );
    } on FirebaseException catch (e) {
      developer.log('Firestore error', name: 'DistributionListScreen', error: '${e.code}: ${e.message}');
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.firestoreError),
          content: SingleChildScrollView(child: Text('code: ${e.code}\nmessage: ${e.message}\nstack: ${e.stackTrace}')),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.ok)),
          ],
        ),
      );
    } catch (e, st) {
      developer.log('Unexpected error reading Firestore', name: 'DistributionListScreen', error: e);
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.unexpectedError),
          content: SingleChildScrollView(child: Text('$e\n$st')),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.ok)),
          ],
        ),
      );
    }
  }

  Future<void> _showLocalDbCount(BuildContext context) async {
    try {
      final localDs = getIt<DistributionLocalDataSource>();
      final list = await localDs.getAllDistributions();
      final t = AppLocalizations.of(context)!;
      final content = list.isEmpty
          ? '${t.localDbDistributions}: 0'
          : '${t.localDbDistributions}: ${list.length} distributions. First id: ${list.first.id}';
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.localDbDistributions),
          content: Text(content),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.ok)),
          ],
        ),
      );
    } catch (e, st) {
      developer.log('Error reading local DB', name: 'DistributionListScreen', error: e);
      final t = AppLocalizations.of(context)!;
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.localDbError),
          content: SingleChildScrollView(child: Text('$e\n$st')),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.ok)),
          ],
        ),
      );
    }
  }

  Future<void> _createTestDistribution(BuildContext context) async {
    developer.log('Create test distribution requested', name: 'DistributionListScreen');
    final t = AppLocalizations.of(context)!;
    try {
      final customerDs = getIt<CustomerLocalDataSource>();
      final productDs = getIt<ProductLocalDataSource>();
      final vm = context.read<DistributionViewModel>();

      // Ensure at least one customer
      var customers = await customerDs.getAllCustomers();
      if (customers.isEmpty) {
        final id = const Uuid().v4();
        final now = DateTime.now();
        final testCustomer = CustomerModel(
          id: id,
          name: 'Test Customer',
          phone: '0000000000',
          createdAt: now,
          updatedAt: now,
        );
        await customerDs.insertCustomer(testCustomer);
        customers = [testCustomer];
        developer.log('Inserted test customer: $id', name: 'DistributionListScreen');
      }

      // Ensure at least one product
      var products = await productDs.getAllProducts();
      if (products.isEmpty) {
        final id = const Uuid().v4();
        final now = DateTime.now();
        final testProduct = ProductModel(
          id: id,
          name: 'Test Milk',
          category: ProductCategory.milk,
          unit: 'L',
          price: 30.0,
          createdAt: now,
          updatedAt: now,
        );
        await productDs.insertProduct(testProduct);
        products = [testProduct];
        developer.log('Inserted test product: $id', name: 'DistributionListScreen');
      }

      final customer = customers.first;
      final product = products.first;

      // Add item to viewmodel current items and create distribution
      vm.addItem(
        productId: product.id,
        productName: product.name,
        quantity: 1.0,
        price: product.price,
      );

      final ok = await vm.createDistribution(
        customerId: customer.id,
        customerName: customer.name,
        distributionDate: DateTime.now(),
      );
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.createTestDistribution),
          content: Text(ok ? t.createTestDistributionSuccess : '${t.createTestDistributionFailedPrefix} ${vm.errorMessage}'),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.ok))],
        ),
      );
    } catch (e, st) {
      developer.log('Error creating test distribution', name: 'DistributionListScreen', error: e);
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.unexpectedError),
          content: SingleChildScrollView(child: Text('$e\n$st')),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.ok))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    developer.log('DistributionListScreen: build', name: 'DistributionListScreen');
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.distributionListTitle),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.firestoreReadResult,
            icon: const Icon(Icons.cloud_outlined),
            onPressed: () => _testFirestoreAccess(context),
          ),
        ],
      ),
      body: Consumer<DistributionViewModel>(
        builder: (context, vm, child) {
          if (vm.state == DistributionViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.state == DistributionViewState.error) {
            return Center(child: Text(vm.errorMessage ?? AppLocalizations.of(context)!.failedToLoadDistributions));
          }

          final list = vm.distributions;
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context)!.noDistributionsToShow),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showLocalDbCount(context),
                    icon: const Icon(Icons.storage),
                    label: Text(AppLocalizations.of(context)!.showLocalDbDistributions),
                  ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _createTestDistribution(context),
                        icon: const Icon(Icons.add),
                        label: Text(AppLocalizations.of(context)!.createTestDistribution),
                      ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final dist = list[index];
              return ListTile(
                title: Text(dist.customerName),
                subtitle: Text('${dist.distributionDate.day}/${dist.distributionDate.month}/${dist.distributionDate.year}'),
                trailing: Text('₹${dist.totalAmount.toStringAsFixed(2)}'),
                onTap: () {
                  // For now just show details dialog
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('${AppLocalizations.of(context)!.distributionLabel} ${dist.id}'),
                      content: Text('Customer: ${dist.customerName}\nTotal: ₹${dist.totalAmount}'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(AppLocalizations.of(context)!.ok)),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
