// ignore_for_file: use_build_context_synchronously, deprecated_member_use, no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import '../../../core/utils/service_locator.dart';
// --- تم حذف استيرادات LocalDataSource ---
import '../../../core/utils/thermal_invoice_generator.dart';
import '../../viewmodels/distribution_viewmodel.dart';
// --- إضافة استيراد المستودع للوصول لبيانات العميل أثناء الطباعة ---
import '../../../domain/repositories/customer_repository.dart';
import '../../../domain/entities/distribution.dart';
import '../../../domain/entities/distribution_item.dart';
import '../../widgets/print_button.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:screenshot/screenshot.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../../core/services/thermal_printer_service.dart';
import '../../../core/utils/ticket_generator.dart';
import '../../widgets/receipt_widget.dart';
import '../../../l10n/app_localizations.dart';
import 'distribution_detail_screen.dart';

class DistributionListScreen extends StatefulWidget {
  const DistributionListScreen({super.key});

  @override
  State<DistributionListScreen> createState() => _DistributionListScreenState();
}

class _DistributionListScreenState extends State<DistributionListScreen> {
  BluetoothDevice? _selectedPrinterDevice;
  final _printerService = ThermalPrinterService();
  final _ticketGenerator = TicketGenerator();
  final _screenshotController = ScreenshotController();
  @override
  void initState() {
    super.initState();
    developer.log(
      'DistributionListScreen: initState',
      name: 'DistributionListScreen',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<DistributionViewModel>().loadDistributions();
        developer.log(
          'Requested DistributionViewModel.loadDistributions',
          name: 'DistributionListScreen',
        );
      } catch (e) {
        developer.log(
          'Error requesting loadDistributions: $e',
          name: 'DistributionListScreen',
        );
      }
    });
  }

  @override
  void dispose() {
    developer.log(
      'DistributionListScreen: dispose',
      name: 'DistributionListScreen',
    );
    super.dispose();
  }

  // هذه الدالة لا تزال تعمل لأنها تستخدم Firestore SDK مباشرة للتحقق، وهو أمر مقبول للـ Debugging
  Future<void> _testFirestoreAccess(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    developer.log(
      'DistributionListScreen: testFirestoreAccess started',
      name: 'DistributionListScreen',
    );
    if (uid == null) {
      developer.log('Not authenticated', name: 'DistributionListScreen');
      messenger.showSnackBar(SnackBar(content: Text(t.notAuthenticated)));
      return;
    }

    try {
      final q = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('distributions')
          .limit(1);
      final snapshot = await q.get();
      developer.log(
        'Firestore read succeeded',
        name: 'DistributionListScreen',
        error: 'docs=${snapshot.docs.length}',
      );
      final content = snapshot.docs.isEmpty
          ? 'No documents found under users/$uid/distributions (read succeeded).'
          : 'Found ${snapshot.docs.length} document(s). First id: ${snapshot.docs.first.id}';

      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.firestoreReadResult),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.ok),
            ),
          ],
        ),
      );
    } on FirebaseException catch (e) {
      developer.log(
        'Firestore error',
        name: 'DistributionListScreen',
        error: '${e.code}: ${e.message}',
      );
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.firestoreError),
          content: SingleChildScrollView(
            child: Text(
              'code: ${e.code}\nmessage: ${e.message}\nstack: ${e.stackTrace}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.ok),
            ),
          ],
        ),
      );
    } catch (e, st) {
      developer.log(
        'Unexpected error reading Firestore',
        name: 'DistributionListScreen',
        error: e,
      );
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.unexpectedError),
          content: SingleChildScrollView(child: Text('$e\n$st')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.ok),
            ),
          ],
        ),
      );
    }
  }

  // --- تم حذف _showLocalDbCount و _createTestDistribution لأنهما يعتمدان على Local DB المحذوف ---

  @override
  Widget build(BuildContext context) {
    developer.log(
      'DistributionListScreen: build',
      name: 'DistributionListScreen',
    );
    final t = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final printTooltip = isAr ? 'طباعة' : 'Print';
    final editTooltip = isAr ? 'تعديل' : 'Edit';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.distributionListTitle),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.firestoreReadResult,
            icon: const Icon(Icons.cloud_outlined),
            onPressed: () => _testFirestoreAccess(context),
          ),
        ],
      ),
      body: Consumer<DistributionViewModel>(
        builder: (context, vm, child) {
          if (vm.state == DistributionViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.state == DistributionViewState.error) {
            return Center(
              child: Text(
                vm.errorMessage ??
                    AppLocalizations.of(context)!.failedToLoadDistributions,
              ),
            );
          }

          final list = vm.distributions;
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context)!.noDistributionsToShow),
                  // تم إزالة أزرار الاختبار المحلية
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final dist = list[index];
              return ListTile(
                title: Text(dist.customerName),
                subtitle: Text(
                  '${dist.distributionDate.day}/${dist.distributionDate.month}/${dist.distributionDate.year}',
                ),
                trailing: SizedBox(
                  width: 200,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          'ريال${dist.totalAmount.toStringAsFixed(2)}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: printTooltip,
                        icon: const Icon(Icons.print),
                        iconSize: 20,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () => _showPrintDialogForDistribution(dist),
                      ),
                      IconButton(
                        tooltip: editTooltip,
                        icon: const Icon(Icons.edit),
                        iconSize: 20,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () => _showEditDialog(dist),
                      ),
                      IconButton(
                        tooltip: t.deleteLabel,
                        icon: const Icon(Icons.delete_outline),
                        iconSize: 20,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () => _confirmAndDelete(dist),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          DistributionDetailScreen(distribution: dist),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showPrintDialogForDistribution(Distribution dist) async {
    PrinterSize selected = kPrinterSizes.first;
    PrintOutput output = PrintOutput.pdf;
    bool preview = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('اختيار مقاس الطابعة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final size in kPrinterSizes)
                    RadioListTile<PrinterSize>(
                      value: size,
                      groupValue: selected,
                      onChanged: (v) => setState(() => selected = v!),
                      title: Text(
                        '${size.name} (عرض فعلي ~${size.printableWidthMm}mm) - ${size.description}',
                      ),
                    ),
                  const Divider(),
                  RadioListTile<PrintOutput>(
                    value: PrintOutput.printer,
                    groupValue: output,
                    onChanged: (v) => setState(() => output = v!),
                    title: const Text('طباعة إلى طابعة حرارية'),
                  ),
                  RadioListTile<PrintOutput>(
                    value: PrintOutput.pdf,
                    groupValue: output,
                    onChanged: (v) => setState(() => output = v!),
                    title: const Text('حفظ / عرض PDF'),
                  ),
                  if (output == PrintOutput.pdf)
                    CheckboxListTile(
                      value: preview,
                      onChanged: (v) => setState(() => preview = v ?? false),
                      title: const Text('عرض ملف PDF بعد الإنشاء'),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _printDistribution(dist, selected, output, preview);
                },
                icon: const Icon(Icons.print),
                label: const Text('طباعة'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _printDistribution(
    Distribution dist,
    PrinterSize size,
    PrintOutput output,
    bool preview,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final vm = context.read<DistributionViewModel>();

      // Ensure we load the saved distribution details
      await vm.getDistributionById(dist.id);
      final distribution = vm.selectedDistribution ?? dist;

      // --- تعديل جوهري: استخدام المستودع بدلاً من مصدر البيانات المحلي ---
      final customerRepo = getIt<CustomerRepository>();
      final customerResult = await customerRepo.getCustomerById(
        distribution.customerId,
      );

      // التعامل مع نتيجة Either
      final customer = customerResult.fold(
        (failure) => null,
        (customer) => customer,
      );
      // -------------------------------------------------------------

      if (customer == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Customer not found')),
        );
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            output == PrintOutput.pdf
                ? 'سيتم إنشاء ملف PDF للمسح/الطباعة بمقاس ${size.name}'
                : 'سيتم طباعة الفاتورة بمقاس ${size.name} (عرض فعلي ${size.printableWidthMm}mm)',
          ),
        ),
      );

      if (output == PrintOutput.pdf) {
        final thermalGen = ThermalInvoiceGenerator();
        final path = await thermalGen.generateDistributionInvoice(
          customer: customer,
          items: distribution.items,
          total: distribution.totalAmount,
          paid: distribution.paidAmount,
          previousBalance: customer.balance,
          dateTime: distribution.distributionDate,
          createdBy:
              FirebaseAuth.instance.currentUser?.displayName ?? 'المستخدم',
          printerSize: size,
          notes: distribution.notes,
        );

        if (!mounted) return;
        final snack = SnackBar(
          content: Text('تم إنشاء PDF: ${path.split(RegExp(r"[\\/]")).last}'),
          action: SnackBarAction(
            label: 'فتح',
            onPressed: () => OpenFile.open(path),
          ),
          duration: const Duration(seconds: 6),
        );
        messenger.showSnackBar(snack);

        if (preview) OpenFile.open(path);
      } else {
        // --- Full thermal printing implementation (copied from AddDistributionScreen) ---
        // تحقق من توفر البلوتوث أولاً
        if (!(await _printerService.isAvailable)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('الرجاء تفعيل البلوتوث')),
            );
          }
          return;
        }

        // حاول الاتصال بالطابعة المحددة إن وجدت
        if (_selectedPrinterDevice != null &&
            !(await _printerService.isConnected)) {
          final ok = await _printerService.connect(_selectedPrinterDevice!);
          if (!ok) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('فشل الاتصال بالطابعة المحددة')),
              );
            }
            setState(() => _selectedPrinterDevice = null);
            return;
          }
        } else if (!(await _printerService.isConnected)) {
          // لا توجد طابعة محددة؛ حاول الاختيار التلقائي من الأجهزة المقترنة
          final devices = await _printerService.getBondedDevices();
          if (devices.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('لا توجد طابعات مقترنة.')),
              );
            }
            return;
          }

          if (devices.length == 1) {
            final ok = await _printerService.connect(devices.first);
            if (!ok && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('فشل الاتصال بالطابعة')),
              );
            }
            if (!ok) return;
            setState(() => _selectedPrinterDevice = devices.first);
          } else {
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
            setState(() => _selectedPrinterDevice = selectedDevice);
          }
        }

        try {
          final vm = context.read<DistributionViewModel>();
          final distribution = vm.selectedDistribution ?? dist;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('جاري معالجة الصورة...')),
          );

          // Capture with verification
          Future<Uint8List?> _captureVerifiedImage() async {
            final attempts = [300, 600, 1000];
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

                // Quick sanity checks
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
                    ((decoded.width / 4).ceil()) *
                    ((decoded.height / 4).ceil());
                final whiteRatio =
                    whiteCount / (totalSamples > 0 ? totalSamples : 1);
                developer.log(
                  'Capture attempt ${i + 1}: bytes=${bytes.length}, whiteRatio=$whiteRatio',
                );

                if (whiteRatio < 0.98) return bytes;

                await Future.delayed(const Duration(milliseconds: 200));
              } catch (e) {
                developer.log('Capture attempt error: $e');
                await Future.delayed(const Duration(milliseconds: 200));
              }
            }
            return null;
          }

          final Uint8List? imageBytes = await _captureVerifiedImage();
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

          // Show preview
          final confirmed = await showDialog<bool>(
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

          if (!confirmed!) {
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

          // Convert image to ESC/POS bytes
          final bytes = await _ticketGenerator.generateImageTicket(
            imageBytes: imageBytes,
            paperSize: size.name == '58mm' ? PaperSize.mm58 : PaperSize.mm80,
          );
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
                const SnackBar(
                  content: Text('خطأ: لم يتم إنشاء أوامر الطباعة'),
                ),
              );
            }
            return;
          }

          try {
            final dir = await getTemporaryDirectory();
            final file = File(
              '${dir.path}/escpos_${DateTime.now().millisecondsSinceEpoch}.bin',
            );
            await file.writeAsBytes(bytes);
            developer.log('Saved ESC/POS bytes to: ${file.path}');
          } catch (_) {}

          final result = await _printerService.printBytes(bytes);
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
        // ---------------------------------------------------------------------------------
      }
    } catch (e, st) {
      developer.log(
        'Error printing distribution: $e\n$st',
        name: 'DistributionListScreen',
        error: e,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الطباعة: $e')));
    }
  }

  Future<void> _confirmAndDelete(Distribution dist) async {
    final vm = context.read<DistributionViewModel>();
    final t = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deleteCustomerTitle),
        content: Text(
          '${t.deleteCustomerConfirm} \n${t.distributionLabel} ${dist.id}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.deleteCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t.deleteLabel),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await vm.deleteDistribution(dist.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${t.distributionLabel} ${dist.id} ${t.distributionDeletedSuccess}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage ?? t.errorOccurred),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog(Distribution dist) async {
    final vm = context.read<DistributionViewModel>();
    await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          EditDistributionDialog(distribution: dist, viewModel: vm),
    );
    return;
  }
}

class EditDistributionDialog extends StatefulWidget {
  final Distribution distribution;
  final DistributionViewModel viewModel;

  const EditDistributionDialog({
    super.key,
    required this.distribution,
    required this.viewModel,
  });

  @override
  State<EditDistributionDialog> createState() => _EditDistributionDialogState();
}

class _EditDistributionDialogState extends State<EditDistributionDialog> {
  late final TextEditingController paidController;
  late final TextEditingController notesController;
  late final List<TextEditingController> qtyControllers;
  late final List<TextEditingController> priceControllers;
  late double currentTotal;

  @override
  void initState() {
    super.initState();
    final dist = widget.distribution;
    paidController = TextEditingController(
      text: dist.paidAmount.toStringAsFixed(2),
    );
    notesController = TextEditingController(text: dist.notes ?? '');
    qtyControllers = dist.items
        .map((it) => TextEditingController(text: it.quantity.toString()))
        .toList();
    priceControllers = dist.items
        .map((it) => TextEditingController(text: it.price.toStringAsFixed(2)))
        .toList();
    currentTotal = _computeTotal();
  }

  double _computeTotal() {
    double s = 0.0;
    for (var i = 0; i < widget.distribution.items.length; i++) {
      final q =
          double.tryParse(qtyControllers[i].text) ??
          widget.distribution.items[i].quantity;
      final p =
          double.tryParse(priceControllers[i].text) ??
          widget.distribution.items[i].price;
      s += q * p;
    }
    return s;
  }

  @override
  void dispose() {
    paidController.dispose();
    notesController.dispose();
    for (final c in qtyControllers) {
      c.dispose();
    }
    for (final c in priceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final dist = widget.distribution;

    return AlertDialog(
      title: Text('${t.distributionLabel} ${dist.id}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t.customerDetailsTitle}: ${dist.customerName}'),
            const SizedBox(height: 8),
            // Items editing
            ...List.generate(dist.items.length, (i) {
              final it = dist.items[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    it.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyControllers[i],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: t.quantityLabel,
                          ),
                          onChanged: (_) =>
                              setState(() => currentTotal = _computeTotal()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: priceControllers[i],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(labelText: t.priceLabel),
                          onChanged: (_) =>
                              setState(() => currentTotal = _computeTotal()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }),

            const Divider(),
            Text(
              'الإجمالي: ريال${currentTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: paidController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: t.paid),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              keyboardType: TextInputType.text,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'ملاحظات'),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (__) {
                final newPaid =
                    double.tryParse(paidController.text) ?? dist.paidAmount;
                final remaining = (currentTotal - newPaid).clamp(
                  0,
                  double.infinity,
                );
                return Text('المتبقي: ريال${remaining.toStringAsFixed(2)}');
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            // Build updated items
            final updatedItems = <DistributionItem>[];
            for (var i = 0; i < dist.items.length; i++) {
              final it = dist.items[i];
              final q = double.tryParse(qtyControllers[i].text) ?? it.quantity;
              final p = double.tryParse(priceControllers[i].text) ?? it.price;
              updatedItems.add(
                it.copyWith(quantity: q, price: p, subtotal: q * p),
              );
            }

            final newTotal = updatedItems.fold(0.0, (s, it) => s + it.subtotal);
            final newPaid =
                double.tryParse(paidController.text) ?? dist.paidAmount;
            final newNotes = notesController.text.trim();

            PaymentStatus newStatus = PaymentStatus.pending;
            if (newPaid >= newTotal) {
              newStatus = PaymentStatus.paid;
            } else if (newPaid > 0) {
              newStatus = PaymentStatus.partial;
            }

            final updated = dist.copyWith(
              items: updatedItems,
              totalAmount: newTotal,
              paidAmount: newPaid,
              notes: newNotes.isEmpty ? null : newNotes,
              paymentStatus: newStatus,
              updatedAt: DateTime.now(),
            );

            Navigator.pop(context, true);

            final ok = await widget.viewModel.updateDistribution(updated);
            if (!mounted) return;
            if (ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${t.distributionLabel} ${dist.id} updated'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.viewModel.errorMessage ?? t.errorOccurred,
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Text(t.confirm),
        ),
      ],
    );
  }
}
