import 'package:equatable/equatable.dart';

class Purchase extends Equatable {
  final String id;
  final String productId;
  final String supplierId;
  final double quantity;
  final double price; // purchase price
  final DateTime createdAt;
  final DateTime updatedAt;

  const Purchase({
    required this.id,
    required this.productId,
    required this.supplierId,
    required this.quantity,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
  });

  Purchase copyWith({
    String? id,
    String? productId,
    String? supplierId,
    double? quantity,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Purchase(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      supplierId: supplierId ?? this.supplierId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, productId, supplierId, quantity, price, createdAt, updatedAt];
}
