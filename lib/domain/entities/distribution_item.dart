import 'package:equatable/equatable.dart';

class DistributionItem extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final double quantity;
  final double price;
  final double subtotal;

  const DistributionItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  DistributionItem copyWith({
    String? id,
    String? productId,
    String? productName,
    double? quantity,
    double? price,
    double? subtotal,
  }) {
    return DistributionItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        quantity,
        price,
        subtotal,
      ];
}