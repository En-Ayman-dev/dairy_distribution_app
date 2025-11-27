import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import '../../domain/repositories/distribution_repository.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../core/utils/pdf_generator.dart';
import '../../core/utils/excel_generator.dart';
// --- الإضافات ---
import '../../domain/entities/customer.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/distribution.dart';
// --- نهاية الإضافات ---

enum ReportViewState {
  initial,
  loading,
  loaded,
  error,
  generating,
}

enum ReportType {
  sales,
  inventory,
  // customerStatement, <-- تم إزالته، أصبح جزءاً من تقرير المبيعات
  outstanding,
  // productWise, <-- تم إزالته، أصبح جزءاً من تقرير المخزون
}

// --- إضافة ---
// نوع تقرير المبيعات بناءً على طلبك (تفصيلي / ملخص)
enum SalesReportType {
  summary,
  detailed,
}
// --- نهاية الإضافة ---

class ReportViewModel extends ChangeNotifier {
  final DistributionRepository _distributionRepository;
  final CustomerRepository _customerRepository;
  final ProductRepository _productRepository;

  ReportViewModel(
    this._distributionRepository,
    this._customerRepository,
    this._productRepository,
  );

  ReportViewState _state = ReportViewState.initial;
  String? _errorMessage;
  Map<String, dynamic> _reportData = {};
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // --- متغيرات الفلاتر الجديدة ---
  Customer? _selectedCustomer;
  List<Product> _selectedProducts = [];
  SalesReportType _salesReportType = SalesReportType.summary;
  // --- نهاية متغيرات الفلاتر ---

  // Getters
  ReportViewState get state => _state;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get reportData => _reportData;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  // --- Getters للفلاتر ---
  Customer? get selectedCustomer => _selectedCustomer;
  List<Product> get selectedProducts => _selectedProducts;
  SalesReportType get salesReportType => _salesReportType;
  // --- نهاية Getters للفلاتر ---

  // Set date range
  void setDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  // --- دوال Setters للفلاتر (لتحديث الواجهة) ---
  void setSelectedCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setSelectedProducts(List<Product> products) {
    _selectedProducts = products;
    notifyListeners();
  }

  void setSalesReportType(SalesReportType type) {
    _salesReportType = type;
    notifyListeners();
  }
  // --- نهاية دوال Setters ---

  // Generate sales report (*** تم تعديله بالكامل ***)
  Future<void> generateSalesReport() async {
    _setState(ReportViewState.loading);

    try {
      // 1. جلب الحركات المفصلة بناءً على الفلاتر
      // (سنقوم بإضافة getFilteredDistributions إلى الـ Repository في الخطوة التالية)
      final distributionsResult =
          await _distributionRepository.getFilteredDistributions(
        startDate: _startDate,
        endDate: _endDate,
        customerId: _selectedCustomer?.id,
        // تحويل قائمة المنتجات إلى قائمة IDs
        productIds: _selectedProducts.map((p) => p.id).toList(),
      );

      distributionsResult.fold(
        (failure) {
          _errorMessage = failure.message;
          _setState(ReportViewState.error);
        },
        (distributions) {
          // 2. بناء بيانات التقرير بناءً على النوع (ملخص أو تفصيلي)
          Map<String, dynamic> stats = {};

          // إذا كان التقرير "ملخص"، قم بحساب الإحصائيات
          if (_salesReportType == SalesReportType.summary) {
            stats = _calculateDistributionStats(distributions);
          }
          // إذا كان "تفصيلي"، سنمرر قائمة الحركات كاملة
          else {
            stats['distributions'] = distributions;
          }

          _reportData = {
            'type': 'sales',
            'report_type': _salesReportType, // ملخص أم تفصيلي
            'start_date': _startDate,
            'end_date': _endDate,
            'customer': _selectedCustomer, // العميل المختار (قد يكون null)
            'products': _selectedProducts, // المنتجات المختارة (قد تكون فارغة)
            'stats': stats, // يحتوي على الإحصائيات أو قائمة الحركات
          };
          _setState(ReportViewState.loaded);
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to generate sales report';
      _setState(ReportViewState.error);
    }
  }

  // دالة مساعدة لحساب الإحصائيات
  Map<String, dynamic> _calculateDistributionStats(
      List<Distribution> distributions) {
    double totalSales = 0;
    double totalPaid = 0;
    double totalPending = 0;

    for (var dist in distributions) {
      totalSales += dist.totalAmount;
      totalPaid += dist.paidAmount;
      totalPending += dist.pendingAmount;
    }

    return {
      'total_sales': totalSales,
      'total_paid': totalPaid,
      'total_pending': totalPending,
      'total_distributions': distributions.length,
      'average_sale': distributions.isEmpty ? 0 : totalSales / distributions.length,
    };
  }

  // Generate inventory report (*** تم تعديله ***)
  Future<void> generateInventoryReport() async {
    _setState(ReportViewState.loading);

    try {
      final productsResult = await _productRepository.getAllProducts();

      productsResult.fold(
        (failure) {
          _errorMessage = failure.message;
          _setState(ReportViewState.error);
        },
        (products) {
          // *** فلترة المنتجات بناءً على اختيار المستخدم ***
          final filteredProducts = _selectedProducts.isEmpty
              ? products // إذا لم يختر شيئاً، اعرض الكل
              : products
                  .where((p) =>
                      _selectedProducts.any((selected) => selected.id == p.id))
                  .toList();
          // *** نهاية الفلترة ***

          double totalValue = 0;
          int lowStockCount = 0;

          for (var product in filteredProducts) {
            totalValue += product.stock * product.price;
            if (product.isLowStock) lowStockCount++;
          }

          _reportData = {
            'type': 'inventory',
            'products': filteredProducts, // استخدام القائمة المفلتزة
            'total_products': filteredProducts.length,
            'total_value': totalValue,
            'low_stock_count': lowStockCount,
          };
          _setState(ReportViewState.loaded);
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to generate inventory report';
      _setState(ReportViewState.error);
    }
  }

  // (*** تم حذف generateCustomerStatement - أصبح جزءاً من generateSalesReport ***)

  // Generate outstanding report (*** تم تعديله ***)
  Future<void> generateOutstandingReport() async {
    _setState(ReportViewState.loading);

    try {
      // إذا اختار المستخدم عميلاً محدداً، اجلب بياناته فقط
      if (_selectedCustomer != null) {
        final customerResult =
            await _customerRepository.getCustomerById(_selectedCustomer!.id);
        customerResult.fold(
          (failure) {
            _errorMessage = failure.message;
            _setState(ReportViewState.error);
          },
          (customer) {
            _reportData = {
              'type': 'outstanding',
              'customers': [customer], // قائمة بعميل واحد
              'total_outstanding': customer.balance,
              'customer_count': 1,
            };
            _setState(ReportViewState.loaded);
          },
        );
      } else {
        // إذا لم يختر عميلاً، قم بتطبيق المنطق القديم (جلب كل العملاء)
        final customersResult = await _customerRepository.getAllCustomers();
        customersResult.fold(
          (failure) {
            _errorMessage = failure.message;
            _setState(ReportViewState.error);
          },
          (customers) {
            final outstandingCustomers = customers
                .where((c) => c.balance > 0)
                .toList()
              ..sort((a, b) => b.balance.compareTo(a.balance));

            final totalOutstanding = outstandingCustomers.fold(
              0.0,
              (sum, customer) => sum + customer.balance,
            );

            _reportData = {
              'type': 'outstanding',
              'customers': outstandingCustomers,
              'total_outstanding': totalOutstanding,
              'customer_count': outstandingCustomers.length,
            };
            _setState(ReportViewState.loaded);
          },
        );
      }
    } catch (e) {
      _errorMessage = 'Failed to generate outstanding report';
      _setState(ReportViewState.error);
    }
  }

  // Export to PDF (*** تم تعديله ***)
  Future<String?> exportToPDF(ReportType reportType) async {
    _setState(ReportViewState.generating);

    try {
      final pdfGenerator = PDFGenerator();
      String? filePath;

      switch (reportType) {
        case ReportType.sales:
          filePath = await pdfGenerator.generateSalesReport(_reportData);
          break;
        case ReportType.inventory:
          filePath = await pdfGenerator.generateInventoryReport(_reportData);
          break;
        // (case ReportType.customerStatement: <-- تم الحذف)
        case ReportType.outstanding:
          filePath = await pdfGenerator.generateOutstandingReport(_reportData);
          break;
        default:
          break;
      }

      _setState(ReportViewState.loaded);
      return filePath;
    } catch (e) {
      _errorMessage = 'Failed to generate PDF';
      _setState(ReportViewState.error);
      return null;
    }
  }

  // Export to Excel (*** تم تعديله ***)
  Future<String?> exportToExcel(ReportType reportType) async {
    _setState(ReportViewState.generating);

    try {
      final excelGenerator = ExcelGenerator();
      String? filePath;

      switch (reportType) {
        case ReportType.sales:
          filePath = await excelGenerator.generateSalesReport(_reportData);
          break;
        case ReportType.inventory:
          filePath = await excelGenerator.generateInventoryReport(_reportData);
          break;
        // (case ReportType.customerStatement: <-- تم الحذف)
        case ReportType.outstanding:
          filePath = await excelGenerator.generateOutstandingReport(_reportData);
          break;
        default:
          break;
      }

      _setState(ReportViewState.loaded);
      return filePath;
    } catch (e) {
      _errorMessage = 'Failed to generate Excel';
      _setState(ReportViewState.error);
      return null;
    }
  }

  void _setState(ReportViewState state) {
    _state = state;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearReportData() {
    _reportData = {};
    notifyListeners();
  }
}

// Extension method for Either
extension EitherX<L, R> on Either<L, R> {
  bool isLeft() => fold((_) => true, (_) => false);
  bool isRight() => fold((_) => false, (_) => true);

  R getOrElse(R Function() orElse) {
    return fold((_) => orElse(), (r) => r);
  }
}