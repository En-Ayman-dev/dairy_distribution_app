// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../viewmodels/report_viewmodel.dart';
// import '../../../l10n/app_localizations.dart';
// import 'package:open_file/Open_file.dart';
// import 'package:share_plus/share_plus.dart';

// class ReportsScreen extends StatefulWidget {
//   const ReportsScreen({super.key});

//   @override
//   State<ReportsScreen> createState() => _ReportsScreenState();
// }

// class _ReportsScreenState extends State<ReportsScreen> {
//   DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
//   DateTime _endDate = DateTime.now();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(AppLocalizations.of(context)!.reportsTitle),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           // Date Range Selector
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     AppLocalizations.of(context)!.selectDateRange,
//                     style: Theme.of(context).textTheme.titleMedium,
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton.icon(
//                           onPressed: () => _selectDate(context, true),
//                           icon: const Icon(Icons.calendar_today),
//                           label: Text(
//                             '${AppLocalizations.of(context)!.fromLabel}: ${_startDate.day}/${_startDate.month}/${_startDate.year}',
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: OutlinedButton.icon(
//                           onPressed: () => _selectDate(context, false),
//                           icon: const Icon(Icons.calendar_today),
//                           label: Text(
//                             '${AppLocalizations.of(context)!.toLabel}: ${_endDate.day}/${_endDate.month}/${_endDate.year}',
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),

//           // Report Types
//           _buildReportCard(
//             context,
//             title: AppLocalizations.of(context)!.salesReportTitle,
//             subtitle: AppLocalizations.of(context)!.salesReportSubtitle,
//             icon: Icons.trending_up,
//             color: Colors.green,
//             onGenerate: () async {
//               // Use the State's context (this.context) instead of the
//               // builder-scoped context parameter to avoid BuildContext
//               // use across async gaps.
//               final vm = this.context.read<ReportViewModel>();
//               await vm.generateSalesReport();
//               if (!mounted) return;
//               _showReportActions(ReportType.sales);
//             },
//           ),
//           _buildReportCard(
//             context,
//             title: AppLocalizations.of(context)!.inventoryReportTitle,
//             subtitle: AppLocalizations.of(context)!.inventoryReportSubtitle,
//             icon: Icons.inventory_2,
//             color: Colors.blue,
//             onGenerate: () async {
//               final vm = this.context.read<ReportViewModel>();
//               await vm.generateInventoryReport();
//               if (!mounted) return;
//               _showReportActions(ReportType.inventory);
//             },
//           ),
//           _buildReportCard(
//             context,
//             title: AppLocalizations.of(context)!.outstandingReportTitle,
//             subtitle: AppLocalizations.of(context)!.outstandingReportSubtitle,
//             icon: Icons.account_balance_wallet,
//             color: Colors.orange,
//             onGenerate: () async {
//               final vm = this.context.read<ReportViewModel>();
//               await vm.generateOutstandingReport();
//               if (!mounted) return;
//               _showReportActions(ReportType.outstanding);
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildReportCard(
//     BuildContext context, {
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required Color color,
//     required VoidCallback onGenerate,
//   }) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: ListTile(
//         leading: Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: color.withAlpha((0.1 * 255).round()),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Icon(icon, color: color, size: 28),
//         ),
//         title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//         subtitle: Text(subtitle),
//         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//         onTap: onGenerate,
//       ),
//     );
//   }

//   Future<void> _selectDate(BuildContext context, bool isStartDate) async {
//     // Capture the ViewModel before awaiting the date picker to avoid using
//     // the builder-local context across an async gap.
//     final vm = context.read<ReportViewModel>();

//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: isStartDate ? _startDate : _endDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//     );

//     if (picked != null) {
//       setState(() {
//         if (isStartDate) {
//           _startDate = picked;
//         } else {
//           _endDate = picked;
//         }
//       });
//       vm.setDateRange(_startDate, _endDate);
//     }
//   }

//   void _showReportActions(ReportType reportType) {
//   // Use this State's context for follow-up UI (dialogs, SnackBars). Do
//   // not capture a builder-local context that may be disposed when the
//   // sheet is closed.
//   final parentContext = context;

//     showModalBottomSheet(
//       context: parentContext,
//       builder: (sheetContext) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.picture_as_pdf),
//               title: Text(AppLocalizations.of(context)!.exportAsPdf),
//               onTap: () async {
//                 Navigator.pop(sheetContext);

//                 final vm = parentContext.read<ReportViewModel>();
//                 final path = await vm.exportToPDF(reportType);

//                 if (!mounted) return;

//                 if (path != null) {
//                   _showFileOptions(path);
//                 }
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.table_chart),
//               title: Text(AppLocalizations.of(context)!.exportAsExcel),
//               onTap: () async {
//                 Navigator.pop(sheetContext);

//                 final vm = parentContext.read<ReportViewModel>();
//                 final path = await vm.exportToExcel(reportType);

//                 if (!mounted) return;

//                 if (path != null) {
//                   _showFileOptions(path);
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showFileOptions(String filePath) {
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: Text(AppLocalizations.of(context)!.reportGeneratedTitle),
//         content: Text(AppLocalizations.of(context)!.reportGeneratedPrompt),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: Text(AppLocalizations.of(context)!.close),
//           ),
//           ElevatedButton.icon(
//             onPressed: () {
//               OpenFile.open(filePath);
//               Navigator.pop(dialogContext);
//             },
//             icon: const Icon(Icons.open_in_new),
//             label: Text(AppLocalizations.of(context)!.openLabel),
//           ),
//           ElevatedButton.icon(
//             onPressed: () {
//               Share.shareXFiles([XFile(filePath)]);
//               Navigator.pop(dialogContext);
//             },
//             icon: const Icon(Icons.share),
//             label: Text(AppLocalizations.of(context)!.shareLabel),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../../viewmodels/customer_viewmodel.dart'; // <-- إضافة
import '../../viewmodels/product_viewmodel.dart'; // <-- إضافة
import '../../../domain/entities/customer.dart'; // <-- إضافة
import '../../../domain/entities/product.dart'; // <-- إضافة
import '../../../l10n/app_localizations.dart';
import 'package:open_file/open_file.dart';
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
  void initState() {
    super.initState();
    // جلب البيانات اللازمة للفلاتر عند فتح الشاشة
    // نستخدم addPostFrameCallback لضمان أن الـ context متاح
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // التأكد من أن الـ ViewModels جاهزة قبل جلب البيانات
      if (mounted) {
        context.read<CustomerViewModel>().loadCustomers();
        context.read<ProductViewModel>().loadProducts();
        // ضبط التاريخ المبدئي في الـ ViewModel
        context.read<ReportViewModel>().setDateRange(_startDate, _endDate);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // استخدام Consumer3 للاستماع إلى جميع الـ ViewModels التي نحتاجها
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reportsTitle),
      ),
      body: Consumer3<ReportViewModel, CustomerViewModel, ProductViewModel>(
        builder: (context, reportVM, customerVM, productVM, child) {
          // جلب القوائم من الـ ViewModels
          final List<Customer> customers = customerVM.customers;
          final List<Product> products = productVM.products;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Date Range Selector (Card 1)
              _buildDateRangeCard(context, reportVM),
              const SizedBox(height: 16),

              // Sales Report Filters (Card 2)
              _buildReportExpansionTile(
                context,
                title: AppLocalizations.of(context)!.salesReportTitle,
                subtitle: AppLocalizations.of(context)!.salesReportSubtitle,
                icon: Icons.trending_up,
                color: Colors.green,
                onGenerate: () async {
                  // المنطق الذي كان موجوداً سابقاً
                  // يتم استدعاؤه الآن *بعد* اختيار الفلاتر
                  final vm = context.read<ReportViewModel>();
                  await vm.generateSalesReport();
                  if (!mounted) return;
                  _showReportActions(ReportType.sales);
                },
                // الفلاتر المخصصة لتقرير المبيعات
                filterWidgets: [
                  _buildSalesReportTypeSelector(context, reportVM),
                  _buildCustomerSelector(context, reportVM, customers),
                  _buildProductMultiSelect(context, reportVM, products),
                ],
              ),

              // Inventory Report Filters (Card 3)
              _buildReportExpansionTile(
                context,
                title: AppLocalizations.of(context)!.inventoryReportTitle,
                subtitle: AppLocalizations.of(context)!.inventoryReportSubtitle,
                icon: Icons.inventory_2,
                color: Colors.blue,
                onGenerate: () async {
                  final vm = context.read<ReportViewModel>();
                  await vm.generateInventoryReport();
                  if (!mounted) return;
                  _showReportActions(ReportType.inventory);
                },
                // الفلاتر المخصصة لتقرير المخزون
                filterWidgets: [
                  _buildProductMultiSelect(context, reportVM, products),
                ],
              ),

              // Outstanding Report Filters (Card 4)
              _buildReportExpansionTile(
                context,
                title: AppLocalizations.of(context)!.outstandingReportTitle,
                subtitle:
                    AppLocalizations.of(context)!.outstandingReportSubtitle,
                icon: Icons.account_balance_wallet,
                color: Colors.orange,
                onGenerate: () async {
                  final vm = context.read<ReportViewModel>();
                  await vm.generateOutstandingReport();
                  if (!mounted) return;
                  _showReportActions(ReportType.outstanding);
                },
                // الفلاتر المخصصة لتقرير الأرصدة
                filterWidgets: [
                  _buildCustomerSelector(context, reportVM, customers),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // (Card 1) - ويدجت اختيار مدى التاريخ
  Widget _buildDateRangeCard(BuildContext context, ReportViewModel reportVM) {
    return Card(
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
    );
  }

  // (Cards 2, 3, 4) - الهيكل الرئيسي لـ ExpansionTile
  Widget _buildReportExpansionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> filterWidgets,
    required VoidCallback onGenerate,
  }) {
    // هذا هو الـ consumer الذي سيعرض مؤشر التحميل
    // سيتم إضافته لاحقاً في ReportViewModel
    final vm = context.watch<ReportViewModel>();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
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
        children: [
          // هذا هو محتوى الفلاتر الذي يتم تمريره
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...filterWidgets,
                const SizedBox(height: 16),
                // زر "إنشاء التقرير"
                ElevatedButton.icon(
                  onPressed: onGenerate,
                  // (vm.state == ReportState.loading) // سيتم تفعيل هذا لاحقاً
                  //     ? null
                  //     : onGenerate,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(
                    AppLocalizations.of(context)!.generateReport,
                  ),
                  // child: (vm.state == ReportState.loading) // وهذا أيضاً
                  //     ? const CircularProgressIndicator()
                  //     : Text(
                  //         AppLocalizations.of(context)!.generateReport,
                  //       ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ويدجتس الفلاتر ---

  // فلتر: نوع تقرير المبيعات (تفصيلي / ملخص)
 // ... (داخل ملف reports_screen.dart) ...

  // فلتر: نوع تقرير المبيعات (تفصيلي / ملخص)
  Widget _buildSalesReportTypeSelector(
      BuildContext context, ReportViewModel vm) {
    
    // (*** تم تعديل هذه الدالة بالكامل ***)

    return DropdownButtonFormField<SalesReportType>( // <-- 1. تم تغيير النوع من String
      value: vm.salesReportType, // <-- 2. أصبح القيمة من الـ ViewModel
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.reportType,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(
          value: SalesReportType.summary, // <-- 3. تم تغيير القيمة إلى enum
          child: Text(AppLocalizations.of(context)!.reportTypeSummary),
        ),
        DropdownMenuItem(
          value: SalesReportType.detailed, // <-- 4. تم تغيير القيمة إلى enum
          child: Text(AppLocalizations.of(context)!.reportTypeDetailed),
        ),
      ],
      onChanged: (value) {
        // 5. الآن 'value' هو من نوع SalesReportType (أو null)
        if (value != null) {
          vm.setSalesReportType(value); // <-- أصبح الكود صحيحاً الآن
        }
      },
    );
  }


  // فلتر: اختيار عميل واحد
  Widget _buildCustomerSelector(
      BuildContext context, ReportViewModel vm, List<Customer> customers) {
    // سنقوم بإضافة selectedCustomer إلى الـ ViewModel لاحقاً
    final Customer? selectedCustomer = vm.selectedCustomer;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: DropdownButtonFormField<Customer?>(
        value: selectedCustomer,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.selectCustomer,
          border: const OutlineInputBorder(),
        ),
        // إضافة خيار "كل العملاء" في البداية
        items: [
          DropdownMenuItem<Customer?>(
            value: null, // القيمة null تمثل "الكل"
            child: Text(AppLocalizations.of(context)!.allCustomers),
          ),
          ...customers.map((customer) {
            return DropdownMenuItem<Customer?>(
              value: customer,
              child: Text(customer.name),
            );
          }),
        ],
        onChanged: (customer) {
          vm.setSelectedCustomer(customer); // سيتم تفعيل هذا لاحقاً
        },
      ),
    );
  }

  // فلتر: اختيار عدة منتجات
  Widget _buildProductMultiSelect(
      BuildContext context, ReportViewModel vm, List<Product> products) {
    // سنقوم بإضافة selectedProducts إلى الـ ViewModel لاحقاً
    final List<Product> selectedProducts = vm.selectedProducts;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.inventory),
        label: Text(
          selectedProducts.isEmpty
              ? AppLocalizations.of(context)!.selectProducts
              : AppLocalizations.of(context)!
                  .productsSelected(selectedProducts.length),
        ),
        onPressed: () {
          // إظهار نافذة لاختيار المنتجات
          _showProductMultiSelectDialog(context, vm, products);
        },
      ),
    );
  }

  // --- دوال المساعدة ---

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
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
      // تحديث الـ ViewModel بالتاريخ الجديد
      vm.setDateRange(_startDate, _endDate);
    }
  }

  // نافذة اختيار المنتجات المتعددة
  void _showProductMultiSelectDialog(
      BuildContext context, ReportViewModel vm, List<Product> allProducts) {
    // هذه الدالة تحتاج إلى StatefulBuilder لأننا سنقوم بتحديث
    // حالة الـ Checkboxes داخل النافذة نفسها
    showDialog(
      context: context,
      builder: (dialogContext) {
        // قائمة مؤقتة لتخزين الاختيارات قبل الحفظ
        final List<Product> tempSelected = List.from(vm.selectedProducts);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.selectProducts),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: allProducts.length,
                  itemBuilder: (context, index) {
                    final product = allProducts[index];
                    final isSelected = tempSelected.contains(product);
                    return CheckboxListTile(
                      title: Text(product.name),
                      value: isSelected,
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            tempSelected.add(product);
                          } else {
                            tempSelected.remove(product);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    vm.setSelectedProducts(tempSelected); // سيتم تفعيل هذا لاحقاً
                    Navigator.pop(dialogContext);
                  },
                  child: Text(AppLocalizations.of(context)!.confirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // (دوال BottomSheet والحوار لم تتغير)
  void _showReportActions(ReportType reportType) {
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
