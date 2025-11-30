import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../viewmodels/purchase_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/supplier_viewmodel.dart';
import '../../../app/routes/app_routes.dart';

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
      // بدء الاستماع لقائمة المشتريات
      context.read<PurchaseViewModel>().listenToAllPurchases();
      // تحميل بيانات المنتجات والموردين لعرض الأسماء بدلاً من المعرفات
      context.read<ProductViewModel>().loadProducts();
      context.read<SupplierViewModel>().loadSuppliers();
    });
  }

  @override
  Widget build(BuildContext context) {
    // نستخدم watch للاستماع للتغييرات في الحالة
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
          // حالة التحميل
          if (purchaseVm.state == PurchaseViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          // حالة الخطأ
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

          // القائمة فارغة
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

          // عرض القائمة
          return ListView.builder(
            itemCount: purchaseVm.purchases.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              final purchase = purchaseVm.purchases[index];

              // البحث عن اسم المنتج
              final product = productVm.products
                  .where((p) => p.id == purchase.productId)
                  .firstOrNull;
              final productName = product?.name ?? '---';

              // البحث عن اسم المورد
              final supplier = supplierVm.suppliers
                  .where((s) => s.id == purchase.supplierId)
                  .firstOrNull;
              final supplierName = supplier?.name ?? '---';

              // تنسيق التاريخ
              final dateStr = DateFormat.yMMMd(localizations.localeName).add_jm().format(purchase.createdAt);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // عرض الكمية (مع الكمية المجانية إن وجدت)
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            TextSpan(
                              text: '${purchase.quantity.toStringAsFixed(0)} ', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (purchase.freeQuantity > 0)
                              TextSpan(
                                text: '(+${purchase.freeQuantity.toStringAsFixed(0)})',
                                style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // عرض السعر
                      Text(
                        '${purchase.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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