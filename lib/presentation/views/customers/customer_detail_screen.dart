import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/customer.dart';
import '../../viewmodels/distribution_viewmodel.dart';
import '../../viewmodels/customer_viewmodel.dart';
import '../../../app/routes/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/confirmation_dialog.dart'; // استخدام الـ Dialog المُعاد هيكلته
import '../payments/payments_screen.dart';
import 'widgets/customer_info_card.dart'; // المكون الجديد
import 'widgets/customer_distribution_history.dart'; // المكون الجديد

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // تحميل سجل التوزيع عند فتح الشاشة
      context.read<DistributionViewModel>().loadDistributionsByCustomer(
        widget.customer.id,
      );
    });
  }

  Future<void> _deleteCustomer() async {
    final t = AppLocalizations.of(context)!;
    final customerVm = context.read<CustomerViewModel>();

    // استخدام الـ ConfirmationDialog المُعاد هيكلته
    await ConfirmationDialog.show(
      context,
      title: t.deleteCustomerTitle,
      content: t.deleteCustomerConfirm,
      confirmText: t.deleteLabel,
      isDestructive: true,
      onConfirm: () async {
        final success = await customerVm.deleteCustomer(widget.customer.id);

        if (success && mounted) {
          Navigator.pop(context); // إغلاق شاشة التفاصيل
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.customerDeletedSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // ملاحظة: تم إزالة الدوال المساعدة القديمة (_buildInfoRow, _buildStatusChip, _buildPaymentStatusChip)

    return Scaffold(
      appBar: AppBar(
        title: Text(t.customerDetailsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.editCustomer,
                arguments: widget.customer,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteCustomer,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Customer Info Card (مكون موحد)
            CustomerInfoCard(customer: widget.customer),
            // زر إضافة دفعة جديد وموحد
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // دالة _showCustomerPaymentDialog لم يتم استخدامها في الكود الأصلي،
                    // ولكن سنعتمد على النمط الأفضل وهو توفير زر موحد في AppBar
                    // Navigator.pushNamed(
                    //   context,
                    //   AppRoutes.customerPaymentPage, // نفترض وجود هذا المسار
                    //   arguments: widget.customer,
                    // );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CustomerPaymentPage(customer: widget.customer),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.attach_money,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: Text(
                    t.addPaymentLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ),
            // 2. Distribution History (مكون موحد)
            CustomerDistributionHistory(customerId: widget.customer.id),
          ],
        ),
      ),
    );
  }
}
