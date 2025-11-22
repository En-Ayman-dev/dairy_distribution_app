// ignore_for_file: unused_element

import 'package:dairy_distribution_app/presentation/views/payments/payments_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/distribution.dart';
import '../../viewmodels/distribution_viewmodel.dart';
import '../../viewmodels/customer_viewmodel.dart';
import '../../../app/routes/app_routes.dart';
import '../../../l10n/app_localizations.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DistributionViewModel>().loadDistributionsByCustomer(
        widget.customer.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.customerDetailsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.editCustomer,
                arguments: widget.customer,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteCustomer,
          ),
        ],
      ),
      body: ListView(
        children: [
          // Customer Info Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        child: Text(
                          widget.customer.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.customer.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            _buildStatusChip(widget.customer.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildInfoRow(
                    Icons.phone,
                    AppLocalizations.of(context)!.phoneLabel,
                    widget.customer.phone,
                  ),
                  if (widget.customer.email != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.email,
                      AppLocalizations.of(context)!.emailLabel,
                      widget.customer.email!,
                    ),
                  ],
                  if (widget.customer.address != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.location_on,
                      AppLocalizations.of(context)!.addressLabel,
                      widget.customer.address!,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Distribution History
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.distributionHistoryLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // View all distributions
                  },
                  child: Text(AppLocalizations.of(context)!.viewAll),
                ),
              ],
            ),
          ),

          Consumer<DistributionViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.state == DistributionViewState.loading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (viewModel.distributions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.noDistributionHistory,
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: viewModel.distributions.length,
                itemBuilder: (context, index) {
                  final distribution = viewModel.distributions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.local_shipping,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        '${distribution.distributionDate.day}/${distribution.distributionDate.month}/${distribution.distributionDate.year}',
                      ),
                      subtitle: Text('${distribution.items.length} items'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'ريال${distribution.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildPaymentStatusChip(distribution.paymentStatus),
                        ],
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.distributionDetail,
                          arguments: distribution,
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(CustomerStatus status) {
    Color color;
    switch (status) {
      case CustomerStatus.active:
        color = Colors.green;
        break;
      case CustomerStatus.inactive:
        color = Colors.orange;
        break;
      case CustomerStatus.blocked:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        // Avoid using withOpacity (deprecated) across the codebase.
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toString().split('.').last.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChip(PaymentStatus status) {
    Color color;
    String text;

    switch (status) {
      case PaymentStatus.paid:
        color = Colors.green;
        text = AppLocalizations.of(context)!.paid;
        break;
      case PaymentStatus.partial:
        color = Colors.orange;
        text = AppLocalizations.of(context)!.partial;
        break;
      case PaymentStatus.pending:
        color = Colors.red;
        text = AppLocalizations.of(context)!.pending;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _deleteCustomer() async {
    // Capture the ViewModel before showing the confirmation dialog so
    // we don't read from the BuildContext after an await.
    final customerVm = context.read<CustomerViewModel>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteCustomerTitle),
        content: Text(AppLocalizations.of(context)!.deleteCustomerConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.deleteCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.deleteLabel),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await customerVm.deleteCustomer(widget.customer.id);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.customerDeletedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showCustomerPaymentDialog(BuildContext context, Customer customer) {
    // Navigate to the reusable payment page so all payment flows use
    // the same UI and logic in `CustomerPaymentPage`.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerPaymentPage(customer: customer),
      ),
    );
  }
}
