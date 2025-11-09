import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../../../l10n/app_localizations.dart';
import 'package:open_file/Open_file.dart';
import 'package:share_plus/share_plus.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reportsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date Range Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.selectDateRange,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(context, true),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${AppLocalizations.of(context)!.fromLabel}: ${_startDate.day}/${_startDate.month}/${_startDate.year}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(context, false),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${AppLocalizations.of(context)!.toLabel}: ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Report Types
          _buildReportCard(
            context,
            title: AppLocalizations.of(context)!.salesReportTitle,
            subtitle: AppLocalizations.of(context)!.salesReportSubtitle,
            icon: Icons.trending_up,
            color: Colors.green,
            onGenerate: () async {
              // Use the State's context (this.context) instead of the
              // builder-scoped context parameter to avoid BuildContext
              // use across async gaps.
              final vm = this.context.read<ReportViewModel>();
              await vm.generateSalesReport();
              if (!mounted) return;
              _showReportActions(ReportType.sales);
            },
          ),
          _buildReportCard(
            context,
            title: AppLocalizations.of(context)!.inventoryReportTitle,
            subtitle: AppLocalizations.of(context)!.inventoryReportSubtitle,
            icon: Icons.inventory_2,
            color: Colors.blue,
            onGenerate: () async {
              final vm = this.context.read<ReportViewModel>();
              await vm.generateInventoryReport();
              if (!mounted) return;
              _showReportActions(ReportType.inventory);
            },
          ),
          _buildReportCard(
            context,
            title: AppLocalizations.of(context)!.outstandingReportTitle,
            subtitle: AppLocalizations.of(context)!.outstandingReportSubtitle,
            icon: Icons.account_balance_wallet,
            color: Colors.orange,
            onGenerate: () async {
              final vm = this.context.read<ReportViewModel>();
              await vm.generateOutstandingReport();
              if (!mounted) return;
              _showReportActions(ReportType.outstanding);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onGenerate,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onGenerate,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    // Capture the ViewModel before awaiting the date picker to avoid using
    // the builder-local context across an async gap.
    final vm = context.read<ReportViewModel>();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      vm.setDateRange(_startDate, _endDate);
    }
  }

  void _showReportActions(ReportType reportType) {
  // Use this State's context for follow-up UI (dialogs, SnackBars). Do
  // not capture a builder-local context that may be disposed when the
  // sheet is closed.
  final parentContext = context;

    showModalBottomSheet(
      context: parentContext,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(AppLocalizations.of(context)!.exportAsPdf),
              onTap: () async {
                Navigator.pop(sheetContext);

                final vm = parentContext.read<ReportViewModel>();
                final path = await vm.exportToPDF(reportType);

                if (!mounted) return;

                if (path != null) {
                  _showFileOptions(path);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: Text(AppLocalizations.of(context)!.exportAsExcel),
              onTap: () async {
                Navigator.pop(sheetContext);

                final vm = parentContext.read<ReportViewModel>();
                final path = await vm.exportToExcel(reportType);

                if (!mounted) return;

                if (path != null) {
                  _showFileOptions(path);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFileOptions(String filePath) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.reportGeneratedTitle),
        content: Text(AppLocalizations.of(context)!.reportGeneratedPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.close),
          ),
          ElevatedButton.icon(
            onPressed: () {
              OpenFile.open(filePath);
              Navigator.pop(dialogContext);
            },
            icon: const Icon(Icons.open_in_new),
            label: Text(AppLocalizations.of(context)!.openLabel),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Share.shareXFiles([XFile(filePath)]);
              Navigator.pop(dialogContext);
            },
            icon: const Icon(Icons.share),
            label: Text(AppLocalizations.of(context)!.shareLabel),
          ),
        ],
      ),
    );
  }
}