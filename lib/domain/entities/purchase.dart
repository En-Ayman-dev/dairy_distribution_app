import 'package:equatable/equatable.dart';
import 'purchase_item.dart';

class Purchase extends Equatable {
  final String id;
  final String supplierId;
  final List<PurchaseItem> items; // قائمة المنتجات في الفاتورة
  final double discount; // قيمة الخصم على إجمالي الفاتورة
  final DateTime createdAt;
  final DateTime updatedAt;

  const Purchase({
    required this.id,
    required this.supplierId,
    required this.items,
    this.discount = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  // حساب إجمالي الفاتورة قبل الخصم (مجموع أسعار العناصر)
  double get subTotal {
    return items.fold(0.0, (sum, item) => sum + item.total);
  }

  // حساب الصافي النهائي (بعد الخصم)
  double get totalAmount {
    return subTotal - discount;
  }

  // حساب إجمالي الكميات (اختياري، للإحصائيات)
  double get totalQuantity {
    return items.fold(0.0, (sum, item) => sum + item.totalQuantity);
  }

  Purchase copyWith({
    String? id,
    String? supplierId,
    List<PurchaseItem>? items,
    double? discount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Purchase(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      items: items ?? this.items,
      discount: discount ?? this.discount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        supplierId,
        items,
        discount,
        createdAt,
        updatedAt,
      ];
}