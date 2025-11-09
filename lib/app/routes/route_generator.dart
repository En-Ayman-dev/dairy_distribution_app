import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../../presentation/views/auth/login_screen.dart';
import '../../presentation/views/auth/register_screen.dart';
import '../../presentation/views/home/home_screen.dart';
import '../../presentation/views/customers/customer_list_screen.dart';
import '../../presentation/views/customers/customer_detail_screen.dart';
import '../../presentation/views/customers/add_customer_screen.dart';
import '../../presentation/views/products/product_list_screen.dart';
import '../../presentation/views/distribution/distribution_list_screen.dart';
import '../../presentation/views/distribution/add_distribution_screen.dart';
import '../../presentation/views/reports/reports_screen.dart';
import '../../domain/entities/customer.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.splash:
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
        
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
        
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
        
      // Customer Routes
      case AppRoutes.customerList:
        return MaterialPageRoute(builder: (_) => const CustomerListScreen());
        
      case AppRoutes.customerDetail:
        if (args is Customer) {
          return MaterialPageRoute(
            builder: (_) => CustomerDetailScreen(customer: args),
          );
        }
        return _errorRoute();
        
      case AppRoutes.addCustomer:
        return MaterialPageRoute(builder: (_) => const AddCustomerScreen());
        
      case AppRoutes.editCustomer:
        if (args is Customer) {
          return MaterialPageRoute(
            builder: (_) => AddCustomerScreen(customer: args),
          );
        }
        return _errorRoute();
        
      // Product Routes
      case AppRoutes.productList:
        return MaterialPageRoute(builder: (_) => const ProductListScreen());
        
      // Distribution Routes
      case AppRoutes.distributionList:
        return MaterialPageRoute(
          builder: (_) => const DistributionListScreen(),
        );
        
      case AppRoutes.addDistribution:
        return MaterialPageRoute(
          builder: (_) => const AddDistributionScreen(),
        );
        
      // Report Routes
      case AppRoutes.reports:
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
        
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Page not found')),
      ),
    );
  }
}