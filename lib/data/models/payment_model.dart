import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.customerId,
    required super.amount,
    required super.paymentMethod,
    required super.paymentDate,
    super.notes,
    required super.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: _methodFromString(json['payment_method'] as String),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'amount': amount,
      'payment_method': _methodToString(paymentMethod),
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: _methodFromString(map['payment_method'] as String),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'amount': amount,
      'payment_method': _methodToString(paymentMethod),
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'sync_status': 0,
      'firebase_id': id,
    };
  }

  static PaymentMethod _methodFromString(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return PaymentMethod.cash;
      case 'upi':
        return PaymentMethod.upi;
      case 'card':
        return PaymentMethod.card;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      default:
        return PaymentMethod.cash;
    }
  }

  static String _methodToString(PaymentMethod method) {
    return method.toString().split('.').last;
  }
}