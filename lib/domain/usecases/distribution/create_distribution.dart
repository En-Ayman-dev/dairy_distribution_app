import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../core/errors/failures.dart';
import '../../entities/distribution.dart';
import '../../entities/distribution_item.dart';
import '../../repositories/distribution_repository.dart';

class CreateDistribution {
  final DistributionRepository repository;
  final Uuid uuid;

  CreateDistribution(this.repository, this.uuid);

  Future<Either<Failure, String>> call(CreateDistributionParams params) async {
    // Calculate total amount
    double totalAmount = 0;
    for (var item in params.items) {
      totalAmount += item.subtotal;
    }

    final distribution = Distribution(
      id: uuid.v4(),
      customerId: params.customerId,
      customerName: params.customerName,
      distributionDate: params.distributionDate,
      items: params.items,
      totalAmount: totalAmount,
      paidAmount: params.paidAmount,
      paymentStatus: _calculatePaymentStatus(totalAmount, params.paidAmount),
      notes: params.notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await repository.createDistribution(distribution);
  }

  PaymentStatus _calculatePaymentStatus(double total, double paid) {
    if (paid >= total) {
      return PaymentStatus.paid;
    } else if (paid > 0) {
      return PaymentStatus.partial;
    } else {
      return PaymentStatus.pending;
    }
  }
}

class CreateDistributionParams {
  final String customerId;
  final String customerName;
  final DateTime distributionDate;
  final List<DistributionItem> items;
  final double paidAmount;
  final String? notes;

  CreateDistributionParams({
    required this.customerId,
    required this.customerName,
    required this.distributionDate,
    required this.items,
    this.paidAmount = 0.0,
    this.notes,
  });
}