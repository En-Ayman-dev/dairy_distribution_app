import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import '../../domain/repositories/distribution_repository.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../core/utils/pdf_generator.dart';
import '../../core/utils/excel_generator.dart';

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
  customerStatement,
  outstanding,
  productWise,
}

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

  // Getters
  ReportViewState get state => _state;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get reportData => _reportData;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  // Set date range
  void setDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  // Generate sales report
  Future<void> generateSalesReport() async {
    _setState(ReportViewState.loading);

    try {
      final statsResult = await _distributionRepository.getDistributionStats(
        _startDate,
        _endDate,
      );

      statsResult.fold(
        (failure) {
          _errorMessage = failure.message;
          _setState(ReportViewState.error);
        },
        (stats) {
          _reportData = {
            'type': 'sales',
            'start_date': _startDate,
            'end_date': _endDate,
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

  // Generate inventory report
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
          double totalValue = 0;
          int lowStockCount = 0;

          for (var product in products) {
            totalValue += product.stock * product.price;
            if (product.isLowStock) lowStockCount++;
          }

          _reportData = {
            'type': 'inventory',
            'products': products,
            'total_products': products.length,
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

  // Generate customer statement
  Future<void> generateCustomerStatement(String customerId) async {
    _setState(ReportViewState.loading);

    try {
      final customerResult = await _customerRepository.getCustomerById(customerId);
      final distributionsResult =
          await _distributionRepository.getDistributionsByCustomer(customerId);

      if (customerResult.isLeft() || distributionsResult.isLeft()) {
        _errorMessage = 'Failed to load customer data';
        _setState(ReportViewState.error);
        return;
      }

      final customer = customerResult.getOrElse(() => throw Exception());
      final distributions = distributionsResult.getOrElse(() => throw Exception());

      _reportData = {
        'type': 'customer_statement',
        'customer': customer,
        'distributions': distributions,
        'total_sales': distributions.fold(
          0.0,
          (sum, dist) => sum + dist.totalAmount,
        ),
        'total_paid': distributions.fold(
          0.0,
          (sum, dist) => sum + dist.paidAmount,
        ),
        'outstanding': customer.balance,
      };
      _setState(ReportViewState.loaded);
    } catch (e) {
      _errorMessage = 'Failed to generate customer statement';
      _setState(ReportViewState.error);
    }
  }

  // Generate outstanding report
  Future<void> generateOutstandingReport() async {
    _setState(ReportViewState.loading);

    try {
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
    } catch (e) {
      _errorMessage = 'Failed to generate outstanding report';
      _setState(ReportViewState.error);
    }
  }

  // Export to PDF
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
        case ReportType.customerStatement:
          filePath = await pdfGenerator.generateCustomerStatement(_reportData);
          break;
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

  // Export to Excel
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
        case ReportType.customerStatement:
          filePath = await excelGenerator.generateCustomerStatement(_reportData);
          break;
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