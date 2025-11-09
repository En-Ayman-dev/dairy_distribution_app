import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final double balance;
  final CustomerStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.balance = 0.0,
    this.status = CustomerStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? balance,
    CustomerStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        address,
        balance,
        status,
        createdAt,
        updatedAt,
      ];
}

enum CustomerStatus {
  active,
  inactive,
  blocked,
}