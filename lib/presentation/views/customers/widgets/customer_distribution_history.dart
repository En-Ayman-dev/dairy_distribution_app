import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../domain/entities/distribution.dart';
import '../../../viewmodels/distribution_viewmodel.dart';
import '../../../widgets/common/status_badge.dart'; // استخدام StatusBadge مرة أخرى
import '../../../widgets/common/empty_list_state.dart'; // استخدام EmptyListState

class CustomerDistributionHistory extends StatelessWidget {
  final String customerId;

  const CustomerDistributionHistory({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final viewModel = context.watch<DistributionViewModel>();
    
    // Header
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.distributionHistoryLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement navigation to View All Distributions Screen
                },
                child: Text(t.viewAll),
              ),
            ],
          ),
        ),
        
        // Body (List/State)
        if (viewModel.state == DistributionViewState.loading)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (viewModel.distributions.isEmpty)
          EmptyListState(
            message: t.noDistributionHistory,
            icon: Icons.local_shipping_outlined,
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: viewModel.distributions.length,
            itemBuilder: (context, index) {
              final distribution = viewModel.distributions[index];
              return _buildDistributionListItem(context, distribution, t);
            },
          ),
      ],
    );
  }

  Widget _buildDistributionListItem(BuildContext context, Distribution distribution, AppLocalizations t) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          Icons.local_shipping,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          '${distribution.distributionDate.day}/${distribution.distributionDate.month}/${distribution.distributionDate.year}',
        ),
        subtitle: Text('${distribution.items.length} ${t.itemsLabel.toLowerCase()}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${distribution.totalAmount.toStringAsFixed(2)} ${t.currencySymbol}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            StatusBadge(
              status: _mapPaymentStatusToString(distribution.paymentStatus, t),
            ),
          ],
        ),
        onTap: () {
          // TODO: Implement navigation to Distribution Detail Screen
          // Navigator.pushNamed(context, AppRoutes.distributionDetail, arguments: distribution);
        },
      ),
    );
  }

  String _mapPaymentStatusToString(PaymentStatus status, AppLocalizations t) {
    switch (status) {
      case PaymentStatus.paid:
        return t.paid;
      case PaymentStatus.partial:
        return t.partial;
      case PaymentStatus.pending:
        return t.pending;
    }
  }
}