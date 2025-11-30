import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../viewmodels/supplier_viewmodel.dart';
import '../widgets/add_payment_dialog.dart';
import '../../../../l10n/app_localizations.dart';

class SupplierPaymentsTab extends StatefulWidget {
  final String? supplierId;

  const SupplierPaymentsTab({super.key, this.supplierId});

  @override
  State<SupplierPaymentsTab> createState() => _SupplierPaymentsTabState();
}

class _SupplierPaymentsTabState extends State<SupplierPaymentsTab> {
  @override
  void didUpdateWidget(covariant SupplierPaymentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.supplierId != oldWidget.supplierId && widget.supplierId != null) {
      _loadData();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.supplierId != null) {
      _loadData();
    }
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierViewModel>().loadSupplierFinancials(widget.supplierId!);
    });
  }

  void _showAddPaymentDialog(BuildContext context) {
    if (widget.supplierId == null) return;
    
    showDialog(
      context: context,
      builder: (_) => AddPaymentDialog(supplierId: widget.supplierId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (widget.supplierId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              localizations.selectSupplierPrompt,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final supplierVm = context.watch<SupplierViewModel>();
    final locale = localizations.localeName;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // استخدام CustomScrollView لحل مشكلة الـ Overflow
      body: CustomScrollView(
        slivers: [
          // 1. بطاقة المديونية والعنوان (عناصر غير قابلة للتكرار)
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildDebtCard(context, supplierVm.currentSupplierDebt),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.history, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        localizations.paymentHistoryTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // 2. قائمة المدفوعات أو رسالة "لا يوجد"
          if (supplierVm.currentSupplierPayments.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  localizations.noPaymentsFound,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final payment = supplierVm.currentSupplierPayments[index];
                    final dateStr = DateFormat.yMMMd(locale).add_jm().format(payment.paymentDate);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withOpacity(0.1),
                          child: const Icon(Icons.check, color: Colors.green),
                        ),
                        title: Text(
                          payment.amount.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(dateStr, style: const TextStyle(fontSize: 12)),
                            if (payment.notes != null && payment.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(payment.notes!, style: const TextStyle(fontStyle: FontStyle.italic)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: supplierVm.currentSupplierPayments.length,
                ),
              ),
            ),
            
          // مسافة سفلية إضافية لضمان عدم تغطية الزر العائم لآخر عنصر
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPaymentDialog(context),
        icon: const Icon(Icons.add_card),
        label: Text(localizations.addPaymentLabel),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, double debt) {
    final localizations = AppLocalizations.of(context)!;
    final isZero = debt == 0;
    final isNegative = debt < 0; 
    
    Color cardColor = isZero ? Colors.blue : (isNegative ? Colors.green : Colors.red);
    
    String statusText = isZero 
        ? localizations.debtStatusPaid 
        : (isNegative ? localizations.debtStatusCredit : localizations.debtStatusDue);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor.withOpacity(0.8), cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            localizations.currentDebtLabel,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            debt.abs().toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}