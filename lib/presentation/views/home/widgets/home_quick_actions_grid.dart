import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../app/routes/app_routes.dart';
import 'quick_action_card.dart';

class HomeQuickActionsGrid extends StatelessWidget {
  const HomeQuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // تم نقل منطق _buildQuickActions بالكامل إلى هنا
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.quickActions,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            QuickActionCard(
              icon: Icons.local_shipping,
              label: t.quickDistribution,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.distributionList);
              },
            ),
            QuickActionCard(
              icon: Icons.inventory_2_outlined,
              label: t.suppliersTitle, 
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.supplierList);
              },
            ),
            QuickActionCard(
              icon: Icons.people,
              label: t.quickCustomers,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.customerList);
              },
            ),
            QuickActionCard(
              icon: Icons.inventory_2,
              label: t.quickProducts,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.productList);
              },
            ),
            QuickActionCard(
              icon: Icons.receipt_long,
              label: t.purchaseListTitle,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.purchaseList);
              },
            ),
            QuickActionCard(
              icon: Icons.assessment,
              label: t.quickReports,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.reports);
              },
            ),
            QuickActionCard(
              icon: Icons.payment,
              label: t.quickPayments,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.payments);
              },
            ),
            QuickActionCard(
              icon: Icons.history,
              label: t.quickHistory,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.distributionList);
              },
            ),
          ],
        ),
      ],
    );
  }
}