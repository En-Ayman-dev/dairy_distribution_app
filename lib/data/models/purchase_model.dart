import '../../domain/entities/purchase.dart';
import 'purchase_item_model.dart';

class PurchaseModel extends Purchase {
  const PurchaseModel({
    required super.id,
    required super.supplierId,
    required super.items,
    super.discount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id'] as String? ?? '',
      supplierId: json['supplier_id'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PurchaseItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_id': supplierId,
      // تحويل كل عنصر في القائمة إلى JSON باستخدام PurchaseItemModel
      'items': items.map((e) => PurchaseItemModel.fromEntity(e).toJson()).toList(),
      'discount': discount,
      // تخزين القيم المحسوبة لتسهيل الاستعلامات والتقارير
      'sub_total': subTotal,
      'total_amount': totalAmount,
      'total_quantity': totalQuantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PurchaseModel.fromMap(Map<String, dynamic> map) {
    return PurchaseModel(
      id: map['id'] as String? ?? '',
      supplierId: map['supplier_id'] as String? ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((e) => PurchaseItemModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
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
      'supplier_id': supplierId,
      'items': items.map((e) => PurchaseItemModel.fromEntity(e).toMap()).toList(),
      'discount': discount,
      'sub_total': subTotal,
      'total_amount': totalAmount,
      'total_quantity': totalQuantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': 0,
      'firebase_id': id,
    };
  }

  factory PurchaseModel.fromEntity(Purchase purchase) {
    return PurchaseModel(
      id: purchase.id,
      supplierId: purchase.supplierId,
      items: purchase.items,
      discount: purchase.discount,
      createdAt: purchase.createdAt,
      updatedAt: purchase.updatedAt,
    );
  }
}