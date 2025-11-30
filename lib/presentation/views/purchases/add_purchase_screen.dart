import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/purchase_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/supplier_viewmodel.dart';
import '../../../l10n/app_localizations.dart';

class AddPurchaseScreen extends StatefulWidget {
  final String? productId;
  const AddPurchaseScreen({super.key, this.productId});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  String? _selectedProductId;
  String? _selectedSupplierId;
  final _qtyController = TextEditingController();
  final _freeQtyController = TextEditingController(); // 1. تحكم جديد للكمية المجانية
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().loadProducts();
      context.read<SupplierViewModel>().loadSuppliers();
      if (widget.productId != null) _selectedProductId = widget.productId;
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _freeQtyController.dispose(); // تنظيف التحكم
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productVm = context.watch<ProductViewModel>();
    final supplierVm = context.watch<SupplierViewModel>();
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.addPurchaseTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // إضافة ScrollView لتجنب مشاكل لوحة المفاتيح
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedProductId,
                items: productVm.products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (v) => setState(() => _selectedProductId = v),
                decoration: InputDecoration(labelText: localizations.productLabel),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSupplierId,
                items: supplierVm.suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (v) => setState(() => _selectedSupplierId = v),
                decoration: InputDecoration(labelText: localizations.supplierLabel),
              ),
              const SizedBox(height: 8),
              
              // حقل الكمية الأساسية
              TextField(
                controller: _qtyController, 
                decoration: InputDecoration(labelText: localizations.quantityLabel), // تأكد من وجود هذا المفتاح في ملفات الترجمة أو استخدم نص ثابت إذا لم يكن موجوداً
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),

              // 2. حقل الكمية المجانية (الجديد)
              TextField(
                controller: _freeQtyController,
                decoration: InputDecoration(
                  labelText: localizations.freeQuantityLabel, // المفتاح الذي أضفناه سابقاً
                  helperText: "تضاف إلى المخزون ولكن لا تؤثر على السعر الإجمالي",
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),

              // حقل السعر
              TextField(
                controller: _priceController, 
                decoration: InputDecoration(labelText: localizations.priceLabel), // تأكد من وجود هذا المفتاح
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () async {
                  if (_selectedProductId == null || _selectedSupplierId == null) return;
                  
                  final qty = double.tryParse(_qtyController.text) ?? 0.0;
                  final freeQty = double.tryParse(_freeQtyController.text) ?? 0.0; // قراءة الكمية المجانية
                  final price = double.tryParse(_priceController.text) ?? 0.0;

                  if (qty <= 0 || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity and price must be positive')));
                    return;
                  }

                  final vm = context.read<PurchaseViewModel>();
                  
                  // 3. تمرير المعاملات الجديدة
                  final success = await vm.addPurchase(
                    productId: _selectedProductId!,
                    supplierId: _selectedSupplierId!,
                    quantity: qty,
                    freeQuantity: freeQty, // تمرير الكمية المجانية
                    price: price,
                  );

                  if (success && mounted) Navigator.pop(context);
                },
                child: Text(localizations.addPurchaseButtonLabel),
              )
            ],
          ),
        ),
      ),
    );
  }
}