import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../viewmodels/purchase_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/supplier_viewmodel.dart';
import '../../../app/routes/app_routes.dart';
import '../../../domain/entities/purchase.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseViewModel>().listenToAllPurchases();
      context.read<ProductViewModel>().loadProducts();
      context.read<SupplierViewModel>().loadSuppliers();
    });
  }

  void _showReturnDialog(BuildContext parentContext, Purchase purchase) {
    final qtyController = TextEditingController();
    final totalQty = purchase.quantity + purchase.freeQuantity;
    final remainingQty = totalQty - purchase.returnedQuantity;

    showDialog(
      context: parentContext,
      // التعديل هنا: استخدام اسم مختلف لسياق الـ Dialog لتجنب التضارب
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل مرتجع / تالف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الكمية المتاحة للإرجاع: ${remainingQty.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'الكمية المراد إرجاعها',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // استخدام dialogContext للإغلاق
            child: Text(AppLocalizations.of(parentContext)!.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final qty = double.tryParse(qtyController.text) ?? 0.0;
              if (qty <= 0) {
                // نستخدم dialogContext هنا لأن الـ Dialog لا يزال مفتوحاً
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('الرجاء إدخال كمية صحيحة')),
                );
                return;
              }
              if (qty > remainingQty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('الكمية المدخلة تتجاوز الكمية المتاحة')),
                );
                return;
              }

              // إغلاق المربع
              Navigator.pop(dialogContext);

              // التحقق من أن الشاشة لا تزال موجودة
              if (!mounted) return;

              // استخدام parentContext (سياق الشاشة) لتنفيذ العملية
              final success = await parentContext
                  .read<PurchaseViewModel>()
                  .returnPurchase(purchaseId: purchase.id, quantity: qty);

              // التحقق مرة أخرى بعد العملية غير المتزامنة
              if (success && mounted) {
                // استخدام parentContext لإظهار الرسالة لأن الـ Dialog قد أغلق
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('تم تسجيل المرتجع وتحديث المخزون بنجاح')),
                );
              }
            },
            child: const Text('تأكيد المرتجع'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchaseVm = context.watch<PurchaseViewModel>();
    final productVm = context.watch<ProductViewModel>();
    final supplierVm = context.watch<SupplierViewModel>();
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.purchaseListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.addPurchase);
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (purchaseVm.state == PurchaseViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (purchaseVm.state == PurchaseViewState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(purchaseVm.errorMessage ?? localizations.errorOccurred),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.read<PurchaseViewModel>().listenToAllPurchases(),
                    child: Text(localizations.retry),
                  ),
                ],
              ),
            );
          }
          if (purchaseVm.purchases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(localizations.noRecentActivity, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: purchaseVm.purchases.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              final purchase = purchaseVm.purchases[index];
              
              final product = productVm.products
                  .where((p) => p.id == purchase.productId)
                  .firstOrNull;
              final productName = product?.name ?? '---';

              final supplier = supplierVm.suppliers
                  .where((s) => s.id == purchase.supplierId)
                  .firstOrNull;
              final supplierName = supplier?.name ?? '---';

              final dateStr = DateFormat.yMMMd(localizations.localeName)
                  .add_jm()
                  .format(purchase.createdAt);

              final hasReturns = purchase.returnedQuantity > 0;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Column(
                  children: [
                    // القسم العلوي: تفاصيل المنتج والمورد
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Icon(Icons.shopping_bag_outlined, color: Theme.of(context).primaryColor),
                      ),
                      title: Text(
                        productName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.store, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(supplierName, style: TextStyle(color: Colors.grey[800])),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // القسم السفلي: الكميات، السعر، وزر المرتجع
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // عمود المعلومات المالية والكمية
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text("الكمية: ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    RichText(
                                      text: TextSpan(
                                        style: DefaultTextStyle.of(context).style,
                                        children: [
                                          TextSpan(
                                            text: purchase.quantity.toStringAsFixed(0),
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          if (purchase.freeQuantity > 0)
                                            TextSpan(
                                              text: ' (+${purchase.freeQuantity.toStringAsFixed(0)} مجاني)',
                                              style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (hasReturns)
                                  Text(
                                    'مرتجع: ${purchase.returnedQuantity.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  '${purchase.price.toStringAsFixed(2)} ريال',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // زر المرتجع
                          OutlinedButton.icon(
                            onPressed: () => _showReturnDialog(context, purchase),
                            icon: const Icon(Icons.assignment_return, size: 18, color: Colors.orange),
                            label: const Text("مرتجع", style: TextStyle(color: Colors.orange)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.orange),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addPurchase);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}