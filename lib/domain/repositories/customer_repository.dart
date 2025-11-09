import 'package:dartz/dartz.dart';
import '../entities/customer.dart';
import '../../core/errors/failures.dart';

abstract class CustomerRepository {
  Future<Either<Failure, List<Customer>>> getAllCustomers();
  Future<Either<Failure, Customer>> getCustomerById(String id);
  Future<Either<Failure, List<Customer>>> getCustomersByStatus(String status);
  Future<Either<Failure, List<Customer>>> searchCustomers(String query);
  Future<Either<Failure, String>> addCustomer(Customer customer);
  Future<Either<Failure, void>> updateCustomer(Customer customer);
  Future<Either<Failure, void>> deleteCustomer(String id);
  Future<Either<Failure, void>> updateCustomerBalance(String id, double balance);
  Stream<Either<Failure, List<Customer>>> watchCustomers();
}