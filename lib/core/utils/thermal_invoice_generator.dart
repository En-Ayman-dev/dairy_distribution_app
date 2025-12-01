import 'dart:developer' as developer;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/distribution_item.dart';
import '../../presentation/widgets/print_button.dart'; // للوصول لـ PrinterSize
import 'pdf_generator.dart'; // للوصول للدوال المشتركة (الخطوط والحفظ)

class ThermalInvoiceGenerator {
  
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
      // 1. تحميل الخطوط من الكلاس المركزي
      await PDFGenerator.loadFonts();

      developer.log('Generating distribution invoice PDF (Thermal)', name: 'ThermalInvoiceGenerator');

      final pdf = pw.Document();

      // 2. حساب عرض الصفحة بناءً على الطابعة
      // تحويل عرض الطابعة من mm إلى points
      final double widthPt = (printerSize.printableWidthMm / 25.4) * PdfPageFormat.inch;
      
      developer.log(
        'Computed widthPt=$widthPt for printerSize=${printerSize.name}',
        name: 'ThermalInvoiceGenerator',
      );

      // 3. حساب ارتفاع الصفحة بشكل ديناميكي
      const double margin = 8.0;
      
      // ارتفاعات تقديرية للأقسام
      const double headerHeight = 140.0; // العنوان، التاريخ، المستخدم، العميل
      const double tableHeaderHeight = 32.0;
      const double summaryHeight = 200.0; // الإجماليات
      const double minHeight = 320.0;
      const double rowHeight = 44.0; // ارتفاع تقديري لصف المنتج الواحد

      // تقدير ارتفاع الملاحظات
      double notesHeight = 0;
      if (notes != null && notes.isNotEmpty) {
        final int notesLines = (notes.length / 35).ceil().clamp(1, 10);
        notesHeight = notesLines * 16.0;
      }

      // هامش أمان
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

      final pageFormat = PdfPageFormat(widthPt, pageHeight, marginAll: margin);

      // 4. ضبط أحجام الخطوط لتناسب العرض الصغير
      const double baseWidth = 200.0; 
      final double widthFactor = (widthPt / baseWidth).clamp(0.8, 1.2);

      final double headerFontSize = 7.0 * widthFactor;
      final double cellFontSize = 8.0 * widthFactor;

      // 5. الحسابات المالية
      final double totalAfterPaid = total - paid;
      final double totalWithPrev = totalAfterPaid + previousBalance;
      final double remaining = totalWithPrev;

      // 6. بناء الصفحة
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          theme: PDFGenerator.getArabicTheme(), // استخدام الثيم الموحد
          textDirection: pw.TextDirection.rtl,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // --- الهيدر ---
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
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'المستخدم: $createdBy',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Divider(),
                
                // --- بيانات العميل ---
                pw.Text(
                  'العميل: ${customer.name}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                if (customer.address != null && customer.address!.isNotEmpty)
                  pw.Text(
                    'العنوان: ${customer.address}',
                    style: const pw.TextStyle(fontSize: 10),
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

                // --- جدول المنتجات ---
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  children: [
                    // ترويسة الجدول
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _buildCell('المنتج', headerFontSize, isBold: true),
                        _buildCell('الكمية', headerFontSize, isBold: true),
                        _buildCell('السعر', headerFontSize, isBold: true),
                        _buildCell('الإجمالي', headerFontSize, isBold: true),
                      ],
                    ),
                    // صفوف المنتجات
                    ...items.map(
                      (item) => pw.TableRow(
                        children: [
                          _buildCell(item.productName, cellFontSize),
                          _buildCell(item.quantity.toString(), cellFontSize),
                          _buildCell(item.price.toStringAsFixed(2), cellFontSize),
                          _buildCell((item.quantity * item.price).toStringAsFixed(2), cellFontSize),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 4),
                pw.Divider(),

                // --- الملخص المالي ---
                _buildSummaryRow('المدفوع', '${paid.toStringAsFixed(2)} '),
                _buildSummaryRow('إجمالي الفاتورة', '${totalAfterPaid.toStringAsFixed(2)} '),
                _buildSummaryRow('الرصيد السابق', '${previousBalance.toStringAsFixed(2)} '),
                _buildSummaryRow('الإجمالي مع الرصيد', '${totalWithPrev.toStringAsFixed(2)} '),
                _buildSummaryRow('المتبقي', '${remaining.toStringAsFixed(2)} ', isBold: true),

                // --- الملاحظات ---
                if (notes != null && notes.isNotEmpty) ...[
                  pw.Divider(),
                  pw.Text(
                    'ملاحظات: $notes',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
                
                pw.SizedBox(height: 4),
                pw.Divider(),
              ],
            );
          },
        ),
      );

      // 7. الحفظ باستخدام الدالة المركزية
      final savedPath = await PDFGenerator.savePdf(pdf, 'distribution_invoice');
      
      developer.log('Saved distribution invoice to $savedPath', name: 'ThermalInvoiceGenerator');
      return savedPath;

    } catch (e, st) {
      developer.log(
        'Failed to generate distribution invoice: $e\n$st',
        name: 'ThermalInvoiceGenerator',
        error: e,
      );
      rethrow;
    }
  }

  // --- دوال مساعدة داخلية للترتيب ---

  pw.Widget _buildCell(String text, double fontSize, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.right,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}