import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PDFGenerator {
  Future<String> generateSalesReport(Map<String, dynamic> reportData) async {
    final pdf = pw.Document();
    final stats = reportData['stats'] as Map<String, dynamic>;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Sales Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Period: ${DateFormat('dd/MM/yyyy').format(reportData['start_date'])} - ${DateFormat('dd/MM/yyyy').format(reportData['end_date'])}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Divider(),
              pw.SizedBox(height: 16),
              _buildStatRow('Total Sales', '₹${stats['total_sales'].toStringAsFixed(2)}'),
              _buildStatRow('Total Paid', '₹${stats['total_paid'].toStringAsFixed(2)}'),
              _buildStatRow('Total Pending', '₹${stats['total_pending'].toStringAsFixed(2)}'),
              _buildStatRow('Total Distributions', '${stats['total_distributions']}'),
              _buildStatRow('Average Sale', '₹${stats['average_sale'].toStringAsFixed(2)}'),
            ],
          );
        },
      ),
    );

    return await _savePdf(pdf, 'sales_report');
  }

  Future<String> generateInventoryReport(Map<String, dynamic> reportData) async {
    final pdf = pw.Document();
    final products = reportData['products'] as List;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text(
              'Inventory Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Divider(),
            pw.SizedBox(height: 16),
            pw.Text('Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _buildStatRow('Total Products', '${reportData['total_products']}'),
            _buildStatRow('Total Value', '₹${reportData['total_value'].toStringAsFixed(2)}'),
            _buildStatRow('Low Stock Items', '${reportData['low_stock_count']}'),
            pw.SizedBox(height: 24),
            pw.Text('Products', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('Product', isHeader: true),
                    _buildTableCell('Category', isHeader: true),
                    _buildTableCell('Stock', isHeader: true),
                    _buildTableCell('Price', isHeader: true),
                    _buildTableCell('Value', isHeader: true),
                  ],
                ),
                ...products.map((product) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(product.name),
                      _buildTableCell(product.category.toString().split('.').last),
                      _buildTableCell('${product.stock} ${product.unit}'),
                      _buildTableCell('₹${product.price}'),
                      _buildTableCell('₹${(product.stock * product.price).toStringAsFixed(2)}'),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return await _savePdf(pdf, 'inventory_report');
  }

  Future<String> generateCustomerStatement(Map<String, dynamic> reportData) async {
    final pdf = pw.Document();
    final customer = reportData['customer'];
    final distributions = reportData['distributions'] as List;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text(
              'Customer Statement',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Customer: ${customer.name}', style: const pw.TextStyle(fontSize: 16)),
            pw.Text('Phone: ${customer.phone}', style: const pw.TextStyle(fontSize: 14)),
            if (customer.email != null)
              pw.Text('Email: ${customer.email}', style: const pw.TextStyle(fontSize: 14)),
            pw.Divider(),
            pw.SizedBox(height: 16),
            pw.Text('Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _buildStatRow('Total Sales', '₹${reportData['total_sales'].toStringAsFixed(2)}'),
            _buildStatRow('Total Paid', '₹${reportData['total_paid'].toStringAsFixed(2)}'),
            _buildStatRow('Outstanding', '₹${reportData['outstanding'].toStringAsFixed(2)}'),
            pw.SizedBox(height: 24),
            pw.Text('Transactions', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('Date', isHeader: true),
                    _buildTableCell('Items', isHeader: true),
                    _buildTableCell('Amount', isHeader: true),
                    _buildTableCell('Paid', isHeader: true),
                    _buildTableCell('Status', isHeader: true),
                  ],
                ),
                ...distributions.map((dist) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(DateFormat('dd/MM/yyyy').format(dist.distributionDate)),
                      _buildTableCell('${dist.items.length}'),
                      _buildTableCell('₹${dist.totalAmount.toStringAsFixed(2)}'),
                      _buildTableCell('₹${dist.paidAmount.toStringAsFixed(2)}'),
                      _buildTableCell(dist.paymentStatus.toString().split('.').last),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return await _savePdf(pdf, 'customer_statement_${customer.name}');
  }

  Future<String> generateOutstandingReport(Map<String, dynamic> reportData) async {
    final pdf = pw.Document();
    final customers = reportData['customers'] as List;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text(
              'Outstanding Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Divider(),
            pw.SizedBox(height: 16),
            _buildStatRow('Total Outstanding', '₹${reportData['total_outstanding'].toStringAsFixed(2)}'),
            _buildStatRow('Customers with Balance', '${reportData['customer_count']}'),
            pw.SizedBox(height: 24),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('Customer', isHeader: true),
                    _buildTableCell('Phone', isHeader: true),
                    _buildTableCell('Outstanding', isHeader: true),
                  ],
                ),
                ...customers.map((customer) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(customer.name),
                      _buildTableCell(customer.phone),
                      _buildTableCell('₹${customer.balance.toStringAsFixed(2)}'),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return await _savePdf(pdf, 'outstanding_report');
  }

  pw.Widget _buildStatRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<String> _savePdf(pw.Document pdf, String filename) async {
    final output = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${output.path}/${filename}_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}