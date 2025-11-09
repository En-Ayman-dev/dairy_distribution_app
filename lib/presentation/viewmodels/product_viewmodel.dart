import 'package:flutter/foundation.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import 'package:uuid/uuid.dart';

enum ProductViewState {
  initial,
  loading,
  loaded,
  error,
}

class ProductViewModel extends ChangeNotifier {
  final ProductRepository _repository;
  final Uuid _uuid;

  ProductViewModel(this._repository, this._uuid);

  ProductViewState _state = ProductViewState.initial;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  Product? _selectedProduct;
  String? _errorMessage;
  ProductCategory? _filterCategory;
  String _searchQuery = '';

  // Getters
  ProductViewState get state => _state;
  List<Product> get products => _filteredProducts;
  Product? get selectedProduct => _selectedProduct;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  int get productCount => _products.length;
  int get lowStockCount =>
      _products.where((p) => p.isLowStock).length;

  // Get total inventory value
  double get totalInventoryValue =>
      _products.fold(0, (sum, product) => sum + (product.stock * product.price));

  // Load all products
  Future<void> loadProducts() async {
    _setState(ProductViewState.loading);

    final result = await _repository.getAllProducts();

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(ProductViewState.error);
      },
      (products) {
        _products = products;
        _applyFilters();
        _setState(ProductViewState.loaded);
      },
    );
  }

  // Add new product
  Future<bool> addProduct({
    required String name,
    required ProductCategory category,
    required String unit,
    required double price,
    double stock = 0.0,
    double minStock = 0.0,
  }) async {
    final product = Product(
      id: _uuid.v4(),
      name: name,
      category: category,
      unit: unit,
      price: price,
      stock: stock,
      minStock: minStock,
      status: ProductStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _repository.addProduct(product);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (productId) {
        loadProducts();
        return true;
      },
    );
  }

  // Update product
  Future<bool> updateProduct(Product product) async {
    final result = await _repository.updateProduct(product);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        loadProducts();
        return true;
      },
    );
  }

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    final result = await _repository.deleteProduct(productId);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        loadProducts();
        return true;
      },
    );
  }

  // Update stock
  Future<bool> updateStock(String productId, double quantity) async {
    final product = _products.firstWhere((p) => p.id == productId);
    final newStock = product.stock + quantity;

    final result = await _repository.updateProductStock(productId, newStock);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        loadProducts();
        return true;
      },
    );
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    final result = await _repository.getLowStockProducts();

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        return [];
      },
      (products) => products,
    );
  }

  // Search products
  void searchProducts(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  // Filter by category
  void filterByCategory(ProductCategory? category) {
    _filterCategory = category;
    _applyFilters();
  }

  // Apply all filters
  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      // Category filter
      if (_filterCategory != null && product.category != _filterCategory) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        return product.name.toLowerCase().contains(_searchQuery);
      }

      return true;
    }).toList();

    // Sort by name
    _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _filterCategory = null;
    _applyFilters();
  }

  // Get products by category
  List<Product> getProductsByCategory(ProductCategory category) {
    return _products.where((p) => p.category == category).toList();
  }

  void _setState(ProductViewState state) {
    _state = state;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setSelectedProduct(Product? product) {
    _selectedProduct = product;
    notifyListeners();
  }
}