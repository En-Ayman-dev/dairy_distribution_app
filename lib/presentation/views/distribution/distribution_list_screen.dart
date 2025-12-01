// ignore_for_file: use_build_context_synchronously, deprecated_member_use, no_leading_underscores_for_local_identifiers, unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/distribution_viewmodel.dart';
import '../../../domain/entities/distribution.dart';
import '../../../l10n/app_localizations.dart';
import 'distribution_detail_screen.dart';
import '../../widgets/print_button.dart'; // نحتاج لهذا الاستيراد لـ kPrinterSizes

// --- New Imports ---
import 'widgets/distribution_list_item.dart';
import 'widgets/edit_distribution_dialog.dart';
import '../../widgets/common/empty_list_state.dart'; 
import '../../utils/distribution_print_mixin.dart'; // Mixin Import!

class DistributionListScreen extends StatefulWidget {
  const DistributionListScreen({super.key});

  @override
  State<DistributionListScreen> createState() => _DistributionListScreenState();
}

// تطبيق Mixin
class _DistributionListScreenState extends State<DistributionListScreen> with DistributionPrintMixin {
  
  // المتغيرات الوحيدة المتبقية في الكلاس الأصلي
  bool _isFilterSectionVisible = false; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DistributionViewModel>().loadDistributions();
    });
  }

  Future<void> _handleDeleteDistribution(Distribution dist) async {
    final vm = context.read<DistributionViewModel>();
    final t = AppLocalizations.of(context)!;
    
    final success = await vm.deleteDistribution(dist.id);
    if (!mounted) return;
    
    final message = success
        ? '${t.distributionLabel} ${dist.id.substring(0, 8)} ${t.distributionDeletedSuccess}'
        : vm.errorMessage ?? t.errorOccurred;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _handleEditDistribution(Distribution dist) async {
    await showDialog<bool>(
      context: context,
      builder: (ctx) => EditDistributionDialog(distribution: dist),
    );
  }

  // دالة فتح ديالوج الطباعة (تستخدم الآن Mixin)
  Future<void> _showPrintDialogForDistribution(Distribution dist) async {
    PrinterSize selected = kPrinterSizes.first;
    PrintOutput output = PrintOutput.pdf;
    bool preview = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('اختيار مقاس الطابعة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final size in kPrinterSizes)
                    RadioListTile<PrinterSize>(
                      value: size,
                      groupValue: selected,
                      onChanged: (v) => setState(() => selected = v!),
                      title: Text(
                        '${size.name} (عرض فعلي ~${size.printableWidthMm}mm) - ${size.description}',
                      ),
                    ),
                  const Divider(),
                  RadioListTile<PrintOutput>(
                    value: PrintOutput.printer,
                    groupValue: output,
                    onChanged: (v) => setState(() => output = v!),
                    title: const Text('طباعة إلى طابعة حرارية'),
                  ),
                  RadioListTile<PrintOutput>(
                    value: PrintOutput.pdf,
                    groupValue: output,
                    onChanged: (v) => setState(() => output = v!),
                    title: const Text('حفظ / عرض PDF'),
                  ),
                  if (output == PrintOutput.pdf)
                    CheckboxListTile(
                      value: preview,
                      onChanged: (v) => setState(() => preview = v ?? true),
                      title: const Text('عرض ملف PDF بعد الإنشاء'),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  // استدعاء دالة الطباعة الموحدة من الـ Mixin
                  await printDistributionInvoice(dist, selected, output, preview);
                },
                icon: const Icon(Icons.print),
                label: const Text('طباعة'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.distributionListTitle),
        actions: [
          // Filter Toggle Button
          IconButton(
            tooltip: t.filterLabel,
            icon: Icon(_isFilterSectionVisible ? Icons.filter_alt_off : Icons.filter_alt),
            onPressed: () {
              setState(() {
                _isFilterSectionVisible = !_isFilterSectionVisible;
              });
            },
          ),
          // Firestore Access Button (Kept for Debugging)
          IconButton(
            tooltip: t.firestoreReadResult,
            icon: const Icon(Icons.cloud_outlined),
            onPressed: () {
              // _testFirestoreAccess(context); 
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Filter Section (Temporary simplified implementation)
          if (_isFilterSectionVisible) 
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.filterLabel, style: Theme.of(context).textTheme.titleMedium),
                  // TODO: Add actual filter widgets (Date Range, Customer Dropdown, Status)
                ],
              ),
            ),
          
          const Divider(height: 1),
          
          // 2. List Body
          Expanded(
            child: Consumer<DistributionViewModel>(
              builder: (context, vm, child) {
                if (vm.state == DistributionViewState.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (vm.state == DistributionViewState.error) {
                  return Center(
                    child: Text(vm.errorMessage ?? t.failedToLoadDistributions),
                  );
                }

                final list = vm.distributions;
                if (list.isEmpty) {
                  // استخدام EmptyListState الجديد
                  return Center(child: EmptyListState(
                    message: t.noDistributionsToShow,
                    icon: Icons.receipt_long_outlined,
                  ));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final dist = list[index];
                    return DistributionListItem(
                      distribution: dist,
                      onEdit: () => _handleEditDistribution(dist),
                      onPrint: () => _showPrintDialogForDistribution(dist),
                      onDelete: _handleDeleteDistribution,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DistributionDetailScreen(distribution: dist),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}