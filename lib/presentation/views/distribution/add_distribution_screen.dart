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
  
  List<Customer> _customers = [];
  List<Product> _products = [];
  
  bool _loading = true;
  bool _creating = false;
  
  // متغير للتحكم في خيار الكمية المجانية
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

      final customerResult = results[0] as dynamic; 
      final productResult = results[1] as dynamic;

      if (!mounted) return;

      setState(() {
        customerResult.fold(
          (failure) {
             developer.log('Failed to load customers: ${failure.message}');
             _customers = [];
          },
          (data) => _customers = data as List<Customer>,
        );

        productResult.fold(
          (failure) {
             developer.log('Failed to load products: ${failure.message}');
             _products = [];
          },
          (data) => _products = data as List<Product>,
        );

        if (_customers.isNotEmpty) _selectedCustomerId ??= _customers.first.id;
        if (_products.isNotEmpty) {
           _selectedProductId ??= _products.first.id;
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
    final _ = AppLocalizations.of(context)!;

    final vm = context.read<DistributionViewModel>();
    if (_selectedProductId == null) return;
    
    final product = _products.firstWhere((p) => p.id == _selectedProductId);
    
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    if (qty <= 0) return;

    // --- 1. التحقق من المخزون (Inventory Check) ---
    // نحسب الكمية الموجودة حالياً في السلة لهذا المنتج
    double currentCartQty = 0.0;
    try {
      final existingItem = vm.currentItems.firstWhere((item) => item.productId == product.id);
      currentCartQty = existingItem.quantity;
    } catch (_) {
      // المنتج غير موجود في السلة
    }

    // التحقق: هل (الكمية الجديدة + ما في السلة) أكبر من المخزون؟
    if ((qty + currentCartQty) > product.stock) {
      final remaining = product.stock - currentCartQty;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'الكمية المطلوبة أكبر من المخزون المتوفر!\n'
          'المخزون الحالي: ${product.stock}\n'
          'الكمية في السلة: $currentCartQty\n'
          'المتاح للإضافة: ${remaining > 0 ? remaining : 0}'
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ));
      return; // إيقاف العملية
    }
    // ------------------------------------------------

    // --- 2. منطق السعر المجاني ---
    final price = _isFree ? 0.0 : (double.tryParse(_priceController.text) ?? product.price);
    
    vm.addItem(productId: product.id, productName: product.name, quantity: qty, price: price);
    
    // إعادة تعيين الحقول
    _qtyController.text = '1';
    _priceController.text = product.price.toString();
    setState(() {
      _isFree = false; // إعادة تعيين خيار المجاني
    });
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
      final lastId = vm.lastCreatedDistributionId;
      if (lastId != null) {
        await vm.getDistributionById(lastId);
      }
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

                    // --- تصميم جديد لصف إضافة المنتج ---
                    // الصف الأول: المنتج والكمية
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButton<String>(
                            value: _selectedProductId,
                            isExpanded: true,
                            hint: const Text("اختر المنتج"),
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
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: t.quantityLabel),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // الصف الثاني: السعر، خيار مجاني، وزر الإضافة
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            enabled: !_isFree, // تعطيل السعر إذا كان مجاني
                            decoration: InputDecoration(
                              labelText: t.priceLabel,
                              filled: _isFree,
                              fillColor: _isFree ? Colors.grey.shade200 : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // خيار "مجاني"
                        Row(
                          children: [
                            Checkbox(
                              value: _isFree,
                              onChanged: (val) {
                                setState(() {
                                  _isFree = val ?? false;
                                  if (!_isFree && _selectedProductId != null) {
                                    // استعادة السعر الأصلي عند إلغاء المجاني
                                    final p = _products.firstWhere((p) => p.id == _selectedProductId);
                                    _priceController.text = p.price.toString();
                                  }
                                });
                              },
                            ),
                            const Text("مجاني", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addItem,
                          child: Text(t.add),
                        ),
                      ],
                    ),
                    // ------------------------------------

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
                              // عرض (مجاني) إذا كان السعر صفر
                              final isFreeItem = it.price == 0;
                              return ListTile(
                                title: Text(it.productName),
                                subtitle: Text(isFreeItem 
                                  ? '${it.quantity} x (مجاني)' 
                                  : '${it.quantity} x ${it.price.toStringAsFixed(2)}'),
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

    if (vm.selectedDistribution == null && vm.lastCreatedDistributionId != null) {
      await vm.getDistributionById(vm.lastCreatedDistributionId!);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(output == PrintOutput.pdf
          ? 'سيتم إنشاء ملف PDF للمسح/الطباعة بمقاس ${size.name}'
          : 'سيتم طباعة الفاتورة بمقاس ${size.name} (عرض فعلي ${size.printableWidthMm}mm)')),
    );

    if (output == PrintOutput.pdf) {
      final pdfGen = PDFGenerator();
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
          OpenFile.open(path);
        }
      } catch (e, st) {
        developer.log('Error while generating PDF: $e\n$st', name: 'AddDistributionScreen', error: e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء إنشاء PDF: $e')));
      }
    }
  }
}