import '../../domain/entities/purchase.dart';

class PurchaseModel extends Purchase {
  const PurchaseModel({
    required super.id,
    required super.productId,
    required super.supplierId,
    required super.quantity,
    super.freeQuantity, 
    super.returnedQuantity,
    required super.price,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id'] as String? ?? '', // حماية ضد null في المعرف
      productId: json['product_id'] as String? ?? '',
      supplierId: json['supplier_id'] as String? ?? '',
      // استخدام التحويل الآمن (Safe Casting) للكمية والسعر
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      freeQuantity: (json['free_quantity'] as num?)?.toDouble() ?? 0.0,
      returnedQuantity: (json['returned_quantity'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(), // حماية التاريخ
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'supplier_id': supplierId,
      'quantity': quantity,
      'free_quantity': freeQuantity,
      'returned_quantity': returnedQuantity,
      'price': price,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PurchaseModel.fromMap(Map<String, dynamic> map) {
    return PurchaseModel(
      id: map['id'] as String? ?? '',
      productId: map['product_id'] as String? ?? '',
      supplierId: map['supplier_id'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      freeQuantity: (map['free_quantity'] as num?)?.toDouble() ?? 0.0,
      returnedQuantity: (map['returned_quantity'] as num?)?.toDouble() ?? 0.0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String) 
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'supplier_id': supplierId,
      'quantity': quantity,
      'free_quantity': freeQuantity,
      'returned_quantity': returnedQuantity,
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
      returnedQuantity: purchase.returnedQuantity,
      price: purchase.price,
      createdAt: purchase.createdAt,
      updatedAt: purchase.updatedAt,
    );
  }
}