import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/repositories/purchase_repository.dart';

enum PurchaseViewState { initial, loading, loaded, error }

class PurchaseViewModel extends ChangeNotifier {
  final PurchaseRepository _repository;
  final Uuid _uuid;

  PurchaseViewModel(this._repository, this._uuid);

  PurchaseViewState _state = PurchaseViewState.initial;
  List<Purchase> _purchases = [];
  String? _errorMessage;

  PurchaseViewState get state => _state;
  List<Purchase> get purchases => _purchases;
  String? get errorMessage => _errorMessage;

  void _setState(PurchaseViewState state) {
    _state = state;
    notifyListeners();
  }

  Future<void> loadPurchasesForProduct(String productId) async {
    _setState(PurchaseViewState.loading);
    final result = await _repository.getPurchasesForProduct(productId);
    result.fold((failure) {
      _errorMessage = failure.message;
      _setState(PurchaseViewState.error);
    }, (data) {
      _purchases = data;
      _setState(PurchaseViewState.loaded);
    });
  }

  Future<bool> addPurchase({required String productId, required String supplierId, required double quantity, required double price}) async {
    final purchase = Purchase(
      id: _uuid.v4(),
      productId: productId,
      supplierId: supplierId,
      quantity: quantity,
      price: price,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _repository.addPurchase(purchase);
    return result.fold((failure) {
      _errorMessage = failure.message;
      notifyListeners();
      return false;
    }, (id) {
      loadPurchasesForProduct(productId);
      return true;
    });
  }
}
