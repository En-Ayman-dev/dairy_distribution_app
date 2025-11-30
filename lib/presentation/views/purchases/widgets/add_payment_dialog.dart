import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/supplier_viewmodel.dart';
import '../../../../l10n/app_localizations.dart';

class AddPaymentDialog extends StatefulWidget {
  final String supplierId;

  const AddPaymentDialog({super.key, required this.supplierId});

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final localizations = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      return;
    }

    setState(() => _isLoading = true);

    // استدعاء ViewModel لإضافة الدفعة
    final success = await context.read<SupplierViewModel>().addPayment(
      supplierId: widget.supplierId,
      amount: amount,
      notes: _notesController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        Navigator.pop(context); // إغلاق النافذة
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.paymentAddedSuccess)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.paymentAddedError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(localizations.addPaymentTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // حقل المبلغ
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: localizations.paymentAmountLabel,
                hintText: '0.00',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.amountRequiredError;
                }
                final val = double.tryParse(value);
                if (val == null || val <= 0) {
                  return localizations.invalidAmountError;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // حقل الملاحظات
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: localizations.paymentNotesLabel,
                hintText: localizations.paymentNotesHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.note_alt_outlined),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(localizations.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                )
              : Text(localizations.savePaymentButton),
        ),
      ],
    );
  }
}