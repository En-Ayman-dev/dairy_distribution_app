import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';

// --- Imports: Core & Utils ---
import '../../../core/utils/pdf_generator.dart';
import '../../../core/utils/service_locator.dart';
import '../../../l10n/app_localizations.dart';

// --- Imports: Domain Layer (Repositories & Entities) ---
import '../../../domain/repositories/customer_repository.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/product.dart';

// --- Imports: Presentation Layer ---
import '../../viewmodels/distribution_viewmodel.dart';
import '../../widgets/print_button.dart';

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
  
  // تم تغيير النوع إلى Entity لأن المستودع يرجع Entities
  List<Customer> _customers = [];
  List<Product> _products = [];
  
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadLookups();
    // Ensure print button is hidden when the screen is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<DistributionViewModel>().clearLastCreatedDistributionId();
      } catch (_) {}
    });
  }

  // --- تم تعديل هذه الدالة لاستخدام المستودعات بدلاً من LocalDataSource ---
  Future<void> _loadLookups() async {
    setState(() => _loading = true);
    try {
      final customerRepo = getIt<CustomerRepository>();
      final productRepo = getIt<ProductRepository>();

      // جلب البيانات بشكل متوازي لتقليل وقت الانتظار
      final results = await Future.wait([
        customerRepo.getAllCustomers(),
        productRepo.getAllProducts(),
      ]);

      final customerResult = results[0] as dynamic; // Dart inference helper
      final productResult = results[1] as dynamic;

      if (!mounted) return;

      setState(() {
        // معالجة نتيجة العملاء
        customerResult.fold(
          (failure) {
             developer.log('Failed to load customers: ${failure.message}');
             _customers = [];
          },
          (data) => _customers = data as List<Customer>,
        );

        // معالجة نتيجة المنتجات
        productResult.fold(
          (failure) {
             developer.log('Failed to load products: ${failure.message}');
             _products = [];
          },
          (data) => _products = data as List<Product>,
        );

        // تعيين القيم الافتراضية
        if (_customers.isNotEmpty) _selectedCustomerId ??= _customers.first.id;
        if (_products.isNotEmpty) {
           _selectedProductId ??= _products.first.id;
           // preset price for initially selected product
           final p = _products.first;
           _priceController.text = p.price.toString();
        }
        
        _loading = false;
      });
    } catch (e) {
      developer.log('Error loading lookups', error: e);
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

  void _addItem() {
    final vm = context.read<DistributionViewModel>();
    if (_selectedProductId == null) return;
    
    // البحث في قائمة المنتجات
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
      // Show success and keep the screen so user can print before exiting.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.createTestDistributionSuccess)));
      // Load the saved distribution details so printing can use that data
      final lastId = vm.lastCreatedDistributionId;
      if (lastId != null) {
        await vm.getDistributionById(lastId);
      }
      // Do NOT pop here. PrintButton becomes visible because ViewModel stores lastCreatedDistributionId.
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
                        SizedBox(width: 90, child: TextField(controller: _priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price'))),
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
                    TextField(controller: _paidController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t.paid)),
                    const SizedBox(height: 16),
                    // Print button is shown only after successful save
                    Consumer<DistributionViewModel>(
                      builder: (c, vm, _) {
                        final canPrint = vm.lastCreatedDistributionId != null;
                        if (!canPrint) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PrintButton(
                              onPrint: (printerSize, output, preview) async {
                                await _printInvoice(printerSize, output, preview);
                              },
                              defaultSize: kPrinterSizes.first,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(AppLocalizations.of(context)!.close),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: _creating ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _submit, child: Text(t.createDistributionLabel))),
                  ],
                ),
              ),
            ),
    );
    
  }
  
  Future<void> _printInvoice(PrinterSize size, PrintOutput output, bool preview) async {
    final vm = context.read<DistributionViewModel>();
    final customer = _customers.firstWhere((c) => c.id == _selectedCustomerId);

    // If we don't have the saved distribution loaded yet, but there is a last-created id,
    // load it so we always print the saved invoice.
    if (vm.selectedDistribution == null && vm.lastCreatedDistributionId != null) {
      await vm.getDistributionById(vm.lastCreatedDistributionId!);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(output == PrintOutput.pdf
          ? 'سيتم إنشاء ملف PDF للمسح/الطباعة بمقاس ${size.name}'
          : 'سيتم طباعة الفاتورة بمقاس ${size.name} (عرض فعلي ${size.printableWidthMm}mm)')),
    );

    if (output == PrintOutput.pdf) {
      // توليد ملف PDF
      final pdfGen = PDFGenerator();
      // Use the saved distribution (if loaded) to print the exact saved invoice.
      final distribution = vm.selectedDistribution;
      final items = distribution?.items ?? vm.currentItems;
      final total = distribution?.totalAmount ?? vm.getCurrentTotal();
      final paid = distribution?.paidAmount ?? vm.currentPaidAmount;
      final previousBalance = customer.balance;

      try {
        developer.log('Attempting to generate distribution PDF', name: 'AddDistributionScreen');
        final path = await pdfGen.generateDistributionInvoice(
          customer: customer,
          items: items,
          total: total,
          paid: paid,
          previousBalance: previousBalance,
          dateTime: DateTime.now(),
          createdBy: 'المستخدم',
          printerSize: size,
          notes: null,
        );

        developer.log('PDF generated at: $path', name: 'AddDistributionScreen');

        if (!mounted) return;

        // Show a SnackBar with an action to open the file. This avoids pushing
        // another Navigator route and prevents accidentally popping the current
        // screen.
        final snack = SnackBar(
          content: Text('تم إنشاء PDF: ${path.split(RegExp(r"[\\/]")).last}'),
          action: SnackBarAction(
            label: 'فتح',
            onPressed: () => OpenFile.open(path),
          ),
          duration: const Duration(seconds: 6),
        );

        ScaffoldMessenger.of(context).showSnackBar(snack);

        if (preview) {
          // Open external viewer but do not pop any in-app routes
          OpenFile.open(path);
        }
      } catch (e, st) {
        developer.log('Error while generating PDF: $e\n$st', name: 'AddDistributionScreen', error: e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء إنشاء PDF: $e')));
      }
    } else {
      // هنا يمكن ربط منطق الطباعة الحرارية الفعلية لاحقاً
    }
  }
}