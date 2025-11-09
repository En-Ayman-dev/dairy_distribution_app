import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id;
  final String customerId;
  final double amount;
  final PaymentMethod paymentMethod;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        customerId,
        amount,
        paymentMethod,
        paymentDate,
        notes,
        createdAt,
      ];
}

enum PaymentMethod {
  cash,
  upi,
  card,
  bankTransfer,
}