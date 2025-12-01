import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class PurchaseSummarySection extends StatelessWidget {
  final double subTotal;
  final double discount;
  
  const PurchaseSummarySection({
    super.key,
    required this.subTotal,
    required this.discount,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final total = subTotal - discount;

    return Card(
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _summaryRow(t.subTotalSummaryLabel, subTotal),
            const Divider(),
            _summaryRow(t.discountLabel, discount, isNegative: true),
            const Divider(),
            _summaryRow(t.netTotalSummaryLabel, total, isBold: true, color: Colors.green[800]),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isNegative = false, bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 16,
          ),
        ),
        Text(
          '${isNegative ? "- " : ""}${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 16,
            color: color ?? (isNegative ? Colors.red : Colors.black),
          ),
        ),
      ],
    );
  }
}