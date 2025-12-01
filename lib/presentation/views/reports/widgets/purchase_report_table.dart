import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../viewmodels/report_viewmodel.dart';
import '../../../viewmodels/supplier_viewmodel.dart';

// ملاحظة: نحتاج لتعريف ReportColumn و PurchaseReportType هنا أو التأكد من استيرادهما
// نفترض أنهما موجودان في ReportViewModel أو ملف منفصل مشترك.
// لتجنب الأخطاء، سنبقي دالة _getLocalizedLabel في الملف الرئيسي مؤقتاً أو نفترض وجودها في مكان مركزي.

class PurchaseReportTable extends StatelessWidget {
  const PurchaseReportTable({super.key});

  String _getLocalizedLabel(BuildContext context, String key) {
    // تم نقل هذه الدالة من الملف الأصلي لتبقى منطقية بجوار الجدول
    final loc = AppLocalizations.of(context)!;
    switch (key) {
      case 'colSupplier': return loc.colSupplier;
      case 'colDate': return loc.colDate;
      case 'colItemsCount': return loc.colItemsCount;
      case 'colTotalAmount': return loc.colTotalAmount;
      case 'colDiscount': return loc.colDiscount;
      case 'colNetTotal': return loc.colNetTotal;
      case 'colInvoiceNum': return loc.colInvoiceNum;
      case 'colProduct': return loc.colProduct;
      case 'colQty': return loc.colQty;
      case 'colFreeQty': return loc.freeQuantityLabel.replaceAll(RegExp(r'\(.*\)'), '').trim();
      case 'colPrice': return loc.colPrice;
      case 'colReturnedQty': return loc.colReturnedQty;
      case 'colDebit': return loc.colDebit;
      case 'colCredit': return loc.colCredit;
      case 'colBalance': return loc.colBalance;
      default: return key;
    }
  }

  String _getSupplierName(BuildContext context, String supplierId) {
    final localizations = AppLocalizations.of(context)!;
    final suppliers = context.read<SupplierViewModel>().suppliers;
    final supplier = suppliers.where((s) => s.id == supplierId).firstOrNull;
    return supplier?.name ?? localizations.unknownSupplier;
  }

  List<DataRow> _buildRows(
      BuildContext context,
      ReportViewModel vm,
      List<ReportColumn> visibleCols,
  ) {
    // منطق بناء الصفوف مع حساب الرصيد الجاري كما في الكود الأصلي
    if (vm.purchaseReportType == PurchaseReportType.statement) {
      final payments = vm.reportData['payments'] as List? ?? [];
      final combined = <dynamic>[...vm.purchases, ...payments];
      combined.sort((a, b) {
        final dateA = a.runtimeType.toString().contains('Purchase') ? a.createdAt : a.paymentDate;
        final dateB = b.runtimeType.toString().contains('Purchase') ? b.createdAt : b.paymentDate;
        return dateA.compareTo(dateB);
      });

      double runningBalance = 0.0;
      int index = 0;

      return combined.map((item) {
        index++;
        final isEven = index % 2 == 0;
        final rowColor = isEven ? Colors.white : Colors.grey[50];

        return DataRow(
          color: MaterialStateProperty.all(rowColor),
          cells: visibleCols.map((col) {
            String cellValue = '';
            bool isBold = false;
            Color? textColor;
            
            // Simplified item type check for refactoring stability
            final isPurchase = item.runtimeType.toString().contains('Purchase');

            if (isPurchase) {
              final p = item;
              switch (col.id) {
                case 'date': cellValue = DateFormat('yyyy-MM-dd').format(p.createdAt); break;
                case 'invoice_num': cellValue = p.id.substring(0, 6).toUpperCase(); break;
                case 'debit': cellValue = p.totalAmount.toStringAsFixed(2); runningBalance += p.totalAmount; break;
                case 'credit': cellValue = '-'; break;
                case 'balance': cellValue = runningBalance.toStringAsFixed(2); isBold = true; break;
                case 'supplier': cellValue = _getSupplierName(context, p.supplierId); break;
                default: cellValue = '-';
              }
            } else {
              final pay = item;
              switch (col.id) {
                case 'date': cellValue = DateFormat('yyyy-MM-dd').format(pay.paymentDate); break;
                case 'invoice_num': cellValue = 'سداد'; break;
                case 'debit': cellValue = '-'; break;
                case 'credit': 
                  cellValue = pay.amount.toStringAsFixed(2); 
                  runningBalance -= pay.amount; 
                  textColor = Colors.green[700]; 
                  break;
                case 'balance': cellValue = runningBalance.toStringAsFixed(2); isBold = true; break;
                case 'supplier': cellValue = _getSupplierName(context, pay.supplierId); break;
                default: cellValue = '-';
              }
            }

            return DataCell(
              Text(
                cellValue,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
            );
          }).toList(),
        );
      }).toList();
    } else {
      // --- تقرير تفصيلي ---
      List<DataRow> rows = [];
      int index = 0;
      for (var purchase in vm.purchases) {
        for (var item in purchase.items) {
          index++;
          final isEven = index % 2 == 0;
          final rowColor = isEven ? Colors.white : Colors.grey[50];

          rows.add(
            DataRow(
              color: MaterialStateProperty.all(rowColor),
              cells: visibleCols.map((col) {
                String cellValue = '';
                switch (col.id) {
                  case 'date': cellValue = DateFormat('yyyy-MM-dd').format(purchase.createdAt); break;
                  case 'invoice_num': cellValue = purchase.id.substring(0, 6).toUpperCase(); break;
                  case 'supplier': cellValue = _getSupplierName(context, purchase.supplierId); break;
                  case 'product': cellValue = '...${item.productId.substring(0, 5)}'; break;
                  case 'qty': cellValue = item.quantity.toStringAsFixed(0); break;
                  case 'free_qty': cellValue = item.freeQuantity.toStringAsFixed(0); break;
                  case 'price': cellValue = item.price.toStringAsFixed(2); break;
                  case 'returned_qty': cellValue = item.returnedQuantity > 0 ? item.returnedQuantity.toStringAsFixed(0) : '-'; break;
                  case 'total': cellValue = item.total.toStringAsFixed(2); break;
                  case 'net_total': cellValue = item.total.toStringAsFixed(2); break;
                  case 'debit': cellValue = purchase.totalAmount.toStringAsFixed(2); break;
                  case 'credit': cellValue = '-'; break;
                  case 'balance': cellValue = '-'; break;
                  default: cellValue = '';
                }
                return DataCell(Text(cellValue));
              }).toList(),
            ),
          );
        }
      }
      return rows;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportVm = context.watch<ReportViewModel>();
    final localizations = AppLocalizations.of(context)!;

    if (reportVm.state == ReportViewState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (reportVm.state == ReportViewState.error) {
      return Center(
        child: Text(reportVm.errorMessage ?? localizations.errorOccurred),
      );
    }

    final visibleColumns = reportVm.purchaseColumns
        .where((col) => col.isVisible)
        .toList();

    final bool isEmpty = reportVm.purchaseReportType == PurchaseReportType.statement
        ? (reportVm.purchases.isEmpty && (reportVm.reportData['payments'] as List? ?? []).isEmpty)
        : reportVm.purchases.isEmpty;

    if (isEmpty) {
      return Center(child: Text(localizations.noRecentActivity));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
          columnSpacing: 20,
          horizontalMargin: 12,
          columns: visibleColumns.map((col) {
            return DataColumn(
              label: Text(
                _getLocalizedLabel(context, col.labelKey),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              numeric: col.isNumeric,
            );
          }).toList(),
          rows: _buildRows(context, reportVm, visibleColumns),
        ),
      ),
    );
  }
}