import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/customer_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../../domain/entities/customer.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? customer;

  const AddCustomerScreen({super.key, this.customer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  CustomerStatus _selectedStatus = CustomerStatus.active;

  bool get isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name);
    _phoneController = TextEditingController(text: widget.customer?.phone);
    _emailController = TextEditingController(text: widget.customer?.email);
    _addressController = TextEditingController(text: widget.customer?.address);
    _selectedStatus = widget.customer?.status ?? CustomerStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      final customerViewModel = context.read<CustomerViewModel>();
      bool success;

      if (isEditing) {
        final updatedCustomer = widget.customer!.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          status: _selectedStatus,
          updatedAt: DateTime.now(),
        );
        success = await customerViewModel.updateCustomer(updatedCustomer);
      } else {
        success = await customerViewModel.addCustomer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? AppLocalizations.of(context)!.customerUpdatedSuccess
                  : AppLocalizations.of(context)!.customerAddedSuccess,
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(customerViewModel.errorMessage ?? AppLocalizations.of(context)!.failedToSaveCustomer),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? AppLocalizations.of(context)!.editCustomerTitle : AppLocalizations.of(context)!.addCustomerTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomTextField(
              controller: _nameController,
              label: AppLocalizations.of(context)!.customerNameLabel,
              hint: AppLocalizations.of(context)!.enterCustomerNameHint,
              prefixIcon: Icons.person_outline,
              validator: Validators.validateName,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _phoneController,
              label: AppLocalizations.of(context)!.phoneNumberLabel,
              hint: AppLocalizations.of(context)!.enterPhoneHint,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhone,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              label: AppLocalizations.of(context)!.emailOptionalLabel,
              hint: AppLocalizations.of(context)!.enterEmailHintShort,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _addressController,
              label: AppLocalizations.of(context)!.addressOptionalLabel,
              hint: AppLocalizations.of(context)!.enterAddressHint,
              prefixIcon: Icons.location_on_outlined,
              maxLines: 3,
            ),
            if (isEditing) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<CustomerStatus>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.statusLabel,
                  prefixIcon: const Icon(Icons.info_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                items: CustomerStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status.toString().split('.').last.toUpperCase(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
            ],
            const SizedBox(height: 32),
            Consumer<CustomerViewModel>(
              builder: (context, viewModel, child) {
                return CustomButton(
                  text: isEditing ? AppLocalizations.of(context)!.updateCustomerLabel : AppLocalizations.of(context)!.addCustomerLabel,
                  onPressed: _saveCustomer,
                  icon: isEditing ? Icons.check : Icons.add,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}