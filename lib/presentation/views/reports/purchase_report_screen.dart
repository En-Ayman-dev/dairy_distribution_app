// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import '../../../../l10n/app_localizations.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../../viewmodels/supplier_viewmodel.dart';
import 'widgets/report_customization_dialog.dart';

// --- New Imports for Extracted Widgets ---
import 'widgets/purchase_report_filters.dart';
import 'widgets/purchase_report_table.dart';
import 'widgets/purchase_report_footer.dart';

class PurchaseReportScreen extends StatefulWidget {
  const PurchaseReportScreen({super.key});

  @override
  State<PurchaseReportScreen> createState() => _PurchaseReportScreenState();
}

class _PurchaseReportScreenState extends State<PurchaseReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // تحميل البيانات الأساسية
      context.read<ReportViewModel>().loadPurchasesReportData();
      context.read<SupplierViewModel>().loadSuppliers();
    });
  }
  
  // تم حذف: _getSupplierName و _getLocalizedLabel و _selectDateRange (تم نقلهم للـ Filter Widget)

  void _showExportOptions(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final reportVm = context.read<ReportViewModel>();
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(localizations.exportAsPdf),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await reportVm.exportToPDF(ReportType.purchases);
                if (path != null) OpenFile.open(path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: Text(localizations.exportAsExcel),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await reportVm.exportToExcel(ReportType.purchases);
                if (path != null) OpenFile.open(path);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.purchasesReportTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: localizations.customizeReportButton,
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => const ReportCustomizationDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: localizations.exportTooltip, // نفترض وجود هذا المفتاح
            onPressed: () => _showExportOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. قسم الفلاتر (مُستخرج)
          const PurchaseReportFilters(),
          
          const Divider(height: 1),

          // 2. الجدول (مُستخرج)
          const Expanded(
            child: PurchaseReportTable(),
          ),

          // 3. التذييل (مُستخرج)
          const PurchaseReportFooter(),
        ],
      ),
    );
  }
  
}