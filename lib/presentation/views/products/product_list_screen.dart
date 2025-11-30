// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/product_viewmodel.dart';
import '../purchases/add_purchase_screen.dart';
import '../../../domain/entities/product.dart';
import '../../../app/themes/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  ProductCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.productsTitle),
        actions: [
          PopupMenuButton<ProductCategory?>(
            icon: const Icon(Icons.filter_list),
            tooltip: AppLocalizations.of(context)!.filterByCategoryTooltip,
            itemBuilder: (context) => [
              PopupMenuItem(value: null, child: Text(AppLocalizations.of(context)!.allCategories)),
              ...ProductCategory.values.map((category) {
                return PopupMenuItem(
                  value: category,
                  child: Text(_getCategoryName(category)),
                );
              }),
            ],
            onSelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
              context.read<ProductViewModel>().filterByCategory(category);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
              child: TextField(
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchProductsHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                context.read<ProductViewModel>().searchProducts(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<ProductViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.state == ProductViewState.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (viewModel.state == ProductViewState.error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(viewModel.errorMessage ?? AppLocalizations.of(context)!.errorOccurred),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => viewModel.loadProducts(),
                          child: Text(AppLocalizations.of(context)!.retry),
                        ),
                      ],
                    ),
                  );
                }

                if (viewModel.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noProductsFound,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.addFirstProductPrompt,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => viewModel.loadProducts(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: viewModel.products.length,
                    itemBuilder: (context, index) {
                      final product = viewModel.products[index];
                      return _buildProductCard(context, product);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddProductDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          _showProductDetailsDialog(context, product);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                // further reduce height to ensure card fits the grid cell
                height: 64,
                decoration: BoxDecoration(
                  color: _getCategoryColor(product.category).withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(product.category),
                    size: 40,
                    color: _getCategoryColor(product.category),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _getCategoryName(product.category),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // small gap instead of Spacer to avoid pushing content beyond card height
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ريال${product.price}/${product.unit}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.green,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (product.isLowStock)
                    const SizedBox(width: 8),
                  if (product.isLowStock)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.lowLabel,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${AppLocalizations.of(context)!.currentStockPrefix} ${product.stock} ${product.unit}',
                style: TextStyle(
                  color: product.isLowStock ? Colors.red : Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryName(ProductCategory category) {
    return category.toString().split('.').last.toUpperCase();
  }

  Color _getCategoryColor(ProductCategory category) {
    switch (category) {
      case ProductCategory.milk:
        return AppColors.milk;
      case ProductCategory.curd:
        return AppColors.curd;
      case ProductCategory.butter:
        return AppColors.butter;
      case ProductCategory.cheese:
        return AppColors.cheese;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(ProductCategory category) {
    switch (category) {
      case ProductCategory.milk:
        return Icons.local_drink;
      case ProductCategory.curd:
        return Icons.breakfast_dining;
      case ProductCategory.butter:
        return Icons.cake;
      case ProductCategory.cheese:
        return Icons.dining;
      default:
        return Icons.inventory_2;
    }
  }

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
              // initial price and stock are now handled from purchases; no priceController used here
              // initial stock is not specified anymore during product creation
    final minStockController = TextEditingController();
    final unitController = TextEditingController(text: 'Liters');
    ProductCategory selectedCategory = ProductCategory.milk;
    showDialog(
      context: this.context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addProductTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.productNameLabel),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ProductCategory>(
                initialValue: selectedCategory,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.categoryLabel),
                items: ProductCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(_getCategoryName(cat)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedCategory = value;
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: unitController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.unitLabel),
              ),
              const SizedBox(height: 8),
              // Note: price and initial stock moved to supplier purchase flow
              const SizedBox(height: 8),
              TextField(
                controller: minStockController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.minStockAlertLabel),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
              ElevatedButton(
            onPressed: () async {
              final vm = this.context.read<ProductViewModel>();
              final success = await vm.addProduct(
                    name: nameController.text,
                    category: selectedCategory,
                    unit: unitController.text,
                    minStock: double.parse(minStockController.text),
                  );

              if (!mounted) return;

              if (success) {
                // Close dialog via the page's Navigator (State context) to
                // avoid using the dialog's builder context after awaiting.
                Navigator.of(this.context).pop();
              }
            },
            child: Text(AppLocalizations.of(context)!.addProductButtonLabel),
          ),
        ],
      ),
    );
  }

  void _showProductDetailsDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppLocalizations.of(context)!.categoryLabel}: ${_getCategoryName(product.category)}'),
            Text('${AppLocalizations.of(context)!.priceLabel}: ريال${product.price}/${product.unit}'),
            Text('${AppLocalizations.of(context)!.currentStockPrefix} ${product.stock} ${product.unit}'),
            Text('${AppLocalizations.of(context)!.minStockAlertLabel}: ${product.minStock} ${product.unit}'),
            if (product.isLowStock)
              Text(
                AppLocalizations.of(context)!.lowStockAlertTitle,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Move to Add Purchase screen to link purchase with supplier
              Navigator.of(context).push(MaterialPageRoute(builder: (c) => AddPurchaseScreen(productId: product.id)));
            },
            child: Text(AppLocalizations.of(context)!.addPurchaseButtonLabel),
          ),
        ],
      ),
    );
  }

  // Stock updates are now handled through the purchase flow which creates
  // a purchase record and updates product stock via transactions.
}