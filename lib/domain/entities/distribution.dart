import 'package:equatable/equatable.dart';
import 'distribution_item.dart';

class Distribution extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final DateTime distributionDate;
  final List<DistributionItem> items;
  final double totalAmount;
  final double paidAmount;
  final PaymentStatus paymentStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Distribution({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.distributionDate,
    required this.items,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.paymentStatus = PaymentStatus.pending,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  double get pendingAmount => totalAmount - paidAmount;
  bool get isFullyPaid => paidAmount >= totalAmount;

  Distribution copyWith({
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
    return Distribution(
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

  @override
  List<Object?> get props => [
        id,
        customerId,
        customerName,
        distributionDate,
        items,
        totalAmount,
        paidAmount,
        paymentStatus,
        notes,
        createdAt,
        updatedAt,
      ];
}

enum PaymentStatus {
  pending,
  partial,
  paid,
}