import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.category,
    required super.unit,
    required super.price,
    super.stock,
    super.minStock,
    super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: _categoryFromString(json['category'] as String),
      unit: json['unit'] as String,
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num?)?.toDouble() ?? 0.0,
      minStock: (json['min_stock'] as num?)?.toDouble() ?? 0.0,
      status: _statusFromString(json['status'] as String? ?? 'active'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': _categoryToString(category),
      'unit': unit,
      'price': price,
      'stock': stock,
      'min_stock': minStock,
      'status': _statusToString(status),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      name: map['name'] as String,
      category: _categoryFromString(map['category'] as String),
      unit: map['unit'] as String,
      price: (map['price'] as num).toDouble(),
      stock: (map['stock'] as num?)?.toDouble() ?? 0.0,
      minStock: (map['min_stock'] as num?)?.toDouble() ?? 0.0,
      status: _statusFromString(map['status'] as String? ?? 'active'),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': _categoryToString(category),
      'unit': unit,
      'price': price,
      'stock': stock,
      'min_stock': minStock,
      'status': _statusToString(status),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': 0,
      'firebase_id': id,
    };
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      category: product.category,
      unit: product.unit,
      price: product.price,
      stock: product.stock,
      minStock: product.minStock,
      status: product.status,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );
  }

  static ProductCategory _categoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'milk':
        return ProductCategory.milk;
      case 'curd':
        return ProductCategory.curd;
      case 'butter':
        return ProductCategory.butter;
      case 'cheese':
        return ProductCategory.cheese;
      case 'paneer':
        return ProductCategory.paneer;
      case 'ghee':
        return ProductCategory.ghee;
      default:
        return ProductCategory.other;
    }
  }

  static String _categoryToString(ProductCategory category) {
    return category.toString().split('.').last;
  }

  static ProductStatus _statusFromString(String status) {
    return status.toLowerCase() == 'active'
        ? ProductStatus.active
        : ProductStatus.inactive;
  }

  static String _statusToString(ProductStatus status) {
    return status.toString().split('.').last;
  }

  @override
  ProductModel copyWith({
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
    return ProductModel(
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
}