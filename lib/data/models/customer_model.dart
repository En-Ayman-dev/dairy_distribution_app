import '../../domain/entities/customer.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.name,
    required super.phone,
    super.email,
    super.address,
    super.balance,
    super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  // From JSON (Firebase)
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      status: _statusFromString(json['status'] as String? ?? 'active'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // To JSON (Firebase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'balance': balance,
      'status': _statusToString(status),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // From SQLite Map
  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      address: map['address'] as String?,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      status: _statusFromString(map['status'] as String? ?? 'active'),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // To SQLite Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'balance': balance,
      'status': _statusToString(status),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': 0,
      'firebase_id': id,
    };
  }

  // From Entity
  factory CustomerModel.fromEntity(Customer customer) {
    return CustomerModel(
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      address: customer.address,
      balance: customer.balance,
      status: customer.status,
      createdAt: customer.createdAt,
      updatedAt: customer.updatedAt,
    );
  }

  // Helper methods for status conversion
  static CustomerStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return CustomerStatus.active;
      case 'inactive':
        return CustomerStatus.inactive;
      case 'blocked':
        return CustomerStatus.blocked;
      default:
        return CustomerStatus.active;
    }
  }

  static String _statusToString(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return 'active';
      case CustomerStatus.inactive:
        return 'inactive';
      case CustomerStatus.blocked:
        return 'blocked';
    }
  }

  @override
  CustomerModel copyWith({
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
    return CustomerModel(
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
}