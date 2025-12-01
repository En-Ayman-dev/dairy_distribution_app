import 'dart:typed_data'; // إضافة مهمة
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

// --- Imports: Core & Utils ---
import '../../../core/utils/service_locator.dart';
import '../../../core/services/thermal_printer_service.dart';
import '../../../core/utils/thermal_invoice_generator.dart';
import '../../../core/utils/ticket_generator.dart';
import '../../../domain/entities/distribution.dart';
import '../../../l10n/app_localizations.dart';

// --- Imports: Domain Layer ---
import '../../../domain/repositories/customer_repository.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/product.dart';

// --- Imports: Presentation Layer ---
import '../../viewmodels/distribution_viewmodel.dart';
import '../../widgets/print_button.dart';
import '../../widgets/receipt_widget.dart';

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
  bool _isFree = false;
  BluetoothDevice? _selectedPrinterDevice;

  final _printerService = ThermalPrinterService();
  final _ticketGenerator = TicketGenerator();
  final _screenshotController =
      ScreenshotController(); // نستخدمه للالتقاط المباشر

  @override
  void initState() {
    super.initState();
    _loadLookups();
    // placeholder - no immediate auto-reconnect performed here
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
        customerResult.fold((failure) {
          _customers = [];
        }, (data) => _customers = data as List<Customer>);

        productResult.fold((failure) {
          _products = [];
        }, (data) => _products = data as List<Product>);

        if (_customers.isNotEmpty) _selectedCustomerId ??= _customers.first.id;
        if (_products.isNotEmpty) {
          _selectedProductId ??= _products.first.id;
          final p = _products.first;
          _priceController.text = p.price.toString();
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

  Future<void> _selectPrinter() async {
    final devices = await _printerService.getBondedDevices();
    if (devices.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا توجد طابعات مقترنة.')));
      }
      return;
    }

    final selected = await showDialog<BluetoothDevice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختر الطابعة'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (ctx, i) => ListTile(
              title: Text(devices[i].name ?? 'Unknown'),
              subtitle: Text(devices[i].address ?? ''),
              onTap: () => Navigator.pop(ctx, devices[i]),
              leading: const Icon(Icons.print),
            ),
          ),
        ),
      ),
    );

    if (selected == null) return;

    final ok = await _printerService.connect(selected);
    if (ok) {
      setState(() => _selectedPrinterDevice = selected);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم الاتصال بالطابعة')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل الاتصال بالطابعة')));
      }
    }
  }

  /// Show in-app preview of the captured receipt image and return true to proceed printing
  Future<bool> _showImagePreview(Uint8List imageBytes) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('معاينة الفاتورة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(imageBytes),
              const SizedBox(height: 8),
              const Text('تحقق من أن المحتوى ظاهر قبل الطباعة'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('طباعة'),
          ),
        ],
      ),
    );

    return proceed ?? false;
  }

  void _addItem() {
    final vm = context.read<DistributionViewModel>();
    if (_selectedProductId == null) return;

    final product = _products.firstWhere((p) => p.id == _selectedProductId);

    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    if (qty <= 0) return;

    double currentCartQty = 0.0;
    try {
      final existingItem = vm.currentItems.firstWhere(
        (item) => item.productId == product.id,
      );
      currentCartQty = existingItem.quantity;
    } catch (_) {}

    if ((qty + currentCartQty) > product.stock) {
      final remaining = product.stock - currentCartQty;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الكمية غير متوفرة. المتاح: ${remaining > 0 ? remaining : 0}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final price = _isFree
        ? 0.0
        : (double.tryParse(_priceController.text) ?? product.price);

    vm.addItem(
      productId: product.id,
      productName: product.name,
      quantity: qty,
      price: price,
    );

    _qtyController.text = '1';
    _priceController.text = product.price.toString();
    setState(() {
      _isFree = false;
    });
  }

  Future<void> _submit() async {
    final vm = context.read<DistributionViewModel>();
    if (_selectedCustomerId == null) return;
    if (vm.currentItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.addFirstProductPrompt),
        ),
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
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.createTestDistributionSuccess,
          ),
        ),
      );
      final lastId = vm.lastCreatedDistributionId;
      if (lastId != null) {
        await vm.getDistributionById(lastId);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            vm.errorMessage ?? AppLocalizations.of(context)!.errorOccurred,
          ),
        ),
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
                    Text(
                      t.customersTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _selectedCustomerId,
                      isExpanded: true,
                      items: _customers
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCustomerId = v),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      t.addProductTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButton<String>(
                            value: _selectedProductId,
                            isExpanded: true,
                            hint: const Text("اختر المنتج"),
                            items: _products
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(p.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() {
                              _selectedProductId = v;
                              if (v != null) {
                                final p = _products.firstWhere(
                                  (p) => p.id == v,
                                );
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
                            decoration: InputDecoration(
                              labelText: t.quantityLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            enabled: !_isFree,
                            decoration: InputDecoration(
                              labelText: t.priceLabel,
                              filled: _isFree,
                              fillColor: _isFree ? Colors.grey.shade200 : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _isFree,
                              onChanged: (val) {
                                setState(() {
                                  _isFree = val ?? false;
                                  if (!_isFree && _selectedProductId != null) {
                                    final p = _products.firstWhere(
                                      (p) => p.id == _selectedProductId,
                                    );
                                    _priceController.text = p.price.toString();
                                  }
                                });
                              },
                            ),
                            const Text(
                              "مجاني",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: _addItem, child: Text(t.add)),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Text(
                      t.itemsLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),

                    SizedBox(
                      height: 220,
                      child: Consumer<DistributionViewModel>(
                        builder: (context, vm, child) {
                          final items = vm.currentItems;
                          if (items.isEmpty) {
                            return Center(child: Text(t.noProductsFound));
                          }
                          return ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, idx) {
                              final it = items[idx];
                              return ListTile(
                                title: Text(it.productName),
                                subtitle: Text(
                                  it.price == 0
                                      ? '${it.quantity} (مجاني)'
                                      : '${it.quantity} x ${it.price}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(it.subtotal.toStringAsFixed(2)),
                                    IconButton(
                                      onPressed: () => vm.removeItem(it.id),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t.currentStockPrefix),
                        Consumer<DistributionViewModel>(
                          builder: (c, vm, _) =>
                              Text(vm.getCurrentTotal().toStringAsFixed(2)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _paidController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(labelText: t.paid),
                    ),
                    const SizedBox(height: 16),

                    Consumer<DistributionViewModel>(
                      builder: (c, vm, _) {
                        final canPrint = vm.lastCreatedDistributionId != null;
                        if (!canPrint) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _selectPrinter,
                                    icon: const Icon(Icons.bluetooth),
                                    label: Text(
                                      _selectedPrinterDevice?.name ??
                                          'اختر الطابعة',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_selectedPrinterDevice != null)
                                  IconButton(
                                    onPressed: () async {
                                      await _printerService.disconnect();
                                      setState(
                                        () => _selectedPrinterDevice = null,
                                      );
                                    },
                                    icon: const Icon(Icons.link_off),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            PrintButton(
                              onPrint: (printerSize, output, preview) async {
                                await _printInvoice(
                                  printerSize,
                                  output,
                                  preview,
                                );
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
                    SizedBox(
                      width: double.infinity,
                      child: _creating
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _submit,
                              child: Text(t.createDistributionLabel),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _printInvoice(
    PrinterSize size,
    PrintOutput output,
    bool preview,
  ) async {
    final vm = context.read<DistributionViewModel>();
    final customer = _customers.firstWhere((c) => c.id == _selectedCustomerId);

    if (vm.selectedDistribution == null &&
        vm.lastCreatedDistributionId != null) {
      await vm.getDistributionById(vm.lastCreatedDistributionId!);
    }

    if (output == PrintOutput.pdf) {
      // (كود PDF القديم كما هو)
      final thermalGen = ThermalInvoiceGenerator();
      final distribution =
          vm.selectedDistribution ??
          Distribution(
            id: 'TEMP',
            customerId: customer.id,
            customerName: customer.name,
            distributionDate: DateTime.now(),
            items: vm.currentItems,
            totalAmount: vm.getCurrentTotal(),
            paidAmount: vm.currentPaidAmount,
            paymentStatus: PaymentStatus.pending,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

      try {
        final path = await thermalGen.generateDistributionInvoice(
          customer: customer,
          items: distribution.items,
          total: distribution.totalAmount,
          paid: distribution.paidAmount,
          previousBalance: customer.balance,
          dateTime: DateTime.now(),
          createdBy: 'المستخدم',
          printerSize: size,
          notes: null,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إنشاء PDF'),
            action: SnackBarAction(
              label: 'فتح',
              onPressed: () => OpenFile.open(path),
            ),
          ),
        );
        if (preview) OpenFile.open(path);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
        }
      }
    } else {
      // --- الطباعة الحرارية (الحل النهائي للورقة البيضاء) ---

      // تحقق من توفر البلوتوث أولاً
      if (!(await _printerService.isAvailable)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الرجاء تفعيل البلوتوث')),
          );
        }
        return;
      }

      // تأكد من الاتصال — حاول الاتصال تلقائياً إذا لم نكن متصلين
      // إذا حدد المستخدم طابعة يدوياً سابقاً، جرب الاتصال بها أولاً
      if (_selectedPrinterDevice != null &&
          !(await _printerService.isConnected)) {
        final ok = await _printerService.connect(_selectedPrinterDevice!);
        if (!ok) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('فشل الاتصال بالطابعة المحددة')),
            );
          }
          // تعيد تعيين الطابعة ليرجع المستخدم لاختيار طابعة أخرى
          setState(() => _selectedPrinterDevice = null);
          return;
        }
      } else if (!(await _printerService.isConnected)) {
        // لا توجد طابعة محددة؛ اعمل الاختيار التلقائي السابق
        final devices = await _printerService.getBondedDevices();
        if (devices.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('لا توجد طابعات مقترنة.')),
            );
          }
          return;
        }

        // إذا كان هناك جهاز واحد فقط، حاول الاتصال به تلقائياً
        if (devices.length == 1) {
          final ok = await _printerService.connect(devices.first);
          if (!ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('فشل الاتصال بالطابعة')),
            );
          }
          if (!ok) return;
        } else {
          // إذا كان هناك أكثر من جهاز، اطلب من المستخدم الاختيار
          final selectedDevice = await showDialog<BluetoothDevice>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('اختر الطابعة'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (ctx, i) => ListTile(
                    title: Text(devices[i].name ?? 'Unknown'),
                    subtitle: Text(devices[i].address ?? ''),
                    onTap: () => Navigator.pop(ctx, devices[i]),
                    leading: const Icon(Icons.print),
                  ),
                ),
              ),
            ),
          );

          if (selectedDevice == null) return;
          final ok = await _printerService.connect(selectedDevice);
          if (!ok && mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('فشل الاتصال')));
          }
          if (!ok) return;
        }
      }

      try {
        // تجهيز البيانات
        final distribution =
            vm.selectedDistribution ??
            Distribution(
              id: 'New',
              customerId: customer.id,
              customerName: customer.name,
              distributionDate: DateTime.now(),
              items: vm.currentItems,
              totalAmount: vm.getCurrentTotal(),
              paidAmount: vm.currentPaidAmount,
              paymentStatus: PaymentStatus.pending,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('جاري معالجة الصورة...')));

        // Capture with verification: try multiple attempts with increasing delay
        Future<Uint8List?> captureVerifiedImage() async {
          final attempts = [300, 600, 1000]; // milliseconds
          for (int i = 0; i < attempts.length; i++) {
            final delayMs = attempts[i];
            try {
              final Uint8List bytes = await _screenshotController
                  .captureFromWidget(
                    Material(
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Theme(
                          data: ThemeData.light(),
                          child: ReceiptWidget(
                            distribution: distribution,
                            customer: customer,
                          ),
                        ),
                      ),
                    ),
                    delay: Duration(milliseconds: delayMs),
                    pixelRatio: 2.0 + i * 0.5,
                    context: context, // ← الإضافة الوحيدة لحل خطأ View.of()
                  );

              // Save debug image for inspection
              try {
                final dir = await getTemporaryDirectory();
                final file = File(
                  '${dir.path}/receipt_debug_attempt_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.png',
                );
                await file.writeAsBytes(bytes);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'صورة الفاتورة محفوظة للتصحيح: ${file.path}',
                      ),
                    ),
                  );
                }
              } catch (e) {
                developer.log('Failed saving debug image', error: e);
              }

              // Quick sanity checks: size and whiteness
              if (bytes.length < 2000) {
                developer.log(
                  'Captured image too small (${bytes.length} bytes), retrying...',
                );
                await Future.delayed(const Duration(milliseconds: 200));
                continue;
              }

              final img.Image? decoded = img.decodeImage(bytes);
              if (decoded == null) {
                developer.log('Failed to decode captured image, retrying...');
                await Future.delayed(const Duration(milliseconds: 200));
                continue;
              }

              // compute percent white pixels
              int whiteCount = 0;
              for (int y = 0; y < decoded.height; y += 4) {
                for (int x = 0; x < decoded.width; x += 4) {
                  final p = decoded.getPixel(x, y);
                  final r = img.getRed(p);
                  final g = img.getGreen(p);
                  final b = img.getBlue(p);
                  final luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b);
                  if (luminance > 250) whiteCount++;
                }
              }

              final totalSamples =
                  ((decoded.width / 4).ceil()) * ((decoded.height / 4).ceil());
              final whiteRatio =
                  whiteCount / (totalSamples > 0 ? totalSamples : 1);
              developer.log(
                'Capture attempt ${i + 1}: bytes=${bytes.length}, whiteRatio=$whiteRatio',
              );

              // If less than 98% white, accept
              if (whiteRatio < 0.98) {
                return bytes;
              }

              // otherwise retry
              await Future.delayed(const Duration(milliseconds: 200));
            } catch (e) {
              developer.log('Capture attempt error: $e');
              await Future.delayed(const Duration(milliseconds: 200));
            }
          }
          return null;
        }

        final Uint8List? imageBytes = await captureVerifiedImage();
        if (imageBytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'فشل التقاط الفاتورة (النتيجة بيضاء). أعد المحاولة',
                ),
              ),
            );
          }
          return;
        }

        // عرض معاينة للمستخدم قبل الإرسال للطابعة
        final confirmed = await _showImagePreview(imageBytes);
        if (!confirmed) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('تم إلغاء الطباعة')));
          }
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('جاري الإرسال للطابعة...')),
        );

        // 2. تحويل الصورة إلى أوامر وإرسالها
        final bytes = await _ticketGenerator.generateImageTicket(
          imageBytes: imageBytes,
        );

        // تحقق أن الأوامر ليست فارغة — إن كانت كذلك، أمنع الطباعة واحتفظ بالمخرجات للتدقيق
        if (bytes.isEmpty) {
          try {
            final dir = await getTemporaryDirectory();
            final file = File(
              '${dir.path}/escpos_debug_${DateTime.now().millisecondsSinceEpoch}.bin',
            );
            await file.writeAsBytes(bytes);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'لم تُنشأ أوامر الطباعة. تم حفظ ملف التصحيح: ${file.path}',
                  ),
                ),
              );
            }
          } catch (e) {
            developer.log('Failed saving ESC/POS debug file', error: e);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('خطأ: لم يتم إنشاء أوامر الطباعة')),
            );
          }
          return;
        }

        // احفظ نسخة من أوامر الطباعة للتدقيق إن رغبت بذلك (مفيد للتحقق من الأمر المرسل)
        try {
          final dir = await getTemporaryDirectory();
          final file = File(
            '${dir.path}/escpos_${DateTime.now().millisecondsSinceEpoch}.bin',
          );
          await file.writeAsBytes(bytes);
          developer.log('Saved ESC/POS bytes to: ${file.path}');
        } catch (_) {}

        final result = await _printerService.printBytes(bytes);

        // امنح الطابعة بعض الوقت لمعالجة المهمة قبل إظهار رسالة النجاح
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          if (result) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تمت الطباعة بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('حدث خطأ أثناء الطباعة'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        developer.log('Print error', error: e);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
        }
      }
    }
  }
}
