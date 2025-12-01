import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/purchase_item.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/purchase_viewmodel.dart';
import '../../viewmodels/supplier_viewmodel.dart';
import '../../../l10n/app_localizations.dart';

// --- New Widgets Imports ---
import 'widgets/purchase_header_form.dart';
import 'widgets/purchase_item_input.dart';
import 'widgets/purchase_cart_list.dart';
import 'widgets/purchase_summary_section.dart';

class AddPurchaseScreen extends StatefulWidget {
  final String? productId;
  const AddPurchaseScreen({super.key, this.productId});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  // --- State ---
  String? _selectedSupplierId;
  String? _selectedProductId;
  
  // --- Controllers ---
  final _discountController = TextEditingController(text: '0.0');
  final _qtyController = TextEditingController();
  final _freeQtyController = TextEditingController(text: '0.0');
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().loadProducts();
      context.read<SupplierViewModel>().loadSuppliers();
      context.read<PurchaseViewModel>().clearCart();
      
      if (widget.productId != null) {
        setState(() {
          _selectedProductId = widget.productId;
        });
      }
    });

    // Listen to discount changes to update UI immediately
    _discountController.addListener(() {
      setState(() {});
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

  void _onProductChanged(String? val) {
    setState(() {
      _selectedProductId = val;
      if (val != null) {
        final productVm = context.read<ProductViewModel>();
        try {
          final product = productVm.products.firstWhere((p) => p.id == val);
          _priceController.text = product.price.toString();
        } catch (_) {}
      }
    });
  }

  void _addItemToCart() {
    final localizations = AppLocalizations.of(context)!;

    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.productLabel} ${localizations.supplierNameRequired.split(' ').last}')),
      );
      return;
    }
    
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    final freeQty = double.tryParse(_freeQtyController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.quantityMustBePositiveError)),
      );
      return;
    }

    final item = PurchaseItem(
      productId: _selectedProductId!,
      quantity: qty,
      freeQuantity: freeQty,
      price: price,
    );

    context.read<PurchaseViewModel>().addToCart(item);

    // Reset inputs
    setState(() {
      _selectedProductId = null;
      _qtyController.clear();
      _freeQtyController.text = '0.0';
      _priceController.clear();
    });
  }

  Future<void> _submitPurchase() async {
    final localizations = AppLocalizations.of(context)!;
    final purchaseVm = context.read<PurchaseViewModel>();

    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.selectSupplierError)),
      );
      return;
    }
    if (purchaseVm.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.addProductsError)),
      );
      return;
    }

    final discount = double.tryParse(_discountController.text) ?? 0.0;

    final success = await purchaseVm.addPurchase(
      supplierId: _selectedSupplierId!,
      discount: discount,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.invoiceSavedSuccess)),
      );
      Navigator.pop(context);
    }
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
            // 1. Header (Supplier & Discount)
            PurchaseHeaderForm(
              suppliers: supplierVm.suppliers,
              selectedSupplierId: _selectedSupplierId,
              discountController: _discountController,
              onSupplierChanged: (v) => setState(() => _selectedSupplierId = v),
            ),
            
            const SizedBox(height: 16),

            // 2. Product Input
            PurchaseItemInput(
              products: productVm.products,
              selectedProductId: _selectedProductId,
              qtyController: _qtyController,
              freeQtyController: _freeQtyController,
              priceController: _priceController,
              onProductChanged: _onProductChanged,
              onAddPressed: _addItemToCart,
            ),

            const SizedBox(height: 24),

            // 3. Cart List
            const PurchaseCartList(),

            const SizedBox(height: 24),

            // 4. Summary & Actions
            PurchaseSummarySection(
              subTotal: purchaseVm.cartSubTotal,
              discount: double.tryParse(_discountController.text) ?? 0.0,
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submitPurchase,
              child: Text(
                localizations.saveFinalInvoiceButton,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}