import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/distribution_viewmodel.dart';
import '../../viewmodels/customer_viewmodel.dart';
import '../../../l10n/app_localizations.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DistributionViewModel>().loadDistributions();
      context.read<CustomerViewModel>().loadCustomers();
    });
  }

  Future<void> _showRecordPaymentDialog(String distributionId, double pending) async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: pending.toStringAsFixed(2));
    final vm = context.read<DistributionViewModel>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.quickPayments),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: t.paid),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.payLabel),
          ),
        ],
      ),
    );

    if (ok == true) {
      final amount = double.tryParse(controller.text) ?? 0.0;
      if (amount <= 0) return;
      // Capture messenger and avoid using BuildContext across async gaps.
      final messenger = ScaffoldMessenger.of(context);
      final success = await vm.recordPayment(distributionId, amount);
      if (!mounted) return;
      if (success) {
        messenger.showSnackBar(SnackBar(content: Text(t.paymentRecorded)));
      } else {
        messenger.showSnackBar(SnackBar(content: Text(vm.errorMessage ?? t.errorOccurred)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.quickPayments)),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<DistributionViewModel>().loadDistributions();
          await context.read<CustomerViewModel>().loadCustomers();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.pendingDistributionsTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Consumer<DistributionViewModel>(
                builder: (context, vm, _) {
                  final pending = vm.distributions.where((d) => d.pendingAmount > 0).toList();
                  if (vm.state == DistributionViewState.loading) return const Center(child: CircularProgressIndicator());
                  if (pending.isEmpty) return Padding(padding: const EdgeInsets.all(8.0), child: Text(t.noPendingDistributions));

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pending.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final d = pending[index];
                      return ListTile(
                        title: Text(d.customerName),
                        subtitle: Text('${d.items.length} items • Pending: ₹${d.pendingAmount.toStringAsFixed(2)}'),
                        trailing: ElevatedButton(
                          onPressed: () => _showRecordPaymentDialog(d.id, d.pendingAmount),
                          child: Text(t.payLabel),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),
              Text(t.outstandingReportSubtitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Consumer2<CustomerViewModel, DistributionViewModel>(
                builder: (context, custVm, distVm, _) {
                  final customers = custVm.customers.where((c) => c.balance > 0).toList();
                  if (customers.isEmpty) return Padding(padding: const EdgeInsets.all(8.0), child: Text(t.noCustomersWithOutstanding));

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: customers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final c = customers[idx];
                      // Find pending distributions for this customer
                      final pendingDists = distVm.distributions.where((d) => d.customerId == c.id && d.pendingAmount > 0).toList();
                      return ExpansionTile(
                        title: Text(c.name),
                        subtitle: Text('Balance: ₹${c.balance.toStringAsFixed(2)}'),
            children: pendingDists.isEmpty
              ? [Padding(padding: const EdgeInsets.all(12), child: Text(t.noPendingDistributionsForCustomer))]
                            : pendingDists.map((d) {
                                return ListTile(
                                  title: Text('${d.distributionDate.day}/${d.distributionDate.month}/${d.distributionDate.year}'),
                                  subtitle: Text('Pending: ₹${d.pendingAmount.toStringAsFixed(2)}'),
                                  trailing: ElevatedButton(onPressed: () => _showRecordPaymentDialog(d.id, d.pendingAmount), child: Text(t.payLabel)),
                                );
                              }).toList(),
                      );
                    },
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
