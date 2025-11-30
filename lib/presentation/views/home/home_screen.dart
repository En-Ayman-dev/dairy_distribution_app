import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/customer_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/distribution_viewmodel.dart';
import '../../../domain/entities/distribution.dart';
// تأكد من استيراد ملف الـ Enum إذا كان منفصلاً، أو الاعتماد على distribution.dart إذا كان داخله
import '../../../app/routes/app_routes.dart';
import 'widgets/dashboard_card.dart';
import 'widgets/quick_action_card.dart';
import '../../../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Delay loading until after the first frame to avoid
    // calling notifyListeners() (via providers) during the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // جلب البيانات من السحابة (عبر الـ ViewModels التي تم تحديثها)
    await Future.wait([
      context.read<CustomerViewModel>().loadCustomers(),
      context.read<ProductViewModel>().loadProducts(),
      context.read<DistributionViewModel>().loadDistributions(),
    ]);
  }

  // --- تم حذف _syncData لأن المزامنة الآن تلقائية عبر Firebase SDK ---

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          // --- تم حذف زر المزامنة اليدوي ---
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Show notifications
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(AppLocalizations.of(context)!.profile),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(AppLocalizations.of(context)!.settingsLabel),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(AppLocalizations.of(context)!.logout),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              } else if (value == 'settings') {
                Navigator.pushNamed(context, AppRoutes.settings);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text(
                AppLocalizations.of(context)!.welcomeBack,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                user?.displayName ?? AppLocalizations.of(context)!.userFallback,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              // Dashboard Cards
              _buildDashboardCards(),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                AppLocalizations.of(context)!.quickActions,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 24),

              // Recent Activity
              Text(
                AppLocalizations.of(context)!.recentActivity,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addDistribution);
        },
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.newDistribution),
      ),
    );
  }

  Widget _buildDashboardCards() {
    return Consumer3<CustomerViewModel, ProductViewModel, DistributionViewModel>(
      builder: (context, customerVM, productVM, distributionVM, child) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: AppLocalizations.of(context)!.dashboardTotalSales,
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
                    title: AppLocalizations.of(context)!.dashboardOutstanding,
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
                    title: AppLocalizations.of(context)!.dashboardCustomers,
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
                    title: AppLocalizations.of(context)!.dashboardLowStock,
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

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        QuickActionCard(
          icon: Icons.local_shipping,
          label: AppLocalizations.of(context)!.quickDistribution,
          onTap: () {
            // Open the distributions list instead of the add-distribution screen
            Navigator.pushNamed(context, AppRoutes.distributionList);
          },
        ),
        QuickActionCard(
          icon: Icons.inventory_2_outlined,
          label: AppLocalizations.of(context)!.suppliersTitle, // تم تصحيح النص الثابت لاستخدام الترجمة إذا كانت متاحة
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.supplierList);
          },
        ),
        QuickActionCard(
          icon: Icons.people,
          label: AppLocalizations.of(context)!.quickCustomers,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.customerList);
          },
        ),
        QuickActionCard(
          icon: Icons.inventory_2,
          label: AppLocalizations.of(context)!.quickProducts,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.productList);
          },
        ),
        // --- الزر الجديد: سجل المشتريات ---
        QuickActionCard(
          icon: Icons.receipt_long,
          label: AppLocalizations.of(context)!.purchaseListTitle,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.purchaseList);
          },
        ),
        QuickActionCard(
          icon: Icons.assessment,
          label: AppLocalizations.of(context)!.quickReports,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.reports);
          },
        ),
        QuickActionCard(
          icon: Icons.payment,
          label: AppLocalizations.of(context)!.quickPayments,
          onTap: () {
            developer.log('Home: quickPayments tapped', name: 'HomeScreen');
            Navigator.pushNamed(context, AppRoutes.payments);
          },
        ),
        QuickActionCard(
          icon: Icons.history,
          label: AppLocalizations.of(context)!.quickHistory,
          onTap: () {
            developer.log('Home: navigating to distributionList', name: 'HomeScreen');
            Navigator.pushNamed(context, AppRoutes.distributionList);
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Consumer<DistributionViewModel>(
      builder: (context, distributionVM, child) {
        if (distributionVM.state == DistributionViewState.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final recentDistributions = distributionVM.distributions.take(5).toList();

        if (recentDistributions.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(AppLocalizations.of(context)!.noRecentActivity),
              ),
            ),
          );
        }

        return Card(
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
                      .withAlpha((0.1 * 255).round()),
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
                      'ريال${distribution.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
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
              );
            },
          ),
        );
      },
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    // Capture the AuthViewModel before awaiting any dialogs to avoid using
    // BuildContext across async gaps.
    final authVm = context.read<AuthViewModel>();

    final loc = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.logout),
        content: Text(loc.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(loc.logout),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authVm.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }
}