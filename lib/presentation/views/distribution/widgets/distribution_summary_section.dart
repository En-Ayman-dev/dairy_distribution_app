import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../viewmodels/distribution_viewmodel.dart';

class DistributionSummarySection extends StatelessWidget {
  final TextEditingController paidController;

  const DistributionSummarySection({
    super.key,
    required this.paidController,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.currentStockPrefix, // ترجمة "الإجمالي"
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Consumer<DistributionViewModel>(
                  builder: (c, vm, _) => Text(
                    vm.getCurrentTotal().toStringAsFixed(2),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: paidController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: t.paid,
                prefixIcon: const Icon(Icons.monetization_on_outlined),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}