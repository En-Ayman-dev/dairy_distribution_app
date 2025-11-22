

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/customer.dart';
import '../../viewmodels/customer_viewmodel.dart';
import '../../viewmodels/distribution_viewmodel.dart';
import '../../../l10n/app_localizations.dart';

/// A standalone page for handling customer payments.
///
/// This page displays the customer's outstanding balance, allows the user
/// to enter a paid amount, and records the payment via the CustomerViewModel.
/// It can be reused throughout the project wherever customer payments are needed.
class CustomerPaymentPage extends StatefulWidget {
  final Customer customer;
  final String? distributionId; // optional: when paying a specific distribution

  const CustomerPaymentPage({super.key, required this.customer, this.distributionId});

  @override
  State<CustomerPaymentPage> createState() => _CustomerPaymentPageState();
}

class _CustomerPaymentPageState extends State<CustomerPaymentPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Pre-fill the controller with the customer's outstanding balance.
    _controller = TextEditingController(
      text: widget.customer.balance.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Records the payment using the injected CustomerViewModel and refreshes
  /// related data on success.
  Future<void> _recordPayment() async {
    final amount = double.tryParse(_controller.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    final customerVm = context.read<CustomerViewModel>();
    final success = await customerVm.recordPayment(widget.customer.id, amount, distributionId: widget.distributionId);

    if (!mounted) return;

    if (success) {
      // Refresh the distributions and customers to reflect the new balance.
      final distVm = context.read<DistributionViewModel>();
      await distVm.loadDistributionsByCustomer(widget.customer.id);
      await context.read<CustomerViewModel>().loadCustomers();

      // If this payment was for a specific distribution, fetch it so
      // callers (like DistributionDetailScreen) can read updated data.
      if (widget.distributionId != null) {
        await distVm.getDistributionById(widget.distributionId!);
      }

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.paymentRecorded,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            customerVm.errorMessage ??
                AppLocalizations.of(context)!.errorOccurred,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.payLabel),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display outstanding balance.
            Text(
              '${l10n.outstandingBalanceLabel}: ريال${widget.customer.balance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            // Input field for the amount paid.
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Amount',
                helperText: 'Enter paid amount',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            // Button to submit the payment.
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _recordPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: Text(l10n.payLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
