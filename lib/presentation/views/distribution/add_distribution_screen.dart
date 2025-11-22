
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/distribution_viewmodel.dart';
import '../../../data/datasources/local/customer_local_datasource.dart';
import '../../../data/datasources/local/product_local_datasource.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/product_model.dart';
import '../../../core/utils/service_locator.dart';
import '../../../l10n/app_localizations.dart';

class AddDistributionScreen extends StatefulWidget {
  const AddDistributionScreen({super.key});

  @override
  State<AddDistributionScreen> createState() => _AddDistributionScreenState();
}

class _AddDistributionScreenState extends State<AddDistributionScreen> {
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _paidController = TextEditingController(text: '0');
  String? _selectedCustomerId;
  String? _selectedProductId;
  List<CustomerModel> _customers = [];
  List<ProductModel> _products = [];
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final customerDs = getIt<CustomerLocalDataSource>();
      final productDs = getIt<ProductLocalDataSource>();
      final customers = await customerDs.getAllCustomers();
      final products = await productDs.getAllProducts();
      setState(() {
        _customers = customers;
        _products = products;
        if (_customers.isNotEmpty) _selectedCustomerId ??= _customers.first.id;
        if (_products.isNotEmpty) _selectedProductId ??= _products.first.id;
          // preset price for initially selected product
          if (_selectedProductId != null) {
            final p = _products.firstWhere((p) => p.id == _selectedProductId);
            _priceController.text = p.price.toString();
          }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  void _addItem() {
    final vm = context.read<DistributionViewModel>();
    if (_selectedProductId == null) return;
    final product = _products.firstWhere((p) => p.id == _selectedProductId);
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    if (qty <= 0) return;
    final price = double.tryParse(_priceController.text) ?? product.price;
    vm.addItem(productId: product.id, productName: product.name, quantity: qty, price: price);
    // reset qty to 1 and price back to product default
    _qtyController.text = '1';
    _priceController.text = product.price.toString();
  }

  Future<void> _submit() async {
    final vm = context.read<DistributionViewModel>();
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorOccurred)));
      return;
    }
    if (vm.currentItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.addFirstProductPrompt)));
      return;
    }

    final paid = double.tryParse(_paidController.text) ?? 0.0;
    vm.setPaidAmount(paid);

    setState(() => _creating = true);
    final customer = _customers.firstWhere((c) => c.id == _selectedCustomerId);
    final ok = await vm.createDistribution(
      customerId: customer.id,
      customerName: customer.name,
      distributionDate: DateTime.now(),
    );
    setState(() => _creating = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.createTestDistributionSuccess)));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? AppLocalizations.of(context)!.errorOccurred)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.createDistributionLabel)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.customersTitle, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    // Wrap dropdown in a Row+Expanded to avoid overflow
                    Row(children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedCustomerId,
                          isExpanded: true,
                          items: _customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                          onChanged: (v) => setState(() => _selectedCustomerId = v),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    Text(t.addProductTitle, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Product dropdown should flex to available space
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedProductId,
                            isExpanded: true,
                            items: _products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                            onChanged: (v) => setState(() {
                              _selectedProductId = v;
                              if (v != null) {
                                final p = _products.firstWhere((p) => p.id == v);
                                _priceController.text = p.price.toString();
                              }
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(width: 80, child: TextField(controller: _qtyController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t.quantityLabel))),
                        const SizedBox(width: 8),
                        SizedBox(width: 90, child: TextField(controller: _priceController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price'))),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: _addItem, child: Text(t.add)),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Text(t.itemsLabel, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),

                    SizedBox(
                      height: 220,
                      child: Consumer<DistributionViewModel>(
                        builder: (context, vm, child) {
                          final items = vm.currentItems;
                          if (items.isEmpty) return Center(child: Text(t.noProductsFound));
                          return ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, idx) {
                              final it = items[idx];
                              return ListTile(
                                title: Text(it.productName),
                                subtitle: Text('${it.quantity} x ${it.price.toStringAsFixed(2)}'),
                                trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(it.subtotal.toStringAsFixed(2)), IconButton(onPressed: () => vm.removeItem(it.id), icon: const Icon(Icons.delete_outline))]),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t.currentStockPrefix), Consumer<DistributionViewModel>(builder: (c, vm, _) => Text(vm.getCurrentTotal().toStringAsFixed(2)))]),
                    const SizedBox(height: 8),
                    TextField(controller: _paidController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t.paid)),
                    const SizedBox(height: 16),
                    // زر طباعة الفاتورة
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.print),
                        label: const Text('طباعة الفاتورة'),
                        onPressed: _showPrintDialog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: _creating ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _submit, child: Text(t.createDistributionLabel))),
                  ],
                ),
              ),
            ),
    );
    
  }
  void _showPrintDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String selectedSize = '58mm';
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('اختيار مقاس الطابعة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  value: '58mm',
                  groupValue: selectedSize,
                  onChanged: (v) => setState(() => selectedSize = v!),
                  title: const Text('58mm (عرض فعلي ~48mm) - مناسب للفواتير الصغيرة'),
                ),
                RadioListTile<String>(
                  value: '80mm',
                  groupValue: selectedSize,
                  onChanged: (v) => setState(() => selectedSize = v!),
                  title: const Text('80mm (عرض فعلي ~72mm) - مناسب للسوبرماركت/المطاعم الكبيرة'),
                ),
                // يمكن إضافة مقاسات أخرى لاحقًا
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('طباعة'),
                onPressed: () {
                  Navigator.pop(context);
                  _printInvoice(selectedSize);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _printInvoice(String size) {
    // هنا منطق الطباعة الفعلي (حسب المقاس)
    // حالياً فقط رسالة توضيحية
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('سيتم طباعة الفاتورة بمقاس $size')),
    );
    // يمكن لاحقاً ربطها بمكتبة طباعة فعلية
  }
}

