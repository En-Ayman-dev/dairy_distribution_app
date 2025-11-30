import '../../domain/entities/distribution.dart';
import '../../domain/entities/distribution_item.dart';

class DistributionModel extends Distribution {
  const DistributionModel({
    required super.id,
    required super.customerId,
    required super.customerName,
    required super.distributionDate,
    required super.items,
    required super.totalAmount,
    super.paidAmount,
    super.paymentStatus,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DistributionModel.fromJson(
    Map<String, dynamic> json,
    List<DistributionItem> items,
  ) {
    return DistributionModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String,
      distributionDate: DateTime.parse(json['distribution_date'] as String),
      items: items,
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: _statusFromString(json['payment_status'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'distribution_date': distributionDate.toIso8601String(),
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'payment_status': _statusToString(paymentStatus),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DistributionModel.fromMap(
    Map<String, dynamic> map,
    List<DistributionItem> items,
  ) {
    return DistributionModel(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      customerName: map['customer_name'] as String,
      distributionDate: DateTime.parse(map['distribution_date'] as String),
      items: items,
      totalAmount: (map['total_amount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: _statusFromString(map['payment_status'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'distribution_date': distributionDate.toIso8601String(),
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'payment_status': _statusToString(paymentStatus),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': 0,
      'firebase_id': id,
    };
  }

  factory DistributionModel.fromEntity(Distribution distribution) {
    return DistributionModel(
      id: distribution.id,
      customerId: distribution.customerId,
      customerName: distribution.customerName,
      distributionDate: distribution.distributionDate,
      items: distribution.items,
      totalAmount: distribution.totalAmount,
      paidAmount: distribution.paidAmount,
      paymentStatus: distribution.paymentStatus,
      notes: distribution.notes,
      createdAt: distribution.createdAt,
      updatedAt: distribution.updatedAt,
    );
  }

  // --- الإضافة: دالة copyWith ---
  @override
  DistributionModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    DateTime? distributionDate,
    List<DistributionItem>? items,
    double? totalAmount,
    double? paidAmount,
    PaymentStatus? paymentStatus,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DistributionModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      distributionDate: distributionDate ?? this.distributionDate,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  // -----------------------------

  static PaymentStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return PaymentStatus.paid;
      case 'partial':
        return PaymentStatus.partial;
      default:
        return PaymentStatus.pending;
    }
  }

  static String _statusToString(PaymentStatus status) {
    return status.toString().split('.').last;
  }
}