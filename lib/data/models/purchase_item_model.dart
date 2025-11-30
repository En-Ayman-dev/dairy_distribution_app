import '../../domain/entities/purchase_item.dart';

class PurchaseItemModel extends PurchaseItem {
  const PurchaseItemModel({
    required super.productId,
    required super.quantity,
    required super.price,
    super.freeQuantity,
    super.returnedQuantity,
  });

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseItemModel(
      productId: json['product_id'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      freeQuantity: (json['free_quantity'] as num?)?.toDouble() ?? 0.0,
      returnedQuantity: (json['returned_quantity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'free_quantity': freeQuantity,
      'returned_quantity': returnedQuantity,
    };
  }

  factory PurchaseItemModel.fromMap(Map<String, dynamic> map) {
    return PurchaseItemModel(
      productId: map['product_id'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      freeQuantity: (map['free_quantity'] as num?)?.toDouble() ?? 0.0,
      returnedQuantity: (map['returned_quantity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'free_quantity': freeQuantity,
      'returned_quantity': returnedQuantity,
    };
  }

  factory PurchaseItemModel.fromEntity(PurchaseItem item) {
    return PurchaseItemModel(
      productId: item.productId,
      quantity: item.quantity,
      price: item.price,
      freeQuantity: item.freeQuantity,
      returnedQuantity: item.returnedQuantity,
    );
  }
}