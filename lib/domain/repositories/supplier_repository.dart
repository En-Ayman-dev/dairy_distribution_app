import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/supplier.dart';
import '../entities/supplier_payment.dart'; // استيراد كيان الدفعات الجديد

abstract class SupplierRepository {
  Future<Either<Failure, List<Supplier>>> getAllSuppliers();
  Future<Either<Failure, Supplier>> getSupplierById(String id);
  Future<Either<Failure, String>> addSupplier(Supplier supplier);
  Future<Either<Failure, void>> updateSupplier(Supplier supplier);
  Future<Either<Failure, void>> deleteSupplier(String id);
  Stream<Either<Failure, List<Supplier>>> watchSuppliers();

  // --- إدارة الدفعات المالية للموردين ---
  
  // إضافة دفعة جديدة
  Future<Either<Failure, String>> addPayment(SupplierPayment payment);
  
  // جلب سجل الدفعات لمورد معين
  Future<Either<Failure, List<SupplierPayment>>> getSupplierPayments(String supplierId);
  
  // مراقبة سجل الدفعات (Real-time)
  Stream<Either<Failure, List<SupplierPayment>>> watchSupplierPayments(String supplierId);
}