import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../../viewmodels/customer_viewmodel.dart'; 
import '../../viewmodels/product_viewmodel.dart'; 
import '../../../domain/entities/customer.dart'; 
import '../../../domain/entities/product.dart'; 
import '../../../l10n/app_localizations.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'purchase_report_screen.dart'; // استيراد شاشة تقرير المشتريات الجديدة

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CustomerViewModel>().loadCustomers();
        context.read<ProductViewModel>().loadProducts();
        context.read<ReportViewModel>().setDateRange(_startDate, _endDate);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reportsTitle),
      ),
      body: Consumer3<ReportViewModel, CustomerViewModel, ProductViewModel>(
        builder: (context, reportVM, customerVM, productVM, child) {
          final List<Customer> customers = customerVM.customers;
          final List<Product> products = productVM.products;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Date Range Selector (Card 1)
              _buildDateRangeCard(context, reportVM),
              const SizedBox(height: 16),

              // --- (جديد) Purchases Report Card ---
              // بطاقة خاصة لتقرير المشتريات التفاعلي الجديد
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_bag, color: Colors.purple, size: 28),
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.purchasesReportTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(AppLocalizations.of(context)!.purchasesReportSubtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PurchaseReportScreen()),
                    );
                  },
                ),
              ),

              // Sales Report Filters (Card 2)
              _buildReportExpansionTile(
                context,
                title: AppLocalizations.of(context)!.salesReportTitle,
                subtitle: AppLocalizations.of(context)!.salesReportSubtitle,
                icon: Icons.trending_up,
                color: Colors.green,
                onGenerate: () async {
                  final vm = context.read<ReportViewModel>();
                  await vm.generateSalesReport();
                  if (!mounted) return;
                  _showReportActions(ReportType.sales);
                },
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
                filterWidgets: [
                  _buildProductMultiSelect(context, reportVM, products),
                ],
              ),

              // Outstanding Report Filters (Card 4)
              _buildReportExpansionTile(
                context,
                title: AppLocalizations.of(context)!.outstandingReportTitle,
                subtitle: AppLocalizations.of(context)!.outstandingReportSubtitle,
                icon: Icons.account_balance_wallet,
                color: Colors.orange,
                onGenerate: () async {
                  final vm = context.read<ReportViewModel>();
                  await vm.generateOutstandingReport();
                  if (!mounted) return;
                  _showReportActions(ReportType.outstanding);
                },
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

  // الهيكل الرئيسي لـ ExpansionTile
  Widget _buildReportExpansionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> filterWidgets,
    required VoidCallback onGenerate,
  }) {
    // ignore: unused_local_variable
    final _ = context.watch<ReportViewModel>(); // للاستماع للتغييرات

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...filterWidgets,
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(AppLocalizations.of(context)!.generateReport),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ويدجتس الفلاتر ---

  Widget _buildSalesReportTypeSelector(BuildContext context, ReportViewModel vm) {
    return DropdownButtonFormField<SalesReportType>(
      initialValue: vm.salesReportType,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.reportType,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(
          value: SalesReportType.summary,
          child: Text(AppLocalizations.of(context)!.reportTypeSummary),
        ),
        DropdownMenuItem(
          value: SalesReportType.detailed,
          child: Text(AppLocalizations.of(context)!.reportTypeDetailed),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          vm.setSalesReportType(value);
        }
      },
    );
  }

  Widget _buildCustomerSelector(BuildContext context, ReportViewModel vm, List<Customer> customers) {
    final Customer? selectedCustomer = vm.selectedCustomer;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: DropdownButtonFormField<Customer?>(
        initialValue: selectedCustomer,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.selectCustomer,
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem<Customer?>(
            value: null,
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
          vm.setSelectedCustomer(customer);
        },
      ),
    );
  }

  Widget _buildProductMultiSelect(BuildContext context, ReportViewModel vm, List<Product> products) {
    final List<Product> selectedProducts = vm.selectedProducts;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.inventory),
        label: Text(
          selectedProducts.isEmpty
              ? AppLocalizations.of(context)!.selectProducts
              : AppLocalizations.of(context)!.productsSelected(selectedProducts.length),
        ),
        onPressed: () {
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
      vm.setDateRange(_startDate, _endDate);
    }
  }

  void _showProductMultiSelectDialog(BuildContext context, ReportViewModel vm, List<Product> allProducts) {
    showDialog(
      context: context,
      builder: (dialogContext) {
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
                    vm.setSelectedProducts(tempSelected);
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