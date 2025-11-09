import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ExcelGenerator {
  Future<String> generateSalesReport(Map<String, dynamic> reportData) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sales Report'];

    // Title
    sheet.appendRow([TextCellValue('Sales Report')]);
    sheet.appendRow([
      TextCellValue(
          'Period: ${DateFormat('dd/MM/yyyy').format(reportData['start_date'])} - ${DateFormat('dd/MM/yyyy').format(reportData['end_date'])}')
    ]);
    sheet.appendRow([]);

    // Stats
    final stats = reportData['stats'] as Map<String, dynamic>;
    sheet.appendRow(
        [TextCellValue('Metric'), TextCellValue('Value')]);
    sheet.appendRow([
      TextCellValue('Total Sales'),
      TextCellValue('₹${stats['total_sales'].toStringAsFixed(2)}')
    ]);
    sheet.appendRow([
      TextCellValue('Total Paid'),
      TextCellValue('₹${stats['total_paid'].toStringAsFixed(2)}')
    ]);
    sheet.appendRow([
      TextCellValue('Total Pending'),
      TextCellValue('₹${stats['total_pending'].toStringAsFixed(2)}')
    ]);
    sheet.appendRow([
      TextCellValue('Total Distributions'),
      TextCellValue(stats['total_distributions'].toString())
    ]);
    sheet.appendRow([
      TextCellValue('Average Sale'),
      TextCellValue('₹${stats['average_sale'].toStringAsFixed(2)}')
    ]);

    return await _saveExcel(excel, 'sales_report');
  }

  Future<String> generateInventoryReport(
      Map<String, dynamic> reportData) async {
    final excel = Excel.createExcel();
    final sheet = excel['Inventory'];

    // Title
    sheet.appendRow([TextCellValue('Inventory Report')]);
    sheet.appendRow([
      TextCellValue(
          'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}')
    ]);
    sheet.appendRow([]);

    // Summary
    sheet.appendRow([TextCellValue('Summary')]);
    sheet.appendRow([
      TextCellValue('Total Products'),
      TextCellValue(reportData['total_products'].toString())
    ]);
    sheet.appendRow([
      TextCellValue('Total Value'),
      TextCellValue('₹${reportData['total_value'].toStringAsFixed(2)}')
    ]);
    sheet.appendRow([
      TextCellValue('Low Stock Items'),
      TextCellValue(reportData['low_stock_count'].toString())
    ]);
    sheet.appendRow([]);

    // Products
    sheet.appendRow([TextCellValue('Products')]);
    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Category'),
      TextCellValue('Stock'),
      TextCellValue('Unit'),
      TextCellValue('Price'),
      TextCellValue('Total Value')
    ]);

    final products = reportData['products'] as List;
    for (var product in products) {
      sheet.appendRow([
        TextCellValue(product.name),
        TextCellValue(product.category.toString().split('.').last),
        TextCellValue(product.stock.toString()),
        TextCellValue(product.unit),
        TextCellValue('₹${product.price}'),
        TextCellValue('₹${(product.stock * product.price).toStringAsFixed(2)}'),
      ]);
    }

    return await _saveExcel(excel, 'inventory_report');
  }

  Future<String> generateCustomerStatement(
      Map<String, dynamic> reportData) async {
    final excel = Excel.createExcel();
    final sheet = excel['Customer Statement'];

    final customer = reportData['customer'];

    // Title
    sheet.appendRow([TextCellValue('Customer Statement')]);
    sheet.appendRow([]);

    // Customer Info
    sheet.appendRow(
        [TextCellValue('Customer Name'), TextCellValue(customer.name)]);
    sheet.appendRow(
        [TextCellValue('Phone'), TextCellValue(customer.phone)]);
    if (customer.email != null) {
      sheet.appendRow(
          [TextCellValue('Email'), TextCellValue(customer.email)]);
    }
    sheet.appendRow([]);

    // Summary
    sheet.appendRow([TextCellValue('Summary')]);
    sheet.appendRow([
      TextCellValue('Total Sales'),
      TextCellValue('₹${reportData['total_sales'].toStringAsFixed(2)}')
    ]);
    sheet.appendRow([
      TextCellValue('Total Paid'),
      TextCellValue('₹${reportData['total_paid'].toStringAsFixed(2)}')
    ]);
    sheet.appendRow([
      TextCellValue('Outstanding'),
      TextCellValue('₹${reportData['outstanding'].toStringAsFixed(2)}')
    ]);
    sheet.appendRow([]);

    // Transactions
    sheet.appendRow([TextCellValue('Transactions')]);
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Items'),
      TextCellValue('Amount'),
      TextCellValue('Paid'),
      TextCellValue('Pending'),
      TextCellValue('Status')
    ]);

    final distributions = reportData['distributions'] as List;
    for (var dist in distributions) {
      sheet.appendRow([
        TextCellValue(DateFormat('dd/MM/yyyy').format(dist.distributionDate)),
        TextCellValue(dist.items.length.toString()),
        TextCellValue('₹${dist.totalAmount.toStringAsFixed(2)}'),
        TextCellValue('₹${dist.paidAmount.toStringAsFixed(2)}'),
        TextCellValue('₹${dist.pendingAmount.toStringAsFixed(2)}'),
        TextCellValue(dist.paymentStatus.toString().split('.').last),
      ]);
    }

    return await _saveExcel(excel, 'customer_statement_${customer.name}');
  }

  Future<String> generateOutstandingReport(
      Map<String, dynamic> reportData) async {
    final excel = Excel.createExcel();
    final sheet = excel['Outstanding'];

    // Title
    sheet.appendRow([TextCellValue('Outstanding Report')]);
    sheet.appendRow([
      TextCellValue(
          'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}')
    ]);
    sheet.appendRow([]);

    // Summary
    sheet.appendRow([
      TextCellValue('Total Outstanding'),
      TextCellValue('₹${reportData['total_outstanding'].toStringAsFixed(2)}')
    ]);
    sheet.appendRow([
      TextCellValue('Customers with Balance'),
      TextCellValue(reportData['customer_count'].toString())
    ]);
    sheet.appendRow([]);

    // Customers
    sheet.appendRow([
      TextCellValue('Customer Name'),
      TextCellValue('Phone'),
      TextCellValue('Outstanding Amount')
    ]);

    final customers = reportData['customers'] as List;
    for (var customer in customers) {
      sheet.appendRow([
        TextCellValue(customer.name),
        TextCellValue(customer.phone),
        TextCellValue('₹${customer.balance.toStringAsFixed(2)}'),
      ]);
    }

    return await _saveExcel(excel, 'outstanding_report');
  }

  Future<String> _saveExcel(Excel excel, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/${filename}_$timestamp.xlsx');

    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return file.path;
  }
}
