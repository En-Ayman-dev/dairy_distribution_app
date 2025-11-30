// مسار الملف: lib/domain/entities/purchase_item.dart

import 'package:equatable/equatable.dart';

class PurchaseItem extends Equatable {
  final String productId;
  final double quantity;      // الكمية المدفوعة
  final double freeQuantity;  // الكمية المجانية
  final double price;         // سعر الشراء للوحدة
  final double returnedQuantity; // الكمية التي تم إرجاعها من هذا الصنف

  const PurchaseItem({
    required this.productId,
    required this.quantity,
    this.freeQuantity = 0.0,
    required this.price,
    this.returnedQuantity = 0.0,
  });

  // حساب إجمالي السعر لهذا الصنف (بدون الكمية المجانية طبعاً)
  double get total => quantity * price;

  // إجمالي الكمية (المدفوعة + المجانية)
  double get totalQuantity => quantity + freeQuantity;

  PurchaseItem copyWith({
    String? productId,
    double? quantity,
    double? freeQuantity,
    double? price,
    double? returnedQuantity,
  }) {
    return PurchaseItem(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      freeQuantity: freeQuantity ?? this.freeQuantity,
      price: price ?? this.price,
      returnedQuantity: returnedQuantity ?? this.returnedQuantity,
    );
  }

  @override
  List<Object?> get props => [productId, quantity, freeQuantity, price, returnedQuantity];
}