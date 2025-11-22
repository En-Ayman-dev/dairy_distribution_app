  
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
import 'package:dairy_distribution_app/domain/entities/distribution_item.dart';
import '../../presentation/widgets/print_button.dart';
import '../../presentation/viewmodels/report_viewmodel.dart' show SalesReportType;

class PDFGenerator {
  // متغير ثابت لتخزين الخط العربي بعد تحميله
  static pw.Font? _arabicFont;
  // --- إضافة جديدة: متغير للخط العريض ---
  static pw.Font? _arabicBoldFont;
  static pw.Font? _fallbackFont;

  // دالة لتحميل الخط من الأصول (Assets)
  Future<void> _loadFont() async {
    // (*** تم تعديل هذه الدالة ***)
    
    // تحميل الخط العادي (إذا لم يتم تحميله)
    if (_arabicFont == null) {
      developer.log('Loading Arabic font (Regular)...', name: 'PDFGenerator');
      try {
        final fontData =
            await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
        _arabicFont = pw.Font.ttf(fontData);
        developer.log('Arabic font (Regular) loaded successfully.', name: 'PDFGenerator');
      } catch (e) {
        developer.log('*** خطأ فادح: لم يتم العثور على الخط Cairo-Regular.ttf ***',
            name: 'PDFGenerator', error: e);
        rethrow;
      }
    }
    
    // تحميل الخط العريض (إذا لم يتم تحميله)
    if (_arabicBoldFont == null) {
      developer.log('Loading Arabic font (Bold)...', name: 'PDFGenerator');
      try {
        final fontData =
            await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
        _arabicBoldFont = pw.Font.ttf(fontData);
        developer.log('Arabic font (Bold) loaded successfully.', name: 'PDFGenerator');
      } catch (e) {
        developer.log('*** خطأ فادح: لم يتم العثور على الخط Cairo-Bold.ttf ***',
            name: 'PDFGenerator', error: e);
        developer.log(
            'تأكد من تحميل ملف "Cairo-Bold.ttf" ووضعه في "assets/fonts/"',
            name: 'PDFGenerator');
        rethrow;
      }
    }
    if (_fallbackFont == null) {
      developer.log('Loading Fallback font (NotoSans)...', name: 'PDFGenerator');
      try {
        final fontData =
            await rootBundle.load('assets/fonts/alfont_com_Al-Haroni-Mashnab-Salawat.ttf');
        _fallbackFont = pw.Font.ttf(fontData);
        developer.log('Fallback font (alfont_com_Al-Haroni-Mashnab-Salawat) loaded successfully.', name: 'PDFGenerator');
      } catch (e) {
        developer.log('*** خطأ فادح: لم يتم العثور على الخط alfont_com_Al-Haroni-Mashnab-Salawat.ttf ***',
            name: 'PDFGenerator', error: e);
        // يمكنك اختيار عدم إيقاف التطبيق هنا إذا كان الخط الاحتياطي اختيارياً
      }
    }
  }

  // دالة لتطبيق الثيم العربي واتجاه النص
  pw.ThemeData _getArabicTheme() {
    // (*** تم تعديل هذه الدالة ***)
    if (_arabicFont == null || _arabicBoldFont == null) {
      throw Exception(
          'Arabic fonts are not loaded. Call _loadFont() first.');
    }
    
    // بدلاً من .withFont()، نستخدم المُنشئ الافتراضي
    // لربط الخط العادي والخط العريض
    return pw.ThemeData.withFont(
      base: _arabicFont!,
      bold: _arabicBoldFont!,
      fontFallback: [ if (_fallbackFont != null) _fallbackFont! ],
      // يمكنك أيضاً إضافة خطوط للمائل والمائل العريض إذا أردت
      // italic: _arabicItalicFont,
      // boldItalic: _arabicBoldItalicFont,
    );
  }

  // (*** باقي دوال إنشاء التقارير تبقى كما هي تماماً ***)
  // (generateSalesReport, _buildSummaryPage, _buildDetailedPage, ...)
  // (generateInventoryReport, generateOutstandingReport, ...)
  // ( _buildStatRow, _buildTableCell, _savePdf ...)

  // ... (generateSalesReport) ...
  Future<String> generateSalesReport(Map<String, dynamic> reportData) async {
    await _loadFont(); // التأكد من تحميل الخط أولاً
    final pdf = pw.Document();

    // 1. استخراج البيانات الجديدة من الخريطة
    final stats = reportData['stats'] as Map<String, dynamic>;
    final reportType = reportData['report_type'] as SalesReportType;
    final customer = reportData['customer'] as Customer?;
    final products = reportData['products'] as List<Product>;
    final startDate = reportData['start_date'] as DateTime;
    final endDate = reportData['end_date'] as DateTime;

    // 2. استخدام MultiPage لأنه قد يكون هناك جدول طويل
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: _getArabicTheme(), // (تم تعديل هذه الدالة)
        textDirection: pw.TextDirection.rtl, // تفعيل RTL
        build: (context) {
          List<pw.Widget> widgets = [];

          // 3. إضافة العناوين ومعلومات الفلاتر
          widgets.add(pw.Text(
            'تقرير المبيعات ${reportType == SalesReportType.detailed ? "(تفصيلي)" : "(ملخص)"}',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ));
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Text(
            'الفترة: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
            style: pw.TextStyle(fontSize: 12),
          ));

          // 4. عرض الفلاتر المطبقة (العميل والمنتجات)
          if (customer != null) {
            widgets.add(pw.Text('العميل: ${customer.name}',
                style: pw.TextStyle(fontSize: 12)));
          }
          if (products.isNotEmpty) {
            widgets.add(pw.Text(
                'المنتجات: ${products.map((p) => p.name).join('، ')}',
                style: pw.TextStyle(fontSize: 12)));
          }
          widgets.add(pw.Divider());
          widgets.add(pw.SizedBox(height: 16));

          // 5. بناء المحتوى (ملخص أو تفصيلي)
          if (reportType == SalesReportType.summary) {
            // --- بناء الملخص (المنطق القديم) ---
            widgets.addAll(_buildSummaryPage(stats));
          } else {
            // --- بناء التقرير التفصيلي (المنطق الجديد) ---
            final distributions = stats['distributions'] as List<Distribution>;
            widgets.addAll(_buildDetailedPage(distributions));
          }

          return widgets;
        },
      ),
    );

    return await _savePdf(pdf, 'sales_report');
  }

  // --- دالة مساعدة جديدة لبناء صفحة الملخص ---
  List<pw.Widget> _buildSummaryPage(Map<String, dynamic> stats) {
    return [
      pw.Text('ملخص الحركات',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      _buildStatRow(
          'إجمالي المبيعات', '${stats['total_sales'].toStringAsFixed(2)} '), // <-- تم التعديل
      _buildStatRow(
          'إجمالي المدفوع', '${stats['total_paid'].toStringAsFixed(2)} '),
      _buildStatRow(
          'إجمالي المتبقي', '${stats['total_pending'].toStringAsFixed(2)} '),
      _buildStatRow('إجمالي التوزيعات', '${stats['total_distributions']}'),
      _buildStatRow(
          'متوسط البيع', '${stats['average_sale'].toStringAsFixed(2)} '),
    ];
  }

  // --- دالة مساعدة جديدة لبناء صفحة التقرير التفصيلي ---
  List<pw.Widget> _buildDetailedPage(List<Distribution> distributions) {
    if (distributions.isEmpty) {
      return [pw.Text('لا توجد حركات للفلاتر المحددة.', style: pw.TextStyle(fontSize: 16))];
    }
    
    return [
      pw.Text('الحركات التفصيلية',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder.all(),
        children: [
          // 1. عناوين الجدول
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
          // 2. صفوف البيانات
          ...distributions.map((dist) {
            return pw.TableRow(
              children: [
                _buildTableCell(
                    DateFormat('dd/MM/yyyy').format(dist.distributionDate)),
                // نفترض أن localDataSource أضاف customerName للـ entity
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

  Future<String> generateInventoryReport(Map<String, dynamic> reportData) async {
    await _loadFont(); // التأكد من تحميل الخط أولاً
    final pdf = pw.Document();
    final products = reportData['products'] as List;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: _getArabicTheme(),
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
              style: pw.TextStyle(fontSize: 12),
            ),
            pw.Divider(),
            pw.SizedBox(height: 16),
            pw.Text('ملخص',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _buildStatRow('إجمالي المنتجات', '${reportData['total_products']}'),
            _buildStatRow('إجمالي القيمة',
                '${reportData['total_value'].toStringAsFixed(2)}'),
            _buildStatRow(
                'منتجات قارب مخزونها على النفاذ', '${reportData['low_stock_count']}'),
            pw.SizedBox(height: 24),
            pw.Text('المنتجات',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
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
                      _buildTableCell(
                          product.category.toString().split('.').last),
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

    return await _savePdf(pdf, 'inventory_report');
  }


  Future<String> generateOutstandingReport(
      Map<String, dynamic> reportData) async {
    await _loadFont(); // التأكد من تحميل الخط أولاً
    final pdf = pw.Document();
    final customers = reportData['customers'] as List;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: _getArabicTheme(),
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
              style: pw.TextStyle(fontSize: 12),
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
                      _buildTableCell(
                          '${customer.balance.toStringAsFixed(2)}'),
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
          pw.Text(label, style: pw.TextStyle(fontSize: 14)),
          pw.Text(value,
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.right,
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
  }/// توليد فاتورة توزيع (مقاس حراري)
/// توليد فاتورة توزيع (مقاس حراري)
Future<String> generateDistributionInvoice({
  required Customer customer,
  required List<DistributionItem> items,
  required double total,
  required double paid,
  required double previousBalance,
  required DateTime dateTime,
  required String createdBy,
  required PrinterSize printerSize,
  String? notes,
}) async {
  try {
    await _loadFont();

    developer.log('Generating distribution invoice PDF', name: 'PDFGenerator');

    final pdf = pw.Document();

    // تحويل عرض الطابعة من mm إلى points
    final double widthPt =
        (printerSize.printableWidthMm / 25.4) * PdfPageFormat.inch;
    developer.log(
      'Computed widthPt=$widthPt for printerSize=${printerSize.name}',
      name: 'PDFGenerator',
    );

    // ---------------- حساب ارتفاع الصفحة بشكل ديناميكي وآمن ----------------

    const double margin = 8.0;

    // أجزاء ثابتة تقريباً (الهيدر + الإجماليات + الفوتر)
    const double headerHeight = 140.0; // عنوان، تاريخ، مستخدم، بيانات عميل
    const double tableHeaderHeight = 32.0;
    // زيادة الملخص لتجنب القطع
    const double summaryHeight = 200.0; // إجماليات + متبقي إلخ
    const double minHeight = 320.0;

    // ارتفاع تقديري لكل صف منتج (اجعلها محافظة)
    const double rowHeight = 44.0;

    // تقدير ارتفاع الملاحظات إن وجدت
    double notesHeight = 0;
    if (notes != null && notes.isNotEmpty) {
      final int notesLines = (notes.length / 35).ceil().clamp(1, 10);
      notesHeight = notesLines * 16.0;
    }

    // هامش احتياطي إضافي لضمان عدم القطع
    const double extraBuffer = 80.0;

    final double estimatedContentHeight = headerHeight +
        tableHeaderHeight +
        (items.length * rowHeight) +
        summaryHeight +
        notesHeight +
        extraBuffer;

    final double pageHeight = (estimatedContentHeight + margin * 2) < minHeight
        ? minHeight
        : (estimatedContentHeight + margin * 2);

    developer.log(
      'PDFGenerator: items=${items.length}, '
      'estimatedContentHeight=$estimatedContentHeight, '
      'pageHeight=$pageHeight, widthPt=$widthPt',
      name: 'PDFGenerator',
    );

    final pageFormat = PdfPageFormat(widthPt, pageHeight, marginAll: margin);

    // ---------------- أحجام الخطوط في جدول المنتجات ----------------

    const double baseWidth = 200.0; // عرض مرجعي تقديري
    final double widthFactor =
        (widthPt / baseWidth).clamp(0.8, 1.2); // منع المبالغة

    final double headerFontSize = 7.0 * widthFactor;
    final double cellFontSize = 8.0 * widthFactor;

    developer.log(
      'PDFGenerator: widthFactor=$widthFactor, headerFontSize=$headerFontSize, cellFontSize=$cellFontSize',
      name: 'PDFGenerator',
    );

    // ---------------- الحسابات المالية كما هي ----------------

    final double totalAfterPaid = total - paid;
    final double totalWithPrev = totalAfterPaid + previousBalance;
    final double remaining = totalWithPrev;

    // Use a single Page sized to the estimated content so totals never move to a new page
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        theme: _getArabicTheme(),
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // header
              pw.Text(
                'فاتورة توزيع',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'التاريخ: ${DateFormat('yyyy/MM/dd – HH:mm').format(dateTime)}',
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'المستخدم: $createdBy',
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.Divider(),
              pw.Text(
                'العميل: ${customer.name}',
                style: pw.TextStyle(fontSize: 12),
              ),
              if (customer.address != null && customer.address!.isNotEmpty)
                pw.Text(
                  'العنوان: ${customer.address}',
                  style: pw.TextStyle(fontSize: 10),
                ),
              pw.SizedBox(height: 4),
              pw.Divider(),

              pw.Text(
                'تفاصيل المنتجات:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              // table
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'المنتج',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: headerFontSize,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'الكمية',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: headerFontSize,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'السعر',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: headerFontSize,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'الإجمالي',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: headerFontSize,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...items.map(
                    (item) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            item.productName,
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(fontSize: cellFontSize),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            item.quantity.toString(),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(fontSize: cellFontSize),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            item.price.toStringAsFixed(2),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(fontSize: cellFontSize),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            (item.quantity * item.price).toStringAsFixed(2),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(fontSize: cellFontSize),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 4),
              pw.Divider(),

              // totals
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'المدفوع',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      '${paid.toStringAsFixed(2)} ',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'إجمالي الفاتورة',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      '${totalAfterPaid.toStringAsFixed(2)} ',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'الرصيد السابق',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      '${previousBalance.toStringAsFixed(2)} ',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'الإجمالي مع الرصيد',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      '${totalWithPrev.toStringAsFixed(2)} ',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'المتبقي',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      '${remaining.toStringAsFixed(2)} ',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              if (notes != null && notes.isNotEmpty) ...[
                pw.Divider(),
                pw.Text(
                  'ملاحظات: $notes',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
              pw.SizedBox(height: 4),
              pw.Divider(),
            ],
          );
        },
      ),
    );

    final savedPath = await _savePdf(pdf, 'distribution_invoice');
    developer.log(
      'Saved distribution invoice to $savedPath',
      name: 'PDFGenerator',
    );
    return savedPath;
  } catch (e, st) {
    developer.log(
      'Failed to generate distribution invoice: $e\n$st',
      name: 'PDFGenerator',
      error: e,
    );
    rethrow;
  }
}
}