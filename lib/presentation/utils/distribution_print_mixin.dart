import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:screenshot/screenshot.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:image/image.dart' as img;
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:open_file/open_file.dart';

import '../../../core/utils/service_locator.dart';
import '../../../core/services/thermal_printer_service.dart';
import '../../../core/utils/thermal_invoice_generator.dart';
import '../../../core/utils/ticket_generator.dart';
import '../../../domain/repositories/customer_repository.dart';
import '../../../domain/entities/distribution.dart';
import '../../../l10n/app_localizations.dart';
import '../viewmodels/distribution_viewmodel.dart';
import '../widgets/print_button.dart';
import '../widgets/receipt_widget.dart';

// Mixin يجب أن يُستخدم مع كلاس يمتد من State<T extends StatefulWidget>
mixin DistributionPrintMixin<T extends StatefulWidget> on State<T> {
  // 1. Printing State/Variables (Private)
  BluetoothDevice? _selectedPrinterDevice;
  final ThermalPrinterService _printerService = ThermalPrinterService();
  final TicketGenerator _ticketGenerator = TicketGenerator();
  final ScreenshotController _screenshotController = ScreenshotController();
  
  // 2. Public Getters & Actions
  BluetoothDevice? get selectedPrinterDevice => _selectedPrinterDevice;
  
  // دوال عامة للاتصال/الفصل
  Future<bool> connectToPrinter() => _connectToPrinter();
  
  Future<void> disconnectPrinter() => _disconnectPrinter();

  // 3. Main Print Orchestration (الوظيفة الرئيسية الموحدة)
  Future<void> printDistributionInvoice(
    Distribution dist,
    PrinterSize size,
    PrintOutput output,
    bool preview,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final vm = context.read<DistributionViewModel>();
      final t = AppLocalizations.of(context)!;

      await vm.getDistributionById(dist.id);
      final distribution = vm.selectedDistribution ?? dist;
      
      final customerRepo = getIt<CustomerRepository>();
      final customerResult = await customerRepo.getCustomerById(distribution.customerId);
      final customer = customerResult.fold((failure) => null, (customer) => customer);

      if (customer == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Customer not found')));
        return;
      }

      if (output == PrintOutput.pdf) {
        await _handlePdfPrinting(distribution, customer, size, preview);
      } else {
        await _handleThermalPrinting(distribution, customer, size, t);
      }
    } catch (e, st) {
      developer.log('Error printing distribution: $e\n$st', name: 'PrintMixin', error: e);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الطباعة: $e')));
    }
  }

  // 4. Sub-Functions: PDF Handling (kept private)
  Future<void> _handlePdfPrinting(Distribution distribution, customer, PrinterSize size, bool preview) async {
    final messenger = ScaffoldMessenger.of(context);
    final thermalGen = ThermalInvoiceGenerator();
    final path = await thermalGen.generateDistributionInvoice(
      customer: customer,
      items: distribution.items,
      total: distribution.totalAmount,
      paid: distribution.paidAmount,
      previousBalance: customer.balance,
      dateTime: distribution.distributionDate,
      createdBy: FirebaseAuth.instance.currentUser?.displayName ?? 'المستخدم',
      printerSize: size,
      notes: distribution.notes,
    );

    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text('تم إنشاء PDF: ${path.split(RegExp(r"[\\/]")).last}'), action: SnackBarAction(label: 'فتح', onPressed: () => OpenFile.open(path))));
    if (preview) OpenFile.open(path);
  }

  // 5. Sub-Functions: Thermal Handling (kept private)
  Future<void> _handleThermalPrinting(Distribution distribution, customer, PrinterSize size, AppLocalizations t) async {
    final messenger = ScaffoldMessenger.of(context);
    
    if (!(await _printerService.isAvailable)) {
      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('الرجاء تفعيل البلوتوث')));
      return;
    }

    if (!await _connectToPrinter()) return;

    messenger.showSnackBar(const SnackBar(content: Text('جاري معالجة الصورة...')));
    
    final Uint8List? imageBytes = await _captureVerifiedImage(distribution, customer);
    if (imageBytes == null) {
      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('فشل التقاط الفاتورة (النتيجة بيضاء). أعد المحاولة')));
      return;
    }
    
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => _buildPreviewDialog(imageBytes));
    if (!confirmed!) return;

    final bytes = await _ticketGenerator.generateImageTicket(
      imageBytes: imageBytes,
      paperSize: size.name == '58mm' ? PaperSize.mm58 : PaperSize.mm80,
    );
    if (bytes.isEmpty) {
      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('خطأ: لم يتم إنشاء أوامر الطباعة')));
      return;
    }

    final result = await _printerService.printBytes(bytes);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      messenger.showSnackBar(SnackBar(
        content: Text(result ? 'تمت الطباعة بنجاح' : 'حدث خطأ أثناء الطباعة'),
        backgroundColor: result ? Colors.green : Colors.red,
      ));
    }
  }

  // 6. Private Helper: Connect to Printer (Implementation)
  Future<bool> _connectToPrinter() async {
    if (_selectedPrinterDevice != null && await _printerService.isConnected) return true;
    
    final devices = await _printerService.getBondedDevices();
    if (devices.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد طابعات مقترنة.')));
      return false;
    }
    
    if (devices.length == 1) {
      final ok = await _printerService.connect(devices.first);
      if (ok) {
        if (mounted) setState(() => _selectedPrinterDevice = devices.first);
        return true;
      }
    } 
    
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

    if (selectedDevice == null) return false;
    final ok = await _printerService.connect(selectedDevice);
    if (ok) if (mounted) setState(() => _selectedPrinterDevice = selectedDevice);

    return ok;
  }

  // 7. Private Helper: Disconnect Printer (Implementation)
  Future<void> _disconnectPrinter() async {
    await _printerService.disconnect();
    if (mounted) {
      setState(() => _selectedPrinterDevice = null);
    }
  }
  
  // 8. Private Helper: Capture Verified Image (kept private)
  Future<Uint8List?> _captureVerifiedImage(Distribution distribution, customer) async {
    final attempts = [300, 600, 1000];
    for (int i = 0; i < attempts.length; i++) {
      final delayMs = attempts[i];
      try {
        final Uint8List bytes = await _screenshotController.captureFromWidget(
          Material(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Theme(
                data: ThemeData.light(),
                child: ReceiptWidget(distribution: distribution, customer: customer),
              ),
            ),
          ),
          delay: Duration(milliseconds: delayMs),
          pixelRatio: 2.0 + i * 0.5,
          context: context,
        );
        if (bytes.length < 2000) continue; 
        final img.Image? decoded = img.decodeImage(bytes);
        if (decoded == null) continue;

        int whiteCount = 0;
        final totalSamples = ((decoded.width / 4).ceil()) * ((decoded.height / 4).ceil());
        for (int y = 0; y < decoded.height; y += 4) {
          for (int x = 0; x < decoded.width; x += 4) {
            final p = decoded.getPixel(x, y);
            final luminance = (0.2126 * img.getRed(p) + 0.7152 * img.getGreen(p) + 0.0722 * img.getBlue(p));
            if (luminance > 250) whiteCount++;
          }
        }
        final whiteRatio = whiteCount / (totalSamples > 0 ? totalSamples : 1);
        if (whiteRatio < 0.98) return bytes;
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    return null;
  }

  // 9. Private Helper: Build Preview Dialog (kept private)
  Widget _buildPreviewDialog(Uint8List imageBytes) {
      return AlertDialog(
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
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('طباعة')),
        ],
      );
  }
}