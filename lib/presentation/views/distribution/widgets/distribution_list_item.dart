import 'package:flutter/material.dart';
import '../../../../domain/entities/distribution.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/status_badge.dart'; // استخدام StatusBadge
import '../../../widgets/common/confirmation_dialog.dart'; // استخدام ConfirmationDialog

class DistributionListItem extends StatelessWidget {
  final Distribution distribution;
  final VoidCallback onEdit;
  final VoidCallback onPrint;
  final Function(Distribution) onDelete;
  final VoidCallback onTap;

  const DistributionListItem({
    super.key,
    required this.distribution,
    required this.onEdit,
    required this.onPrint,
    required this.onDelete,
    required this.onTap,
  });

  String _mapPaymentStatusToString(PaymentStatus status, AppLocalizations t) {
    switch (status) {
      case PaymentStatus.paid:
        return t.paid;
      case PaymentStatus.partial:
        return t.partial;
      case PaymentStatus.pending:
        return t.pending;
      }
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    await ConfirmationDialog.show(
      context,
      title: t.deleteDistributionTitle,
      content: '${t.deleteDistributionConfirm}\n${t.distributionLabel} ${distribution.id.substring(0, 8)}',
      confirmText: t.deleteLabel,
      isDestructive: true,
      onConfirm: () => onDelete(distribution),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0.5,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.local_shipping, color: theme.colorScheme.primary),
        ),
        title: Text(
          distribution.customerName,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${distribution.distributionDate.day}/${distribution.distributionDate.month}/${distribution.distributionDate.year}',
              style: theme.textTheme.bodySmall,
            ),
            StatusBadge(
              status: _mapPaymentStatusToString(distribution.paymentStatus, t),
            ),
          ],
        ),
        trailing: SizedBox(
          width: 200, 
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Total Amount
              Expanded(
                child: Text(
                  '${distribution.totalAmount.toStringAsFixed(2)} ${t.currencySymbol}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: distribution.paymentStatus != PaymentStatus.paid ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
              ),
              
              // Print Button
              IconButton(
                tooltip: t.printTooltip,
                icon: const Icon(Icons.print, size: 20),
                onPressed: onPrint,
              ),
              
              // Edit Button
              IconButton(
                tooltip: t.editLabel,
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEdit,
              ),
              
              // Delete Button
              IconButton(
                tooltip: t.deleteLabel,
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                onPressed: () => _confirmAndDelete(context),
              ),
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}