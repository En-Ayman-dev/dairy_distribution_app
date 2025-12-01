import 'package:flutter/material.dart';
import '../../../../domain/entities/supplier.dart';
import '../../../../l10n/app_localizations.dart';

class PurchaseHeaderForm extends StatelessWidget {
  final List<Supplier> suppliers;
  final String? selectedSupplierId;
  final TextEditingController discountController;
  final ValueChanged<String?> onSupplierChanged;

  const PurchaseHeaderForm({
    super.key,
    required this.suppliers,
    required this.selectedSupplierId,
    required this.discountController,
    required this.onSupplierChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedSupplierId,
              items: suppliers
                  .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                  .toList(),
              onChanged: onSupplierChanged,
              decoration: InputDecoration(
                labelText: t.supplierLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.store),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: discountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: t.totalDiscountLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.discount),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}