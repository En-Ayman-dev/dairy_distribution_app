import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Dairy Distribution'**
  String get appTitle;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @language_label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language_label;

  /// No description provided for @theme_label.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme_label;

  /// No description provided for @dark_mode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get dark_mode;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @login_title.
  ///
  /// In en, this message translates to:
  /// **'Dairy Distribution'**
  String get login_title;

  /// No description provided for @login_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Login to your account'**
  String get login_subtitle;

  /// No description provided for @email_label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email_label;

  /// No description provided for @enter_email_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enter_email_hint;

  /// No description provided for @password_label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password_label;

  /// No description provided for @enter_password_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enter_password_hint;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgot_password;

  /// No description provided for @login_button.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_button;

  /// No description provided for @dont_have_account.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dont_have_account;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @reset_password_title.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get reset_password_title;

  /// No description provided for @reset_password_instruction.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive password reset link'**
  String get reset_password_instruction;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @password_reset_sent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get password_reset_sent;

  /// No description provided for @sync_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync Data'**
  String get sync_tooltip;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @welcome_back.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcome_back;

  /// No description provided for @user_fallback.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user_fallback;

  /// No description provided for @quick_actions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quick_actions;

  /// No description provided for @recent_activity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recent_activity;

  /// No description provided for @new_distribution.
  ///
  /// In en, this message translates to:
  /// **'New Distribution'**
  String get new_distribution;

  /// No description provided for @dashboard_total_sales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get dashboard_total_sales;

  /// No description provided for @dashboard_outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get dashboard_outstanding;

  /// No description provided for @dashboard_customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get dashboard_customers;

  /// No description provided for @dashboard_low_stock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get dashboard_low_stock;

  /// No description provided for @quick_distribution.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get quick_distribution;

  /// No description provided for @quick_customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get quick_customers;

  /// No description provided for @quick_products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get quick_products;

  /// No description provided for @quick_reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get quick_reports;

  /// No description provided for @quick_payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get quick_payments;

  /// No description provided for @quick_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get quick_history;

  /// No description provided for @no_recent_activity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get no_recent_activity;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @partial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @logout_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logout_confirm;

  /// No description provided for @suppliersTitle.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliersTitle;

  /// No description provided for @noSuppliersFound.
  ///
  /// In en, this message translates to:
  /// **'No suppliers found'**
  String get noSuppliersFound;

  /// No description provided for @supplierName.
  ///
  /// In en, this message translates to:
  /// **'Supplier Name'**
  String get supplierName;

  /// No description provided for @addSupplierTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Supplier'**
  String get addSupplierTitle;

  /// No description provided for @editSupplierTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Supplier'**
  String get editSupplierTitle;

  /// No description provided for @confirmDeleteSupplier.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete Supplier'**
  String get confirmDeleteSupplier;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @addPurchaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Purchase'**
  String get addPurchaseTitle;

  /// No description provided for @productLabel.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get productLabel;

  /// No description provided for @supplierLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplierLabel;

  /// No description provided for @addPurchaseButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Purchase'**
  String get addPurchaseButtonLabel;

  /// Label for the optional free quantity field in Add Purchase Screen
  ///
  /// In en, this message translates to:
  /// **'Free Quantity (optional)'**
  String get freeQuantityLabel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @productsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTitle;

  /// No description provided for @filterByCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter by Category'**
  String get filterByCategoryTooltip;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @searchProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProductsHint;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @addFirstProductPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add your first product by clicking the + button'**
  String get addFirstProductPrompt;

  /// No description provided for @lowLabel.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowLabel;

  /// No description provided for @currentStockPrefix.
  ///
  /// In en, this message translates to:
  /// **'Current Stock: '**
  String get currentStockPrefix;

  /// No description provided for @addProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProductTitle;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productNameLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @minStockAlertLabel.
  ///
  /// In en, this message translates to:
  /// **'Min Stock Alert'**
  String get minStockAlertLabel;

  /// No description provided for @addProductButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProductButtonLabel;

  /// No description provided for @lowStockAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alert'**
  String get lowStockAlertTitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @supplierNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Supplier name is required'**
  String get supplierNameRequired;

  /// No description provided for @supplierAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Supplier added successfully'**
  String get supplierAddedSuccess;

  /// No description provided for @supplierUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Supplier updated successfully'**
  String get supplierUpdatedSuccess;

  /// No description provided for @supplierDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Supplier deleted successfully'**
  String get supplierDeletedSuccess;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @payLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get payLabel;

  /// No description provided for @outstandingBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Balance'**
  String get outstandingBalanceLabel;

  /// No description provided for @paymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded successfully'**
  String get paymentRecorded;

  /// No description provided for @settingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsLabel;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBack;

  /// No description provided for @userFallback.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userFallback;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @newDistribution.
  ///
  /// In en, this message translates to:
  /// **'New Distribution'**
  String get newDistribution;

  /// No description provided for @dashboardTotalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get dashboardTotalSales;

  /// No description provided for @dashboardOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get dashboardOutstanding;

  /// No description provided for @dashboardCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get dashboardCustomers;

  /// No description provided for @dashboardLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get dashboardLowStock;

  /// No description provided for @quickDistribution.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get quickDistribution;

  /// No description provided for @quickCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get quickCustomers;

  /// No description provided for @quickProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get quickProducts;

  /// No description provided for @quickReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get quickReports;

  /// No description provided for @quickPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get quickPayments;

  /// No description provided for @quickHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get quickHistory;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @notAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated'**
  String get notAuthenticated;

  /// No description provided for @firestoreReadResult.
  ///
  /// In en, this message translates to:
  /// **'Firestore read result'**
  String get firestoreReadResult;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @firestoreError.
  ///
  /// In en, this message translates to:
  /// **'Firestore error'**
  String get firestoreError;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error'**
  String get unexpectedError;

  /// No description provided for @distributionListTitle.
  ///
  /// In en, this message translates to:
  /// **'Distributions'**
  String get distributionListTitle;

  /// No description provided for @failedToLoadDistributions.
  ///
  /// In en, this message translates to:
  /// **'Failed to load distributions'**
  String get failedToLoadDistributions;

  /// No description provided for @noDistributionsToShow.
  ///
  /// In en, this message translates to:
  /// **'No distributions to show'**
  String get noDistributionsToShow;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @deleteCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete distribution'**
  String get deleteCustomerTitle;

  /// No description provided for @deleteCustomerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this distribution?'**
  String get deleteCustomerConfirm;

  /// No description provided for @distributionLabel.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get distributionLabel;

  /// No description provided for @deleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deleteCancel;

  /// No description provided for @customerDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer details'**
  String get customerDetailsTitle;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @outstandingLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstandingLabel;

  /// No description provided for @createDistributionLabel.
  ///
  /// In en, this message translates to:
  /// **'Create distribution'**
  String get createDistributionLabel;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @itemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsLabel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @createTestDistributionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Distribution created successfully'**
  String get createTestDistributionSuccess;

  /// No description provided for @distributionDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Distribution deleted successfully'**
  String get distributionDeletedSuccess;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select date range'**
  String get selectDateRange;

  /// No description provided for @fromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromLabel;

  /// No description provided for @toLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toLabel;

  /// No description provided for @salesReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales report'**
  String get salesReportTitle;

  /// No description provided for @salesReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View sales in the selected period'**
  String get salesReportSubtitle;

  /// No description provided for @inventoryReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory report'**
  String get inventoryReportTitle;

  /// No description provided for @inventoryReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check stock and product movements'**
  String get inventoryReportSubtitle;

  /// No description provided for @outstandingReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Outstanding balances report'**
  String get outstandingReportTitle;

  /// No description provided for @outstandingReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View customers\' outstanding balances'**
  String get outstandingReportSubtitle;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate report'**
  String get generateReport;

  /// No description provided for @reportType.
  ///
  /// In en, this message translates to:
  /// **'Report type'**
  String get reportType;

  /// No description provided for @reportTypeSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get reportTypeSummary;

  /// No description provided for @reportTypeDetailed.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get reportTypeDetailed;

  /// No description provided for @selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select customer'**
  String get selectCustomer;

  /// No description provided for @allCustomers.
  ///
  /// In en, this message translates to:
  /// **'All customers'**
  String get allCustomers;

  /// No description provided for @selectProducts.
  ///
  /// In en, this message translates to:
  /// **'Select products'**
  String get selectProducts;

  /// Label showing how many products are selected in reports filter
  ///
  /// In en, this message translates to:
  /// **'{count} products selected'**
  String productsSelected(int count);

  /// No description provided for @exportAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportAsPdf;

  /// No description provided for @exportAsExcel.
  ///
  /// In en, this message translates to:
  /// **'Export as Excel'**
  String get exportAsExcel;

  /// No description provided for @reportGeneratedTitle.
  ///
  /// In en, this message translates to:
  /// **'Report generated'**
  String get reportGeneratedTitle;

  /// No description provided for @reportGeneratedPrompt.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do with the file?'**
  String get reportGeneratedPrompt;

  /// No description provided for @openLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openLabel;

  /// No description provided for @customerUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Customer updated successfully'**
  String get customerUpdatedSuccess;

  /// No description provided for @customerAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Customer added successfully'**
  String get customerAddedSuccess;

  /// No description provided for @failedToSaveCustomer.
  ///
  /// In en, this message translates to:
  /// **'Failed to save customer'**
  String get failedToSaveCustomer;

  /// No description provided for @editCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get editCustomerTitle;

  /// No description provided for @addCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get addCustomerTitle;

  /// No description provided for @customerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get customerNameLabel;

  /// No description provided for @enterCustomerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter customer name'**
  String get enterCustomerNameHint;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @enterPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneHint;

  /// No description provided for @emailOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptionalLabel;

  /// No description provided for @enterEmailHintShort.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get enterEmailHintShort;

  /// No description provided for @addressOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addressOptionalLabel;

  /// No description provided for @enterAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter address'**
  String get enterAddressHint;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @updateCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Update customer'**
  String get updateCustomerLabel;

  /// No description provided for @addCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get addCustomerLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @distributionHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Distribution history'**
  String get distributionHistoryLabel;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @noDistributionHistory.
  ///
  /// In en, this message translates to:
  /// **'No distribution history'**
  String get noDistributionHistory;

  /// No description provided for @customerDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Customer deleted successfully'**
  String get customerDeletedSuccess;

  /// No description provided for @filterByStatusTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get filterByStatusTooltip;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @inactiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveLabel;

  /// No description provided for @blockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blockedLabel;

  /// No description provided for @searchCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'Search customers...'**
  String get searchCustomersHint;

  /// No description provided for @noCustomersFound.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get noCustomersFound;

  /// No description provided for @addFirstCustomerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add your first customer using the + button'**
  String get addFirstCustomerPrompt;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Dairy Distribution'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login to your account'**
  String get loginSubtitle;

  /// No description provided for @enterEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @enterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPasswordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive password reset link'**
  String get resetPasswordInstruction;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get passwordResetSent;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @lightModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightModeLabel;

  /// No description provided for @darkModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkModeLabel;

  /// No description provided for @testFirestoreAccess.
  ///
  /// In en, this message translates to:
  /// **'Test Firestore access'**
  String get testFirestoreAccess;

  /// No description provided for @shareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLabel;

  /// No description provided for @purchaseListTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase History'**
  String get purchaseListTitle;

  /// No description provided for @purchasesAndPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchases & Payments'**
  String get purchasesAndPaymentsTitle;

  /// No description provided for @invoicesTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoices Log'**
  String get invoicesTabTitle;

  /// No description provided for @paymentsAndDebtTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments & Debt'**
  String get paymentsAndDebtTabTitle;

  /// No description provided for @filterBySupplierHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by Supplier (View All)'**
  String get filterBySupplierHint;

  /// No description provided for @viewAllSuppliers.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAllSuppliers;

  /// No description provided for @selectSupplierPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please select a supplier from the filter above\nto view debt and payments'**
  String get selectSupplierPrompt;

  /// No description provided for @paymentHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistoryTitle;

  /// No description provided for @noPaymentsFound.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded'**
  String get noPaymentsFound;

  /// No description provided for @addPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Payment'**
  String get addPaymentLabel;

  /// No description provided for @currentDebtLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Debt'**
  String get currentDebtLabel;

  /// No description provided for @debtStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid Off'**
  String get debtStatusPaid;

  /// No description provided for @debtStatusCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit Balance'**
  String get debtStatusCredit;

  /// No description provided for @debtStatusDue.
  ///
  /// In en, this message translates to:
  /// **'Payment Due'**
  String get debtStatusDue;

  /// No description provided for @addPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Supplier Payment'**
  String get addPaymentTitle;

  /// No description provided for @paymentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Amount'**
  String get paymentAmountLabel;

  /// No description provided for @amountRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount'**
  String get amountRequiredError;

  /// No description provided for @invalidAmountError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount greater than zero'**
  String get invalidAmountError;

  /// No description provided for @paymentNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (Payment Details)'**
  String get paymentNotesLabel;

  /// No description provided for @paymentNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Cash / Bank Transfer'**
  String get paymentNotesHint;

  /// No description provided for @savePaymentButton.
  ///
  /// In en, this message translates to:
  /// **'Save Payment'**
  String get savePaymentButton;

  /// No description provided for @paymentAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment added successfully'**
  String get paymentAddedSuccess;

  /// No description provided for @paymentAddedError.
  ///
  /// In en, this message translates to:
  /// **'Failed to add payment'**
  String get paymentAddedError;

  /// No description provided for @noInvoicesForSupplier.
  ///
  /// In en, this message translates to:
  /// **'No invoices for this supplier'**
  String get noInvoicesForSupplier;

  /// No description provided for @newInvoiceButton.
  ///
  /// In en, this message translates to:
  /// **'New Invoice'**
  String get newInvoiceButton;

  /// No description provided for @returnItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Return Item'**
  String get returnItemTitle;

  /// No description provided for @productPrefix.
  ///
  /// In en, this message translates to:
  /// **'Product: '**
  String get productPrefix;

  /// No description provided for @returnableQuantityPrefix.
  ///
  /// In en, this message translates to:
  /// **'Returnable: '**
  String get returnableQuantityPrefix;

  /// No description provided for @returnQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Return Quantity'**
  String get returnQuantityLabel;

  /// No description provided for @invalidReturnAmountError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid quantity'**
  String get invalidReturnAmountError;

  /// No description provided for @returnAmountExceedsError.
  ///
  /// In en, this message translates to:
  /// **'Quantity exceeds available amount'**
  String get returnAmountExceedsError;

  /// No description provided for @returnRecordedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Return recorded successfully'**
  String get returnRecordedSuccess;

  /// No description provided for @unknownSupplier.
  ///
  /// In en, this message translates to:
  /// **'Unknown Supplier'**
  String get unknownSupplier;

  /// No description provided for @unknownProduct.
  ///
  /// In en, this message translates to:
  /// **'Unknown Product'**
  String get unknownProduct;

  /// No description provided for @invoiceItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Items:'**
  String get invoiceItemsLabel;

  /// No description provided for @subTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal:'**
  String get subTotalLabel;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount:'**
  String get discountLabel;

  /// No description provided for @netTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Total:'**
  String get netTotalLabel;

  /// No description provided for @returnedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Returned: '**
  String get returnedPrefix;

  /// No description provided for @totalDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Discount'**
  String get totalDiscountLabel;

  /// No description provided for @addProductsToInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Products to Invoice'**
  String get addProductsToInvoiceTitle;

  /// No description provided for @addToCartButton.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCartButton;

  /// No description provided for @invoiceContentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice Contents'**
  String get invoiceContentsTitle;

  /// No description provided for @noProductsAdded.
  ///
  /// In en, this message translates to:
  /// **'No products added'**
  String get noProductsAdded;

  /// No description provided for @saveFinalInvoiceButton.
  ///
  /// In en, this message translates to:
  /// **'Save Final Invoice'**
  String get saveFinalInvoiceButton;

  /// No description provided for @selectSupplierError.
  ///
  /// In en, this message translates to:
  /// **'Please select a supplier'**
  String get selectSupplierError;

  /// No description provided for @addProductsError.
  ///
  /// In en, this message translates to:
  /// **'Please add products to the invoice'**
  String get addProductsError;

  /// No description provided for @invoiceSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invoice saved successfully'**
  String get invoiceSavedSuccess;

  /// No description provided for @subTotalSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal:'**
  String get subTotalSummaryLabel;

  /// No description provided for @netTotalSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Total:'**
  String get netTotalSummaryLabel;

  /// No description provided for @quantityMustBePositiveError.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be greater than zero'**
  String get quantityMustBePositiveError;

  /// No description provided for @freeLabel.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeLabel;

  /// No description provided for @purchasesReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchases Report'**
  String get purchasesReportTitle;

  /// No description provided for @purchasesReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed financial purchase report'**
  String get purchasesReportSubtitle;

  /// No description provided for @customizeReportButton.
  ///
  /// In en, this message translates to:
  /// **'Customize Report'**
  String get customizeReportButton;

  /// No description provided for @selectColumnsTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Report Columns'**
  String get selectColumnsTitle;

  /// No description provided for @saveAsDefaultConfig.
  ///
  /// In en, this message translates to:
  /// **'Save as default'**
  String get saveAsDefaultConfig;

  /// No description provided for @colSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get colSupplier;

  /// No description provided for @colDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get colDate;

  /// No description provided for @colItemsCount.
  ///
  /// In en, this message translates to:
  /// **'Items Count'**
  String get colItemsCount;

  /// No description provided for @colTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get colTotalAmount;

  /// No description provided for @colDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get colDiscount;

  /// No description provided for @colNetTotal.
  ///
  /// In en, this message translates to:
  /// **'Net Total'**
  String get colNetTotal;

  /// No description provided for @colPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get colPaid;

  /// No description provided for @colRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get colRemaining;

  /// No description provided for @colStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get colStatus;

  /// No description provided for @reportGeneratedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report generated successfully'**
  String get reportGeneratedSuccess;

  /// No description provided for @totalSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get totalSummaryLabel;

  /// No description provided for @generateViewButton.
  ///
  /// In en, this message translates to:
  /// **'View Report'**
  String get generateViewButton;

  /// No description provided for @reportTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Type'**
  String get reportTypeTitle;

  /// No description provided for @reportTypeDetailedItems.
  ///
  /// In en, this message translates to:
  /// **'Detailed (Items Movement)'**
  String get reportTypeDetailedItems;

  /// No description provided for @reportTypeStatement.
  ///
  /// In en, this message translates to:
  /// **'Summary (Statement of Account)'**
  String get reportTypeStatement;

  /// No description provided for @colInvoiceNum.
  ///
  /// In en, this message translates to:
  /// **'Invoice #'**
  String get colInvoiceNum;

  /// No description provided for @colProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get colProduct;

  /// No description provided for @colQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get colQty;

  /// No description provided for @colFreeQty.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get colFreeQty;

  /// No description provided for @colPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get colPrice;

  /// No description provided for @colReturnedQty.
  ///
  /// In en, this message translates to:
  /// **'Returned Qty'**
  String get colReturnedQty;

  /// No description provided for @colReturnedVal.
  ///
  /// In en, this message translates to:
  /// **'Returned Value'**
  String get colReturnedVal;

  /// No description provided for @colDebit.
  ///
  /// In en, this message translates to:
  /// **'Invoice Amount'**
  String get colDebit;

  /// No description provided for @colCredit.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get colCredit;

  /// No description provided for @colBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get colBalance;

  /// No description provided for @supplierHeaderName.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplierHeaderName;

  /// No description provided for @supplierHeaderPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get supplierHeaderPhone;

  /// No description provided for @supplierHeaderAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get supplierHeaderAddress;

  /// No description provided for @grandTotalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get grandTotalPaid;

  /// Label for the customer's current balance/debt.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalanceLabel;

  /// The local currency symbol (e.g.,YER, SAR).
  ///
  /// In en, this message translates to:
  /// **'YER'**
  String get currencySymbol;

  /// General text for data that is missing or not provided.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// Tooltip text for the export button (PDF/Excel).
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportTooltip;

  /// Option in a dropdown to select all suppliers.
  ///
  /// In en, this message translates to:
  /// **'All Suppliers'**
  String get allSuppliersLabel;

  /// Title of the confirmation dialog for deleting a distribution invoice.
  ///
  /// In en, this message translates to:
  /// **'Delete Distribution Invoice'**
  String get deleteDistributionTitle;

  /// Confirmation message for deletion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this distribution invoice?'**
  String get deleteDistributionConfirm;

  /// Success notification after updating an invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice updated successfully'**
  String get distributionUpdatedSuccess;

  /// Label showing the amount remaining due from the customer.
  ///
  /// In en, this message translates to:
  /// **'Remaining Amount'**
  String get remainingAmount;

  /// Button/title for the edit operation.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editLabel;

  /// Tooltip for the print button.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printTooltip;

  /// Title and button to open filter options.
  ///
  /// In en, this message translates to:
  /// **'Filter List'**
  String get filterLabel;

  /// No description provided for @selectPrinter.
  ///
  /// In en, this message translates to:
  /// **' Select Printer'**
  String get selectPrinter;

  /// No description provided for @grandTotalRemaining.
  ///
  /// In en, this message translates to:
  /// **'Total Remaining'**
  String get grandTotalRemaining;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
