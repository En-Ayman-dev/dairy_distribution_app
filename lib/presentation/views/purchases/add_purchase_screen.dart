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
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productVm = context.watch<ProductViewModel>();
    final supplierVm = context.watch<SupplierViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addPurchaseTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedProductId,
              items: productVm.products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
              onChanged: (v) => setState(() => _selectedProductId = v),
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.productLabel),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSupplierId,
              items: supplierVm.suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              onChanged: (v) => setState(() => _selectedSupplierId = v),
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.supplierLabel),
            ),
            const SizedBox(height: 8),
            TextField(controller: _qtyController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.quantityLabel), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: _priceController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.priceLabel), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_selectedProductId == null || _selectedSupplierId == null) return;
                final qty = double.tryParse(_qtyController.text) ?? 0.0;
                final price = double.tryParse(_priceController.text) ?? 0.0;
                if (qty <= 0 || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity and price must be positive')));
                  return;
                }
                final vm = context.read<PurchaseViewModel>();
                final success = await vm.addPurchase(productId: _selectedProductId!, supplierId: _selectedSupplierId!, quantity: qty, price: price);
                if (success && mounted) Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.addPurchaseButtonLabel),
            )
          ],
        ),
      ),
    );
  }
}
