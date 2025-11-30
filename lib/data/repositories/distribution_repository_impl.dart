// ignore_for_file: unused_import

import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../domain/entities/distribution.dart';
import '../../domain/entities/distribution_item.dart';
import '../../domain/repositories/distribution_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/distribution_remote_datasource.dart';
import '../datasources/remote/customer_remote_datasource.dart';
import '../datasources/remote/product_remote_datasource.dart';
import '../models/distribution_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class DistributionRepositoryImpl implements DistributionRepository {
  final DistributionRemoteDataSource remoteDataSource;
  final CustomerRemoteDataSource customerRemoteDataSource;
  final ProductRemoteDataSource productRemoteDataSource;
  final FirebaseAuth firebaseAuth;

  DistributionRepositoryImpl({
    required this.remoteDataSource,
    required this.customerRemoteDataSource,
    required this.productRemoteDataSource,
    required this.firebaseAuth,
  });

  String get _userId => firebaseAuth.currentUser?.uid ?? '';
  bool get _isAuthenticated => firebaseAuth.currentUser != null;

  /// التحقق من أخطاء الشبكة
  bool _isOfflineError(Object e) {
    if (e is TimeoutException) return true;
    if (e is FirebaseException && (e.code == 'unavailable' || e.code == 'unknown')) {
      return true;
    }
    final s = e.toString().toLowerCase();
    return s.contains('unavailable') || 
           s.contains('unknownhostexception') || 
           s.contains('network') || 
           s.contains('failed to resolve name');
  }

  // --- ثوابت الأداء ---
  // نبقي مهلة الكتابة فقط لتسريع الواجهة عند الحفظ
  static const Duration _writeTimeout = Duration(milliseconds: 300);
  
  // تم إزالة مهلة القراءة للسماح للكاش بالعمل بشكل طبيعي

  @override
  Future<Either<Failure, List<Distribution>>> getAllDistributions() async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      // إزالة Timeout للسماح لـ Firestore بجلب البيانات من الكاش عند انقطاع النت
      final remoteDistributions = await remoteDataSource.getAllDistributions(_userId);
      
      // الإثراء المتوازي (سريع جداً)
      final enriched = await Future.wait(remoteDistributions.map((d) => _enrichDistributionWithNames(d)));
      return Right(enriched);
    } catch (e) {
      // في حالة القراءة، إذا حدث خطأ حقيقي (غير الأوفلاين) نرجعه
      // Firestore Persistence عادة لا يرمي خطأ عند الأوفلاين بل يعيد الكاش
      developer.log('Error fetching distributions', error: e, name: 'DistributionRepository');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Distribution>> getDistributionById(String id) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final distribution = await remoteDataSource.getDistributionById(_userId, id);
      final enriched = await _enrichDistributionWithNames(distribution);
      return Right(enriched);
    } catch (e) {
      return Left(NotFoundFailure('Distribution not found'));
    }
  }

  @override
  Future<Either<Failure, List<Distribution>>> getDistributionsByCustomer(String customerId) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final allDistributions = await remoteDataSource.getAllDistributions(_userId);
      final customerDistributions = allDistributions.where((d) => d.customerId == customerId).toList();
      final enriched = await Future.wait(customerDistributions.map((d) => _enrichDistributionWithNames(d)));
      return Right(enriched);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch customer distributions'));
    }
  }

  @override
  Future<Either<Failure, List<Distribution>>> getDistributionsByDateRange(DateTime start, DateTime end) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final allDistributions = await remoteDataSource.getAllDistributions(_userId);
      final rangeDistributions = allDistributions.where((d) {
        return d.distributionDate.isAfter(start.subtract(const Duration(days: 1))) && 
               d.distributionDate.isBefore(end.add(const Duration(days: 1)));
      }).toList();
      final enriched = await Future.wait(rangeDistributions.map((d) => _enrichDistributionWithNames(d)));
      return Right(enriched);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch distributions by date range'));
    }
  }

  @override
  Future<Either<Failure, String>> createDistribution(Distribution distribution) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      // عمليات الكتابة: نحتفظ بمهلة الكتابة القصيرة لمنع التعليق
      
      // 1. Update Product Stocks
      for (var item in distribution.items) {
        try {
          final productModel = await productRemoteDataSource.getProductById(_userId, item.productId);
          final updatedStock = productModel.stock - item.quantity;
          final updatedProduct = productModel.copyWith(stock: updatedStock);
          await productRemoteDataSource.updateProduct(_userId, updatedProduct)
              .timeout(_writeTimeout);
        } catch (e) {
          if (!_isOfflineError(e)) rethrow;
          developer.log('Offline: Product stock update queued locally.', name: 'DistributionRepository');
        }
      }

      // 2. Update Customer Balance
      try {
        final customerModel = await customerRemoteDataSource.getCustomerById(_userId, distribution.customerId);
        final updatedBalance = customerModel.balance + distribution.pendingAmount;
        final updatedCustomer = customerModel.copyWith(balance: updatedBalance);
        await customerRemoteDataSource.updateCustomer(_userId, updatedCustomer)
            .timeout(_writeTimeout);
      } catch (e) {
        if (!_isOfflineError(e)) rethrow;
        developer.log('Offline: Customer balance update queued locally.', name: 'DistributionRepository');
      }

      // 3. Create Distribution
      final distributionModel = DistributionModel.fromEntity(distribution);
      await remoteDataSource.createDistribution(_userId, distributionModel)
          .timeout(_writeTimeout);

      return Right(distribution.id);
    } catch (e) {
      if (_isOfflineError(e)) {
        developer.log('Offline/Timeout during Create Distribution. Optimistic success.', name: 'DistributionRepository');
        return Right(distribution.id);
      }
      return Left(ServerFailure('Failed to create distribution: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateDistribution(Distribution distribution) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final distributionModel = DistributionModel.fromEntity(distribution);
      await remoteDataSource.updateDistribution(_userId, distributionModel)
          .timeout(_writeTimeout);
      return const Right(null);
    } catch (e) {
      if (_isOfflineError(e)) {
        return const Right(null);
      }
      return Left(ServerFailure('Failed to update distribution'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDistribution(String id) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final distribution = await remoteDataSource.getDistributionById(_userId, id);

      for (var item in distribution.items) {
        try {
          final productModel = await productRemoteDataSource.getProductById(_userId, item.productId);
          final updatedStock = productModel.stock + item.quantity; 
          final updatedProduct = productModel.copyWith(stock: updatedStock);
          await productRemoteDataSource.updateProduct(_userId, updatedProduct)
              .timeout(_writeTimeout);
        } catch (e) {
          if (!_isOfflineError(e)) rethrow;
        }
      }

      try {
        final customerModel = await customerRemoteDataSource.getCustomerById(_userId, distribution.customerId);
        final updatedBalance = customerModel.balance - distribution.pendingAmount;
        final updatedCustomer = customerModel.copyWith(balance: updatedBalance);
        await customerRemoteDataSource.updateCustomer(_userId, updatedCustomer)
            .timeout(_writeTimeout);
      } catch (e) {
        if (!_isOfflineError(e)) rethrow;
      }

      await remoteDataSource.deleteDistribution(_userId, id)
          .timeout(_writeTimeout);

      return const Right(null);
    } catch (e) {
      if (_isOfflineError(e)) {
        return const Right(null);
      }
      return Left(ServerFailure('Failed to delete distribution'));
    }
  }

  @override
  Future<Either<Failure, void>> recordPayment(String distributionId, double amount) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final distribution = await remoteDataSource.getDistributionById(_userId, distributionId);
      
      final newPaidAmount = distribution.paidAmount + amount;
      
      PaymentStatus paymentStatus = PaymentStatus.pending;
      if (newPaidAmount >= distribution.totalAmount) {
        paymentStatus = PaymentStatus.paid;
      } else if (newPaidAmount > 0) {
        paymentStatus = PaymentStatus.partial;
      }

      final updatedDistribution = DistributionModel.fromEntity(distribution).copyWith(
        paidAmount: newPaidAmount,
        paymentStatus: paymentStatus,
      );

      try {
        await remoteDataSource.updateDistribution(_userId, updatedDistribution)
            .timeout(_writeTimeout);
      } catch (e) {
        if (!_isOfflineError(e)) rethrow;
      }

      try {
        final customerModel = await customerRemoteDataSource.getCustomerById(_userId, distribution.customerId);
        final updatedBalance = customerModel.balance - amount;
        final updatedCustomer = customerModel.copyWith(balance: updatedBalance);
        
        await customerRemoteDataSource.updateCustomer(_userId, updatedCustomer)
            .timeout(_writeTimeout);
      } catch (e) {
        if (!_isOfflineError(e)) rethrow;
      }

      return const Right(null);
    } catch (e) {
      if (_isOfflineError(e)) {
        return const Right(null);
      }
      return Left(ServerFailure('Failed to record payment'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDistributionStats(DateTime start, DateTime end) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final allDistributions = await remoteDataSource.getAllDistributions(_userId);
      final distributions = allDistributions.where((d) {
        return d.distributionDate.isAfter(start.subtract(const Duration(days: 1))) && 
               d.distributionDate.isBefore(end.add(const Duration(days: 1)));
      }).toList();

      double totalSales = 0;
      double totalPaid = 0;
      double totalPending = 0;
      int totalDistributions = distributions.length;

      for (var distribution in distributions) {
        totalSales += distribution.totalAmount;
        totalPaid += distribution.paidAmount;
        totalPending += distribution.pendingAmount;
      }

      return Right({
        'total_sales': totalSales,
        'total_paid': totalPaid,
        'total_pending': totalPending,
        'total_distributions': totalDistributions,
        'average_sale': totalDistributions > 0 ? totalSales / totalDistributions : 0,
      });
    } catch (e) {
      return Left(ServerFailure('Failed to calculate distribution stats'));
    }
  }

  @override
  Future<Either<Failure, List<Distribution>>> getFilteredDistributions({
    required DateTime startDate,
    required DateTime endDate,
    String? customerId,
    List<String>? productIds,
  }) async {
    if (!_isAuthenticated) {
      return Left(AuthenticationFailure('User not authenticated'));
    }
    try {
      final allDistributions = await remoteDataSource.getAllDistributions(_userId);
      
      final filtered = allDistributions.where((d) {
        bool matchDate = d.distributionDate.isAfter(startDate.subtract(const Duration(days: 1))) && 
                         d.distributionDate.isBefore(endDate.add(const Duration(days: 1)));
        bool matchCustomer = customerId == null || d.customerId == customerId;
        
        bool matchProduct = productIds == null || productIds.isEmpty || 
                            d.items.any((item) => productIds.contains(item.productId));
                            
        return matchDate && matchCustomer && matchProduct;
      }).toList();

      final enriched = await Future.wait(filtered.map((d) => _enrichDistributionWithNames(d)));
      return Right(enriched);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch filtered distributions'));
    }
  }

  // --- الإثراء المتوازي (سريع وآمن للأوفلاين) ---
  Future<Distribution> _enrichDistributionWithNames(Distribution dist) async {
    var updated = dist;
    try {
      // استخدام Future.wait لا يعمل هنا لأننا نريد تحديث الكائن نفسه، 
      // ولكن عمليات الجلب بحد ذاتها يجب أن تكون سريعة (من الكاش).
      // سنستخدم مهلة قصيرة جدًا (200ms) لكل حقل اسم فقط لضمان عدم تعليق القائمة الكاملة
      // إذا فشل الجلب، نعرض الاسم الفارغ أو القديم.
      
      if (updated.customerName.trim().isEmpty) {
        try {
          final customerModel = await customerRemoteDataSource.getCustomerById(_userId, updated.customerId)
              .timeout(const Duration(milliseconds: 200)); 
          updated = updated.copyWith(customerName: customerModel.name);
        } catch (_) {}
      }

      // تحسين متوازي لأسماء المنتجات داخل الفاتورة الواحدة
      final itemFutures = updated.items.map((it) async {
        if (it.productName.trim().isEmpty) {
          try {
            final productModel = await productRemoteDataSource.getProductById(_userId, it.productId)
                .timeout(const Duration(milliseconds: 200));
            return it.copyWith(productName: productModel.name);
          } catch (_) {
            return it;
          }
        } else {
          return it;
        }
      }).toList();

      final enrichedItems = await Future.wait(itemFutures);
      updated = updated.copyWith(items: enrichedItems);

    } catch (_) {
      // ignore
    }
    return updated;
  }
}