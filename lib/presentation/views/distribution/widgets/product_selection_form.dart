import 'package:flutter/material.dart';
import '../../../../domain/entities/customer.dart';
import '../../../../domain/entities/product.dart';
import '../../../../l10n/app_localizations.dart';

class ProductSelectionForm extends StatelessWidget {
  final List<Customer> customers;
  final List<Product> products;
  final String? selectedCustomerId;
  final String? selectedProductId;
  final TextEditingController qtyController;
  final TextEditingController priceController;
  final bool isFree;
  final ValueChanged<String?> onCustomerChanged;
  final ValueChanged<String?> onProductChanged;
  final ValueChanged<bool?> onFreeChanged;
  final VoidCallback onAddPressed;

  const ProductSelectionForm({
    super.key,
    required this.customers,
    required this.products,
    required this.selectedCustomerId,
    required this.selectedProductId,
    required this.qtyController,
    required this.priceController,
    required this.isFree,
    required this.onCustomerChanged,
    required this.onProductChanged,
    required this.onFreeChanged,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // قسم العميل
        Text(
          t.customersTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedCustomerId,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: customers.map((c) => DropdownMenuItem(
            value: c.id,
            child: Text(c.name),
          )).toList(),
          onChanged: onCustomerChanged,
        ),
        
        const SizedBox(height: 16),

        // قسم المنتج
        Text(
          t.addProductTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: selectedProductId,
                isExpanded: true,
                hint: const Text("اختر المنتج"),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: products.map((p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(p.name),
                )).toList(),
                onChanged: onProductChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.quantityLabel,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enabled: !isFree,
                decoration: InputDecoration(
                  labelText: t.priceLabel,
                  border: const OutlineInputBorder(),
                  filled: isFree,
                  fillColor: isFree ? Colors.grey.shade200 : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Checkbox(
                  value: isFree,
                  onChanged: onFreeChanged,
                ),
                const Text(
                  "مجاني",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onAddPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(t.add),
            ),
          ],
        ),
      ],
    );
  }
}