import 'package:flutter/material.dart';
import '../../../../domain/entities/customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/info_display_row.dart';
import '../../../widgets/common/status_badge.dart'; // سنعيد استخدام StatusBadge لتبسيط _buildStatusChip

class CustomerInfoCard extends StatelessWidget {
  final Customer customer;

  const CustomerInfoCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar, Name, Status
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Text(
                    customer.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(
                        status: customer.status.name, // يعتمد على الـ enum مباشرة
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(height: 32),
            
            // Details: Balance (Highlighted)
            InfoDisplayRow(
              label: t.currentBalanceLabel,
              value: '${customer.balance.toStringAsFixed(2)} ${t.currencySymbol}',
              isHighlight: true,
              valueColor: customer.balance > 0 ? Colors.red.shade700 : Colors.green.shade700,
            ),
            const Divider(height: 16),

            // Details: Phone, Email, Address
            InfoDisplayRow(
              label: t.phoneLabel,
              value: customer.phone.isNotEmpty ? customer.phone : t.notAvailable,
            ),
            if (customer.email?.isNotEmpty == true)
              InfoDisplayRow(
                label: t.emailLabel,
                value: customer.email!,
              ),
            if (customer.address?.isNotEmpty == true)
              InfoDisplayRow(
                label: t.addressLabel,
                value: customer.address!,
              ),
          ],
        ),
      ),
    );
  }
}