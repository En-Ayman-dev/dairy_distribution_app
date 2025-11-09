import 'package:sqflite/sqflite.dart';
import '../../models/customer_model.dart';
import '../../../core/constants/database_constants.dart';
import 'database_helper.dart';

abstract class CustomerLocalDataSource {
  Future<List<CustomerModel>> getAllCustomers();
  Future<CustomerModel?> getCustomerById(String id);
  Future<List<CustomerModel>> getCustomersByStatus(String status);
  Future<List<CustomerModel>> searchCustomers(String query);
  Future<String> insertCustomer(CustomerModel customer);
  Future<void> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String id);
  Future<void> updateCustomerBalance(String id, double balance);
}

class CustomerLocalDataSourceImpl implements CustomerLocalDataSource {
  final DatabaseHelper databaseHelper;

  CustomerLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<CustomerModel>> getAllCustomers() async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.customersTable,
      orderBy: '${DatabaseConstants.columnName} ASC',
    );
    return maps.map((map) => CustomerModel.fromMap(map)).toList();
  }

  @override
  Future<CustomerModel?> getCustomerById(String id) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.customersTable,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return CustomerModel.fromMap(maps.first);
  }

  @override
  Future<List<CustomerModel>> getCustomersByStatus(String status) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.customersTable,
      where: '${DatabaseConstants.columnStatus} = ?',
      whereArgs: [status],
      orderBy: '${DatabaseConstants.columnName} ASC',
    );
    return maps.map((map) => CustomerModel.fromMap(map)).toList();
  }

  @override
  Future<List<CustomerModel>> searchCustomers(String query) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.customersTable,
      where: '''
        ${DatabaseConstants.columnName} LIKE ? OR 
        ${DatabaseConstants.columnPhone} LIKE ?
      ''',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: '${DatabaseConstants.columnName} ASC',
    );
    return maps.map((map) => CustomerModel.fromMap(map)).toList();
  }

  @override
  Future<String> insertCustomer(CustomerModel customer) async {
    final db = await databaseHelper.database;
    await db.insert(
      DatabaseConstants.customersTable,
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return customer.id;
  }

  @override
  Future<void> updateCustomer(CustomerModel customer) async {
    final db = await databaseHelper.database;
    await db.update(
      DatabaseConstants.customersTable,
      customer.toMap(),
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [customer.id],
    );
  }

  @override
  Future<void> deleteCustomer(String id) async {
    final db = await databaseHelper.database;
    await db.delete(
      DatabaseConstants.customersTable,
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateCustomerBalance(String id, double balance) async {
    final db = await databaseHelper.database;
    await db.update(
      DatabaseConstants.customersTable,
      {
        DatabaseConstants.columnBalance: balance,
        DatabaseConstants.columnUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${DatabaseConstants.columnId} = ?',
      whereArgs: [id],
    );
  }
}