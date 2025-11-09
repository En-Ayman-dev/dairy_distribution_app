import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final ProductCategory category;
  final String unit;
  final double price;
  final double stock;
  final double minStock;
  final ProductStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    this.stock = 0.0,
    this.minStock = 0.0,
    this.status = ProductStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => stock <= minStock;

  Product copyWith({
    String? id,
    String? name,
    ProductCategory? category,
    String? unit,
    double? price,
    double? stock,
    double? minStock,
    ProductStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        unit,
        price,
        stock,
        minStock,
        status,
        createdAt,
        updatedAt,
      ];
}

enum ProductCategory {
  milk,
  curd,
  butter,
  cheese,
  paneer,
  ghee,
  other,
}

enum ProductStatus {
  active,
  inactive,
}