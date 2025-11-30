// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../viewmodels/supplier_viewmodel.dart';
import '../../viewmodels/purchase_viewmodel.dart';
import 'tabs/invoices_tab.dart';
import 'tabs/supplier_payments_tab.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> with SingleTickerProviderStateMixin {
  String? _selectedSupplierId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierViewModel>().loadSuppliers();
      context.read<PurchaseViewModel>().listenToAllPurchases(); 
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supplierVm = context.watch<SupplierViewModel>();
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.purchasesAndPaymentsTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: localizations.invoicesTabTitle, icon: const Icon(Icons.receipt_long)),
            Tab(text: localizations.paymentsAndDebtTabTitle, icon: const Icon(Icons.account_balance_wallet)),
          ],
        ),
      ),
      body: Column(
        children: [
          // --- شريط الفلترة (Filter Bar) ---
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text(localizations.filterBySupplierHint),
                      value: _selectedSupplierId,
                      items: [
                        // خيار "عرض الكل"
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(localizations.viewAllSuppliers, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        // قائمة الموردين
                        ...supplierVm.suppliers.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedSupplierId = val;
                        });
                        if (val != null) _tabController.animateTo(1); 
                      },
                    ),
                  ),
                ),
                if (_selectedSupplierId != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedSupplierId = null;
                      });
                    },
                  ),
              ],
            ),
          ),

          // --- محتوى التبويبات ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                InvoicesTab(supplierId: _selectedSupplierId),
                SupplierPaymentsTab(supplierId: _selectedSupplierId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}