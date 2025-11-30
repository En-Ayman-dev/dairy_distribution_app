import '../../domain/entities/purchase.dart';

class PurchaseModel extends Purchase {
  const PurchaseModel({
    required super.id,
    required super.productId,
    required super.supplierId,
    required super.quantity,
    super.freeQuantity, // إضافة الحقل هنا (اختياري لأنه يملك قيمة افتراضية في الكيان)
    required super.price,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      supplierId: json['supplier_id'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      // قراءة الكمية المجانية مع قيمة افتراضية 0 إذا كانت null
      freeQuantity: (json['free_quantity'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'supplier_id': supplierId,
      'quantity': quantity,
      'free_quantity': freeQuantity, // تخزين الكمية المجانية
      'price': price,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PurchaseModel.fromMap(Map<String, dynamic> map) {
    return PurchaseModel(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      supplierId: map['supplier_id'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      freeQuantity: (map['free_quantity'] as num?)?.toDouble() ?? 0.0,
      price: (map['price'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'supplier_id': supplierId,
      'quantity': quantity,
      'free_quantity': freeQuantity,
      'price': price,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': 0,
      'firebase_id': id,
    };
  }

  factory PurchaseModel.fromEntity(Purchase purchase) {
    return PurchaseModel(
      id: purchase.id,
      productId: purchase.productId,
      supplierId: purchase.supplierId,
      quantity: purchase.quantity,
      freeQuantity: purchase.freeQuantity,
      price: purchase.price,
      createdAt: purchase.createdAt,
      updatedAt: purchase.updatedAt,
    );
  }
}