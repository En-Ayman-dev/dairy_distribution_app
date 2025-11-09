import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/customer.dart';
import '../../repositories/customer_repository.dart';

class GetCustomers {
  final CustomerRepository repository;

  GetCustomers(this.repository);

  Future<Either<Failure, List<Customer>>> call() async {
    return await repository.getAllCustomers();
  }
}