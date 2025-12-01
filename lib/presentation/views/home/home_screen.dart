import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/customer_viewmodel.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../../viewmodels/distribution_viewmodel.dart';
import '../../../app/routes/app_routes.dart';
import '../../../l10n/app_localizations.dart';

// --- New Imports for Extracted Widgets ---
import 'widgets/home_dashboard_stats.dart';
import 'widgets/home_quick_actions_grid.dart';
import 'widgets/home_recent_distributions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
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

  Future<void> _logout() async {
    final authVm = context.read<AuthViewModel>();
    final loc = AppLocalizations.of(context)!;
    
    // تم الإبقاء على AlertDialog لعدم وجود دورة اعتمادية (Dependency Cycle) مع ConfirmationDialog
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
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
                  title: Text(t.profile),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(t.settingsLabel),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(t.logout),
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
                t.welcomeBack,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                user?.displayName ?? t.userFallback,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              // 1. Dashboard Cards (مكون مُستخرج)
              const HomeDashboardStats(),
              
              const SizedBox(height: 24),

              // 2. Quick Actions (مكون مُستخرج)
              const HomeQuickActionsGrid(),
              
              const SizedBox(height: 24),

              // 3. Recent Activity (مكون مُستخرج)
              const HomeRecentDistributions(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addDistribution);
        },
        icon: const Icon(Icons.add),
        label: Text(t.newDistribution),
      ),
    );
  }
}

