import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Minimal localizations shim used during development.
/// When you run Flutter gen-l10n this will be replaced by the generated
/// `AppLocalizations` class (from `package:flutter_gen/gen_l10n/...`).
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // Keys used in the settings page
  String get settingsTitle => locale.languageCode == 'ar' ? 'الإعدادات' : 'Settings';
    /// Label for quantity fields in forms
    String get quantityLabel => 'Quantity';

    /// Label for the items section in distribution/add forms
    String get itemsLabel => 'Items';

    /// Label for the create/submit distribution button
    String get createDistributionLabel => 'Create distribution';
  String get languageLabel => locale.languageCode == 'ar' ? 'اللغة' : 'Language';
  String get themeLabel => locale.languageCode == 'ar' ? 'المظهر' : 'Theme';
  String get appTitle => locale.languageCode == 'ar' ? 'توزيع الألبان' : 'Dairy Distribution';

  // Login screen and common strings
  String get loginTitle => locale.languageCode == 'ar' ? 'توزيع الألبان' : 'Dairy Distribution';
  String get loginSubtitle => locale.languageCode == 'ar' ? 'تسجيل الدخول إلى حسابك' : 'Login to your account';
  String get emailLabel => locale.languageCode == 'ar' ? 'البريد الإلكتروني' : 'Email';
  String get enterEmailHint => locale.languageCode == 'ar' ? 'أدخل بريدك الإلكتروني' : 'Enter your email';
  String get passwordLabel => locale.languageCode == 'ar' ? 'كلمة المرور' : 'Password';
  String get enterPasswordHint => locale.languageCode == 'ar' ? 'أدخل كلمة المرور' : 'Enter your password';
  String get forgotPassword => locale.languageCode == 'ar' ? 'نسيت كلمة المرور؟' : 'Forgot Password?';
  String get loginButton => locale.languageCode == 'ar' ? 'تسجيل الدخول' : 'Login';
  String get dontHaveAccount => locale.languageCode == 'ar' ? 'ليس لديك حساب؟' : "Don't have an account?";
  String get register => locale.languageCode == 'ar' ? 'إنشاء حساب' : 'Register';
  String get resetPasswordTitle => locale.languageCode == 'ar' ? 'إعادة تعيين كلمة المرور' : 'Reset Password';
  String get resetPasswordInstruction => locale.languageCode == 'ar' ? 'أدخل بريدك الإلكتروني لاستلام رابط إعادة التعيين' : 'Enter your email to receive password reset link';
  String get cancel => locale.languageCode == 'ar' ? 'إلغاء' : 'Cancel';
  String get send => locale.languageCode == 'ar' ? 'إرسال' : 'Send';
  String get passwordResetSent => locale.languageCode == 'ar' ? 'تم إرسال رابط إعادة تعيين كلمة المرور' : 'Password reset email sent';
  
  // Home & dashboard
  String get syncTooltip => locale.languageCode == 'ar' ? 'مزامنة البيانات' : 'Sync Data';
  String get profile => locale.languageCode == 'ar' ? 'الملف الشخصي' : 'Profile';
  String get settingsLabel => locale.languageCode == 'ar' ? 'الإعدادات' : 'Settings';
  String get logout => locale.languageCode == 'ar' ? 'تسجيل الخروج' : 'Logout';
  String get welcomeBack => locale.languageCode == 'ar' ? 'مرحباً بعودتك،' : 'Welcome back,';
  String get userFallback => locale.languageCode == 'ar' ? 'المستخدم' : 'User';
  String get quickActions => locale.languageCode == 'ar' ? 'إجراءات سريعة' : 'Quick Actions';
  String get recentActivity => locale.languageCode == 'ar' ? 'النشاط الأخير' : 'Recent Activity';
  String get newDistribution => locale.languageCode == 'ar' ? 'توزيع جديد' : 'New Distribution';
  String get dashboardTotalSales => locale.languageCode == 'ar' ? 'إجمالي المبيعات' : 'Total Sales';
  String get dashboardOutstanding => locale.languageCode == 'ar' ? 'المبالغ المستحقة' : 'Outstanding';
  String get dashboardCustomers => locale.languageCode == 'ar' ? 'العملاء' : 'Customers';
  String get dashboardLowStock => locale.languageCode == 'ar' ? 'المخزون المنخفض' : 'Low Stock';
  String get quickDistribution => locale.languageCode == 'ar' ? 'توزيع' : 'Distribution';
  String get quickCustomers => locale.languageCode == 'ar' ? 'العملاء' : 'Customers';
  String get quickProducts => locale.languageCode == 'ar' ? 'المنتجات' : 'Products';
  String get quickReports => locale.languageCode == 'ar' ? 'التقارير' : 'Reports';
  String get quickPayments => locale.languageCode == 'ar' ? 'الدفعات' : 'Payments';
  String get quickHistory => locale.languageCode == 'ar' ? 'السجل' : 'History';
  String get noRecentActivity => locale.languageCode == 'ar' ? 'لا توجد نشاطات حديثة' : 'No recent activity';
  String get paid => locale.languageCode == 'ar' ? 'مدفوع' : 'Paid';
  String get partial => locale.languageCode == 'ar' ? 'جزئي' : 'Partial';
  String get pending => locale.languageCode == 'ar' ? 'قيد الانتظار' : 'Pending';
  String get logoutConfirm => locale.languageCode == 'ar' ? 'هل تريد بالتأكيد تسجيل الخروج؟' : 'Are you sure you want to logout?';
  // Distribution / diagnostics
  String get distributionListTitle => locale.languageCode == 'ar' ? 'قائمة التوزيع' : 'Distribution List';
  String get firestoreReadResult => locale.languageCode == 'ar' ? 'نتيجة قراءة Firestore' : 'Firestore read result';
  String get firestoreError => locale.languageCode == 'ar' ? 'خطأ في Firestore' : 'Firestore error';
  String get unexpectedError => locale.languageCode == 'ar' ? 'خطأ غير متوقع' : 'Unexpected error';
  String get localDbDistributions => locale.languageCode == 'ar' ? 'سجلات قاعدة البيانات المحلية' : 'Local DB distributions';
  String get localDbError => locale.languageCode == 'ar' ? 'خطأ قاعدة البيانات المحلية' : 'Local DB error';
  String get createTestDistribution => locale.languageCode == 'ar' ? 'إنشاء توزيع تجريبي' : 'Create test distribution';
  String get createTestDistributionSuccess => locale.languageCode == 'ar' ? 'تم إنشاء توزيع تجريبي بنجاح' : 'Created test distribution successfully';
  String get createTestDistributionFailedPrefix => locale.languageCode == 'ar' ? 'فشل في إنشاء التوزيع:' : 'Failed to create distribution:';
  String get noDistributionsToShow => locale.languageCode == 'ar' ? 'لا توجد توزيعات للعرض' : 'No distributions to show';
  String get showLocalDbDistributions => locale.languageCode == 'ar' ? 'عرض توزيعات قاعدة البيانات المحلية' : 'Show local DB distributions';
  String get ok => locale.languageCode == 'ar' ? 'حسنًا' : 'OK';
  String get notAuthenticated => locale.languageCode == 'ar' ? 'غير مصدق' : 'Not authenticated';
  String get distributionLabel => locale.languageCode == 'ar' ? 'توزيع' : 'Distribution';
  String get failedToLoadDistributions => locale.languageCode == 'ar' ? 'فشل في تحميل التوزيعات' : 'Failed to load distributions';
  // Products
  String get productsTitle => locale.languageCode == 'ar' ? 'المنتجات' : 'Products';
  String get filterByCategoryTooltip => locale.languageCode == 'ar' ? 'تصفية حسب الفئة' : 'Filter by category';
  String get allCategories => locale.languageCode == 'ar' ? 'كل الفئات' : 'All Categories';
  String get searchProductsHint => locale.languageCode == 'ar' ? 'ابحث عن المنتجات...' : 'Search products...';
  String get errorOccurred => locale.languageCode == 'ar' ? 'حدث خطأ' : 'An error occurred';
  String get retry => locale.languageCode == 'ar' ? 'إعادة المحاولة' : 'Retry';
  String get noProductsFound => locale.languageCode == 'ar' ? 'لم يتم العثور على منتجات' : 'No products found';
  String get addFirstProductPrompt => locale.languageCode == 'ar' ? 'أضف منتجك الأول للبدء' : 'Add your first product to get started';
  String get addProductTitle => locale.languageCode == 'ar' ? 'إضافة منتج' : 'Add Product';
  String get productNameLabel => locale.languageCode == 'ar' ? 'اسم المنتج' : 'Product Name';
  String get categoryLabel => locale.languageCode == 'ar' ? 'الفئة' : 'Category';
  String get unitLabel => locale.languageCode == 'ar' ? 'الوحدة' : 'Unit';
  String get priceLabel => locale.languageCode == 'ar' ? 'السعر' : 'Price';
  String get initialStockLabel => locale.languageCode == 'ar' ? 'المخزون الأولي' : 'Initial Stock';
  String get minStockAlertLabel => locale.languageCode == 'ar' ? 'تنبيه المخزون الأدنى' : 'Min Stock Alert';
  String get add => locale.languageCode == 'ar' ? 'إضافة' : 'Add';
  String get update => locale.languageCode == 'ar' ? 'تحديث' : 'Update';
  String get close => locale.languageCode == 'ar' ? 'إغلاق' : 'Close';
  String get updateStockTitle => locale.languageCode == 'ar' ? 'تحديث المخزون' : 'Update Stock';
  String get currentStockPrefix => locale.languageCode == 'ar' ? 'المخزون الحالي:' : 'Current Stock:';
  String get lowLabel => locale.languageCode == 'ar' ? 'منخفض' : 'Low';
  String get lowStockAlert => locale.languageCode == 'ar' ? 'تنبيه نقص المخزون!' : 'Low Stock Alert!';
  // Customers
  String get customersTitle => locale.languageCode == 'ar' ? 'العملاء' : 'Customers';
  String get filterByStatusTooltip => locale.languageCode == 'ar' ? 'تصفية حسب الحالة' : 'Filter by status';
  String get allLabel => locale.languageCode == 'ar' ? 'الكل' : 'All';
  String get activeLabel => locale.languageCode == 'ar' ? 'نشط' : 'Active';
  String get inactiveLabel => locale.languageCode == 'ar' ? 'غير نشط' : 'Inactive';
  String get blockedLabel => locale.languageCode == 'ar' ? 'محظور' : 'Blocked';
  String get searchCustomersHint => locale.languageCode == 'ar' ? 'ابحث عن العملاء...' : 'Search customers...';
  String get noCustomersFound => locale.languageCode == 'ar' ? 'لم يتم العثور على عملاء' : 'No customers found';
  String get addFirstCustomerPrompt => locale.languageCode == 'ar' ? 'أضف عميلك الأول للبدء' : 'Add your first customer to get started';
  String get outstandingLabel => locale.languageCode == 'ar' ? 'المستحقات' : 'Outstanding';
  // Customer details / actions
  String get customerDetailsTitle => locale.languageCode == 'ar' ? 'تفاصيل العميل' : 'Customer Details';
  String get phoneLabel => locale.languageCode == 'ar' ? 'الهاتف' : 'Phone';
  
  String get addressLabel => locale.languageCode == 'ar' ? 'العنوان' : 'Address';
  String get outstandingBalanceLabel => locale.languageCode == 'ar' ? 'رصيد مستحق' : 'Outstanding Balance';
  String get payLabel => locale.languageCode == 'ar' ? 'ادفع' : 'Pay';
  String get distributionHistoryLabel => locale.languageCode == 'ar' ? 'سجل التوزيع' : 'Distribution History';
  String get viewAll => locale.languageCode == 'ar' ? 'عرض الكل' : 'View All';
  String get noDistributionHistory => locale.languageCode == 'ar' ? 'لا يوجد سجل للتوزيع' : 'No distribution history';
  String get deleteCustomerTitle => locale.languageCode == 'ar' ? 'حذف العميل' : 'Delete Customer';
  String get deleteCustomerConfirm => locale.languageCode == 'ar' ? 'هل تريد بالتأكيد حذف هذا العميل؟ هذا الإجراء لا يمكن التراجع عنه.' : 'Are you sure you want to delete this customer? This action cannot be undone.';
  String get deleteCancel => locale.languageCode == 'ar' ? 'إلغاء' : 'Cancel';
  String get deleteLabel => locale.languageCode == 'ar' ? 'حذف' : 'Delete';
  String get customerDeletedSuccess => locale.languageCode == 'ar' ? 'تم حذف العميل بنجاح' : 'Customer deleted successfully';
  // Add/Edit Customer
  String get addCustomerTitle => locale.languageCode == 'ar' ? 'إضافة عميل' : 'Add Customer';
  String get editCustomerTitle => locale.languageCode == 'ar' ? 'تعديل العميل' : 'Edit Customer';
  String get customerNameLabel => locale.languageCode == 'ar' ? 'اسم العميل' : 'Customer Name';
  String get enterCustomerNameHint => locale.languageCode == 'ar' ? 'أدخل اسم العميل' : 'Enter customer name';
  String get phoneNumberLabel => locale.languageCode == 'ar' ? 'رقم الهاتف' : 'Phone Number';
  String get enterPhoneHint => locale.languageCode == 'ar' ? 'أدخل رقم الهاتف' : 'Enter phone number';
  String get emailOptionalLabel => locale.languageCode == 'ar' ? 'البريد الإلكتروني (اختياري)' : 'Email (Optional)';
  String get enterEmailHintShort => locale.languageCode == 'ar' ? 'أدخل البريد الإلكتروني' : 'Enter email address';
  String get addressOptionalLabel => locale.languageCode == 'ar' ? 'العنوان (اختياري)' : 'Address (Optional)';
  String get enterAddressHint => locale.languageCode == 'ar' ? 'أدخل العنوان' : 'Enter address';
  String get statusLabel => locale.languageCode == 'ar' ? 'الحالة' : 'Status';
  String get updateCustomerLabel => locale.languageCode == 'ar' ? 'تحديث العميل' : 'Update Customer';
  String get addCustomerLabel => locale.languageCode == 'ar' ? 'إضافة عميل' : 'Add Customer';
  String get customerUpdatedSuccess => locale.languageCode == 'ar' ? 'تم تحديث العميل بنجاح' : 'Customer updated successfully';
  String get customerAddedSuccess => locale.languageCode == 'ar' ? 'تم إضافة العميل بنجاح' : 'Customer added successfully';
  String get failedToSaveCustomer => locale.languageCode == 'ar' ? 'فشل في حفظ العميل' : 'Failed to save customer';
  // Reports
  String get reportsTitle => locale.languageCode == 'ar' ? 'التقارير' : 'Reports';

  // --- مفاتيح جديدة تمت إضافتها ---
  String get confirm=>locale.languageCode=='ar'?'تأكيد':'Confirm';
  String get reportType => locale.languageCode == 'ar' ? 'نوع التقرير' : 'Report Type';
  String get reportTypeSummary => locale.languageCode == 'ar' ? 'ملخص' : 'Summary';
  String get reportTypeDetailed => locale.languageCode == 'ar' ? 'تفصيلي' : 'Detailed';
  String get selectCustomer => locale.languageCode == 'ar' ? 'اختر العميل' : 'Select Customer';
  String get allCustomers => locale.languageCode == 'ar' ? 'كل العملاء' : 'All Customers';
  String get selectProducts => locale.languageCode == 'ar' ? 'اختر المنتجات' : 'Select Products';
  String productsSelected(Object count) => locale.languageCode == 'ar' ? '$count منتجات تم اختيارها' : '$count products selected';
  String get generateReport => locale.languageCode == 'ar' ? 'إنشاء التقرير' : 'Generate Report';
  String get selectDateRange => locale.languageCode == 'ar' ? 'اختر نطاق التاريخ' : 'Select Date Range';
  String get fromLabel => locale.languageCode == 'ar' ? 'من' : 'From';
  String get toLabel => locale.languageCode == 'ar' ? 'إلى' : 'To';
  String get salesReportTitle => locale.languageCode == 'ar' ? 'تقرير المبيعات' : 'Sales Report';
  String get salesReportSubtitle => locale.languageCode == 'ar' ? 'عرض ملخص وإحصاءات المبيعات' : 'View sales summary and statistics';
  String get inventoryReportTitle => locale.languageCode == 'ar' ? 'تقرير المخزون' : 'Inventory Report';
  String get inventoryReportSubtitle => locale.languageCode == 'ar' ? 'المخزون الحالي وتفاصيل المنتج' : 'Current stock and product details';
  String get outstandingReportTitle => locale.languageCode == 'ar' ? 'تقرير المستحقات' : 'Outstanding Report';
  String get outstandingReportSubtitle => locale.languageCode == 'ar' ? 'العملاء ذوي المدفوعات المعلقة' : 'Customers with pending payments';
  String get exportAsPdf => locale.languageCode == 'ar' ? 'تصدير كـ PDF' : 'Export as PDF';
  String get exportAsExcel => locale.languageCode == 'ar' ? 'تصدير كـ Excel' : 'Export as Excel';
  String get reportGeneratedTitle => locale.languageCode == 'ar' ? 'تم إنشاء التقرير' : 'Report Generated';
  String get reportGeneratedPrompt => locale.languageCode == 'ar' ? 'ماذا تريد أن تفعل بالتقرير؟' : 'What would you like to do with the report?';
  String get openLabel => locale.languageCode == 'ar' ? 'فتح' : 'Open';
  String get shareLabel => locale.languageCode == 'ar' ? 'مشاركة' : 'Share';
  // Settings small labels
  String get english => locale.languageCode == 'ar' ? 'الإنجليزية' : 'English';
  String get arabic => locale.languageCode == 'ar' ? 'العربية' : 'العربية';
  String get lightModeLabel => locale.languageCode == 'ar' ? 'فاتح' : 'Light';
  String get darkModeLabel => locale.languageCode == 'ar' ? 'داكن' : 'Dark';
  String get testFirestoreAccess => locale.languageCode == 'ar' ? 'اختبار وصول Firestore' : 'Test Firestore access';
  
  // Payments / pending distributions
  String get paymentRecorded => locale.languageCode == 'ar' ? 'تم تسجيل الدفعة' : 'Payment recorded';
  String get pendingDistributionsTitle => locale.languageCode == 'ar' ? 'التوزيعات المعلقة' : 'Pending Distributions';
  String get noPendingDistributions => locale.languageCode == 'ar' ? 'لا توجد توزيعات معلقة' : 'No pending distributions';
  String get noCustomersWithOutstanding => locale.languageCode == 'ar' ? 'لا يوجد عملاء بمبالغ مستحقة' : 'No customers with outstanding balances';
  String get noPendingDistributionsForCustomer => locale.languageCode == 'ar' ? 'لا توجد توزيعات معلقة لهذا العميل' : 'No pending distributions for this customer';

  // Suppliers & Purchases
  String get suppliersTitle => locale.languageCode == 'ar' ? 'الموردين' : 'Suppliers';
  String get noSuppliersFound => locale.languageCode == 'ar' ? 'لا يوجد موردين' : 'No suppliers found';
  String get supplierName => locale.languageCode == 'ar' ? 'اسم المورد' : 'Supplier Name';
  String get addSupplierTitle => locale.languageCode == 'ar' ? 'إضافة مورد' : 'Add Supplier';
  String get editSupplierTitle => locale.languageCode == 'ar' ? 'تعديل مورد' : 'Edit Supplier';
  String get confirmDeleteSupplier => locale.languageCode == 'ar' ? 'تأكيد حذف المورد' : 'Confirm Delete Supplier';
  String get contact => locale.languageCode == 'ar' ? 'التواصل' : 'Contact';
  String get address => locale.languageCode == 'ar' ? 'العنوان' : 'Address';
  String get delete => locale.languageCode == 'ar' ? 'حذف' : 'Delete';
  String get addPurchaseTitle => locale.languageCode == 'ar' ? 'إضافة عملية شراء' : 'Add Purchase';
  String get productLabel => locale.languageCode == 'ar' ? 'المنتج' : 'Product';
  String get supplierLabel => locale.languageCode == 'ar' ? 'المورد' : 'Supplier';
  String get addPurchaseButtonLabel => locale.languageCode == 'ar' ? 'إضافة شراء' : 'Add Purchase';

  // Suppliers messages and utilities
  String get supplierNameRequired => locale.languageCode == 'ar' ? 'اسم المورد مطلوب' : 'Supplier name is required';
  String get supplierAddedSuccess => locale.languageCode == 'ar' ? 'تم إضافة المورد بنجاح' : 'Supplier added successfully';
  String get supplierUpdatedSuccess => locale.languageCode == 'ar' ? 'تم تحديث المورد بنجاح' : 'Supplier updated successfully';
  String get supplierDeletedSuccess => locale.languageCode == 'ar' ? 'تم حذف المورد بنجاح' : 'Supplier deleted successfully';
  String get undo => locale.languageCode == 'ar' ? 'تراجع' : 'Undo';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
