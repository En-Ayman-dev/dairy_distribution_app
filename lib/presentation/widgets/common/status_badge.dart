import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Color? color;

  const StatusBadge({
    super.key,
    required this.status,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // تحديد اللون تلقائياً بناءً على النص إذا لم يتم تمريره
    final Color badgeColor = color ?? _getAutoColor(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12), // خلفية شفافة
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.4), width: 1),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
      ),
    );
  }

  Color _getAutoColor(BuildContext context, String status) {
    final s = status.toLowerCase();
    if (s.contains('مدفوع') || s.contains('paid') || s.contains('كتمل')) {
      return Colors.green.shade700;
    } else if (s.contains('آجل') || s.contains('pending') || s.contains('partial')) {
      return Colors.orange.shade800;
    } else if (s.contains('ملغي') || s.contains('cancel') || s.contains('مسترجع')) {
      return Colors.red.shade700;
    }
    return Theme.of(context).primaryColor;
  }
}