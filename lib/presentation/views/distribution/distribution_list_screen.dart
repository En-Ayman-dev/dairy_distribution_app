
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
import '../../../domain/entities/distribution.dart';
import '../../../domain/entities/distribution_item.dart';
import '../../../core/utils/pdf_generator.dart';
import '../../widgets/print_button.dart';
import 'package:open_file/open_file.dart';
import '../../../l10n/app_localizations.dart';
import 'distribution_detail_screen.dart';

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
    final t = AppLocalizations.of(context)!;
    final isAr = t.locale.languageCode == 'ar';
    final printTooltip = isAr ? 'طباعة' : 'Print';
    final editTooltip = isAr ? 'تعديل' : 'Edit';

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
                trailing: SizedBox(
                  width: 200,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Make the amount text flexible and ellipsize if it's too long
                      Flexible(
                        child: Text(
                          'ريال${dist.totalAmount.toStringAsFixed(2)}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Use compact icon buttons to save horizontal space
                      IconButton(
                        tooltip: printTooltip,
                        icon: const Icon(Icons.print),
                        iconSize: 20,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () => _showPrintDialogForDistribution(dist),
                      ),
                      IconButton(
                        tooltip: editTooltip,
                        icon: const Icon(Icons.edit),
                        iconSize: 20,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () => _showEditDialog(dist),
                      ),
                      IconButton(
                        tooltip: t.deleteLabel,
                        icon: const Icon(Icons.delete_outline),
                        iconSize: 20,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () => _confirmAndDelete(dist),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  // For now open detail screen
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => DistributionDetailScreen(distribution: dist)));
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showPrintDialogForDistribution(Distribution dist) async {
    PrinterSize selected = kPrinterSizes.first;
    PrintOutput output = PrintOutput.pdf;
    bool preview = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: const Text('اختيار مقاس الطابعة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final size in kPrinterSizes)
                  RadioListTile<PrinterSize>(
                    value: size,
                    groupValue: selected,
                    onChanged: (v) => setState(() => selected = v!),
                    title: Text('${size.name} (عرض فعلي ~${size.printableWidthMm}mm) - ${size.description}'),
                  ),
                const Divider(),
                RadioListTile<PrintOutput>(
                  value: PrintOutput.printer,
                  groupValue: output,
                  onChanged: (v) => setState(() => output = v!),
                  title: const Text('طباعة إلى طابعة حرارية'),
                ),
                RadioListTile<PrintOutput>(
                  value: PrintOutput.pdf,
                  groupValue: output,
                  onChanged: (v) => setState(() => output = v!),
                  title: const Text('حفظ / عرض PDF'),
                ),
                if (output == PrintOutput.pdf)
                  CheckboxListTile(
                    value: preview,
                    onChanged: (v) => setState(() => preview = v ?? false),
                    title: const Text('عرض ملف PDF بعد الإنشاء'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await _printDistribution(dist, selected, output, preview);
              },
              icon: const Icon(Icons.print),
              label: const Text('طباعة'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _printDistribution(Distribution dist, PrinterSize size, PrintOutput output, bool preview) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final vm = context.read<DistributionViewModel>();

      // Ensure we load the saved distribution details
      await vm.getDistributionById(dist.id);
      final distribution = vm.selectedDistribution ?? dist;

      // Load customer details from local datasource
      final customerDs = getIt<CustomerLocalDataSource>();
      final customer = await customerDs.getCustomerById(distribution.customerId);
      if (customer == null) {
        messenger.showSnackBar(SnackBar(content: Text('Customer not found')));
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text(output == PrintOutput.pdf
          ? 'سيتم إنشاء ملف PDF للمسح/الطباعة بمقاس ${size.name}'
          : 'سيتم طباعة الفاتورة بمقاس ${size.name} (عرض فعلي ${size.printableWidthMm}mm)')));

      if (output == PrintOutput.pdf) {
        final pdfGen = PDFGenerator();
        final path = await pdfGen.generateDistributionInvoice(
          customer: customer,
          items: distribution.items,
          total: distribution.totalAmount,
          paid: distribution.paidAmount,
          previousBalance: customer.balance,
          dateTime: distribution.distributionDate,
          createdBy: FirebaseAuth.instance.currentUser?.displayName ?? 'المستخدم',
          printerSize: size,
          notes: distribution.notes,
        );

        if (!mounted) return;
        final snack = SnackBar(
          content: Text('تم إنشاء PDF: ${path.split(RegExp(r"[\\/]")).last}'),
          action: SnackBarAction(label: 'فتح', onPressed: () => OpenFile.open(path)),
          duration: const Duration(seconds: 6),
        );
        messenger.showSnackBar(snack);

        if (preview) OpenFile.open(path);
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('طباعة مباشرة غير مدعومة حالياً')));
      }
    } catch (e, st) {
      developer.log('Error printing distribution: $e\n$st', name: 'DistributionListScreen', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الطباعة: $e')));
    }
  }

  Future<void> _confirmAndDelete(Distribution dist) async {
    final vm = context.read<DistributionViewModel>();
    final t = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deleteCustomerTitle),
        content: Text('${t.deleteCustomerConfirm} \n${t.distributionLabel} ${dist.id}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.deleteCancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: Text(t.deleteLabel)),
        ],
      ),
    );

    if (confirm == true) {
      final success = await vm.deleteDistribution(dist.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t.distributionLabel} ${dist.id} ${t.customerDeletedSuccess}'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? t.errorOccurred), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _showEditDialog(Distribution dist) async {
    final vm = context.read<DistributionViewModel>();
    final t = AppLocalizations.of(context)!;
    // Prepare controllers for items, paid and notes
    final paidController = TextEditingController(text: dist.paidAmount.toStringAsFixed(2));
    final notesController = TextEditingController(text: dist.notes ?? '');

    final qtyControllers = dist.items.map((it) => TextEditingController(text: it.quantity.toString())).toList();
    final priceControllers = dist.items.map((it) => TextEditingController(text: it.price.toStringAsFixed(2))).toList();

    double computeTotal() {
      double s = 0.0;
      for (var i = 0; i < dist.items.length; i++) {
        final q = double.tryParse(qtyControllers[i].text) ?? dist.items[i].quantity;
        final p = double.tryParse(priceControllers[i].text) ?? dist.items[i].price;
        s += q * p;
      }
      return s;
    }

    double currentTotal = computeTotal();

    await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: Text('${t.distributionLabel} ${dist.id}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${t.customerDetailsTitle}: ${dist.customerName}'),
                const SizedBox(height: 8),
                // Items editing
                ...List.generate(dist.items.length, (i) {
                  final it = dist.items[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: qtyControllers[i],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: '${t.quantityLabel}'),
                              onChanged: (_) => setState(() => currentTotal = computeTotal()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: priceControllers[i],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: t.priceLabel),
                              onChanged: (_) => setState(() => currentTotal = computeTotal()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }),

                const Divider(),
                Text('الإجمالي: ريال${currentTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                TextField(
                  controller: paidController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: t.paid),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  keyboardType: TextInputType.text,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: 'ملاحظات'),
                ),
                const SizedBox(height: 8),
                Builder(builder: (__) {
                  final newPaid = double.tryParse(paidController.text) ?? dist.paidAmount;
                  final remaining = (currentTotal - newPaid).clamp(0, double.infinity);
                  return Text('المتبقي: ريال${remaining.toStringAsFixed(2)}');
                }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
            ElevatedButton(
              onPressed: () async {
                // Build updated items
                final updatedItems = <DistributionItem>[];
                for (var i = 0; i < dist.items.length; i++) {
                  final it = dist.items[i];
                  final q = double.tryParse(qtyControllers[i].text) ?? it.quantity;
                  final p = double.tryParse(priceControllers[i].text) ?? it.price;
                  updatedItems.add(it.copyWith(quantity: q, price: p, subtotal: q * p));
                }

                final newTotal = updatedItems.fold(0.0, (s, it) => s + it.subtotal);
                final newPaid = double.tryParse(paidController.text) ?? dist.paidAmount;
                final newNotes = notesController.text.trim();

                PaymentStatus newStatus = PaymentStatus.pending;
                if (newPaid >= newTotal) {
                  newStatus = PaymentStatus.paid;
                } else if (newPaid > 0) {
                  newStatus = PaymentStatus.partial;
                }

                final updated = dist.copyWith(
                  items: updatedItems,
                  totalAmount: newTotal,
                  paidAmount: newPaid,
                  notes: newNotes.isEmpty ? null : newNotes,
                  paymentStatus: newStatus,
                  updatedAt: DateTime.now(),
                );

                Navigator.pop(ctx, true);

                final ok = await vm.updateDistribution(updated);
                if (!mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t.distributionLabel} ${dist.id} updated'), backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? t.errorOccurred), backgroundColor: Colors.red));
                }
              },
              child: Text(t.confirm),
            ),
          ],
        );
      }),
    );

    // dispose controllers
    paidController.dispose();
    notesController.dispose();
    for (final c in qtyControllers) {
      c.dispose();
    }
    for (final c in priceControllers) {
      c.dispose();
    }
    return;
  }
}
