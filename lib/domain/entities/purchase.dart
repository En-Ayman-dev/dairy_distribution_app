import 'package:equatable/equatable.dart';

class Purchase extends Equatable {
  final String id;
  final String productId;
  final String supplierId;
  final double quantity;
  final double freeQuantity; // الكمية المجانية (الإضافية)
  final double price; // purchase price
  final DateTime createdAt;
  final DateTime updatedAt;

  const Purchase({
    required this.id,
    required this.productId,
    required this.supplierId,
    required this.quantity,
    this.freeQuantity = 0.0, // القيمة الافتراضية 0
    required this.price,
    required this.createdAt,
    required this.updatedAt,
  });

  Purchase copyWith({
    String? id,
    String? productId,
    String? supplierId,
    double? quantity,
    double? freeQuantity,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Purchase(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      supplierId: supplierId ?? this.supplierId,
      quantity: quantity ?? this.quantity,
      freeQuantity: freeQuantity ?? this.freeQuantity,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        supplierId,
        quantity,
        freeQuantity,
        price,
        createdAt,
        updatedAt,
      ];
}