import 'package:sqflite/sqflite.dart';
import '../../models/product_model.dart';
import '../../../core/constants/database_constants.dart';
import 'database_helper.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getAllProducts();
  Future<ProductModel?> getProductById(String id);
  Future<List<ProductModel>> getProductsByCategory(String category);
  Future<List<ProductModel>> getLowStockProducts();
  Future<String> insertProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
  Future<void> updateProductStock(String id, double stock);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final DatabaseHelper databaseHelper;

  ProductLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<ProductModel>> getAllProducts() async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.productsTable,
      orderBy: '${DatabaseConstants.columnName} ASC',
    );
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.productsTable,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ProductModel.fromMap(maps.first);
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.productsTable,
      where: '${DatabaseConstants.columnCategory} = ?',
      whereArgs: [category],
      orderBy: '${DatabaseConstants.columnName} ASC',
    );
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  @override
  Future<List<ProductModel>> getLowStockProducts() async {
    final db = await databaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT * FROM ${DatabaseConstants.productsTable}
      WHERE ${DatabaseConstants.columnStock} <= ${DatabaseConstants.columnMinStock}
      AND ${DatabaseConstants.columnStatus} = 'active'
      ORDER BY ${DatabaseConstants.columnStock} ASC
    ''');
    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  @override
  Future<String> insertProduct(ProductModel product) async {
    final db = await databaseHelper.database;
    await db.insert(
      DatabaseConstants.productsTable,
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return product.id;
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final db = await databaseHelper.database;
    await db.update(
      DatabaseConstants.productsTable,
      product.toMap(),
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [product.id],
    );
  }

  @override
  Future<void> deleteProduct(String id) async {
    final db = await databaseHelper.database;
    await db.delete(
      DatabaseConstants.productsTable,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateProductStock(String id, double stock) async {
    final db = await databaseHelper.database;
    await db.update(
      DatabaseConstants.productsTable,
      {
        DatabaseConstants.columnStock: stock,
        DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }
}