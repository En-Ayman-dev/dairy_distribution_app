import '../../domain/entities/distribution_item.dart';

class DistributionItemModel extends DistributionItem {
  const DistributionItemModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.quantity,
    required super.price,
    required super.subtotal,
  });

  factory DistributionItemModel.fromJson(Map<String, dynamic> json) {
    return DistributionItemModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }

  factory DistributionItemModel.fromMap(Map<String, dynamic> map) {
    return DistributionItemModel(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      price: (map['price'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap(String distributionId) {
    return {
      'id': id,
      'distribution_id': distributionId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }

  factory DistributionItemModel.fromEntity(DistributionItem item) {
    return DistributionItemModel(
      id: item.id,
      productId: item.productId,
      productName: item.productName,
      quantity: item.quantity,
      price: item.price,
      subtotal: item.subtotal,
    );
  }
}