import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../core/errors/failures.dart';
import '../../entities/customer.dart';
import '../../repositories/customer_repository.dart';

class AddCustomer {
  final CustomerRepository repository;
  final Uuid uuid;

  AddCustomer(this.repository, this.uuid);

  Future<Either<Failure, String>> call(AddCustomerParams params) async {
    final customer = Customer(
      id: uuid.v4(),
      name: params.name,
      phone: params.phone,
      email: params.email,
      address: params.address,
      balance: 0.0,
      status: CustomerStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await repository.addCustomer(customer);
  }
}

class AddCustomerParams {
  final String name;
  final String phone;
  final String? email;
  final String? address;

  AddCustomerParams({
    required this.name,
    required this.phone,
    this.email,
    this.address,
  });
}