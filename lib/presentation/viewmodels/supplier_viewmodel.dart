import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';

enum SupplierViewState { initial, loading, loaded, error }

class SupplierViewModel extends ChangeNotifier {
  final SupplierRepository _repository;
  final Uuid _uuid;

  SupplierViewModel(this._repository, this._uuid);

  SupplierViewState _state = SupplierViewState.initial;
  List<Supplier> _suppliers = [];
  String? _errorMessage;

  // Getters
  SupplierViewState get state => _state;
  List<Supplier> get suppliers => _suppliers;
  String? get errorMessage => _errorMessage;

  void _setState(SupplierViewState state) {
    _state = state;
    notifyListeners();
  }

  Future<void> loadSuppliers() async {
    _setState(SupplierViewState.loading);
    final result = await _repository.getAllSuppliers();
    result.fold((failure) {
      _errorMessage = failure.message;
      _setState(SupplierViewState.error);
    }, (data) {
      _suppliers = data;
      _setState(SupplierViewState.loaded);
    });
  }

  Future<bool> addSupplier({required String name, String? contact, String? address}) async {
    final supplier = Supplier(
      id: _uuid.v4(),
      name: name,
      contact: contact,
      address: address,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _repository.addSupplier(supplier);

    return result.fold((failure) {
      _errorMessage = failure.message;
      notifyListeners();
      return false;
    }, (_) {
      loadSuppliers();
      return true;
    });
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    final result = await _repository.updateSupplier(supplier);
    return result.fold((failure) {
      _errorMessage = failure.message;
      notifyListeners();
      return false;
    }, (_) {
      loadSuppliers();
      return true;
    });
  }

  Future<bool> deleteSupplier(String id) async {
    final result = await _repository.deleteSupplier(id);
    return result.fold((failure) {
      _errorMessage = failure.message;
      notifyListeners();
      return false;
    }, (_) {
      loadSuppliers();
      return true;
    });
  }
}
