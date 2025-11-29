import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/supplier_viewmodel.dart';
import '../../../l10n/app_localizations.dart';

// Improve Suppliers list UX
// - Card based items with avatars
// - Swipe to delete (Dismissible) with Undo
// - Modal bottom sheet for Add/Edit supplier with validation

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierViewModel>().loadSuppliers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.suppliersTitle),
      ),
      body: Consumer<SupplierViewModel>(
        builder: (context, vm, child) {
          if (vm.state == SupplierViewState.loading) return const Center(child: CircularProgressIndicator());
          if (vm.state == SupplierViewState.error) return Center(child: Text(vm.errorMessage ?? 'Error'));

          if (vm.suppliers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_shipping, size: 56, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.of(context)!.noSuppliersFound, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context)!.addSupplierTitle),
                    onPressed: () => _showAddEditSupplierSheet(context),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => vm.loadSuppliers(),
            child: ListView.builder(
              itemCount: vm.suppliers.length,
              itemBuilder: (context, index) {
              final s = vm.suppliers[index];
              return Dismissible(
                key: Key(s.id),
                background: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.centerLeft,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.horizontal,
                secondaryBackground: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(color: Colors.blueGrey, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  // show a small confirmation before deleting
                  if (direction == DismissDirection.endToStart) {
                    // treat this as an edit gesture - open edit sheet
                    _showAddEditSupplierSheet(context, supplier: s);
                    return false;
                  }
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text(AppLocalizations.of(context)!.confirmDeleteSupplier),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(AppLocalizations.of(context)!.cancel)),
                        ElevatedButton(onPressed: () => Navigator.pop(c, true), child: Text(AppLocalizations.of(context)!.delete)),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _handleDeleteWithUndo(context, s);
                    return true;
                  }
                  return false;
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      child: Text(s.name.isEmpty ? '?' : s.name[0].toUpperCase(), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                    ),
                    title: Text(s.name, style: Theme.of(context).textTheme.titleMedium),
                    subtitle: Text(s.contact ?? '' , style: Theme.of(context).textTheme.bodyMedium),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _showAddEditSupplierSheet(context, supplier: s),
                          icon: const Icon(Icons.edit),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => _deleteSupplierWithUndo(context, s),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSupplierSheet(context),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.add),
      ),
    );
  }

  void _showAddEditSupplierSheet(BuildContext context, {supplier}) {
    final nameController = TextEditingController(text: supplier?.name);
    final contactController = TextEditingController(text: supplier?.contact);
    final addressController = TextEditingController(text: supplier?.address);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 12),
                Text(supplier == null ? AppLocalizations.of(context)!.addSupplierTitle : AppLocalizations.of(context)!.editSupplierTitle,
                    style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.supplierName),
                  validator: (value) => (value == null || value.trim().isEmpty) ? AppLocalizations.of(context)!.supplierNameRequired : null,
                ),
                const SizedBox(height: 8),
                TextFormField(controller: contactController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.contact), keyboardType: TextInputType.phone),
                const SizedBox(height: 8),
                TextFormField(controller: addressController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.address)),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final vm = context.read<SupplierViewModel>();
                    if (supplier == null) {
                      final success = await vm.addSupplier(name: nameController.text.trim(), contact: contactController.text.isEmpty ? null : contactController.text.trim(), address: addressController.text.isEmpty ? null : addressController.text.trim());
                      if (success) {
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.supplierAddedSuccess)));
                      }
                    } else {
                      final updated = supplier.copyWith(name: nameController.text.trim(), contact: contactController.text.trim(), address: addressController.text.trim(), updatedAt: DateTime.now());
                      final success = await vm.updateSupplier(updated);
                      if (success) {
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.supplierUpdatedSuccess)));
                      }
                    }
                  },
                  child: Text(supplier == null ? AppLocalizations.of(context)!.add : AppLocalizations.of(context)!.update),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Using the bottom sheet for both Add + Edit now. The old dialog is replaced.

  Future<void> _deleteSupplierWithUndo(BuildContext context, supplier) async {
    // Delete and show undo
    final vm = context.read<SupplierViewModel>();
    final deleted = supplier;
    final success = await vm.deleteSupplier(supplier.id);
    if (success) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${deleted.name} - ${AppLocalizations.of(context)!.supplierDeletedSuccess}'),
        action: SnackBarAction(label: AppLocalizations.of(context)!.undo, onPressed: () async {
          await vm.addSupplier(name: deleted.name, contact: deleted.contact, address: deleted.address);
        }),
      ));
    }
  }

  Future<void> _handleDeleteWithUndo(BuildContext context, supplier) async {
    await _deleteSupplierWithUndo(context, supplier);
  }
}
