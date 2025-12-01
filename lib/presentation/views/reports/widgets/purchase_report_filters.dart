import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../viewmodels/report_viewmodel.dart';
import '../../../viewmodels/supplier_viewmodel.dart';

class PurchaseReportFilters extends StatelessWidget {
  const PurchaseReportFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final reportVm = context.watch<ReportViewModel>();
    final supplierVm = context.watch<SupplierViewModel>();
    final t = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          // 1. فلتر المورد
          DropdownButtonFormField<String?>(
            isExpanded: true,
            decoration: InputDecoration(
              labelText: t.supplierLabel,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.store, color: Colors.grey),
            ),
            initialValue: reportVm.selectedSupplier?.id,
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(t.allSuppliersLabel), // نفترض وجود هذا المفتاح
              ),
              ...supplierVm.suppliers.map(
                (s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (val) {
              final supplier = val == null
                  ? null
                  : supplierVm.suppliers.firstWhere((s) => s.id == val);
              reportVm.setSelectedSupplier(supplier);
              reportVm.generatePurchasesReport();
            },
          ),
          const SizedBox(height: 12), 

          // 2. فلتر نوع التقرير
          DropdownButtonFormField<PurchaseReportType>(
            isExpanded: true,
            decoration: InputDecoration(
              labelText: t.reportType,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.description, color: Colors.grey),
            ),
            initialValue: reportVm.purchaseReportType,
            items: [
              DropdownMenuItem(
                value: PurchaseReportType.statement,
                child: Text(t.reportTypeStatement),
              ),
              DropdownMenuItem(
                value: PurchaseReportType.detailedItems,
                child: Text(t.reportTypeDetailedItems),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                reportVm.setPurchaseReportType(val);
                reportVm.generatePurchasesReport();
              }
            },
          ),
          const SizedBox(height: 12),

          // 3. الصف الأخير: التاريخ وزر التحديث
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDateRange(context, reportVm),
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    '${DateFormat('yyyy/MM/dd').format(reportVm.startDate)} - ${DateFormat('yyyy/MM/dd').format(reportVm.endDate)}',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => reportVm.generatePurchasesReport(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                child: const Icon(Icons.refresh),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context, ReportViewModel vm) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: vm.startDate, end: vm.endDate),
    );

    if (picked != null) {
      vm.setDateRange(picked.start, picked.end);
      vm.generatePurchasesReport();
    }
  }
}