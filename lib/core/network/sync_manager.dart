import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../data/datasources/local/database_helper.dart';
import '../constants/database_constants.dart';
import 'network_info.dart';
import 'package:logger/logger.dart';

class SyncManager {
  final DatabaseHelper databaseHelper;
  final NetworkInfo networkInfo;
  final Logger logger;

  SyncManager({
    required this.databaseHelper,
    required this.networkInfo,
    required this.logger,
  });

  // Queue sync operation
  Future<void> queueSync({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        DatabaseConstants.syncQueueTable,
        {
          DatabaseConstants.columnEntityType: entityType,
          DatabaseConstants.columnEntityId: entityId,
          DatabaseConstants.columnOperation: operation,
          DatabaseConstants.columnData: jsonEncode(data),
          DatabaseConstants.columnCreatedAt: DateTime.now().toIso8601String(),
          DatabaseConstants.columnSyncStatus: 0, // 0 = pending
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      logger.i('Queued sync: $entityType - $operation - $entityId');
    } catch (e) {
      logger.e('Failed to queue sync: $e');
    }
  }

  // Get pending sync operations
  Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    try {
      final db = await databaseHelper.database;
      return await db.query(
        DatabaseConstants.syncQueueTable,
        where: '${DatabaseConstants.columnSyncStatus} = ?',
        whereArgs: [0],
        orderBy: '${DatabaseConstants.columnCreatedAt} ASC',
      );
    } catch (e) {
      logger.e('Failed to get pending sync operations: $e');
      return [];
    }
  }

  // Mark operation as synced
  Future<void> markAsSynced(String entityType, String entityId) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseConstants.syncQueueTable,
        {DatabaseConstants.columnSyncStatus: 1}, // 1 = synced
        where: '''
          ${DatabaseConstants.columnEntityType} = ? AND 
          ${DatabaseConstants.columnEntityId} = ?
        ''',
        whereArgs: [entityType, entityId],
      );
      logger.i('Marked as synced: $entityType - $entityId');
    } catch (e) {
      logger.e('Failed to mark as synced: $e');
    }
  }

  // Sync all pending operations
  Future<void> syncAllPending() async {
    if (!await networkInfo.isConnected) {
      logger.w('No internet connection. Cannot sync.');
      return;
    }

    final pendingOps = await getPendingSyncOperations();
    logger.i('Found ${pendingOps.length} pending sync operations');

    for (var op in pendingOps) {
      try {
        await _syncOperation(op);
      } catch (e) {
        logger.e('Failed to sync operation: $e');
      }
    }
  }

  Future<void> _syncOperation(Map<String, dynamic> op) async {
    final entityType = op[DatabaseConstants.columnEntityType] as String;
    final entityId = op[DatabaseConstants.columnEntityId] as String;
    final operation = op[DatabaseConstants.columnOperation] as String;

    logger.i('Syncing: $entityType - $operation - $entityId');

    // This will be handled by repositories
    // Just mark as synced for now
    await markAsSynced(entityType, entityId);
  }

  // Clear synced operations older than specified days
  Future<void> clearOldSyncedOperations({int daysOld = 7}) async {
    try {
      final db = await databaseHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      await db.delete(
        DatabaseConstants.syncQueueTable,
        where: '''
          ${DatabaseConstants.columnSyncStatus} = 1 AND 
          ${DatabaseConstants.columnCreatedAt} < ?
        ''',
        whereArgs: [cutoffDate.toIso8601String()],
      );
      
      logger.i('Cleared old synced operations');
    } catch (e) {
      logger.e('Failed to clear old synced operations: $e');
    }
  }

  // Get sync status
  Future<Map<String, int>> getSyncStatus() async {
    try {
      final db = await databaseHelper.database;
      
      final pending = Sqflite.firstIntValue(
        await db.rawQuery('''
          SELECT COUNT(*) FROM ${DatabaseConstants.syncQueueTable}
          WHERE ${DatabaseConstants.columnSyncStatus} = 0
        '''),
      ) ?? 0;

      final synced = Sqflite.firstIntValue(
        await db.rawQuery('''
          SELECT COUNT(*) FROM ${DatabaseConstants.syncQueueTable}
          WHERE ${DatabaseConstants.columnSyncStatus} = 1
        '''),
      ) ?? 0;

      return {
        'pending': pending,
        'synced': synced,
        'total': pending + synced,
      };
    } catch (e) {
      logger.e('Failed to get sync status: $e');
      return {'pending': 0, 'synced': 0, 'total': 0};
    }
  }
}