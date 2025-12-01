import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dairy_distribution_app/presentation/views/payments/payments_screen.dart';
import '../../../domain/entities/distribution.dart';
import '../../viewmodels/customer_viewmodel.dart';
import '../../viewmodels/distribution_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart'; // لجلب اسم المستخدم
import '../../../l10n/app_localizations.dart';
import 'dart:developer' as developer;
import 'package:open_file/open_file.dart'; // لفتح ملف الـ PDF

// --- الاستيرادات الجديدة للطباعة ---
import '../../widgets/print_button.dart';
import '../../../core/utils/thermal_invoice_generator.dart';

class DistributionDetailScreen extends StatefulWidget {
  final Distribution distribution;

  const DistributionDetailScreen({super.key, required this.distribution});

  @override
  State<DistributionDetailScreen> createState() =>
      _DistributionDetailScreenState();
}

class _DistributionDetailScreenState extends State<DistributionDetailScreen> {
  bool _isRecording = false;
  bool _isPrinting = false; // حالة تحميل الطباعة
  Distribution? _currentDistribution;

  Future<void> _showRecordPaymentDialog() async {
    final vm = context.read<CustomerViewModel>();
    final t = AppLocalizations.of(context)!;

    setState(() => _isRecording = true);
    await vm.getCustomerById(widget.distribution.customerId);
    setState(() => _isRecording = false);

    final customer = vm.selectedCustomer;
    if (customer == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.errorOccurred)));
      return;
    }

    final paymentResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerPaymentPage(
          customer: customer,
          distributionId: widget.distribution.id,
        ),
      ),
    );

    if (paymentResult != true) return;

    if (!mounted) return;
    setState(() => _isRecording = true);
    await context.read<DistributionViewModel>().getDistributionById(
      widget.distribution.id,
    );
    final updated = context.read<DistributionViewModel>().selectedDistribution;
    setState(() {
      _currentDistribution = updated ?? widget.distribution;
      _isRecording = false;
    });
  }

  // --- دالة الطباعة الجديدة ---
  Future<void> _printInvoice(PrinterSize printerSize) async {
    final t = AppLocalizations.of(context)!;
    final dist = _currentDistribution ?? widget.distribution;
    final customerVm = context.read<CustomerViewModel>();
    final authVm = context.read<AuthViewModel>();

    setState(() => _isPrinting = true);

    try {
      // 1. جلب بيانات العميل الكاملة (للعنوان والهاتف)
      await customerVm.getCustomerById(dist.customerId);
      final customer = customerVm.selectedCustomer;

      if (customer == null) {
        throw Exception("Customer data not found");
      }

      // 2. اسم المستخدم الحالي
      final createdBy =
          authVm.user?.displayName ?? authVm.user?.email ?? 'User';

      // 3. توليد ملف الـ PDF باستخدام الكلاس الجديد
      final generator = ThermalInvoiceGenerator();
      final filePath = await generator.generateDistributionInvoice(
        customer: customer,
        items: dist.items,
        total: dist.totalAmount,
        paid: dist.paidAmount,
        previousBalance: 0.0, // يمكن تعديل هذا إذا كان لديك رصيد سابق مخزن
        dateTime: dist.distributionDate,
        createdBy: createdBy,
        printerSize: printerSize,
        notes: null, // يمكن تمرير الملاحظات إذا وجدت
      );

      // 4. فتح الملف
      await OpenFile.open(filePath);
    } catch (e) {
      developer.log('Error printing invoice', error: e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${t.errorOccurred}: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dist = _currentDistribution ?? widget.distribution;
    developer.log(
      'DistributionDetailScreen.build - dist runtimeType=${dist.runtimeType} hashCode=${dist.hashCode}',
      name: 'DistributionDetailScreen',
    );
    final t = AppLocalizations.of(context)!;

    var card = Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.itemsLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...dist.items.map(
              (it) => ListTile(
                title: Text(it.productName),
                subtitle: Text(
                  '${it.quantity} x ${it.price.toStringAsFixed(2)}',
                ),
                trailing: Text('ريال${it.subtotal.toStringAsFixed(2)}'),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.dashboardTotalSales,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'ريال${dist.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.outstandingLabel),
                Text('ريال${dist.pendingAmount.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.distributionLabel} ${dist.customerName}'),
        actions: [
          // زر الطباعة في الأعلى
          if (_isPrinting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            PrintButton(
              onPrint: (size, output, isReprint) async {
                await _printInvoice(size);
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            dist.customerName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (ctx) {
              String dateStr;
              try {
                final d = dist.distributionDate;
                dateStr = '${d.day}/${d.month}/${d.year}';
              } catch (e, st) {
                developer.log(
                  'Failed to format distributionDate',
                  name: 'DistributionDetailScreen',
                  error: e,
                  stackTrace: st,
                );
                dateStr = '-';
              }
              return Text(dateStr);
            },
          ),
          const SizedBox(height: 16),
          card,
          const SizedBox(height: 16),
          _isRecording
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _showRecordPaymentDialog,
                  icon: const Icon(Icons.payment),
                  label: Text(t.payLabel),
                ),
        ],
      ),
    );
  }
}
