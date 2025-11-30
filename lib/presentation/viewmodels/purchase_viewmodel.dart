import 'dart:async'; // إضافة مكتبة async للتعامل مع StreamSubscription
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/repositories/purchase_repository.dart';

enum PurchaseViewState { initial, loading, loaded, error }

class PurchaseViewModel extends ChangeNotifier {
  final PurchaseRepository _repository;
  final Uuid _uuid;
  
  // متغير لحفظ الاشتراك في Stream
  StreamSubscription? _purchasesSubscription;

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

  // --- دالة جديدة للاستماع لكل المشتريات (لسجل الفواتير) ---
  void listenToAllPurchases() {
    _setState(PurchaseViewState.loading);
    
    // إلغاء أي اشتراك سابق لتجنب التكرار
    _purchasesSubscription?.cancel();

    _purchasesSubscription = _repository.watchPurchases().listen((event) {
      event.fold(
        (failure) {
          _errorMessage = failure.message;
          _setState(PurchaseViewState.error);
        },
        (data) {
          _purchases = data;
          // فرز القائمة بحيث تظهر الأحدث أولاً
          _purchases.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _setState(PurchaseViewState.loaded);
        },
      );
    });
  }

  Future<void> loadPurchasesForProduct(String productId) async {
    _setState(PurchaseViewState.loading);
    final result = await _repository.getPurchasesForProduct(productId);
    result.fold((failure) {
      _errorMessage = failure.message;
      _setState(PurchaseViewState.error);
    }, (data) {
      _purchases = data;
      // فرز القائمة للأحدث أولاً أيضاً
      _purchases.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _setState(PurchaseViewState.loaded);
    });
  }

  Future<bool> addPurchase({
    required String productId,
    required String supplierId,
    required double quantity,
    double freeQuantity = 0.0,
    required double price,
  }) async {
    final purchase = Purchase(
      id: _uuid.v4(),
      productId: productId,
      supplierId: supplierId,
      quantity: quantity,
      freeQuantity: freeQuantity,
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
      // إذا كنا في صفحة تفاصيل المنتج، نحدث القائمة الخاصة به
      // أما إذا كنا نستمع للكل (Stream)، فالتحديث سيتم تلقائياً
      if (_purchasesSubscription == null) {
          loadPurchasesForProduct(productId);
      }
      return true;
    });
  }

  // --- دالة جديدة لمعالجة المرتجع ---
  Future<bool> returnPurchase({required String purchaseId, required double quantity}) async {
    // لا نقوم بتغيير الحالة إلى loading هنا لأننا نريد تجربة مستخدم سلسة (مربع حوار)
    // التحديث سيأتي عبر الـ Stream
    final result = await _repository.processReturn(purchaseId, quantity);
    
    return result.fold((failure) {
      _errorMessage = failure.message;
      notifyListeners(); // لإظهار رسالة الخطأ في الواجهة إذا لزم الأمر
      return false;
    }, (_) {
      // نجاح العملية
      return true;
    });
  }

  @override
  void dispose() {
    _purchasesSubscription?.cancel();
    super.dispose();
  }
}