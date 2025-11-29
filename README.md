# dairy_distribution_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Suppliers & Purchases (Inventory Management Changes)

The app now separates supplier, purchase, and product responsibilities:

- Products define static information: name, category, unit, and min stock.
- Product `stock` and `price` are now managed via Purchases linked to Suppliers.
- A `Suppliers` CRUD screen is available under Home quick actions; purchases are added via the product details screen or Add Purchase route.

Migration:

1. Existing product `stock` and `price` remain intact. New stock/price updates should be performed using the `Add Purchase` flow.
2. For bulk migration where you wish to convert existing product `stock` into `Purchase` documents tied to a legacy supplier, run the provided migration script at `tool/migrate_product_stock_to_purchases.dart` (requires running with authenticated Firebase user and credentials).

Notes:
- Purchases update product stock and set product price to the latest purchase price via a Firestore transaction to ensure consistency.
- The UI was updated so `Add Product` only accepts name/category/unit and optional minStock; `price` and `stock` fields are removed from the add-product dialog.
