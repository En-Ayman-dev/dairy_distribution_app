// class AppRoutes {
//   static const String splash = '/';
//   static const String login = '/login';
//   static const String register = '/register';
//   static const String home = '/home';
//   static const String customerList = '/customers';
//   static const String customerDetail = '/customer-detail';
//   static const String addCustomer = '/add-customer';
//   static const String editCustomer = '/edit-customer';
//   static const String productList = '/products';
//   static const String addProduct = '/add-product';
//   static const String distributionList = '/distributions';
//   static const String distributionDetail = '/distribution-detail';
//   static const String addDistribution = '/add-distribution';
//   static const String reports = '/reports';
// }

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  
  // Customer Routes
  static const String customerList = '/customers';
  static const String customerDetail = '/customers/detail';
  static const String addCustomer = '/customers/add';
  static const String editCustomer = '/customers/edit';
  
  // Product Routes
  static const String productList = '/products';
  static const String productDetail = '/products/detail';
  static const String addProduct = '/products/add';
  
  // Distribution Routes
  static const String distributionList = '/distributions';
  static const String addDistribution = '/distributions/add';
  static const String distributionDetail = '/distributions/detail';
  
  // Report Routes
  static const String reports = '/reports';
  static const String customerStatement = '/reports/customer-statement';
  static const String salesReport = '/reports/sales';
  static const String inventoryReport = '/reports/inventory';

  // Payments
  static const String payments = '/payments';
  
  // Settings
  static const String settings = '/settings';
  static const String profile = '/profile';
}