// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../../../../l10n/app_localizations.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../../viewmodels/supplier_viewmodel.dart';
import 'widgets/report_customization_dialog.dart';

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
      context.read<ReportViewModel>().loadPurchasesReportData();
      context.read<SupplierViewModel>().loadSuppliers();
    });
  }

  String _getSupplierName(BuildContext context, String supplierId) {
    final localizations = AppLocalizations.of(context)!;
    final suppliers = context.read<SupplierViewModel>().suppliers;
    final supplier = suppliers.where((s) => s.id == supplierId).firstOrNull;
    return supplier?.name ?? localizations.unknownSupplier;
  }

  String _getLocalizedLabel(BuildContext context, String key) {
    final loc = AppLocalizations.of(context)!;
    switch (key) {
      case 'colSupplier':
        return loc.colSupplier;
      case 'colDate':
        return loc.colDate;
      case 'colItemsCount':
        return loc.colItemsCount;
      case 'colTotalAmount':
        return loc.colTotalAmount; // إجمالي الصنف
      case 'colDiscount':
        return loc.colDiscount;
      case 'colNetTotal':
        return loc.colNetTotal;
      case 'colInvoiceNum':
        return loc.colInvoiceNum;
      case 'colProduct':
        return loc.colProduct;
      case 'colQty':
        return loc.colQty;
      case 'colFreeQty':
        return loc.freeQuantityLabel.replaceAll(RegExp(r'\(.*\)'), '').trim();
      case 'colPrice':
        return loc.colPrice;
      case 'colReturnedQty':
        return loc.colReturnedQty;
      case 'colDebit':
        return loc.colDebit; // مبلغ الفاتورة
      case 'colCredit':
        return loc.colCredit; // المسدد
      case 'colBalance':
        return loc.colBalance; // الرصيد
      default:
        return key;
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final vm = context.read<ReportViewModel>();
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

  void _showExportOptions(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
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
                final path = await context.read<ReportViewModel>().exportToPDF(
                  ReportType.purchases,
                );
                if (path != null) OpenFile.open(path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: Text(localizations.exportAsExcel),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await context
                    .read<ReportViewModel>()
                    .exportToExcel(ReportType.purchases);
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
    final reportVm = context.watch<ReportViewModel>();
    final supplierVm = context.watch<SupplierViewModel>();
    final localizations = AppLocalizations.of(context)!;

    final visibleColumns = reportVm.purchaseColumns
        .where((col) => col.isVisible)
        .toList();

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
            tooltip: "تصدير",
            onPressed: () => _showExportOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- الفلاتر ---
          // --- 1. قسم الفلاتر (Filters) ---
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                // --- التعديل هنا: إلغاء Row واستخدام Column للفلاتر ---

                // 1. فلتر المورد
                DropdownButtonFormField<String?>(
                  isExpanded:
                      true, // هام جداً: يسمح للنص بأخذ المساحة وقصه بأمان إن لزم الأمر
                  decoration: InputDecoration(
                    labelText: localizations.supplierLabel,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(
                      Icons.store,
                      color: Colors.grey,
                    ), // تحسين بصري
                  ),
                  value: reportVm.selectedSupplier?.id,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(
                        localizations.allCategories.replaceFirst(
                          'الفئات',
                          'الموردين',
                        ),
                        overflow: TextOverflow.ellipsis, // قص النص الزائد بأمان
                      ),
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

                const SizedBox(height: 12), // مسافة فاصلة
                // 2. فلتر نوع التقرير
                DropdownButtonFormField<PurchaseReportType>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: localizations.reportType,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(
                      Icons.description,
                      color: Colors.grey,
                    ), // تحسين بصري
                  ),
                  value: reportVm.purchaseReportType,
                  items: [
                    DropdownMenuItem(
                      value: PurchaseReportType.statement,
                      child: Text(
                        localizations.reportTypeStatement,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: PurchaseReportType.detailedItems,
                      child: Text(
                        localizations.reportTypeDetailedItems,
                        overflow: TextOverflow.ellipsis,
                      ),
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

                // 3. الصف الأخير: التاريخ وزر التحديث (يبقى Row لأنهما أصغر)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDateRange(context),
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                      child: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- الجدول ---
          Expanded(
            child: Builder(
              builder: (context) {
                if (reportVm.state == ReportViewState.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (reportVm.state == ReportViewState.error) {
                  return Center(
                    child: Text(
                      reportVm.errorMessage ?? localizations.errorOccurred,
                    ),
                  );
                }

                final bool isEmpty =
                    reportVm.purchaseReportType == PurchaseReportType.statement
                    ? (reportVm.purchases.isEmpty &&
                          (reportVm.reportData['payments'] as List? ?? [])
                              .isEmpty)
                    : reportVm.purchases.isEmpty;

                if (isEmpty) {
                  return Center(child: Text(localizations.noRecentActivity));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                      // إضافة ألوان متبادلة للصفوف (Zebra Striping)
                      dataRowColor: WidgetStateProperty.resolveWith<Color?>((
                        Set<WidgetState> states,
                      ) {
                        return null; // سيتم التعامل معه في الخلية لكل صف
                      }),
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
              },
            ),
          ),

          _buildTotalFooter(context, reportVm, visibleColumns),
        ],
      ),
    );
  }

  List<DataRow> _buildRows(
    BuildContext context,
    ReportViewModel vm,
    List<ReportColumn> visibleCols,
  ) {
    if (vm.purchaseReportType == PurchaseReportType.statement) {
      // --- كشف حساب ---
      final payments = vm.reportData['payments'] as List? ?? [];
      final combined = <dynamic>[...vm.purchases, ...payments];

      combined.sort((a, b) {
        final dateA = a.runtimeType.toString().contains('Purchase')
            ? a.createdAt
            : a.paymentDate;
        final dateB = b.runtimeType.toString().contains('Purchase')
            ? b.createdAt
            : b.paymentDate;
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

            if (item.runtimeType.toString().contains('Purchase')) {
              final p = item;
              switch (col.id) {
                case 'date':
                  cellValue = DateFormat('yyyy-MM-dd').format(p.createdAt);
                  break;
                case 'invoice_num':
                  cellValue = p.id.substring(0, 6).toUpperCase();
                  break;
                // في كشف الحساب: Debit = مبلغ الفاتورة
                case 'debit':
                  cellValue = p.totalAmount.toStringAsFixed(2);
                  runningBalance += p.totalAmount;
                  break;
                case 'credit':
                  cellValue = '-';
                  break;
                case 'balance':
                  cellValue = runningBalance.toStringAsFixed(2);
                  isBold = true;
                  break;
                case 'supplier':
                  cellValue = _getSupplierName(context, p.supplierId);
                  break;
                default:
                  cellValue = '-';
              }
            } else {
              final pay = item;
              switch (col.id) {
                case 'date':
                  cellValue = DateFormat('yyyy-MM-dd').format(pay.paymentDate);
                  break;
                case 'invoice_num':
                  cellValue = 'سداد';
                  break;
                case 'debit':
                  cellValue = '-';
                  break;
                // في كشف الحساب: Credit = مبلغ السداد
                case 'credit':
                  cellValue = pay.amount.toStringAsFixed(2);
                  runningBalance -= pay.amount;
                  textColor = Colors.green[700];
                  break;
                case 'balance':
                  cellValue = runningBalance.toStringAsFixed(2);
                  isBold = true;
                  break;
                case 'supplier':
                  cellValue = _getSupplierName(context, pay.supplierId);
                  break;
                default:
                  cellValue = '-';
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
              color: WidgetStateProperty.all(rowColor),
              cells: visibleCols.map((col) {
                String cellValue = '';
                switch (col.id) {
                  case 'date':
                    cellValue = DateFormat(
                      'yyyy-MM-dd',
                    ).format(purchase.createdAt);
                    break;
                  case 'invoice_num':
                    cellValue = purchase.id.substring(0, 6).toUpperCase();
                    break;
                  case 'supplier':
                    cellValue = _getSupplierName(context, purchase.supplierId);
                    break;

                  // تفاصيل الصنف
                  case 'product':
                    cellValue = '...${item.productId.substring(0, 5)}';
                    break;
                  case 'qty':
                    cellValue = item.quantity.toStringAsFixed(0);
                    break;
                  case 'free_qty':
                    cellValue = item.freeQuantity.toStringAsFixed(0);
                    break;
                  case 'price':
                    cellValue = item.price.toStringAsFixed(2);
                    break;
                  case 'returned_qty':
                    cellValue = item.returnedQuantity > 0
                        ? item.returnedQuantity.toStringAsFixed(0)
                        : '-';
                    break;

                  // المبالغ
                  case 'total':
                    cellValue = item.total.toStringAsFixed(2);
                    break; // إجمالي الصنف
                  case 'net_total':
                    cellValue = item.total.toStringAsFixed(2);
                    break; // في التفصيلي = إجمالي الصنف

                  // تعبئة أعمدة كشف الحساب بقيم الفاتورة (للتوضيح)
                  case 'debit':
                    cellValue = purchase.totalAmount.toStringAsFixed(2);
                    break; // مبلغ الفاتورة الكلي
                  case 'credit':
                    cellValue = '-';
                    break;
                  case 'balance':
                    cellValue = '-';
                    break;

                  default:
                    cellValue = '';
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

  Widget _buildTotalFooter(
    BuildContext context,
    ReportViewModel vm,
    List<ReportColumn> visibleCols,
  ) {
    final localizations = AppLocalizations.of(context)!;
    double grandTotal = 0.0;
    bool showTotal = false;
    String label = localizations.totalSummaryLabel;

    // حساب الإجمالي بناءً على النوع والعمود
    if (vm.purchaseReportType == PurchaseReportType.statement &&
        visibleCols.any((c) => c.id == 'balance')) {
      double totalDebit = vm.purchases.fold(0.0, (s, p) => s + p.totalAmount);
      double totalCredit = (vm.reportData['payments'] as List? ?? []).fold(
        0.0,
        (s, p) => s + (p as dynamic).amount,
      );
      grandTotal = totalDebit - totalCredit;
      showTotal = true;
      label = localizations.grandTotalRemaining; // "إجمالي المتبقي"
    } else if (visibleCols.any(
      (col) => col.id == 'net_total' || col.id == 'total',
    )) {
      // في التفصيلي، نجمع إجمالي الأصناف (أو الفواتير)
      // بما أننا نكرر الفواتير لكل صنف، يجب الحذر.
      // هنا سنجمع "item.total" لكل الأصناف المعروضة
      for (var p in vm.purchases) {
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
        color: Colors.blue[50], // تمييز الفوتر بلون
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
            grandTotal.toStringAsFixed(2),
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
