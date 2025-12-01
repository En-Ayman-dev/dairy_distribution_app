import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/distribution_repository.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../../core/utils/pdf_generator.dart';
import '../../core/utils/excel_generator.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/distribution.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/entities/supplier_payment.dart';

// --- تعريف أعمدة التقرير ---
class ReportColumn {
  final String id;
  final String labelKey;
  bool isVisible;
  final bool isNumeric;

  ReportColumn({
    required this.id,
    required this.labelKey,
    this.isVisible = true,
    this.isNumeric = false,
  });
}

enum ReportViewState { initial, loading, loaded, error, generating }

enum ReportType { sales, inventory, outstanding, purchases }

enum SalesReportType { summary, detailed }

// --- نوع تقرير المشتريات الجديد ---
enum PurchaseReportType { detailedItems, statement }

class ReportViewModel extends ChangeNotifier {
  final DistributionRepository _distributionRepository;
  final CustomerRepository _customerRepository;
  final ProductRepository _productRepository;
  final PurchaseRepository _purchaseRepository;
  final SupplierRepository _supplierRepository;

  ReportViewModel(
    this._distributionRepository,
    this._customerRepository,
    this._productRepository,
    this._purchaseRepository,
    this._supplierRepository,
  );

  ReportViewState _state = ReportViewState.initial;
  String? _errorMessage;
  Map<String, dynamic> _reportData = {};
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // --- الفلاتر ---
  Customer? _selectedCustomer;
  List<Product> _selectedProducts = [];
  SalesReportType _salesReportType = SalesReportType.summary;
  
  // --- فلاتر تقارير المشتريات ---
  Supplier? _selectedSupplier;
  PurchaseReportType _purchaseReportType = PurchaseReportType.statement;

  // --- بيانات المشتريات ---
  List<Purchase> _purchases = [];
  List<SupplierPayment> _payments = [];

  // --- تعريف الأعمدة ---
  final List<ReportColumn> _purchaseReportColumns = [
    ReportColumn(id: 'invoice_num', labelKey: 'colInvoiceNum', isVisible: true),
    ReportColumn(id: 'date', labelKey: 'colDate', isVisible: true),
    ReportColumn(id: 'supplier', labelKey: 'colSupplier', isVisible: true),
    ReportColumn(id: 'product', labelKey: 'colProduct', isVisible: true),
    ReportColumn(id: 'qty', labelKey: 'colQty', isVisible: true, isNumeric: true),
    ReportColumn(id: 'free_qty', labelKey: 'colFreeQty', isVisible: true, isNumeric: true),
    ReportColumn(id: 'price', labelKey: 'colPrice', isVisible: true, isNumeric: true),
    ReportColumn(id: 'returned_qty', labelKey: 'colReturnedQty', isVisible: true, isNumeric: true),
    ReportColumn(id: 'debit', labelKey: 'colDebit', isVisible: true, isNumeric: true),
    ReportColumn(id: 'credit', labelKey: 'colCredit', isVisible: true, isNumeric: true),
    ReportColumn(id: 'balance', labelKey: 'colBalance', isVisible: true, isNumeric: true),
  ];

  // Getters
  ReportViewState get state => _state;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get reportData => _reportData;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  Customer? get selectedCustomer => _selectedCustomer;
  List<Product> get selectedProducts => _selectedProducts;
  SalesReportType get salesReportType => _salesReportType;

  Supplier? get selectedSupplier => _selectedSupplier;
  PurchaseReportType get purchaseReportType => _purchaseReportType;
  List<Purchase> get purchases => _purchases;
  List<ReportColumn> get purchaseColumns => _purchaseReportColumns;

  // Setters
  void setDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

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

  void setSelectedSupplier(Supplier? supplier) {
    _selectedSupplier = supplier;
    notifyListeners();
  }

  void setPurchaseReportType(PurchaseReportType type) {
    _purchaseReportType = type;
    notifyListeners();
  }

  // --- إدارة الأعمدة ---
  void toggleColumnVisibility(String columnId, bool isVisible) {
    final index = _purchaseReportColumns.indexWhere((col) => col.id == columnId);
    if (index != -1) {
      _purchaseReportColumns[index].isVisible = isVisible;
      notifyListeners();
    }
  }

  Future<void> saveColumnPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final visibleColumns = _purchaseReportColumns.where((col) => col.isVisible).map((col) => col.id).toList();
    await prefs.setStringList('purchase_report_cols', visibleColumns);
  }

  Future<void> _loadColumnPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCols = prefs.getStringList('purchase_report_cols');
    if (savedCols != null) {
      for (var col in _purchaseReportColumns) {
        col.isVisible = savedCols.contains(col.id);
      }
    }
  }

  // --- الدالة المفقودة: تحميل بيانات تقرير المشتريات للعرض ---
  Future<void> loadPurchasesReportData() async {
    _setState(ReportViewState.loading);
    try {
      await _loadColumnPreferences();
      final resultStream = _purchaseRepository.watchPurchases();
      final result = await resultStream.first; 

      result.fold(
        (failure) {
          _errorMessage = failure.message;
          _setState(ReportViewState.error);
        },
        (data) {
          _purchases = data;
          _setState(ReportViewState.loaded);
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to load purchases report data';
      _setState(ReportViewState.error);
    }
  }

  // --- توليد تقرير المشتريات (للتصدير) ---
  Future<void> generatePurchasesReport() async {
    _setState(ReportViewState.loading);
    try {
      await _loadColumnPreferences();

      final purchasesResultStream = _purchaseRepository.watchPurchases();
      final allPurchases = await purchasesResultStream.first.then((either) => either.getOrElse(() => []));
      
      // فلترة المشتريات
      _purchases = allPurchases.where((p) {
        final dateOk = p.createdAt.isAfter(_startDate.subtract(const Duration(days: 1))) && 
                       p.createdAt.isBefore(_endDate.add(const Duration(days: 1)));
        final supplierOk = _selectedSupplier == null || p.supplierId == _selectedSupplier!.id;
        return dateOk && supplierOk;
      }).toList();

      // جلب الدفعات إذا كان كشف حساب
      _payments = [];
      if (_purchaseReportType == PurchaseReportType.statement) {
        if (_selectedSupplier != null) {
          final paymentsResult = await _supplierRepository.getSupplierPayments(_selectedSupplier!.id);
          _payments = paymentsResult.getOrElse(() => []).where((p) {
             return p.paymentDate.isAfter(_startDate.subtract(const Duration(days: 1))) && 
                    p.paymentDate.isBefore(_endDate.add(const Duration(days: 1)));
          }).toList();
        }
      }

      _reportData = {
        'type': 'purchases',
        'sub_type': _purchaseReportType,
        'start_date': _startDate,
        'end_date': _endDate,
        'supplier': _selectedSupplier,
        'purchases': _purchases,
        'payments': _payments,
        'columns': _purchaseReportColumns.where((c) => c.isVisible).map((c) => c.id).toList(),
      };

      _setState(ReportViewState.loaded);
    } catch (e) {
      _errorMessage = 'Failed to generate purchases report';
      _setState(ReportViewState.error);
    }
  }

  // --- التقارير الأخرى ---
  
  Future<void> generateSalesReport() async {
    _setState(ReportViewState.loading);
    try {
      final distributionsResult = await _distributionRepository.getFilteredDistributions(
        startDate: _startDate,
        endDate: _endDate,
        customerId: _selectedCustomer?.id,
        productIds: _selectedProducts.map((p) => p.id).toList(),
      );

      distributionsResult.fold(
        (failure) {
          _errorMessage = failure.message;
          _setState(ReportViewState.error);
        },
        (distributions) {
          Map<String, dynamic> stats = {};
          if (_salesReportType == SalesReportType.summary) {
            stats = _calculateDistributionStats(distributions);
          } else {
            stats['distributions'] = distributions;
          }
          _reportData = {
            'type': 'sales',
            'report_type': _salesReportType,
            'start_date': _startDate,
            'end_date': _endDate,
            'customer': _selectedCustomer,
            'products': _selectedProducts,
            'stats': stats,
          };
          _setState(ReportViewState.loaded);
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to generate sales report';
      _setState(ReportViewState.error);
    }
  }

  Map<String, dynamic> _calculateDistributionStats(List<Distribution> distributions) {
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
          final filteredProducts = _selectedProducts.isEmpty
              ? products
              : products.where((p) => _selectedProducts.any((selected) => selected.id == p.id)).toList();

          double totalValue = 0;
          int lowStockCount = 0;
          for (var product in filteredProducts) {
            totalValue += product.stock * product.price;
            if (product.isLowStock) lowStockCount++;
          }
          _reportData = {
            'type': 'inventory',
            'products': filteredProducts,
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

  Future<void> generateOutstandingReport() async {
    _setState(ReportViewState.loading);
    try {
      if (_selectedCustomer != null) {
        final customerResult = await _customerRepository.getCustomerById(_selectedCustomer!.id);
        customerResult.fold(
          (failure) {
            _errorMessage = failure.message;
            _setState(ReportViewState.error);
          },
          (customer) {
            _reportData = {
              'type': 'outstanding',
              'customers': [customer],
              'total_outstanding': customer.balance,
              'customer_count': 1,
            };
            _setState(ReportViewState.loaded);
          },
        );
      } else {
        final customersResult = await _customerRepository.getAllCustomers();
        customersResult.fold(
          (failure) {
            _errorMessage = failure.message;
            _setState(ReportViewState.error);
          },
          (customers) {
            final outstandingCustomers = customers.where((c) => c.balance > 0).toList()
              ..sort((a, b) => b.balance.compareTo(a.balance));
            final totalOutstanding = outstandingCustomers.fold(0.0, (sum, customer) => sum + customer.balance);
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
        case ReportType.outstanding:
          filePath = await pdfGenerator.generateOutstandingReport(_reportData);
          break;
        case ReportType.purchases:
          filePath = await pdfGenerator.generatePurchasesReport(_reportData);
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
        case ReportType.outstanding:
          filePath = await excelGenerator.generateOutstandingReport(_reportData);
          break;
        case ReportType.purchases:
          // سيتم إضافة هذا الجزء في الخطوة التالية عند تحديث ExcelGenerator
          filePath = await excelGenerator.generatePurchasesReport(_reportData);
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

extension EitherX<L, R> on Either<L, R> {
  bool isLeft() => fold((_) => true, (_) => false);
  bool isRight() => fold((_) => false, (_) => true);
  R getOrElse(R Function() orElse) => fold((_) => orElse(), (r) => r);
}