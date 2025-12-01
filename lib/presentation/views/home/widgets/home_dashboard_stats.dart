import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/customer_viewmodel.dart';
import '../../../viewmodels/product_viewmodel.dart';
import '../../../viewmodels/distribution_viewmodel.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import 'dashboard_card.dart';

class HomeDashboardStats extends StatelessWidget {
  const HomeDashboardStats({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدام Consumer3 لربط جميع الـ ViewModels التي نحتاجها
    return Consumer3<CustomerViewModel, ProductViewModel, DistributionViewModel>(
      builder: (context, customerVM, productVM, distributionVM, child) {
        final t = AppLocalizations.of(context)!;
        
        // تم نقل منطق _buildDashboardCards بالكامل إلى هنا
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: t.dashboardTotalSales,
                    value: distributionVM.totalSales.toStringAsFixed(2),
                    icon: Icons.trending_up,
                    color: Colors.green,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.reports);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DashboardCard(
                    title: t.dashboardOutstanding,
                    value: customerVM.totalOutstanding.toStringAsFixed(2),
                    icon: Icons.account_balance_wallet,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.customerList);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: t.dashboardCustomers,
                    value: '${customerVM.activeCustomerCount}',
                    icon: Icons.people,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.customerList);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DashboardCard(
                    title: t.dashboardLowStock,
                    value: '${productVM.lowStockCount}',
                    icon: Icons.inventory,
                    color: Colors.red,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.productList);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}