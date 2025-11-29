import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/supplier_viewmodel.dart';
import '../../../l10n/app_localizations.dart';

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

          if (vm.suppliers.isEmpty) return Center(child: Text(AppLocalizations.of(context)!.noSuppliersFound));

          return ListView.builder(
            itemCount: vm.suppliers.length,
            itemBuilder: (context, index) {
              final s = vm.suppliers[index];
              return ListTile(
                title: Text(s.name),
                subtitle: Text(s.contact ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showEditSupplierDialog(context, s),
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () => _deleteSupplier(s.id),
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSupplierDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context) {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addSupplierTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.supplierName)),
            TextField(controller: contactController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.contact)),
            TextField(controller: addressController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.address)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(onPressed: () async {
            final vm = context.read<SupplierViewModel>();
            final success = await vm.addSupplier(name: nameController.text, contact: contactController.text.isEmpty ? null : contactController.text, address: addressController.text.isEmpty ? null : addressController.text);
            if (success) {
              if (!mounted) return;
              Navigator.of(context).pop();
            }
          }, child: Text(AppLocalizations.of(context)!.add)),
        ],
      ),
    );
  }

  void _showEditSupplierDialog(BuildContext context, supplier) {
    final nameController = TextEditingController(text: supplier.name);
    final contactController = TextEditingController(text: supplier.contact);
    final addressController = TextEditingController(text: supplier.address);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editSupplierTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.supplierName)),
            TextField(controller: contactController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.contact)),
            TextField(controller: addressController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.address)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(onPressed: () async {
            final vm = context.read<SupplierViewModel>();
            final updated = supplier.copyWith(name: nameController.text, contact: contactController.text, address: addressController.text, updatedAt: DateTime.now());
            final success = await vm.updateSupplier(updated);
            if (success) {
              if (!mounted) return;
              Navigator.of(context).pop();
            }
          }, child: Text(AppLocalizations.of(context)!.update)),
        ],
      ),
    );
  }

  void _deleteSupplier(String id) async {
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
      final vm = context.read<SupplierViewModel>();
      await vm.deleteSupplier(id);
    }
  }
}
