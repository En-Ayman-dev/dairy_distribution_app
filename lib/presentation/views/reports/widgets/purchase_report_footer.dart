import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../viewmodels/report_viewmodel.dart';

class PurchaseReportFooter extends StatelessWidget {
  const PurchaseReportFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final reportVm = context.watch<ReportViewModel>();
    final t = AppLocalizations.of(context)!;
    
    // هذا الكود يتطلب معرفة بـ ReportColumn، لذا يتم جلبه من ViewModel
    final visibleCols = reportVm.purchaseColumns.where((col) => col.isVisible).toList();
    
    double grandTotal = 0.0;
    bool showTotal = false;
    String label = t.totalSummaryLabel;

    // حساب الإجمالي
    if (reportVm.purchaseReportType == PurchaseReportType.statement &&
        visibleCols.any((c) => c.id == 'balance')) {
      double totalDebit = reportVm.purchases.fold(0.0, (s, p) => s + p.totalAmount);
      double totalCredit = (reportVm.reportData['payments'] as List? ?? []).fold(
        0.0,
        (s, p) => s + (p as dynamic).amount,
      );
      grandTotal = totalDebit - totalCredit;
      showTotal = true;
      label = t.grandTotalRemaining; // "إجمالي المتبقي"
    } else if (visibleCols.any(
      (col) => col.id == 'net_total' || col.id == 'total',
    )) {
      // تجميع إجمالي الأصناف
      for (var p in reportVm.purchases) {
        for (var i in p.items) {
          grandTotal += i.total;
        }
      }
      showTotal = true;
    }

    if (!showTotal) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '${grandTotal.toStringAsFixed(2)} ${t.currencySymbol}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: grandTotal > 0 ? Colors.red[700] : Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }
}