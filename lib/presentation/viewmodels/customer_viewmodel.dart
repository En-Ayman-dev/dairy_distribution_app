import 'package:flutter/foundation.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/usecases/customer/add_customer.dart';
import 'package:uuid/uuid.dart';

enum CustomerViewState {
  initial,
  loading,
  loaded,
  error,
}

class CustomerViewModel extends ChangeNotifier {
  final CustomerRepository _repository;
  final Uuid _uuid;

  CustomerViewModel(this._repository, this._uuid);

  CustomerViewState _state = CustomerViewState.initial;
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  Customer? _selectedCustomer;
  String? _errorMessage;
  CustomerStatus? _filterStatus;
  String _searchQuery = '';

  // Getters
  CustomerViewState get state => _state;
  List<Customer> get customers => _filteredCustomers;
  Customer? get selectedCustomer => _selectedCustomer;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  int get customerCount => _customers.length;
  int get activeCustomerCount =>
      _customers.where((c) => c.status == CustomerStatus.active).length;

  // Get total outstanding balance
  double get totalOutstanding =>
      _customers.fold(0, (sum, customer) => sum + customer.balance);

  // Load all customers
  Future<void> loadCustomers() async {
    _setState(CustomerViewState.loading);

    final result = await _repository.getAllCustomers();

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(CustomerViewState.error);
      },
      (customers) {
        _customers = customers;
        _applyFilters();
        _setState(CustomerViewState.loaded);
      },
    );
  }

  // Add new customer
  Future<bool> addCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
  }) async {
    final params = AddCustomerParams(
      name: name,
      phone: phone,
      email: email,
      address: address,
    );

    final useCase = AddCustomer(_repository, _uuid);
    final result = await useCase(params);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (customerId) {
        loadCustomers(); // Reload customers
        return true;
      },
    );
  }

  // Update customer
  Future<bool> updateCustomer(Customer customer) async {
    final result = await _repository.updateCustomer(customer);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        loadCustomers();
        return true;
      },
    );
  }

  // Delete customer
  Future<bool> deleteCustomer(String customerId) async {
    final result = await _repository.deleteCustomer(customerId);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        loadCustomers();
        return true;
      },
    );
  }

  // Get customer by ID
  Future<void> getCustomerById(String id) async {
    final result = await _repository.getCustomerById(id);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _selectedCustomer = null;
      },
      (customer) {
        _selectedCustomer = customer;
      },
    );
    notifyListeners();
  }

  // Search customers
  void searchCustomers(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  // Filter by status
  void filterByStatus(CustomerStatus? status) {
    _filterStatus = status;
    _applyFilters();
  }

  // Apply all filters
  void _applyFilters() {
    _filteredCustomers = _customers.where((customer) {
      // Status filter
      if (_filterStatus != null && customer.status != _filterStatus) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        return customer.name.toLowerCase().contains(_searchQuery) ||
            customer.phone.contains(_searchQuery);
      }

      return true;
    }).toList();

    // Sort by name
    _filteredCustomers.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _filterStatus = null;
    _applyFilters();
  }

  // Get customers with outstanding balance
  List<Customer> getCustomersWithBalance() {
    return _customers.where((c) => c.balance > 0).toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));
  }

  void _setState(CustomerViewState state) {
    _state = state;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelectedCustomer() {
    _selectedCustomer = null;
    notifyListeners();
  }

  // Record a payment for a customer by reducing their balance.
  // Returns true on success.
  Future<bool> recordPayment(String customerId, double amount) async {
    // Find current customer to compute new balance
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index == -1) {
      _errorMessage = 'Customer not found';
      notifyListeners();
      return false;
    }

    final current = _customers[index];
    final newBalance = (current.balance - amount).clamp(0.0, double.infinity);

    final result = await _repository.updateCustomerBalance(customerId, newBalance);

    return result.fold((failure) {
      _errorMessage = failure.message;
      notifyListeners();
      return false;
    }, (_) {
      // Reload customers to reflect updated balance
      loadCustomers();
      return true;
    });
  }
}