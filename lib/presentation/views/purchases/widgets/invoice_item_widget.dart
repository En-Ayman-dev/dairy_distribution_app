import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/purchase_item.dart';
import '../../../viewmodels/product_viewmodel.dart';
import '../../../../l10n/app_localizations.dart';

class InvoiceItemWidget extends StatelessWidget {
  final PurchaseItem item;
  final VoidCallback onRemove;

  const InvoiceItemWidget({
    super.key,
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    // البحث عن اسم المنتج باستخدام الـ ID
    final productVm = context.watch<ProductViewModel>();
    final product = productVm.products
        .where((p) => p.id == item.productId)
        .firstOrNull;
    
    final productName = product?.name ?? localizations.unknownProduct;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. أيقونة المنتج (جانبية)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_offer_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // 2. تفاصيل المنتج (الوسط)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المنتج
                    Text(
                      productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // التفاصيل (الكمية، المجاني، السعر)
                    // نستخدم Wrap بدلاً من Row لمنع overflow
                    Wrap(
                      spacing: 8.0, // مسافة أفقية بين العناصر
                      runSpacing: 6.0, // مسافة عمودية بين الأسطر
                      children: [
                        // كبسولة الكمية
                        _buildInfoChip(
                          context,
                          label: '${localizations.quantityLabel}: ${item.quantity.toStringAsFixed(0)}',
                          icon: Icons.inventory_2_outlined,
                          bgColor: Colors.grey[100],
                          textColor: Colors.grey[800],
                        ),
                        
                        // كبسولة المجاني (تظهر فقط إذا وجدت)
                        if (item.freeQuantity > 0)
                          _buildInfoChip(
                            context,
                            label: '+${item.freeQuantity.toStringAsFixed(0)} ${localizations.freeLabel}',
                            icon: Icons.card_giftcard,
                            bgColor: Colors.green[50],
                            textColor: Colors.green[800],
                          ),

                        // كبسولة سعر الوحدة
                        _buildInfoChip(
                          context,
                          label: item.price.toStringAsFixed(2),
                          icon: Icons.attach_money,
                          bgColor: Colors.blue[50],
                          textColor: Colors.blue[800],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 3. الإجمالي وزر الحذف (اليسار)
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // الإجمالي
                  Text(
                    item.total.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // زر الحذف
                  InkWell(
                    onTap: onRemove,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ويدجت مساعد لإنشاء الكبسولات الصغيرة
  Widget _buildInfoChip(BuildContext context, {
    required String label,
    required IconData icon,
    Color? bgColor,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: (textColor ?? Colors.grey).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}