import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/distribution.dart';
import '../../viewmodels/distribution_viewmodel.dart';
import '../../../l10n/app_localizations.dart';

class DistributionDetailScreen extends StatefulWidget {
  final Distribution distribution;

  const DistributionDetailScreen({super.key, required this.distribution});

  @override
  State<DistributionDetailScreen> createState() => _DistributionDetailScreenState();
}

class _DistributionDetailScreenState extends State<DistributionDetailScreen> {
  bool _isRecording = false;

  Future<void> _showRecordPaymentDialog() async {
    final vm = context.read<DistributionViewModel>();
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.payLabel),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: '0.00'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(t.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(t.payLabel)),
        ],
      ),
    );

    if (confirm != true) return;

    final amount = double.tryParse(controller.text) ?? 0.0;
    if (amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    setState(() => _isRecording = true);
    final ok = await vm.recordPayment(widget.distribution.id, amount);
    setState(() => _isRecording = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Payment recorded' : vm.errorMessage ?? 'Failed to record payment'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dist = widget.distribution;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.distributionLabel} ${dist.id}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(dist.customerName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('${dist.distributionDate.day}/${dist.distributionDate.month}/${dist.distributionDate.year}'),
          const SizedBox(height: 16),
          Card(
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
                        trailing: Text('₹${it.subtotal.toStringAsFixed(2)}'),
                      )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.dashboardTotalSales, style: Theme.of(context).textTheme.titleMedium),
                      Text('₹${dist.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.outstandingLabel),
                      Text('₹${dist.pendingAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
