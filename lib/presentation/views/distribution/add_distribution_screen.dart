import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/service_locator.dart';
import '../../../domain/repositories/customer_repository.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/product.dart';
import '../../../l10n/app_localizations.dart';
import '../../viewmodels/distribution_viewmodel.dart';
import '../distribution/widgets/product_selection_form.dart';
import '../distribution/widgets/distribution_cart_list.dart';
import '../distribution/widgets/distribution_summary_section.dart';
import '../../utils/distribution_print_mixin.dart'; // Mixin Import!
import '../../widgets/print_button.dart';

class AddDistributionScreen extends StatefulWidget {
  const AddDistributionScreen({super.key});

  @override
  State<AddDistributionScreen> createState() => _AddDistributionScreenState();
}

// تطبيق Mixin
class _AddDistributionScreenState extends State<AddDistributionScreen> with DistributionPrintMixin {
  // --- Controllers & State (Form State ONLY) ---
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _paidController = TextEditingController(text: '0');

  // --- Data ---
  String? _selectedCustomerId;
  String? _selectedProductId;
  List<Customer> _customers = [];
  List<Product> _products = [];

  // --- UI State ---
  bool _loading = true;
  bool _creating = false;
  bool _isFree = false;
  
  @override
  void initState() {
    super.initState();
    _loadLookups();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<DistributionViewModel>().clearLastCreatedDistributionId();
      } catch (_) {}
    });
  }

  Future<void> _loadLookups() async {
    setState(() => _loading = true);
    try {
      final customerRepo = getIt<CustomerRepository>();
      final productRepo = getIt<ProductRepository>();

      final results = await Future.wait([
        customerRepo.getAllCustomers(),
        productRepo.getAllProducts(),
      ]);

      if (!mounted) return;

      setState(() {
        results[0].fold(
          (failure) => _customers = [],
          (data) => _customers = data as List<Customer>,
        );

        results[1].fold(
          (failure) => _products = [],
          (data) => _products = data as List<Product>,
        );

        if (_customers.isNotEmpty) _selectedCustomerId ??= _customers.first.id;
        if (_products.isNotEmpty) {
          _selectedProductId ??= _products.first.id;
          _priceController.text = _products.first.price.toString();
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  // --- Logic Methods (Kept for submission/cart management) ---

  void _onProductChanged(String? val) {
    setState(() {
      _selectedProductId = val;
      if (val != null) {
        final p = _products.firstWhere((p) => p.id == val);
        if (!_isFree) {
          _priceController.text = p.price.toString();
        }
      }
    });
  }

  void _onFreeChanged(bool? val) {
    setState(() {
      _isFree = val ?? false;
      if (!_isFree && _selectedProductId != null) {
        final p = _products.firstWhere((p) => p.id == _selectedProductId);
        _priceController.text = p.price.toString();
      }
    });
  }

  void _addItem() {
    final vm = context.read<DistributionViewModel>();
    if (_selectedProductId == null) return;

    final product = _products.firstWhere((p) => p.id == _selectedProductId);
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    if (qty <= 0) return;

    // Stock Validation
    double currentCartQty = 0.0;
    try {
      final existingItem = vm.currentItems.firstWhere((item) => item.productId == product.id);
      currentCartQty = existingItem.quantity;
    } catch (_) {}

    if ((qty + currentCartQty) > product.stock) {
      final remaining = product.stock - currentCartQty;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الكمية غير متوفرة. المتاح: ${remaining > 0 ? remaining : 0}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final price = _isFree ? 0.0 : (double.tryParse(_priceController.text) ?? product.price);

    vm.addItem(
      productId: product.id,
      productName: product.name,
      quantity: qty,
      price: price,
    );

    _qtyController.text = '1';
    if (!_isFree) _priceController.text = product.price.toString();
    setState(() => _isFree = false);
  }

  Future<void> _submit() async {
    final vm = context.read<DistributionViewModel>();
    final t = AppLocalizations.of(context)!;
    
    if (_selectedCustomerId == null) return;
    if (vm.currentItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.addFirstProductPrompt)),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.createTestDistributionSuccess)),
      );
      // Fetch the created distribution for printing
      final lastId = vm.lastCreatedDistributionId;
      if (lastId != null) {
        await vm.getDistributionById(lastId);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? t.errorOccurred)),
      );
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
                    // 1. Product Selection Form
                    ProductSelectionForm(
                      customers: _customers,
                      products: _products,
                      selectedCustomerId: _selectedCustomerId,
                      selectedProductId: _selectedProductId,
                      qtyController: _qtyController,
                      priceController: _priceController,
                      isFree: _isFree,
                      onCustomerChanged: (v) => setState(() => _selectedCustomerId = v),
                      onProductChanged: _onProductChanged,
                      onFreeChanged: _onFreeChanged,
                      onAddPressed: _addItem,
                    ),

                    const SizedBox(height: 24),

                    // 2. Cart List
                    const DistributionCartList(),

                    const SizedBox(height: 24),

                    // 3. Summary & Payment
                    DistributionSummarySection(paidController: _paidController),
                    
                    const SizedBox(height: 24),

                    // 4. Print & Submit Actions
                    Consumer<DistributionViewModel>(
                      builder: (c, vm, _) {
                        final canPrint = vm.lastCreatedDistributionId != null;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                             // Print Section (Uses Mixin's State and Logic)
                             if (canPrint && vm.selectedDistribution != null) ...[
                                Row(
                                   children: [
                                     Expanded(
                                       child: ElevatedButton.icon(
                                         onPressed: connectToPrinter, // استدعاء الدالة العامة connectToPrinter
                                         icon: const Icon(Icons.bluetooth),
                                         label: Text(selectedPrinterDevice?.name ?? t.selectPrinter), // استخدام Getter من Mixin
                                         style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey.shade800,
                                            foregroundColor: Colors.white,
                                         ),
                                       ),
                                     ),
                                     if (selectedPrinterDevice != null) ...[ // استخدام Getter من Mixin
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.link_off),
                                          onPressed: disconnectPrinter, // استدعاء الدالة العامة disconnectPrinter
                                        )
                                     ]
                                   ],
                                ),
                                const SizedBox(height: 8),
                                PrintButton(
                                  // استدعاء دالة الطباعة الموحدة من الـ Mixin
                                  onPrint: (size, output, preview) => printDistributionInvoice(
                                    vm.selectedDistribution!, 
                                    size, output, preview
                                  ),
                                  defaultSize: kPrinterSizes.first,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(t.close),
                                ),
                             ],

                             // Submit Button
                             if (!canPrint)
                               SizedBox(
                                 width: double.infinity,
                                 height: 54,
                                 child: _creating
                                     ? const Center(child: CircularProgressIndicator())
                                     : ElevatedButton(
                                         onPressed: _submit,
                                         style: ElevatedButton.styleFrom(
                                           backgroundColor: Theme.of(context).primaryColor,
                                           foregroundColor: Colors.white,
                                         ),
                                         child: Text(t.createDistributionLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                       ),
                               ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}