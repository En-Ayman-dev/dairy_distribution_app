import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../viewmodels/distribution_viewmodel.dart';

class DistributionCartList extends StatelessWidget {
  const DistributionCartList({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.itemsLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          height: 220,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Consumer<DistributionViewModel>(
            builder: (context, vm, child) {
              final items = vm.currentItems;
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    t.noProductsFound,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                );
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, idx) {
                  final it = items[idx];
                  return ListTile(
                    title: Text(it.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      it.price == 0
                          ? '${it.quantity} (مجاني)'
                          : '${it.quantity} x ${it.price}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          it.subtotal.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        IconButton(
                          onPressed: () => vm.removeItem(it.id),
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}