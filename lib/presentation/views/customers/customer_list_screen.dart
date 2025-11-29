// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/customer_viewmodel.dart';
import '../../../domain/entities/customer.dart';
import '../../../app/routes/app_routes.dart';
import '../../../l10n/app_localizations.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  CustomerStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerViewModel>().loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.customersTitle),
        actions: [
          PopupMenuButton<CustomerStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: AppLocalizations.of(context)!.filterByStatusTooltip,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Text(AppLocalizations.of(context)!.allLabel),
              ),
              PopupMenuItem(
                value: CustomerStatus.active,
                child: Text(AppLocalizations.of(context)!.activeLabel),
              ),
              PopupMenuItem(
                value: CustomerStatus.inactive,
                child: Text(AppLocalizations.of(context)!.inactiveLabel),
              ),
              PopupMenuItem(
                value: CustomerStatus.blocked,
                child: Text(AppLocalizations.of(context)!.blockedLabel),
              ),
            ],
            onSelected: (status) {
              setState(() {
                _selectedStatus = status;
              });
              context.read<CustomerViewModel>().filterByStatus(status);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchCustomersHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                context.read<CustomerViewModel>().searchCustomers(value);
              },
            ),
          ),

          // Customer List
          Expanded(
            child: Consumer<CustomerViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.state == CustomerViewState.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (viewModel.state == CustomerViewState.error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(viewModel.errorMessage ?? AppLocalizations.of(context)!.errorOccurred),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => viewModel.loadCustomers(),
                          child: Text(AppLocalizations.of(context)!.retry),
                        ),
                      ],
                    ),
                  );
                }

                if (viewModel.customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noCustomersFound,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.addFirstCustomerPrompt,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => viewModel.loadCustomers(),
                  child: ListView.builder(
                    itemCount: viewModel.customers.length,
                    itemBuilder: (context, index) {
                      final customer = viewModel.customers[index];
                      return _buildCustomerCard(context, customer);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addCustomer);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(customer.status).withAlpha((0.2 * 255).round()),
          child: Text(
            customer.name[0].toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(customer.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.phone),
            if (customer.balance > 0)
              Text(
                '${AppLocalizations.of(context)!.outstandingLabel}: ريال${customer.balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        trailing: _buildStatusChip(customer.status),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.customerDetail,
            arguments: customer,
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(CustomerStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toString().split('.').last.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return Colors.green;
      case CustomerStatus.inactive:
        return Colors.orange;
      case CustomerStatus.blocked:
        return Colors.red;
    }
  }
}