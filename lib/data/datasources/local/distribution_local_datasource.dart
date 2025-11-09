import 'package:sqflite/sqflite.dart';
import '../../models/distribution_model.dart';
import '../../models/distribution_item_model.dart';
import '../../../core/constants/database_constants.dart';
import 'database_helper.dart';

abstract class DistributionLocalDataSource {
  Future<List<DistributionModel>> getAllDistributions();
  Future<DistributionModel?> getDistributionById(String id);
  Future<List<DistributionModel>> getDistributionsByCustomer(String customerId);
  Future<List<DistributionModel>> getDistributionsByDateRange(
    DateTime start,
    DateTime end,
  );
  Future<String> insertDistribution(DistributionModel distribution);
  Future<void> updateDistribution(DistributionModel distribution);
  Future<void> deleteDistribution(String id);
  Future<void> updatePaymentStatus(
    String id,
    double paidAmount,
    String paymentStatus,
  );
}

class DistributionLocalDataSourceImpl implements DistributionLocalDataSource {
  final DatabaseHelper databaseHelper;

  DistributionLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<DistributionModel>> getAllDistributions() async {
    final db = await databaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT d.*, c.${DatabaseConstants.columnName} as customer_name
      FROM ${DatabaseConstants.distributionsTable} d
      INNER JOIN ${DatabaseConstants.customersTable} c 
        ON d.${DatabaseConstants.columnCustomerId} = c.${DatabaseConstants.columnId}
      ORDER BY d.${DatabaseConstants.columnDistributionDate} DESC
    ''');

    List<DistributionModel> distributions = [];
    for (var map in maps) {
      final items = await _getDistributionItems(map['id'] as String);
      distributions.add(DistributionModel.fromMap(map, items));
    }
    return distributions;
  }

  @override
  Future<DistributionModel?> getDistributionById(String id) async {
    final db = await databaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT d.*, c.${DatabaseConstants.columnName} as customer_name
      FROM ${DatabaseConstants.distributionsTable} d
      INNER JOIN ${DatabaseConstants.customersTable} c 
        ON d.${DatabaseConstants.columnCustomerId} = c.${DatabaseConstants.columnId}
      WHERE d.${DatabaseConstants.columnId} = ?
    ''', [id]);

    if (maps.isEmpty) return null;

    final items = await _getDistributionItems(id);
    return DistributionModel.fromMap(maps.first, items);
  }

  @override
  Future<List<DistributionModel>> getDistributionsByCustomer(
    String customerId,
  ) async {
    final db = await databaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT d.*, c.${DatabaseConstants.columnName} as customer_name
      FROM ${DatabaseConstants.distributionsTable} d
      INNER JOIN ${DatabaseConstants.customersTable} c 
        ON d.${DatabaseConstants.columnCustomerId} = c.${DatabaseConstants.columnId}
      WHERE d.${DatabaseConstants.columnCustomerId} = ?
      ORDER BY d.${DatabaseConstants.columnDistributionDate} DESC
    ''', [customerId]);

    List<DistributionModel> distributions = [];
    for (var map in maps) {
      final items = await _getDistributionItems(map['id'] as String);
      distributions.add(DistributionModel.fromMap(map, items));
    }
    return distributions;
  }

  @override
  Future<List<DistributionModel>> getDistributionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await databaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT d.*, c.${DatabaseConstants.columnName} as customer_name
      FROM ${DatabaseConstants.distributionsTable} d
      INNER JOIN ${DatabaseConstants.customersTable} c 
        ON d.${DatabaseConstants.columnCustomerId} = c.${DatabaseConstants.columnId}
      WHERE d.${DatabaseConstants.columnDistributionDate} BETWEEN ? AND ?
      ORDER BY d.${DatabaseConstants.columnDistributionDate} DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);

    List<DistributionModel> distributions = [];
    for (var map in maps) {
      final items = await _getDistributionItems(map['id'] as String);
      distributions.add(DistributionModel.fromMap(map, items));
    }
    return distributions;
  }

  @override
  Future<String> insertDistribution(DistributionModel distribution) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      // Insert distribution
      await txn.insert(
        DatabaseConstants.distributionsTable,
        distribution.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert distribution items
      for (var item in distribution.items) {
        final itemModel = DistributionItemModel.fromEntity(item);
        await txn.insert(
          DatabaseConstants.distributionItemsTable,
          itemModel.toMap(distribution.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    return distribution.id;
  }

  @override
  Future<void> updateDistribution(DistributionModel distribution) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        DatabaseConstants.distributionsTable,
        distribution.toMap(),
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [distribution.id],
      );

      // Delete old items
      await txn.delete(
        DatabaseConstants.distributionItemsTable,
        where: '${DatabaseConstants.columnDistributionId} = ?',
        whereArgs: [distribution.id],
      );

      // Insert new items
      for (var item in distribution.items) {
        final itemModel = DistributionItemModel.fromEntity(item);
        await txn.insert(
          DatabaseConstants.distributionItemsTable,
          itemModel.toMap(distribution.id),
        );
      }
    });
  }

  @override
  Future<void> deleteDistribution(String id) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      await txn.delete(
        DatabaseConstants.distributionItemsTable,
        where: '${DatabaseConstants.columnDistributionId} = ?',
        whereArgs: [id],
      );

      await txn.delete(
        DatabaseConstants.distributionsTable,
        where: '${DatabaseConstants.columnId} = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<void> updatePaymentStatus(
    String id,
    double paidAmount,
    String paymentStatus,
  ) async {
    final db = await databaseHelper.database;
    await db.update(
      DatabaseConstants.distributionsTable,
      {
        DatabaseConstants.columnPaidAmount: paidAmount,
        DatabaseConstants.columnPaymentStatus: paymentStatus,
        DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<List<DistributionItemModel>> _getDistributionItems(
    String distributionId,
  ) async {
    final db = await databaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT di.*, p.${DatabaseConstants.columnName} as product_name
      FROM ${DatabaseConstants.distributionItemsTable} di
      INNER JOIN ${DatabaseConstants.productsTable} p 
        ON di.${DatabaseConstants.columnProductId} = p.${DatabaseConstants.columnId}
      WHERE di.${DatabaseConstants.columnDistributionId} = ?
    ''', [distributionId]);

    return maps.map((map) => DistributionItemModel.fromMap(map)).toList();
  }
}