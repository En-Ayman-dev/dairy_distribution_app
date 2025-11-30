import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../viewmodels/purchase_viewmodel.dart';
import '../../../viewmodels/product_viewmodel.dart';
import '../../../viewmodels/supplier_viewmodel.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../domain/entities/purchase.dart';
import '../../../../domain/entities/purchase_item.dart';

class InvoicesTab extends StatefulWidget {
  final String? supplierId;

  const InvoicesTab({super.key, this.supplierId});

  @override
  State<InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<InvoicesTab> {
  @override
  void initState() {
    super.initState();
    // تحميل البيانات إذا لم تكن محملة مسبقاً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseViewModel>().listenToAllPurchases();
      context.read<ProductViewModel>().loadProducts();
      context.read<SupplierViewModel>().loadSuppliers();
    });
  }

  String _getProductName(BuildContext context, String productId) {
    final localizations = AppLocalizations.of(context)!;
    try {
      final products = context.read<ProductViewModel>().products;
      final product = products.where((p) => p.id == productId).firstOrNull;
      return product?.name ?? localizations.unknownProduct;
    } catch (e) {
      return localizations.unknownProduct;
    }
  }

  void _showReturnDialog(BuildContext parentContext, Purchase purchase, PurchaseItem item) {
    final localizations = AppLocalizations.of(parentContext)!;
    final qtyController = TextEditingController();
    final totalItemQty = item.quantity + item.freeQuantity;
    final remainingQty = totalItemQty - item.returnedQuantity;
    final productName = _getProductName(parentContext, item.productId);

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(localizations.returnItemTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${localizations.productPrefix}$productName', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${localizations.returnableQuantityPrefix}${remainingQty.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: localizations.returnQuantityLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final qty = double.tryParse(qtyController.text) ?? 0.0;
              if (qty <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(localizations.invalidReturnAmountError)));
                return;
              }
              if (qty > remainingQty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(localizations.returnAmountExceedsError)));
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
                ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(content: Text(localizations.returnRecordedSuccess)));
              }
            },
            child: Text(localizations.confirm),
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

    // تصفية القائمة بناءً على المورد المحدد (إذا وجد)
    final filteredPurchases = widget.supplierId == null
        ? purchaseVm.purchases
        : purchaseVm.purchases.where((p) => p.supplierId == widget.supplierId).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Builder(
        builder: (context) {
          if (purchaseVm.state == PurchaseViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (purchaseVm.state == PurchaseViewState.error) {
            return Center(child: Text(purchaseVm.errorMessage ?? localizations.errorOccurred));
          }
          if (filteredPurchases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    widget.supplierId == null
                        ? localizations.noRecentActivity
                        : localizations.noInvoicesForSupplier,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredPurchases.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              final purchase = filteredPurchases[index];
              
              final supplier = supplierVm.suppliers
                  .where((s) => s.id == purchase.supplierId)
                  .firstOrNull;
              final supplierName = supplier?.name ?? localizations.unknownSupplier;

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
                        '${purchase.totalAmount.toStringAsFixed(2)}', // العملة يمكن إضافتها لاحقاً أو كجزء من النص
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
                          Text(localizations.invoiceItemsLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 8),
                          ...purchase.items.map((item) => _buildPurchaseItemRow(context, purchase, item)),
                          const Divider(),
                          _buildSummaryRow(localizations.subTotalSummaryLabel, purchase.subTotal),
                          if (purchase.discount > 0)
                            _buildSummaryRow(localizations.discountLabel, -purchase.discount, color: Colors.red),
                          const SizedBox(height: 4),
                          _buildSummaryRow(localizations.netTotalSummaryLabel, purchase.totalAmount, isBold: true, color: Colors.green[700]),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addPurchase),
        icon: const Icon(Icons.add_shopping_cart),
        label: Text(localizations.newInvoiceButton),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  Widget _buildPurchaseItemRow(BuildContext context, Purchase purchase, PurchaseItem item) {
    final localizations = AppLocalizations.of(context)!;
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
          Text(
            productName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    _buildBadge(
                      '${item.quantity.toStringAsFixed(0)}${item.freeQuantity > 0 ? "+${item.freeQuantity.toStringAsFixed(0)} ${localizations.freeLabel}" : ""}',
                      Icons.inventory_2_outlined,
                      Colors.blue[50],
                      Colors.blue[800],
                    ),
                    _buildBadge(
                      item.price.toStringAsFixed(2),
                      Icons.attach_money,
                      Colors.grey[200],
                      Colors.grey[800],
                    ),
                    if (hasReturns)
                      _buildBadge(
                        '${localizations.returnedPrefix}${item.returnedQuantity.toStringAsFixed(0)}',
                        Icons.assignment_return,
                        Colors.red[50],
                        Colors.red[800],
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: () => _showReturnDialog(context, purchase, item),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(localizations.returnItemTitle, style: const TextStyle(fontSize: 12, color: Colors.orange)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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