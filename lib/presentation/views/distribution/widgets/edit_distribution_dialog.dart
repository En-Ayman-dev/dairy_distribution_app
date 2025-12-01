import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/distribution.dart';
import '../../../../domain/entities/distribution_item.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../viewmodels/distribution_viewmodel.dart';
import '../../../widgets/common/info_display_row.dart'; // استخدام InfoDisplayRow

class EditDistributionDialog extends StatefulWidget {
  final Distribution distribution;

  const EditDistributionDialog({
    super.key,
    required this.distribution,
  });

  @override
  State<EditDistributionDialog> createState() => _EditDistributionDialogState();
}

class _EditDistributionDialogState extends State<EditDistributionDialog> {
  late final TextEditingController paidController;
  late final TextEditingController notesController;
  late final List<TextEditingController> qtyControllers;
  late final List<TextEditingController> priceControllers;
  late double currentTotal;

  @override
  void initState() {
    super.initState();
    final dist = widget.distribution;
    paidController = TextEditingController(
      text: dist.paidAmount.toStringAsFixed(2),
    );
    notesController = TextEditingController(text: dist.notes ?? '');
    qtyControllers = dist.items
        .map((it) => TextEditingController(text: it.quantity.toString()))
        .toList();
    priceControllers = dist.items
        .map((it) => TextEditingController(text: it.price.toStringAsFixed(2)))
        .toList();
    currentTotal = _computeTotal();
    
    // Add listeners to recompute total whenever item quantity/price changes
    for (var c in qtyControllers) {
      c.addListener(_updateTotal);
    }
    for (var c in priceControllers) {
      c.addListener(_updateTotal);
    }
    paidController.addListener(() => setState((){})); // Listen to paid change for remaining display
  }

  void _updateTotal() {
    final newTotal = _computeTotal();
    if (newTotal != currentTotal) {
      setState(() {
        currentTotal = newTotal;
      });
    }
  }
  
  double _computeTotal() {
    double s = 0.0;
    for (var i = 0; i < widget.distribution.items.length; i++) {
      final q = double.tryParse(qtyControllers[i].text) ?? 0.0;
      final p = double.tryParse(priceControllers[i].text) ?? 0.0;
      s += q * p;
    }
    return s;
  }

  @override
  void dispose() {
    paidController.dispose();
    notesController.dispose();
    for (final c in qtyControllers) {
      c.removeListener(_updateTotal);
      c.dispose();
    }
    for (final c in priceControllers) {
      c.removeListener(_updateTotal);
      c.dispose();
    }
    super.dispose();
  }
  
  Future<void> _saveChanges() async {
    final t = AppLocalizations.of(context)!;
    final dist = widget.distribution;
    final vm = context.read<DistributionViewModel>();
    
    // Build updated items
    final updatedItems = <DistributionItem>[];
    for (var i = 0; i < dist.items.length; i++) {
      final it = dist.items[i];
      final q = double.tryParse(qtyControllers[i].text) ?? 0.0;
      final p = double.tryParse(priceControllers[i].text) ?? 0.0;
      updatedItems.add(
        it.copyWith(quantity: q, price: p, subtotal: q * p),
      );
    }

    final newTotal = currentTotal;
    final newPaid = double.tryParse(paidController.text) ?? dist.paidAmount;
    final newNotes = notesController.text.trim();

    PaymentStatus newStatus = PaymentStatus.pending;
    if (newPaid >= newTotal) {
      newStatus = PaymentStatus.paid;
    } else if (newPaid > 0) {
      newStatus = PaymentStatus.partial;
    }

    final updated = dist.copyWith(
      items: updatedItems,
      totalAmount: newTotal,
      paidAmount: newPaid,
      notes: newNotes.isEmpty ? null : newNotes,
      paymentStatus: newStatus,
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, true); // Close the dialog

    final ok = await vm.updateDistribution(updated);
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok 
          ? '${t.distributionLabel} ${dist.id.substring(0, 8)} ${t.distributionUpdatedSuccess}' 
          : vm.errorMessage ?? t.errorOccurred),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final dist = widget.distribution;

    final newPaid = double.tryParse(paidController.text) ?? dist.paidAmount;
    final remaining = (currentTotal - newPaid).clamp(0, double.infinity);

    return AlertDialog(
      title: Text('${t.editLabel} ${t.distributionLabel} ${dist.id.substring(0, 8)}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t.customerDetailsTitle}: ${dist.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            
            // Items editing
            ...List.generate(dist.items.length, (i) {
              final it = dist.items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyControllers[i],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: t.quantityLabel),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: priceControllers[i],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: t.priceLabel),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const Divider(),
            
            // Summary and paid amount
            InfoDisplayRow(
              label: t.totalSummaryLabel,
              value: '${currentTotal.toStringAsFixed(2)} ${t.currencySymbol}',
              isHighlight: true,
            ),
            const SizedBox(height: 8),

            TextField(
              controller: paidController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: t.paid),
            ),
            const SizedBox(height: 8),
            
            // Notes
            TextField(
              controller: notesController,
              keyboardType: TextInputType.text,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'ملاحظات'),
            ),
            const SizedBox(height: 8),
            
            // Remaining Balance
            InfoDisplayRow(
              label: t.remainingAmount,
              value: '${remaining.toStringAsFixed(2)} ${t.currencySymbol}',
              valueColor: remaining > 0 ? Colors.red.shade700 : Colors.green.shade700,
              isHighlight: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: Text(t.confirm),
        ),
      ],
    );
  }
} 