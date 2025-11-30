import 'package:equatable/equatable.dart';

class SupplierPayment extends Equatable {
  final String id;
  final String supplierId;
  final double amount;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;

  const SupplierPayment({
    required this.id,
    required this.supplierId,
    required this.amount,
    required this.paymentDate,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, supplierId, amount, paymentDate, notes, createdAt];
}