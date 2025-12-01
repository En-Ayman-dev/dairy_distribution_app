import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../domain/entities/distribution.dart';
import '../../../viewmodels/distribution_viewmodel.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../widgets/common/status_badge.dart'; // استخدام StatusBadge المُعاد هيكلته

class HomeRecentDistributions extends StatelessWidget {
  const HomeRecentDistributions({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    return Consumer<DistributionViewModel>(
      builder: (context, distributionVM, child) {
        if (distributionVM.state == DistributionViewState.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final recentDistributions = distributionVM.distributions.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.recentActivity,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (recentDistributions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(t.noRecentActivity),
                  ),
                ),
              )
            else
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentDistributions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final distribution = recentDistributions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1), 
                        child: Icon(
                          Icons.local_shipping,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(distribution.customerName),
                      subtitle: Text(
                        '${distribution.distributionDate.day}/${distribution.distributionDate.month}/${distribution.distributionDate.year}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            // تم استخدام مفتاح العملة لضمان التوافق
                            '${distribution.totalAmount.toStringAsFixed(2)} ${t.currencySymbol}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // استخدام StatusBadge بدلاً من _buildPaymentStatusChip
                          StatusBadge(
                            status: _mapPaymentStatusToString(distribution.paymentStatus, t),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.distributionDetail,
                          arguments: distribution,
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
  
  String _mapPaymentStatusToString(PaymentStatus status, AppLocalizations t) {
    // تم نقل منطق الترجمة من الدالة المساعدة القديمة إلى هنا
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