import '../../domain/entities/supplier_payment.dart';

class SupplierPaymentModel extends SupplierPayment {
  const SupplierPaymentModel({
    required super.id,
    required super.supplierId,
    required super.amount,
    required super.paymentDate,
    super.notes,
    required super.createdAt,
  });

  factory SupplierPaymentModel.fromJson(Map<String, dynamic> json) {
    return SupplierPaymentModel(
      id: json['id'] as String? ?? '',
      supplierId: json['supplier_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'] as String)
          : DateTime.now(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SupplierPaymentModel.fromMap(Map<String, dynamic> map) {
    return SupplierPaymentModel(
      id: map['id'] as String? ?? '',
      supplierId: map['supplier_id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: map['payment_date'] != null
          ? DateTime.parse(map['payment_date'] as String)
          : DateTime.now(),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'sync_status': 0,
      'firebase_id': id,
    };
  }

  factory SupplierPaymentModel.fromEntity(SupplierPayment payment) {
    return SupplierPaymentModel(
      id: payment.id,
      supplierId: payment.supplierId,
      amount: payment.amount,
      paymentDate: payment.paymentDate,
      notes: payment.notes,
      createdAt: payment.createdAt,
    );
  }
}