import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../viewmodels/report_viewmodel.dart';

class ReportCustomizationDialog extends StatefulWidget {
  const ReportCustomizationDialog({super.key});

  @override
  State<ReportCustomizationDialog> createState() => _ReportCustomizationDialogState();
}

class _ReportCustomizationDialogState extends State<ReportCustomizationDialog> {
  bool _saveAsDefault = false;

  // دالة مساعدة لترجمة مفتاح العمود (تم تحديثها لتشمل جميع الأعمدة)
  String _getLocalizedLabel(BuildContext context, String key) {
    final loc = AppLocalizations.of(context)!;
    switch (key) {
      // الأعمدة الأساسية
      case 'colSupplier': return loc.colSupplier;
      case 'colDate': return loc.colDate;
      case 'colItemsCount': return loc.colItemsCount;
      
      // أعمدة الأصناف
      case 'colProduct': return loc.colProduct;
      case 'colQty': return loc.colQty;
      case 'colFreeQty': return loc.freeQuantityLabel.replaceAll(RegExp(r'\(.*\)'), '').trim();
      case 'colPrice': return loc.colPrice;
      case 'colReturnedQty': return loc.colReturnedQty;
      case 'colTotalAmount': return loc.colTotalAmount; // إجمالي الصنف
      case 'colNetTotal': return loc.colNetTotal;

      // أعمدة كشف الحساب / الفاتورة
      case 'colInvoiceNum': return loc.colInvoiceNum;
      case 'colDebit': return loc.colDebit;   // مبلغ الفاتورة
      case 'colCredit': return loc.colCredit; // المسدد
      case 'colBalance': return loc.colBalance; // الرصيد

      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportVm = context.watch<ReportViewModel>();
    final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(localizations.selectColumnsTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // زر "إلغاء تحديد الكل" / "تحديد الكل" (تحسين إضافي)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      for (var col in reportVm.purchaseColumns) {
                         // تفعيل الأعمدة الأساسية فقط أو الكل
                         // هنا سنقوم بعكس الحالة الأولى
                         bool newState = !reportVm.purchaseColumns.first.isVisible;
                         context.read<ReportViewModel>().toggleColumnVisibility(col.id, newState);
                      }
                    }, 
                    child: const Text("تبديل الكل"),
                  ),
                ],
              ),
              const Divider(),
              // قائمة الأعمدة القابلة للتحديد
              ...reportVm.purchaseColumns.map((col) {
                return CheckboxListTile(
                  title: Text(_getLocalizedLabel(context, col.labelKey)),
                  value: col.isVisible,
                  onChanged: (val) {
                    context.read<ReportViewModel>().toggleColumnVisibility(col.id, val ?? false);
                  },
                );
              }),
              const Divider(),
              // خيار الحفظ كافتراضي
              CheckboxListTile(
                title: Text(
                  localizations.saveAsDefaultConfig,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                value: _saveAsDefault,
                activeColor: Colors.green,
                onChanged: (val) {
                  setState(() {
                    _saveAsDefault = val ?? false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localizations.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_saveAsDefault) {
              await context.read<ReportViewModel>().saveColumnPreferences();
            }
            if (mounted) Navigator.pop(context, true);
          },
          child: Text(localizations.generateViewButton),
        ),
      ],
    );
  }
}