import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/supplier.dart';

abstract class SupplierRepository {
  Future<Either<Failure, List<Supplier>>> getAllSuppliers();
  Future<Either<Failure, Supplier>> getSupplierById(String id);
  Future<Either<Failure, String>> addSupplier(Supplier supplier);
  Future<Either<Failure, void>> updateSupplier(Supplier supplier);
  Future<Either<Failure, void>> deleteSupplier(String id);
  Stream<Either<Failure, List<Supplier>>> watchSuppliers();
}
