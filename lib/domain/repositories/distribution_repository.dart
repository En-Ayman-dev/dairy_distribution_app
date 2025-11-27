import 'package:dartz/dartz.dart';
import '../entities/distribution.dart';
import '../../core/errors/failures.dart';

abstract class DistributionRepository {
  Future<Either<Failure, List<Distribution>>> getAllDistributions();
  Future<Either<Failure, Distribution>> getDistributionById(String id);
  Future<Either<Failure, List<Distribution>>> getDistributionsByCustomer(
      String customerId);
  Future<Either<Failure, List<Distribution>>> getDistributionsByDateRange(
    DateTime start,
    DateTime end,
  );
  Future<Either<Failure, String>> createDistribution(Distribution distribution);
  Future<Either<Failure, void>> updateDistribution(Distribution distribution);
  Future<Either<Failure, void>> deleteDistribution(String id);
  Future<Either<Failure, void>> recordPayment(
    String distributionId,
    double amount,
  );
  Future<Either<Failure, Map<String, dynamic>>> getDistributionStats(
    DateTime start,
    DateTime end,
  );

  // --- إضافة جديدة ---
  // دالة لجلب الحركات (التوزيعات) بناءً على جميع الفلاتر
  Future<Either<Failure, List<Distribution>>> getFilteredDistributions({
    required DateTime startDate,
    required DateTime endDate,
    String? customerId, // فلتر العميل (اختياري)
    List<String>? productIds, // فلتر المنتجات (اختياري)
  });
  // --- نهاية الإضافة ---
}