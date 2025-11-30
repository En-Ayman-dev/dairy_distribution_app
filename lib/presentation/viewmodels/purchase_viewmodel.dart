import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/purchase_item.dart'; // استيراد كيان العنصر
import '../../domain/repositories/purchase_repository.dart';

enum PurchaseViewState { initial, loading, loaded, error }

class PurchaseViewModel extends ChangeNotifier {
  final PurchaseRepository _repository;
  final Uuid _uuid;
  
  StreamSubscription? _purchasesSubscription;

  PurchaseViewModel(this._repository, this._uuid);

  PurchaseViewState _state = PurchaseViewState.initial;
  List<Purchase> _purchases = [];
  String? _errorMessage;

  // --- سلة المشتريات (Cart State) ---
  final List<PurchaseItem> _cartItems = [];

  PurchaseViewState get state => _state;
  List<Purchase> get purchases => _purchases;
  String? get errorMessage => _errorMessage;
  
  // الوصول لعناصر السلة
  List<PurchaseItem> get cartItems => List.unmodifiable(_cartItems);

  // --- الحسابات اللحظية للسلة ---
  
  // إجمالي المبلغ (قبل الخصم)
  double get cartSubTotal {
    return _cartItems.fold(0.0, (sum, item) => sum + item.total);
  }

  // إجمالي عدد القطع (للعرض فقط)
  double get cartTotalQuantity {
    return _cartItems.fold(0.0, (sum, item) => sum + item.totalQuantity);
  }

  void _setState(PurchaseViewState state) {
    _state = state;
    notifyListeners();
  }

  // --- دوال إدارة السلة ---

  void addToCart(PurchaseItem item) {
    // التحقق مما إذا كان المنتج موجوداً بالفعل لدمج الكميات
    final index = _cartItems.indexWhere((e) => e.productId == item.productId);
    
    if (index >= 0) {
      final existing = _cartItems[index];
      _cartItems[index] = existing.copyWith(
        quantity: existing.quantity + item.quantity,
        freeQuantity: existing.freeQuantity + item.freeQuantity,
        price: item.price, // تحديث السعر للأحدث
      );
    } else {
      _cartItems.add(item);
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // --- الدوال الأساسية ---

  void listenToAllPurchases() {
    _setState(PurchaseViewState.loading);
    _purchasesSubscription?.cancel();

    _purchasesSubscription = _repository.watchPurchases().listen((event) {
      event.fold(
        (failure) {
          _errorMessage = failure.message;
          _setState(PurchaseViewState.error);
        },
        (data) {
          _purchases = data;
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
      _purchases.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _setState(PurchaseViewState.loaded);
    });
  }

  // --- دالة إضافة الفاتورة (Updated) ---
  Future<bool> addPurchase({
    required String supplierId,
    double discount = 0.0,
  }) async {
    if (_cartItems.isEmpty) {
      _errorMessage = "السلة فارغة";
      notifyListeners();
      return false;
    }

    // إنشاء الفاتورة باستخدام عناصر السلة
    final purchase = Purchase(
      id: _uuid.v4(),
      supplierId: supplierId,
      items: List.from(_cartItems), // نسخ القائمة
      discount: discount,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _repository.addPurchase(purchase);
    
    return result.fold((failure) {
      _errorMessage = failure.message;
      notifyListeners();
      return false;
    }, (id) {
      // تنظيف السلة بعد الحفظ بنجاح
      clearCart();
      return true;
    });
  }

  // --- دالة المرتجع (Updated) ---
  // تم تحديثها لتطلب productId لأن الإرجاع أصبح على مستوى الصنف
  Future<bool> returnPurchase({
    required String purchaseId, 
    required String productId, 
    required double quantity
  }) async {
    // ملاحظة: سيظهر خطأ هنا في التجميع (Compilation Error) مؤقتاً
    // حتى نقوم بتحديث PurchaseRepository ليتوافق مع المعاملات الجديدة.
    final result = await _repository.processReturn(purchaseId, productId, quantity); // تم تعديل الاستدعاء
    
    return result.fold((failure) {
      _errorMessage = failure.message;
      notifyListeners();
      return false;
    }, (_) {
      return true;
    });
  }

  @override
  void dispose() {
    _purchasesSubscription?.cancel();
    super.dispose();
  }
}