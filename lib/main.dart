import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider;
import 'firebase_options.dart';
import 'core/utils/service_locator.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/customer_viewmodel.dart';
import 'presentation/viewmodels/product_viewmodel.dart';
import 'presentation/viewmodels/distribution_viewmodel.dart';
import 'presentation/viewmodels/report_viewmodel.dart';
import 'presentation/views/auth/login_screen.dart';
import 'presentation/views/auth/register_screen.dart';
import 'presentation/views/home/home_screen.dart';
import 'presentation/views/customers/customer_list_screen.dart';
import 'presentation/views/customers/customer_detail_screen.dart';
import 'presentation/views/customers/add_customer_screen.dart';
import 'presentation/views/products/product_list_screen.dart';
import 'presentation/views/reports/reports_screen.dart';
import 'presentation/views/distribution/distribution_list_screen.dart';
import 'presentation/views/distribution/add_distribution_screen.dart';
import 'presentation/views/distribution/distribution_detail_screen.dart';
import 'presentation/views/payments/payments_screen.dart';
import 'features/settings/settings_page.dart';
import 'presentation/views/splash/splash_screen.dart';
import 'app/routes/app_routes.dart';
import 'app/themes/app_theme.dart';
import 'features/settings/settings_notifier.dart';
import 'domain/entities/customer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // تهيئة Service Locator
  await setupServiceLocator();

  // Log the current Firebase Auth user id (useful to verify client-side auth)
  developer.log('Firebase currentUser uid', name: 'main', error: FirebaseAuth.instance.currentUser?.uid);

  // Listen to auth state changes for debugging intermittent navigation to login
  FirebaseAuth.instance.authStateChanges().listen((user) {
    developer.log('authStateChanges -> user: ${user?.uid}', name: 'main.auth');
  });

  // Prevent google_fonts package from trying to fetch fonts from the network
  // (useful for offline devices or restricted networks). When false, the
  // package will not attempt runtime fetching from fonts.gstatic.com.
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const riverpod.ProviderScope(child: MyApp()));
}
class MyApp extends riverpod.ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);

    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (_) => getIt<AuthViewModel>()),
        provider.ChangeNotifierProvider(create: (_) => getIt<CustomerViewModel>()),
        provider.ChangeNotifierProvider(create: (_) => getIt<ProductViewModel>()),
        provider.ChangeNotifierProvider(create: (_) => getIt<DistributionViewModel>()),
        provider.ChangeNotifierProvider(create: (_) => getIt<ReportViewModel>()),
      ],
      child: MaterialApp(
        title: 'Dairy Distribution',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settings.themeMode,
        locale: settings.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
  initialRoute: AppRoutes.splash,
  navigatorObservers: [LoggingNavigatorObserver()],
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case AppRoutes.splash:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
            case AppRoutes.login:
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case AppRoutes.register:
              return MaterialPageRoute(builder: (_) => const RegisterScreen());
            case AppRoutes.home:
              return MaterialPageRoute(builder: (_) => const HomeScreen());
            case AppRoutes.customerList:
              return MaterialPageRoute(builder: (_) => const CustomerListScreen());
            case AppRoutes.customerDetail:
              final customer = settings.arguments as Customer;
              return MaterialPageRoute(
                builder: (_) => CustomerDetailScreen(customer: customer),
              );
            case AppRoutes.addCustomer:
              return MaterialPageRoute(builder: (_) => const AddCustomerScreen());
            case AppRoutes.editCustomer:
              final customer = settings.arguments as Customer;
              return MaterialPageRoute(
                builder: (_) => AddCustomerScreen(customer: customer),
              );
            case AppRoutes.productList:
              return MaterialPageRoute(builder: (_) => const ProductListScreen());
            case AppRoutes.distributionList:
              return MaterialPageRoute(
                builder: (_) => const DistributionListScreen(),
              );
            case AppRoutes.payments:
              return MaterialPageRoute(builder: (_) => const PaymentsScreen());
            case AppRoutes.distributionDetail:
              final distribution = settings.arguments as dynamic;
              // callers should pass a Distribution instance as the arguments
              return MaterialPageRoute(
                builder: (_) => DistributionDetailScreen(distribution: distribution),
              );
            case AppRoutes.addDistribution:
              return MaterialPageRoute(
                builder: (_) => const AddDistributionScreen(),
              );
            case AppRoutes.settings:
              return MaterialPageRoute(builder: (_) => const SettingsPage());
            case AppRoutes.reports:
              return MaterialPageRoute(builder: (_) => const ReportsScreen());
            default:
              return MaterialPageRoute(builder: (_) => const LoginScreen());
          }
        },
      ),
    );
  }
}

class LoggingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    developer.log('Navigator push: ${route.settings.name}', name: 'Navigator');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    developer.log('Navigator pop: ${route.settings.name}', name: 'Navigator');
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    developer.log('Navigator replace: from ${oldRoute?.settings.name} to ${newRoute?.settings.name}', name: 'Navigator');
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}