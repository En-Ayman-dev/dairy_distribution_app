import 'package:flutter/foundation.dart';
import '../../domain/entities/distribution.dart';
import '../../domain/entities/distribution_item.dart';
import '../../domain/repositories/distribution_repository.dart';
import '../../domain/usecases/distribution/create_distribution.dart';
import 'package:uuid/uuid.dart';

enum DistributionViewState {
  initial,
  loading,
  loaded,
  error,
}

class DistributionViewModel extends ChangeNotifier {
  final DistributionRepository _repository;
  final Uuid _uuid;

  DistributionViewModel(this._repository, this._uuid);

  DistributionViewState _state = DistributionViewState.initial;
  List<Distribution> _distributions = [];
  List<Distribution> _filteredDistributions = [];
  Distribution? _selectedDistribution;
  String? _lastCreatedDistributionId;
  String? _errorMessage;
  // Date range fields removed (previously unused).
  PaymentStatus? _filterPaymentStatus;

  // For creating new distribution
  final List<DistributionItem> _currentItems = [];
  double _currentPaidAmount = 0.0;

  // Getters
  DistributionViewState get state => _state;
  List<Distribution> get distributions => _filteredDistributions;
  Distribution? get selectedDistribution => _selectedDistribution;
  String? get errorMessage => _errorMessage;
  List<DistributionItem> get currentItems => _currentItems;
  double get currentPaidAmount => _currentPaidAmount;
  bool get hasError => _errorMessage != null;
  String? get lastCreatedDistributionId => _lastCreatedDistributionId;

  // Statistics
  double get totalSales =>
      _distributions.fold(0, (sum, dist) => sum + dist.totalAmount);
  double get totalPaid =>
      _distributions.fold(0, (sum, dist) => sum + dist.paidAmount);
  double get totalPending =>
      _distributions.fold(0, (sum, dist) => sum + dist.pendingAmount);
  int get distributionCount => _distributions.length;

  // Load distributions
  Future<void> loadDistributions() async {
    _setState(DistributionViewState.loading);

    final result = await _repository.getAllDistributions();

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(DistributionViewState.error);
      },
      (distributions) {
        _distributions = distributions;
        _applyFilters();
        _setState(DistributionViewState.loaded);
      },
    );
  }

  // Load distributions by customer
  Future<void> loadDistributionsByCustomer(String customerId) async {
    _setState(DistributionViewState.loading);

    final result = await _repository.getDistributionsByCustomer(customerId);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(DistributionViewState.error);
      },
      (distributions) {
        _distributions = distributions;
        _filteredDistributions = distributions;
        _setState(DistributionViewState.loaded);
      },
    );
  }

  // Load distributions by date range
  Future<void> loadDistributionsByDateRange(DateTime start, DateTime end) async {
    _setState(DistributionViewState.loading);
    // Note: We intentionally don't store start/end locally here as they
    // were unused; we apply filters based on repository results.

    final result = await _repository.getDistributionsByDateRange(start, end);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(DistributionViewState.error);
      },
      (distributions) {
        _distributions = distributions;
        _applyFilters();
        _setState(DistributionViewState.loaded);
      },
    );
  }

  // Create distribution
  Future<bool> createDistribution({
    required String customerId,
    required String customerName,
    required DateTime distributionDate,
    String? notes,
  }) async {
    if (_currentItems.isEmpty) {
      _errorMessage = 'Please add at least one item';
      notifyListeners();
      return false;
    }

    final params = CreateDistributionParams(
      customerId: customerId,
      customerName: customerName,
      distributionDate: distributionDate,
      items: _currentItems,
      paidAmount: _currentPaidAmount,
      notes: notes,
    );

    final useCase = CreateDistribution(_repository, _uuid);
    final result = await useCase(params);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (distributionId) {
        _lastCreatedDistributionId = distributionId;
        // Create a local Distribution representation so the UI can display
        // the customer and product names immediately (works offline too).
        final total = _currentItems.fold<double>(0.0, (s, i) => s + i.subtotal);
        PaymentStatus paymentStatus = PaymentStatus.pending;
        if (_currentPaidAmount >= total) {
          paymentStatus = PaymentStatus.paid;
        } else if (_currentPaidAmount > 0) {
          paymentStatus = PaymentStatus.partial;
        }

        _selectedDistribution = Distribution(
          id: distributionId,
          customerId: params.customerId,
          customerName: params.customerName,
          distributionDate: params.distributionDate,
          items: List<DistributionItem>.from(_currentItems),
          totalAmount: total,
          paidAmount: _currentPaidAmount,
          paymentStatus: paymentStatus,
          notes: params.notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        notifyListeners();

        // Attempt to fetch the saved distribution from the repository to keep
        // the app state in sync (refresh and clear now optional)
        () async {
          await getDistributionById(distributionId);
          clearCurrentDistribution();
          await loadDistributions();
          notifyListeners();
        }();
        return true;
      },
    );
  }

  // Add item to current distribution
  void addItem({
    required String productId,
    required String productName,
    required double quantity,
    required double price,
  }) {
    final subtotal = quantity * price;
    final item = DistributionItem(
      id: _uuid.v4(),
      productId: productId,
      productName: productName,
      quantity: quantity,
      price: price,
      subtotal: subtotal,
    );

    _currentItems.add(item);
    notifyListeners();
  }

  // Update item quantity
  void updateItemQuantity(String itemId, double quantity) {
    final index = _currentItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final item = _currentItems[index];
      final updatedItem = item.copyWith(
        quantity: quantity,
        subtotal: quantity * item.price,
      );
      _currentItems[index] = updatedItem;
      notifyListeners();
    }
  }

  // Remove item from current distribution
  void removeItem(String itemId) {
    _currentItems.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  // Set paid amount
  void setPaidAmount(double amount) {
    _currentPaidAmount = amount;
    notifyListeners();
  }

  // Get current total
  double getCurrentTotal() {
    return _currentItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  // Clear current distribution
  void clearCurrentDistribution() {
    _currentItems.clear();
    _currentPaidAmount = 0.0;
    notifyListeners();
  }

  // Record payment
  Future<bool> recordPayment(String distributionId, double amount) async {
    final result = await _repository.recordPayment(distributionId, amount);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        loadDistributions();
        return true;
      },
    );
  }

  // Delete distribution
  Future<bool> deleteDistribution(String distributionId) async {
    final result = await _repository.deleteDistribution(distributionId);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        loadDistributions();
        return true;
      },
    );
  }

  // Update distribution
  Future<bool> updateDistribution(Distribution distribution) async {
    final result = await _repository.updateDistribution(distribution);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        // Reload list to reflect changes
        loadDistributions();
        return true;
      },
    );
  }

  // Get distribution by ID
  Future<void> getDistributionById(String id) async {
    final result = await _repository.getDistributionById(id);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _selectedDistribution = null;
      },
      (distribution) {
        _selectedDistribution = distribution;
      },
    );
    notifyListeners();
  }

  // Filter by payment status
  void filterByPaymentStatus(PaymentStatus? status) {
    _filterPaymentStatus = status;
    _applyFilters();
  }

  // Apply filters
  void _applyFilters() {
    _filteredDistributions = _distributions.where((dist) {
      if (_filterPaymentStatus != null &&
          dist.paymentStatus != _filterPaymentStatus) {
        return false;
      }
      return true;
    }).toList();

    // Sort by date (newest first)
    _filteredDistributions.sort(
      (a, b) => b.distributionDate.compareTo(a.distributionDate),
    );
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _filterPaymentStatus = null;
    _applyFilters();
  }

  // Get distribution statistics
  Future<Map<String, dynamic>> getStatistics(DateTime start, DateTime end) async {
    final result = await _repository.getDistributionStats(start, end);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        return {};
      },
      (stats) => stats,
    );
  }

  void _setState(DistributionViewState state) {
    _state = state;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelectedDistribution() {
    _selectedDistribution = null;
    notifyListeners();
  }

  // Clear the last created distribution id (used to control print visibility)
  void clearLastCreatedDistributionId() {
    _lastCreatedDistributionId = null;
    notifyListeners();
  }
}