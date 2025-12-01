import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../viewmodels/purchase_viewmodel.dart';
import '../../../widgets/common/empty_list_state.dart';
import 'invoice_item_widget.dart'; // تأكد من وجود هذا الملف أو استبداله بمكون مخصص

class PurchaseCartList extends StatelessWidget {
  const PurchaseCartList({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final purchaseVm = context.watch<PurchaseViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${t.invoiceContentsTitle} (${purchaseVm.cartItems.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (purchaseVm.cartItems.isEmpty)
           EmptyListState(
             message: t.noProductsAdded,
             icon: Icons.shopping_basket_outlined,
           )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: purchaseVm.cartItems.length,
            itemBuilder: (context, index) {
              final item = purchaseVm.cartItems[index];
              // ملاحظة: نفترض أن InvoiceItemWidget موجود مسبقاً كما في الكود الأصلي
              return InvoiceItemWidget(
                item: item,
                onRemove: () => purchaseVm.removeFromCart(item.productId),
              );
            },
          ),
      ],
    );
  }
}