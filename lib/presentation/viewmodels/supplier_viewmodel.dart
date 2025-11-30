import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/entities/supplier_payment.dart';
import '../../domain/repositories/supplier_repository.dart';
// نحتاج لمستودع المشتريات لحساب المديونية
import '../../domain/repositories/purchase_repository.dart';

enum SupplierViewState { initial, loading, loaded, error }

class SupplierViewModel extends ChangeNotifier {
  final SupplierRepository _supplierRepository;
  final PurchaseRepository _purchaseRepository; // إضافة الاعتماد الجديد
  final Uuid _uuid;

  SupplierViewModel(
    this._supplierRepository,
    this._purchaseRepository,
    this._uuid,
  );

  SupplierViewState _state = SupplierViewState.initial;
  List<Supplier> _suppliers = [];
  
  // --- حالة البيانات المالية للمورد المحدد ---
  List<SupplierPayment> _currentSupplierPayments = [];
  double _currentSupplierDebt = 0.0;
  String? _errorMessage;

  // Getters
  SupplierViewState get state => _state;
  List<Supplier> get suppliers => _suppliers;
  
  List<SupplierPayment> get currentSupplierPayments => _currentSupplierPayments;
  double get currentSupplierDebt => _currentSupplierDebt;
  
  String? get errorMessage => _errorMessage;

  void _setState(SupplierViewState state) {
    _state = state;
    notifyListeners();
  }

  // --- إدارة الموردين (CRUD) ---

  Future<void> loadSuppliers() async {
    _setState(SupplierViewState.loading);
    final result = await _supplierRepository.getAllSuppliers();
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

    final result = await _supplierRepository.addSupplier(supplier);

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
    final result = await _supplierRepository.updateSupplier(supplier);
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
    final result = await _supplierRepository.deleteSupplier(id);
    return result.fold((failure) {
      _errorMessage = failure.message;
      notifyListeners();
      return false;
    }, (_) {
      loadSuppliers();
      return true;
    });
  }

  // --- الإدارة المالية (Financial Management) ---

  // 1. إضافة دفعة جديدة
  Future<bool> addPayment({
    required String supplierId,
    required double amount,
    String? notes,
  }) async {
    final payment = SupplierPayment(
      id: _uuid.v4(),
      supplierId: supplierId,
      amount: amount,
      paymentDate: DateTime.now(),
      notes: notes,
      createdAt: DateTime.now(),
    );

    final result = await _supplierRepository.addPayment(payment);

    return result.fold((failure) {
      _errorMessage = failure.message;
      notifyListeners();
      return false;
    }, (_) {
      // بعد الإضافة، نعيد تحميل البيانات المالية لتحديث المديونية
      loadSupplierFinancials(supplierId);
      return true;
    });
  }

  // 2. تحميل البيانات المالية (دفعات + حساب المديونية)
  Future<void> loadSupplierFinancials(String supplierId) async {
    // تحميل سجل الدفعات
    final paymentsResult = await _supplierRepository.getSupplierPayments(supplierId);
    
    paymentsResult.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
      },
      (payments) async {
        _currentSupplierPayments = payments;
        
        // حساب المديونية بعد الحصول على الدفعات
        await _calculateDebt(supplierId, payments);
      },
    );
  }

  // 3. خوارزمية حساب المديونية
  Future<void> _calculateDebt(String supplierId, List<SupplierPayment> payments) async {
    // أ) نحصل على كل المشتريات (يمكن تحسين هذا بجلب مشتريات المورد فقط من المستودع لاحقاً)
    // حالياً نستخدم الـ Stream الموجود ونأخذ أول قيمة (Snapshot)
    final purchasesSnapshot = await _purchaseRepository.watchPurchases().first;
    
    purchasesSnapshot.fold(
      (failure) => null, // تجاهل الخطأ في الحساب مؤقتاً
      (allPurchases) {
        // فلترة المشتريات الخاصة بهذا المورد
        final supplierPurchases = allPurchases.where((p) => p.supplierId == supplierId).toList();

        double totalPurchasesAmount = 0.0;
        double totalReturnsValue = 0.0;

        for (var purchase in supplierPurchases) {
          // 1. إجمالي الفاتورة (الصافي بعد الخصم)
          totalPurchasesAmount += purchase.totalAmount;

          // 2. حساب قيمة المرتجعات
          // المرتجعات يتم خصمها لأن totalAmount في الفاتورة يمثل (الكمية الأصلية * السعر - الخصم)
          // لذا يجب أن نطرح قيمة البضاعة التي عادت للمورد
          for (var item in purchase.items) {
            if (item.returnedQuantity > 0) {
              totalReturnsValue += (item.returnedQuantity * item.price);
            }
          }
        }

        // 3. إجمالي المدفوعات
        double totalPaymentsAmount = payments.fold(0.0, (sum, p) => sum + p.amount);

        // المعادلة النهائية للمديونية:
        // (إجمالي الفواتير) - (قيمة المرتجعات) - (ما تم سداده)
        _currentSupplierDebt = totalPurchasesAmount - totalReturnsValue - totalPaymentsAmount;
        
        notifyListeners();
      },
    );
  }
}