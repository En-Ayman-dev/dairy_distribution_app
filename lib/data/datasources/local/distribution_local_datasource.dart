
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

  // --- إضافة جديدة (الخطوة 7 - الواجهة) ---
  Future<List<DistributionModel>> getFilteredDistributions({
    required DateTime startDate,
    required DateTime endDate,
    String? customerId,
    List<String>? productIds,
  });
  // --- نهاية الإضافة ---
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

  // ... (getDistributionById, getDistributionsByCustomer ... تبقى كما هي) ...
  
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
  Future<List<DistributionModel>> getDistributionsByCustomer(String customerId) async {
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

  // --- إضافة جديدة (الخطوة 7 - التنفيذ) ---
  @override
  Future<List<DistributionModel>> getFilteredDistributions({
    required DateTime startDate,
    required DateTime endDate,
    String? customerId,
    List<String>? productIds,
  }) async {
    final db = await databaseHelper.database;

    // 1. بناء الاستعلام الأساسي
    String sql = '''
      SELECT d.*, c.${DatabaseConstants.columnName} as customer_name
      FROM ${DatabaseConstants.distributionsTable} d
      INNER JOIN ${DatabaseConstants.customersTable} c 
        ON d.${DatabaseConstants.columnCustomerId} = c.${DatabaseConstants.columnId}
    ''';

    // 2. بناء جملة WHERE و Arguments بشكل ديناميكي
    List<String> whereConditions = [];
    List<dynamic> args = [];

    // الفلتر الأول: التاريخ (إجباري)
    whereConditions.add('d.${DatabaseConstants.columnDistributionDate} BETWEEN ? AND ?');
    args.add(startDate.toIso8601String());
    args.add(endDate.toIso8601String());

    // الفلتر الثاني: العميل (اختياري)
    if (customerId != null) {
      whereConditions.add('d.${DatabaseConstants.columnCustomerId} = ?');
      args.add(customerId);
    }

    // الفلتر الثالث: المنتجات (اختياري)
    if (productIds != null && productIds.isNotEmpty) {
      // بناء علامات الاستفهام '?' لـ 'IN' clause
      String placeholders = List.filled(productIds.length, '?').join(',');
      
      // إضافة استعلام فرعي (subquery) للتحقق من وجود المنتجات
      // هذا الاستعلام يعني: "جلب التوزيعات التي (يوجد) لها على الأقل
      // (عنصر واحد) في جدول العناصر يتطابق ID المنتج الخاص به مع
      // قائمة المنتجات المختارة"
      whereConditions.add('''
        EXISTS (
          SELECT 1 
          FROM ${DatabaseConstants.distributionItemsTable} di
          WHERE di.${DatabaseConstants.columnDistributionId} = d.${DatabaseConstants.columnId}
          AND di.${DatabaseConstants.columnProductId} IN ($placeholders)
        )
      ''');
      args.addAll(productIds);
    }

    // 3. تجميع الاستعلام النهائي
    if (whereConditions.isNotEmpty) {
      sql += ' WHERE ${whereConditions.join(' AND ')}';
    }

    sql += ' ORDER BY d.${DatabaseConstants.columnDistributionDate} DESC';

    // 4. تنفيذ الاستعلام
    final maps = await db.rawQuery(sql, args);

    // 5. بناء الـ Models (نفس الكود المستخدم في الدوال الأخرى)
    List<DistributionModel> distributions = [];
    for (var map in maps) {
      final items = await _getDistributionItems(map['id'] as String);
      distributions.add(DistributionModel.fromMap(map, items));
    }
    return distributions;
  }
  // --- نهاية الإضافة ---

  @override
  Future<String> insertDistribution(DistributionModel distribution) async {
    // ... (يبقى كما هو) ...
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
    // ... (يبقى كما هو) ...
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
    // ... (يبقى كما هو) ...
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
    // ... (يبقى كما هو) ...
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
    // ... (يبقى كما هو) ...
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