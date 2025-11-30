import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../viewmodels/purchase_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/supplier_viewmodel.dart';
import '../../../app/routes/app_routes.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/purchase_item.dart';

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

  // --- إصلاح الخطأ: دالة البحث عن اسم المنتج بشكل آمن ---
  String _getProductName(BuildContext context, String productId) {
    try {
      final products = context.read<ProductViewModel>().products;
      // البحث عن المنتج بأمان، إذا لم يوجد نعيد null
      final product = products.where((p) => p.id == productId).firstOrNull;
      return product?.name ?? 'منتج غير معروف';
    } catch (e) {
      return 'منتج غير معروف';
    }
  }

  // --- مربع حوار المرتجع ---
  void _showReturnDialog(BuildContext parentContext, Purchase purchase, PurchaseItem item) {
    final qtyController = TextEditingController();
    final totalItemQty = item.quantity + item.freeQuantity;
    final remainingQty = totalItemQty - item.returnedQuantity;
    
    // الحصول على الاسم بأمان قبل بناء الواجهة
    final productName = _getProductName(parentContext, item.productId);

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مرتجع صنف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المنتج: $productName', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('المتاح للإرجاع: ${remainingQty.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(parentContext)!.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final qty = double.tryParse(qtyController.text) ?? 0.0;
              if (qty <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('الرجاء إدخال كمية صحيحة')));
                return;
              }
              if (qty > remainingQty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('الكمية تتجاوز المتاح')));
                return;
              }

              Navigator.pop(dialogContext);

              if (!mounted) return;

              final success = await parentContext.read<PurchaseViewModel>().returnPurchase(
                purchaseId: purchase.id,
                productId: item.productId,
                quantity: qty,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('تم تسجيل المرتجع بنجاح')));
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchaseVm = context.watch<PurchaseViewModel>();
    final supplierVm = context.watch<SupplierViewModel>();
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.purchaseListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addPurchase),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (purchaseVm.state == PurchaseViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (purchaseVm.state == PurchaseViewState.error) {
            return Center(child: Text(purchaseVm.errorMessage ?? localizations.errorOccurred));
          }
          if (purchaseVm.purchases.isEmpty) {
            return Center(child: Text(localizations.noRecentActivity));
          }

          return ListView.builder(
            itemCount: purchaseVm.purchases.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              final purchase = purchaseVm.purchases[index];
              
              final supplier = supplierVm.suppliers
                  .where((s) => s.id == purchase.supplierId)
                  .firstOrNull;
              final supplierName = supplier?.name ?? 'مورد غير معروف';

              final dateStr = DateFormat.yMMMd(localizations.localeName).add_jm().format(purchase.createdAt);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: const Icon(Icons.receipt, color: Colors.blue),
                  ),
                  title: Text(supplierName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(dateStr),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${purchase.totalAmount.toStringAsFixed(2)} ريال',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                      ),
                      const Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                  children: [
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("الأصناف:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 8),
                          // استخدام التصميم الجديد لكل عنصر
                          ...purchase.items.map((item) => _buildPurchaseItemRow(context, purchase, item)),
                          const Divider(),
                          _buildSummaryRow('المجموع:', purchase.subTotal),
                          if (purchase.discount > 0)
                            _buildSummaryRow('الخصم:', -purchase.discount, color: Colors.red),
                          const SizedBox(height: 4),
                          _buildSummaryRow('الصافي:', purchase.totalAmount, isBold: true, color: Colors.green[700]),
                          const SizedBox(height: 8),
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
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addPurchase),
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- تحسين التصميم: صف العنصر (Item Row) ---
  Widget _buildPurchaseItemRow(BuildContext context, Purchase purchase, PurchaseItem item) {
    final productName = _getProductName(context, item.productId);
    final hasReturns = item.returnedQuantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // السطر الأول: اسم المنتج
          Text(
            productName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          
          // السطر الثاني: التفاصيل وزر الإرجاع
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // معلومات الكمية والسعر
              Expanded(
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    // الكمية
                    _buildBadge(
                      '${item.quantity.toStringAsFixed(0)}${item.freeQuantity > 0 ? "+${item.freeQuantity.toStringAsFixed(0)}" : ""}',
                      Icons.inventory_2_outlined,
                      Colors.blue[50],
                      Colors.blue[800],
                    ),
                    // السعر
                    _buildBadge(
                      item.price.toStringAsFixed(2),
                      Icons.attach_money,
                      Colors.grey[200],
                      Colors.grey[800],
                    ),
                    // المرتجع (إذا وجد)
                    if (hasReturns)
                      _buildBadge(
                        'مسترجع: ${item.returnedQuantity.toStringAsFixed(0)}',
                        Icons.assignment_return,
                        Colors.red[50],
                        Colors.red[800],
                      ),
                  ],
                ),
              ),
              
              // زر الإرجاع
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: () => _showReturnDialog(context, purchase, item),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('إرجاع', style: TextStyle(fontSize: 12, color: Colors.orange)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // عنصر مساعد لرسم البطاقات الصغيرة (Badges)
  Widget _buildBadge(String text, IconData icon, Color? bgColor, Color? textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}