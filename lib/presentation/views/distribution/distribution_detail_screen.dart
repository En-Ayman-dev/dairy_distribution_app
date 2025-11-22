import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dairy_distribution_app/presentation/views/payments/payments_screen.dart';
import '../../../domain/entities/distribution.dart';
import '../../viewmodels/customer_viewmodel.dart';
import '../../viewmodels/distribution_viewmodel.dart';
import '../../../l10n/app_localizations.dart';
import 'dart:developer' as developer;

class DistributionDetailScreen extends StatefulWidget {
  final Distribution distribution;

  const DistributionDetailScreen({super.key, required this.distribution});

  @override
  State<DistributionDetailScreen> createState() => _DistributionDetailScreenState();
}

class _DistributionDetailScreenState extends State<DistributionDetailScreen> {
  bool _isRecording = false;
  Distribution? _currentDistribution;

  Future<void> _showRecordPaymentDialog() async {
    // Instead of showing an inline dialog, navigate to the centralized
    // CustomerPaymentPage so all payment UI/logic is consistent.
    final vm = context.read<CustomerViewModel>();
    final t = AppLocalizations.of(context)!;

    setState(() => _isRecording = true);
    await vm.getCustomerById(widget.distribution.customerId);
    setState(() => _isRecording = false);

    final customer = vm.selectedCustomer;
    if (customer == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorOccurred)),
      );
      return;
    }

    // Push the shared payment page. When it returns, refresh data to reflect
    // any payments that may have been recorded there.
    final paymentResult = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomerPaymentPage(customer: customer, distributionId: widget.distribution.id)),
    );

    // If the payment page returned true, a payment was recorded and we
    // should refresh the distribution. Otherwise skip the reload.
    if (paymentResult != true) return;

    if (!mounted) return;
    setState(() => _isRecording = true);
    await context.read<DistributionViewModel>().getDistributionById(widget.distribution.id);
    final updated = context.read<DistributionViewModel>().selectedDistribution;
    setState(() {
      _currentDistribution = updated ?? widget.distribution;
      _isRecording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dist = _currentDistribution ?? widget.distribution;
    // Log the runtime type and hashCode to help diagnose unexpected values
    developer.log('DistributionDetailScreen.build - dist runtimeType=${dist.runtimeType} hashCode=${dist.hashCode}',
        name: 'DistributionDetailScreen');
    final t = AppLocalizations.of(context)!;

    // Log only — accept subtypes like DistributionModel (common for local/remote models).
    // We don't block rendering for subclasses.

    var card = Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Items', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...dist.items.map((it) => ListTile(
                        title: Text(it.productName),
                        subtitle: Text('${it.quantity} x ${it.price.toStringAsFixed(2)}'),
                        trailing: Text('ريال${it.subtotal.toStringAsFixed(2)}'),
                      )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.dashboardTotalSales, style: Theme.of(context).textTheme.titleMedium),
                      Text('ريال${dist.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(dist.customerName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          // Safely format distribution date to avoid crashes if the
          // underlying value is unexpected. Log errors for diagnosis.
          Builder(builder: (ctx) {
            String dateStr;
            try {
              final d = dist.distributionDate;
              dateStr = '${d.day}/${d.month}/${d.year}';
            } catch (e, st) {
              developer.log('Failed to format distributionDate', name: 'DistributionDetailScreen', error: e, stackTrace: st);
              dateStr = '-';
            }
            return Text(dateStr);
          }),
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
