import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

// --- الاستيرادات الجديدة ---
import '../../domain/entities/purchase.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/entities/supplier_payment.dart';
import '../../presentation/viewmodels/report_viewmodel.dart'; // لاستيراد Enums

class ExcelGenerator {
  // ... (الدوال السابقة generateSalesReport وغيرها تبقى كما هي، سأعيد كتابتها هنا ليكون الملف كاملاً) ...

  Future<String> generateSalesReport(Map<String, dynamic> reportData) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sales Report'];
    sheet.isRTL = true; // تفعيل الاتجاه من اليمين لليسار

    // Title
    sheet.appendRow([TextCellValue('تقرير المبيعات')]);
    sheet.appendRow([
      TextCellValue(
          'الفترة: ${DateFormat('dd/MM/yyyy').format(reportData['start_date'])} - ${DateFormat('dd/MM/yyyy').format(reportData['end_date'])}')
    ]);
    sheet.appendRow([]);

    // Stats
    final stats = reportData['stats'] as Map<String, dynamic>;
    sheet.appendRow([TextCellValue('المقياس'), TextCellValue('القيمة')]);
    sheet.appendRow([
      TextCellValue('إجمالي المبيعات'),
      TextCellValue('${stats['total_sales'].toStringAsFixed(2)}')
    ]);
    sheet.appendRow([
      TextCellValue('إجمالي المدفوع'),
      TextCellValue('${stats['total_paid'].toStringAsFixed(2)}')
    ]);
    sheet.appendRow([
      TextCellValue('إجمالي المتبقي'),
      TextCellValue('${stats['total_pending'].toStringAsFixed(2)}')
    ]);
    sheet.appendRow([
      TextCellValue('عدد التوزيعات'),
      TextCellValue(stats['total_distributions'].toString())
    ]);
    sheet.appendRow([
      TextCellValue('متوسط البيع'),
      TextCellValue('${stats['average_sale'].toStringAsFixed(2)}')
    ]);

    return await _saveExcel(excel, 'sales_report');
  }

  Future<String> generateInventoryReport(Map<String, dynamic> reportData) async {
    final excel = Excel.createExcel();
    final sheet = excel['Inventory'];
    sheet.isRTL = true;

    // Title
    sheet.appendRow([TextCellValue('تقرير المخزون')]);
    sheet.appendRow([
      TextCellValue(
          'تاريخ الإنشاء: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}')
    ]);
    sheet.appendRow([]);

    // Summary
    sheet.appendRow([TextCellValue('ملخص')]);
    sheet.appendRow([
      TextCellValue('إجمالي المنتجات'),
      TextCellValue(reportData['total_products'].toString())
    ]);
    sheet.appendRow([
      TextCellValue('إجمالي القيمة'),
      TextCellValue('${reportData['total_value'].toStringAsFixed(2)}')
    ]);
    sheet.appendRow([
      TextCellValue('منتجات منخفضة المخزون'),
      TextCellValue(reportData['low_stock_count'].toString())
    ]);
    sheet.appendRow([]);

    // Products
    sheet.appendRow([TextCellValue('المنتجات')]);
    sheet.appendRow([
      TextCellValue('الاسم'),
      TextCellValue('الفئة'),
      TextCellValue('المخزون'),
      TextCellValue('الوحدة'),
      TextCellValue('السعر'),
      TextCellValue('القيمة الإجمالية')
    ]);

    final products = reportData['products'] as List;
    for (var product in products) {
      sheet.appendRow([
        TextCellValue(product.name),
        TextCellValue(product.category.toString().split('.').last),
        TextCellValue(product.stock.toString()),
        TextCellValue(product.unit),
        TextCellValue('${product.price}'),
        TextCellValue('${(product.stock * product.price).toStringAsFixed(2)}'),
      ]);
    }

    return await _saveExcel(excel, 'inventory_report');
  }

  // (تم حذف generateCustomerStatement لأنه لم يعد مستخدماً في الـ ViewModel الجديد)

  Future<String> generateOutstandingReport(Map<String, dynamic> reportData) async {
    final excel = Excel.createExcel();
    final sheet = excel['Outstanding'];
    sheet.isRTL = true;

    // Title
    sheet.appendRow([TextCellValue('تقرير الأرصدة المتبقية (الذمم)')]);
    sheet.appendRow([
      TextCellValue(
          'تاريخ الإنشاء: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}')
    ]);
    sheet.appendRow([]);

    // Summary
    sheet.appendRow([
      TextCellValue('إجمالي الأرصدة'),
      TextCellValue('${reportData['total_outstanding'].toStringAsFixed(2)}')
    ]);
    sheet.appendRow([
      TextCellValue('عدد العملاء'),
      TextCellValue(reportData['customer_count'].toString())
    ]);
    sheet.appendRow([]);

    // Customers
    sheet.appendRow([
      TextCellValue('العميل'),
      TextCellValue('رقم الهاتف'),
      TextCellValue('المبلغ المتبقي')
    ]);

    final customers = reportData['customers'] as List;
    for (var customer in customers) {
      sheet.appendRow([
        TextCellValue(customer.name),
        TextCellValue(customer.phone),
        TextCellValue('${customer.balance.toStringAsFixed(2)}'),
      ]);
    }

    return await _saveExcel(excel, 'outstanding_report');
  }

  // ========================================================================
  // ====================  (جديد) تقرير المشتريات  ====================
  // ========================================================================

  Future<String> generatePurchasesReport(Map<String, dynamic> reportData) async {
    final excel = Excel.createExcel();
    final sheet = excel['Purchases Report'];
    sheet.isRTL = true; // تفعيل اتجاه اليمين لليسار

    final subType = reportData['sub_type'] as PurchaseReportType;
    final supplier = reportData['supplier'] as Supplier?;
    final purchases = reportData['purchases'] as List<Purchase>;
    final payments = reportData['payments'] as List<SupplierPayment>;
    final startDate = reportData['start_date'] as DateTime;
    final endDate = reportData['end_date'] as DateTime;

    // --- 1. رأس التقرير ---
    sheet.appendRow([
      TextCellValue(subType == PurchaseReportType.statement
          ? 'كشف حساب مورد'
          : 'تقرير مشتريات تفصيلي')
    ]);
    sheet.appendRow([
      TextCellValue(
          'من: ${DateFormat('yyyy/MM/dd').format(startDate)}  إلى: ${DateFormat('yyyy/MM/dd').format(endDate)}')
    ]);

    if (supplier != null) {
      sheet.appendRow([TextCellValue('المورد: ${supplier.name}')]);
      if (supplier.contact != null) {
        sheet.appendRow([TextCellValue('الهاتف: ${supplier.contact}')]);
      }
    } else {
      sheet.appendRow([TextCellValue('تقرير عام لجميع الموردين')]);
    }
    sheet.appendRow([]); // سطر فارغ

    // --- 2. جدول البيانات ---

    if (subType == PurchaseReportType.statement) {
      // --- كشف حساب (Statement) ---
      
      // العناوين
      sheet.appendRow([
        TextCellValue('التاريخ'),
        TextCellValue('البيان / رقم الفاتورة'),
        TextCellValue('مدين (فاتورة)'),
        TextCellValue('دائن (سداد)'),
        TextCellValue('الرصيد'),
      ]);

      // دمج وترتيب البيانات
      final combined = <dynamic>[...purchases, ...payments];
      combined.sort((a, b) {
        final dateA = a is Purchase ? a.createdAt : (a as SupplierPayment).paymentDate;
        final dateB = b is Purchase ? b.createdAt : (b as SupplierPayment).paymentDate;
        return dateA.compareTo(dateB);
      });

      double runningBalance = 0.0;
      double totalDebit = 0.0;
      double totalCredit = 0.0;

      for (var item in combined) {
        String dateStr = '';
        String desc = '';
        String debit = '';
        String credit = '';

        if (item is Purchase) {
          dateStr = DateFormat('yyyy/MM/dd').format(item.createdAt);
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

        sheet.appendRow([
          TextCellValue(dateStr),
          TextCellValue(desc),
          TextCellValue(debit),
          TextCellValue(credit),
          TextCellValue(runningBalance.toStringAsFixed(2)),
        ]);
      }

      // صف الإجماليات
      sheet.appendRow([]);
      sheet.appendRow([
        TextCellValue('الإجمالي'),
        TextCellValue(''),
        TextCellValue(totalDebit.toStringAsFixed(2)),
        TextCellValue(totalCredit.toStringAsFixed(2)),
        TextCellValue(runningBalance.toStringAsFixed(2)),
      ]);

    } else {
      // --- تقرير تفصيلي (Detailed) ---

      // العناوين
      sheet.appendRow([
        TextCellValue('التاريخ'),
        TextCellValue('رقم الفاتورة'),
        TextCellValue('المنتج'),
        TextCellValue('الكمية'),
        TextCellValue('السعر'),
        TextCellValue('مرتجع'),
        TextCellValue('الإجمالي'),
      ]);

      double grandTotal = 0.0;

      for (var purchase in purchases) {
        String dateStr = DateFormat('yyyy/MM/dd').format(purchase.createdAt);
        String shortId = purchase.id.length > 6 ? purchase.id.substring(0, 6).toUpperCase() : purchase.id;

        for (var item in purchase.items) {
          sheet.appendRow([
            TextCellValue(dateStr),
            TextCellValue(shortId),
            TextCellValue(item.productId.substring(0, 5)), // يمكن تحسينه بجلب الاسم
            TextCellValue('${item.quantity.toInt()} ${item.freeQuantity > 0 ? "+${item.freeQuantity.toInt()}" : ""}'),
            TextCellValue(item.price.toStringAsFixed(2)),
            TextCellValue(item.returnedQuantity > 0 ? item.returnedQuantity.toString() : '-'),
            TextCellValue(item.total.toStringAsFixed(2)),
          ]);
        }
        grandTotal += purchase.totalAmount;
      }

      // الإجمالي الكلي
      sheet.appendRow([]);
      sheet.appendRow([
        TextCellValue('الإجمالي الكلي للفواتير'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(grandTotal.toStringAsFixed(2)),
      ]);
    }

    return await _saveExcel(excel, 'purchases_report');
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