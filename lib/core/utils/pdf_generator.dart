import 'dart:io';
import 'dart:developer' as developer;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/distribution.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/entities/supplier_payment.dart';
import '../../presentation/viewmodels/report_viewmodel.dart'; // لاستيراد Enums

class PDFGenerator {
  // المتغيرات أصبحت عامة لتتمكن الكلاسات الأخرى من التحقق منها
  static pw.Font? arabicFont;
  static pw.Font? arabicBoldFont;
  static pw.Font? fallbackFont;

  // --- دوال مساعدة عامة (Static) ---

  // دالة تحميل الخطوط
  static Future<void> loadFonts() async {
    if (arabicFont == null) {
      try {
        final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
        arabicFont = pw.Font.ttf(fontData);
        developer.log('Arabic font (Regular) loaded.', name: 'PDFGenerator');
      } catch (e) {
        developer.log('Error loading Cairo-Regular', error: e, name: 'PDFGenerator');
        rethrow;
      }
    }
    
    if (arabicBoldFont == null) {
      try {
        final fontData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
        arabicBoldFont = pw.Font.ttf(fontData);
        developer.log('Arabic font (Bold) loaded.', name: 'PDFGenerator');
      } catch (e) {
        developer.log('Error loading Cairo-Bold', error: e, name: 'PDFGenerator');
        rethrow;
      }
    }
    
    if (fallbackFont == null) {
      try {
        final fontData = await rootBundle.load('assets/fonts/alfont_com_Al-Haroni-Mashnab-Salawat.ttf');
        fallbackFont = pw.Font.ttf(fontData);
        developer.log('Fallback font loaded.', name: 'PDFGenerator');
      } catch (e) {
        developer.log('Error loading fallback font', error: e, name: 'PDFGenerator');
      }
    }
  }

  // دالة الثيم العربي
  static pw.ThemeData getArabicTheme() {
    if (arabicFont == null || arabicBoldFont == null) {
      throw Exception('Fonts not loaded. Call loadFonts() first.');
    }
    return pw.ThemeData.withFont(
      base: arabicFont!,
      bold: arabicBoldFont!,
      fontFallback: [if (fallbackFont != null) fallbackFont!],
    );
  }

  // دالة حفظ الملف
  static Future<String> savePdf(pw.Document pdf, String filename) async {
    final output = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${output.path}/${filename}_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());
    developer.log('PDF saved to: ${file.path}', name: 'PDFGenerator');
    return file.path;
  }

  // ========================================================================
  // ====================       تقارير المبيعات        ====================
  // ========================================================================

  Future<String> generateSalesReport(Map<String, dynamic> reportData) async {
    await loadFonts();
    final pdf = pw.Document();

    final stats = reportData['stats'] as Map<String, dynamic>;
    final reportType = reportData['report_type'] as SalesReportType;
    final customer = reportData['customer'] as Customer?;
    final products = reportData['products'] as List<Product>;
    final startDate = reportData['start_date'] as DateTime;
    final endDate = reportData['end_date'] as DateTime;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: getArabicTheme(),
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          List<pw.Widget> widgets = [];

          // العنوان
          widgets.add(pw.Text(
            'تقرير المبيعات ${reportType == SalesReportType.detailed ? "(تفصيلي)" : "(ملخص)"}',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ));
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Text(
            'الفترة: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
            style: const pw.TextStyle(fontSize: 12),
          ));

          // الفلاتر
          if (customer != null) {
            widgets.add(pw.Text('العميل: ${customer.name}', style: const pw.TextStyle(fontSize: 12)));
          }
          if (products.isNotEmpty) {
            widgets.add(pw.Text(
                'المنتجات: ${products.map((p) => p.name).join('، ')}',
                style: const pw.TextStyle(fontSize: 12)));
          }
          widgets.add(pw.Divider());
          widgets.add(pw.SizedBox(height: 16));

          // المحتوى
          if (reportType == SalesReportType.summary) {
            widgets.addAll(_buildSummaryPage(stats));
          } else {
            final distributions = stats['distributions'] as List<Distribution>;
            widgets.addAll(_buildDetailedPage(distributions));
          }

          return widgets;
        },
      ),
    );

    return await savePdf(pdf, 'sales_report');
  }

  List<pw.Widget> _buildSummaryPage(Map<String, dynamic> stats) {
    return [
      pw.Text('ملخص الحركات',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      _buildStatRow(
          'إجمالي المبيعات', '${stats['total_sales'].toStringAsFixed(2)} '),
      _buildStatRow(
          'إجمالي المدفوع', '${stats['total_paid'].toStringAsFixed(2)} '),
      _buildStatRow(
          'إجمالي المتبقي', '${stats['total_pending'].toStringAsFixed(2)} '),
      _buildStatRow('إجمالي التوزيعات', '${stats['total_distributions']}'),
      _buildStatRow(
          'متوسط البيع', '${stats['average_sale'].toStringAsFixed(2)} '),
    ];
  }

  List<pw.Widget> _buildDetailedPage(List<Distribution> distributions) {
    if (distributions.isEmpty) {
      return [pw.Text('لا توجد حركات للفلاتر المحددة.', style: const pw.TextStyle(fontSize: 16))];
    }
    
    return [
      pw.Text('الحركات التفصيلية',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder.all(),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              _buildTableCell('التاريخ', isHeader: true),
              _buildTableCell('العميل', isHeader: true),
              _buildTableCell('المبلغ', isHeader: true),
              _buildTableCell('المدفوع', isHeader: true),
              _buildTableCell('المتبقي', isHeader: true),
              _buildTableCell('الحالة', isHeader: true),
            ],
          ),
          ...distributions.map((dist) {
            return pw.TableRow(
              children: [
                _buildTableCell(DateFormat('dd/MM/yyyy').format(dist.distributionDate)),
                _buildTableCell(dist.customerName),
                _buildTableCell(dist.totalAmount.toStringAsFixed(2)),
                _buildTableCell(dist.paidAmount.toStringAsFixed(2)),
                _buildTableCell(dist.pendingAmount.toStringAsFixed(2)),
                _buildTableCell(dist.paymentStatus.toString().split('.').last),
              ],
            );
          }),
        ],
      ),
    ];
  }

  // ========================================================================
  // ====================       تقرير المخزون          ====================
  // ========================================================================

  Future<String> generateInventoryReport(Map<String, dynamic> reportData) async {
    await loadFonts();
    final pdf = pw.Document();
    final products = reportData['products'] as List;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: getArabicTheme(),
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return [
            pw.Text(
              'تقرير المخزون',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'تاريخ الإنشاء: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Divider(),
            pw.SizedBox(height: 16),
            pw.Text('ملخص',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _buildStatRow('إجمالي المنتجات', '${reportData['total_products']}'),
            _buildStatRow('إجمالي القيمة',
                '${reportData['total_value'].toStringAsFixed(2)}'),
            _buildStatRow(
                'منتجات قارب مخزونها على النفاذ', '${reportData['low_stock_count']}'),
            pw.SizedBox(height: 24),
            pw.Text('المنتجات',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('المنتج', isHeader: true),
                    _buildTableCell('الصنف', isHeader: true),
                    _buildTableCell('المخزون', isHeader: true),
                    _buildTableCell('السعر', isHeader: true),
                    _buildTableCell('القيمة', isHeader: true),
                  ],
                ),
                ...products.map((product) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(product.name),
                      _buildTableCell(product.category.toString().split('.').last),
                      _buildTableCell('${product.stock} ${product.unit}'),
                      _buildTableCell('${product.price}'),
                      _buildTableCell(
                          '${(product.stock * product.price).toStringAsFixed(2)}'),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return await savePdf(pdf, 'inventory_report');
  }

  // ========================================================================
  // ====================       تقرير الذمم (الأرصدة)   ====================
  // ========================================================================

  Future<String> generateOutstandingReport(Map<String, dynamic> reportData) async {
    await loadFonts();
    final pdf = pw.Document();
    final customers = reportData['customers'] as List;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: getArabicTheme(),
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return [
            pw.Text(
              'تقرير الأرصدة المتبقية',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'تاريخ الإنشاء: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Divider(),
            pw.SizedBox(height: 16),
            _buildStatRow('إجمالي المتبقي',
                '${reportData['total_outstanding'].toStringAsFixed(2)}'),
            _buildStatRow(
                'عدد العملاء ذوي الرصيد', '${reportData['customer_count']}'),
            pw.SizedBox(height: 24),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('العميل', isHeader: true),
                    _buildTableCell('الهاتف', isHeader: true),
                    _buildTableCell('المبلغ المتبقي', isHeader: true),
                  ],
                ),
                ...customers.map((customer) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(customer.name),
                      _buildTableCell(customer.phone),
                      _buildTableCell('${customer.balance.toStringAsFixed(2)}'),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return await savePdf(pdf, 'outstanding_report');
  }

  // ========================================================================
  // ====================  (جديد) تقرير المشتريات  ====================
  // ========================================================================

  Future<String> generatePurchasesReport(Map<String, dynamic> reportData) async {
    await loadFonts();
    final pdf = pw.Document();

    final subType = reportData['sub_type'] as PurchaseReportType;
    final supplier = reportData['supplier'] as Supplier?;
    final purchases = reportData['purchases'] as List<Purchase>;
    final payments = reportData['payments'] as List<SupplierPayment>; // قد تكون فارغة
    final startDate = reportData['start_date'] as DateTime;
    final endDate = reportData['end_date'] as DateTime;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: getArabicTheme(),
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return [
            // --- 1. رأس التقرير ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      subType == PurchaseReportType.statement 
                          ? 'كشف حساب مورد' 
                          : 'تقرير مشتريات تفصيلي',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.Text(
                      'من: ${DateFormat('yyyy/MM/dd').format(startDate)}  إلى: ${DateFormat('yyyy/MM/dd').format(endDate)}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                // شعار أو اسم المؤسسة هنا (اختياري)
              ],
            ),
            pw.Divider(thickness: 1.5),
            pw.SizedBox(height: 10),

            // --- 2. بيانات المورد ---
            if (supplier != null)
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                  color: PdfColors.grey100,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('المورد: ${supplier.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        if (supplier.address != null) 
                          pw.Text('العنوان: ${supplier.address}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    if (supplier.contact != null)
                      pw.Text('الهاتف: ${supplier.contact}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              )
            else
              pw.Text('تقرير عام لجميع الموردين', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            
            pw.SizedBox(height: 20),

            // --- 3. جدول البيانات (حسب النوع) ---
            if (subType == PurchaseReportType.statement)
              _buildStatementTable(purchases, payments)
            else
              _buildDetailedItemsTable(purchases),
          ];
        },
      ),
    );

    return await savePdf(pdf, 'purchases_report');
  }

  // --- جدول كشف الحساب (Statement) ---
  pw.Widget _buildStatementTable(List<Purchase> purchases, List<SupplierPayment> payments) {
    // دمج القائمتين لعمل تسلسل زمني
    final combined = <dynamic>[...purchases, ...payments];
    combined.sort((a, b) {
      final dateA = a is Purchase ? a.createdAt : (a as SupplierPayment).paymentDate;
      final dateB = b is Purchase ? b.createdAt : (b as SupplierPayment).paymentDate;
      return dateA.compareTo(dateB);
    });

    double runningBalance = 0.0;
    double totalDebit = 0.0;
    double totalCredit = 0.0;

    final rows = <pw.TableRow>[
      // Header
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blue50),
        children: [
          _buildTableCell('التاريخ', isHeader: true),
          _buildTableCell('البيان / رقم الفاتورة', isHeader: true),
          _buildTableCell('مدين (فاتورة)', isHeader: true),
          _buildTableCell('دائن (سداد)', isHeader: true),
          _buildTableCell('الرصيد', isHeader: true),
        ],
      ),
    ];

    for (var item in combined) {
      String dateStr = '';
      String desc = '';
      String debit = '';
      String credit = '';
      
      if (item is Purchase) {
        dateStr = DateFormat('yyyy/MM/dd').format(item.createdAt);
        // نستخدم آخر 6 أرقام من المعرف كرقم فاتورة
        String shortId = item.id.length > 6 ? item.id.substring(0, 6).toUpperCase() : item.id;
        desc = 'فاتورة شراء #$shortId';
        
        double amount = item.totalAmount; 
        runningBalance += amount;
        totalDebit += amount;
        debit = amount.toStringAsFixed(2);
        
      } else if (item is SupplierPayment) {
        dateStr = DateFormat('yyyy/MM/dd').format(item.paymentDate);
        desc = 'سداد نقدي${item.notes != null ? " - ${item.notes}" : ""}';
        
        runningBalance -= item.amount;
        totalCredit += item.amount;
        credit = item.amount.toStringAsFixed(2);
      }

      rows.add(pw.TableRow(
        children: [
          _buildTableCell(dateStr),
          _buildTableCell(desc, alignLeft: true),
          _buildTableCell(debit),
          _buildTableCell(credit),
          _buildTableCell(runningBalance.toStringAsFixed(2), isBold: true),
        ],
      ));
    }

    // صف الإجماليات
    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _buildTableCell('الإجمالي', isHeader: true),
        _buildTableCell(''),
        _buildTableCell(totalDebit.toStringAsFixed(2), isHeader: true),
        _buildTableCell(totalCredit.toStringAsFixed(2), isHeader: true),
        _buildTableCell(runningBalance.toStringAsFixed(2), isHeader: true, color: runningBalance > 0 ? PdfColors.red : PdfColors.green),
      ],
    ));

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
      },
      children: rows,
    );
  }

  // --- جدول التفاصيل (Detailed Items) ---
  pw.Widget _buildDetailedItemsTable(List<Purchase> purchases) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blue50),
        children: [
          _buildTableCell('التاريخ', isHeader: true),
          _buildTableCell('رقم الفاتورة', isHeader: true),
          _buildTableCell('المنتج', isHeader: true),
          _buildTableCell('الكمية', isHeader: true),
          _buildTableCell('السعر', isHeader: true),
          _buildTableCell('مرتجع', isHeader: true),
          _buildTableCell('الإجمالي', isHeader: true),
        ],
      ),
    ];


    for (var purchase in purchases) {
      String dateStr = DateFormat('yyyy/MM/dd').format(purchase.createdAt);
      String shortId = purchase.id.length > 6 ? purchase.id.substring(0, 6).toUpperCase() : purchase.id;

      for (var item in purchase.items) {
        // نفترض أننا نعرض جزء من الـ ID أو الاسم إذا كان مخزناً
        // في تطبيق حقيقي يفضل تخزين اسم المنتج في PurchaseItem
        rows.add(pw.TableRow(
          children: [
            _buildTableCell(dateStr),
            _buildTableCell(shortId),
            _buildTableCell('...${item.productId.substring(0, 5)}'), 
            _buildTableCell('${item.quantity.toInt()} ${item.freeQuantity > 0 ? "+${item.freeQuantity.toInt()}" : ""}'),
            _buildTableCell(item.price.toStringAsFixed(2)),
            _buildTableCell(item.returnedQuantity > 0 ? item.returnedQuantity.toString() : '-'),
            _buildTableCell(item.total.toStringAsFixed(2)),
          ],
        ));
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
      children: rows,
    );
  }

  // --- أدوات مساعدة ---

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

  pw.Widget _buildTableCell(String text, {bool isHeader = false, bool isBold = false, bool alignLeft = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: alignLeft ? pw.TextAlign.right : pw.TextAlign.center, // RTL
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }
}