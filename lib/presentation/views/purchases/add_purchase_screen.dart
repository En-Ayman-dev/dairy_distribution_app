import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/purchase_item.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/purchase_viewmodel.dart';
import '../../viewmodels/supplier_viewmodel.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/invoice_item_widget.dart';

class AddPurchaseScreen extends StatefulWidget {
  final String? productId; // اختياري: إذا جئنا من تفاصيل المنتج
  const AddPurchaseScreen({super.key, this.productId});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  // --- حقول رأس الفاتورة (Master) ---
  String? _selectedSupplierId;
  final _discountController = TextEditingController(text: '0.0');

  // --- حقول إدخال العنصر (Item Entry) ---
  String? _selectedProductId;
  final _qtyController = TextEditingController();
  final _freeQtyController = TextEditingController(text: '0.0');
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().loadProducts();
      context.read<SupplierViewModel>().loadSuppliers();
      
      // تنظيف السلة عند فتح الشاشة لضمان عدم وجود بقايا سابقة
      context.read<PurchaseViewModel>().clearCart();
      
      if (widget.productId != null) {
        setState(() {
          _selectedProductId = widget.productId;
        });
      }
    });
  }

  @override
  void dispose() {
    _discountController.dispose();
    _qtyController.dispose();
    _freeQtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // دالة لإضافة العنصر إلى السلة (في الذاكرة)
  void _addItemToCart() {
    final localizations = AppLocalizations.of(context)!;

    if (_selectedProductId == null) {
      // استخدام رسالة عامة أو يمكن إضافة مفتاح خاص لاحقاً
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${localizations.productLabel} ${localizations.supplierNameRequired.split(' ').last}'))); // "المنتج مطلوب" تقريباً
      return;
    }
    
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    final freeQty = double.tryParse(_freeQtyController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizations.quantityMustBePositiveError)));
      return;
    }

    final item = PurchaseItem(
      productId: _selectedProductId!,
      quantity: qty,
      freeQuantity: freeQty,
      price: price,
    );

    // إضافة للسلة في الـ ViewModel
    context.read<PurchaseViewModel>().addToCart(item);

    // تصفية حقول الإدخال للاستعداد للعنصر التالي
    setState(() {
      _selectedProductId = null;
      _qtyController.clear();
      _freeQtyController.text = '0.0';
      _priceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final supplierVm = context.watch<SupplierViewModel>();
    final productVm = context.watch<ProductViewModel>();
    final purchaseVm = context.watch<PurchaseViewModel>();
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.addPurchaseTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. القسم العلوي: المورد والخصم ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedSupplierId,
                      items: supplierVm.suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (v) => setState(() => _selectedSupplierId = v),
                      decoration: InputDecoration(
                        labelText: localizations.supplierLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.store),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _discountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: localizations.totalDiscountLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.discount),
                        // تم إزالة suffixText الثابت لضمان الحيادية، يمكن إضافته كمتغير عملة لاحقاً
                      ),
                      onChanged: (_) => setState(() {}), // لتحديث الملخص عند الكتابة
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- 2. قسم إضافة المنتجات ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(localizations.addProductsToInvoiceTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedProductId,
                      items: productVm.products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                      onChanged: (v) {
                         setState(() {
                           _selectedProductId = v;
                           // تعبئة السعر تلقائياً من بيانات المنتج إذا وجد
                           if (v != null) {
                             final product = productVm.products.firstWhere((p) => p.id == v);
                             _priceController.text = product.price.toString();
                           }
                         });
                      },
                      decoration: InputDecoration(
                        labelText: localizations.productLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _qtyController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: localizations.quantityLabel,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _freeQtyController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: localizations.freeLabel,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: localizations.priceLabel,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addItemToCart,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: Text(localizations.addToCartButton),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 3. قائمة السلة (Cart List) ---
            Text('${localizations.invoiceContentsTitle} (${purchaseVm.cartItems.length})', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (purchaseVm.cartItems.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Text(localizations.noProductsAdded)))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // لمنع التمرير الداخلي
                itemCount: purchaseVm.cartItems.length,
                itemBuilder: (context, index) {
                  final item = purchaseVm.cartItems[index];
                  return InvoiceItemWidget(
                    item: item,
                    onRemove: () => purchaseVm.removeFromCart(item.productId),
                  );
                },
              ),
            const SizedBox(height: 24),

            // --- 4. الملخص وزر الحفظ النهائي ---
            _buildSummarySection(purchaseVm, localizations),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (_selectedSupplierId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizations.selectSupplierError)));
                  return;
                }
                if (purchaseVm.cartItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizations.addProductsError)));
                  return;
                }

                final discount = double.tryParse(_discountController.text) ?? 0.0;

                // استدعاء دالة الحفظ الجديدة
                final success = await purchaseVm.addPurchase(
                  supplierId: _selectedSupplierId!,
                  discount: discount,
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizations.invoiceSavedSuccess)));
                  Navigator.pop(context);
                }
              },
              child: Text(localizations.saveFinalInvoiceButton, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ويدجت لعرض الملخص المالي
  Widget _buildSummarySection(PurchaseViewModel vm, AppLocalizations localizations) {
    final subTotal = vm.cartSubTotal;
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final total = subTotal - discount;

    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _summaryRow(localizations.subTotalSummaryLabel, subTotal),
            const Divider(),
            _summaryRow(localizations.discountLabel, discount, isNegative: true),
            const Divider(),
            _summaryRow(localizations.netTotalSummaryLabel, total, isBold: true, color: Colors.green[800]),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isNegative = false, bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 16)),
        Text(
          '${isNegative ? "- " : ""}${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 16,
            color: color ?? (isNegative ? Colors.red : Colors.black),
          ),
        ),
      ],
    );
  }
}