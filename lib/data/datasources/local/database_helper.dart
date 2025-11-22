import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../core/constants/database_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(DatabaseConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Customers Table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.customersTable} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnName} TEXT NOT NULL,
        ${DatabaseConstants.columnPhone} TEXT NOT NULL,
        ${DatabaseConstants.columnEmail} TEXT,
        ${DatabaseConstants.columnAddress} TEXT,
        ${DatabaseConstants.columnBalance} REAL DEFAULT 0,
        ${DatabaseConstants.columnStatus} TEXT DEFAULT 'active',
        ${DatabaseConstants.columnCreatedAt} TEXT NOT NULL,
        ${DatabaseConstants.columnUpdatedAt} TEXT NOT NULL,
        ${DatabaseConstants.columnSyncStatus} INTEGER DEFAULT 0,
        ${DatabaseConstants.columnFirebaseId} TEXT
      )
    ''');

    // Products Table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.productsTable} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnName} TEXT NOT NULL,
        ${DatabaseConstants.columnCategory} TEXT NOT NULL,
        ${DatabaseConstants.columnUnit} TEXT NOT NULL,
        ${DatabaseConstants.columnPrice} REAL NOT NULL,
        ${DatabaseConstants.columnStock} REAL DEFAULT 0,
        ${DatabaseConstants.columnMinStock} REAL DEFAULT 0,
        ${DatabaseConstants.columnStatus} TEXT DEFAULT 'active',
        ${DatabaseConstants.columnCreatedAt} TEXT NOT NULL,
        ${DatabaseConstants.columnUpdatedAt} TEXT NOT NULL,
        ${DatabaseConstants.columnSyncStatus} INTEGER DEFAULT 0,
        ${DatabaseConstants.columnFirebaseId} TEXT
      )
    ''');

    // Distributions Table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.distributionsTable} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnCustomerId} TEXT NOT NULL,
        ${DatabaseConstants.columnDistributionDate} TEXT NOT NULL,
        ${DatabaseConstants.columnTotalAmount} REAL NOT NULL,
        ${DatabaseConstants.columnPaidAmount} REAL DEFAULT 0,
        ${DatabaseConstants.columnPaymentStatus} TEXT DEFAULT 'pending',
        ${DatabaseConstants.columnNotes} TEXT,
        ${DatabaseConstants.columnCreatedAt} TEXT NOT NULL,
        ${DatabaseConstants.columnUpdatedAt} TEXT NOT NULL,
        ${DatabaseConstants.columnSyncStatus} INTEGER DEFAULT 0,
        ${DatabaseConstants.columnFirebaseId} TEXT,
        FOREIGN KEY (${DatabaseConstants.columnCustomerId}) 
          REFERENCES ${DatabaseConstants.customersTable}(${DatabaseConstants.columnId})
      )
    ''');

    // Distribution Items Table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.distributionItemsTable} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnDistributionId} TEXT NOT NULL,
        ${DatabaseConstants.columnProductId} TEXT NOT NULL,
        ${DatabaseConstants.columnQuantity} REAL NOT NULL,
        ${DatabaseConstants.columnPrice} REAL NOT NULL,
        ${DatabaseConstants.columnSubtotal} REAL NOT NULL,
        FOREIGN KEY (${DatabaseConstants.columnDistributionId}) 
          REFERENCES ${DatabaseConstants.distributionsTable}(${DatabaseConstants.columnId}),
        FOREIGN KEY (${DatabaseConstants.columnProductId}) 
          REFERENCES ${DatabaseConstants.productsTable}(${DatabaseConstants.columnId})
      )
    ''');

    // Payments Table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.paymentsTable} (
        ${DatabaseConstants.columnId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnCustomerId} TEXT NOT NULL,
        ${DatabaseConstants.columnAmount} REAL NOT NULL,
        ${DatabaseConstants.columnPaymentMethod} TEXT NOT NULL,
        ${DatabaseConstants.columnPaymentDate} TEXT NOT NULL,
        ${DatabaseConstants.columnNotes} TEXT,
        ${DatabaseConstants.columnCreatedAt} TEXT NOT NULL,
        ${DatabaseConstants.columnSyncStatus} INTEGER DEFAULT 0,
        ${DatabaseConstants.columnFirebaseId} TEXT,
        FOREIGN KEY (${DatabaseConstants.columnCustomerId}) 
          REFERENCES ${DatabaseConstants.customersTable}(${DatabaseConstants.columnId})
      )
    ''');

    // Sync Queue Table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.syncQueueTable} (
        ${DatabaseConstants.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.columnEntityType} TEXT NOT NULL,
        ${DatabaseConstants.columnEntityId} TEXT NOT NULL,
        ${DatabaseConstants.columnOperation} TEXT NOT NULL,
        ${DatabaseConstants.columnData} TEXT NOT NULL,
        ${DatabaseConstants.columnCreatedAt} TEXT NOT NULL,
        ${DatabaseConstants.columnSyncStatus} INTEGER DEFAULT 0
      )
    ''');

    // Create Indexes
    await db.execute('''
      CREATE INDEX idx_customer_status 
      ON ${DatabaseConstants.customersTable}(${DatabaseConstants.columnStatus})
    ''');

    await db.execute('''
      CREATE INDEX idx_distribution_customer 
      ON ${DatabaseConstants.distributionsTable}(${DatabaseConstants.columnCustomerId})
    ''');

    await db.execute('''
      CREATE INDEX idx_distribution_date 
      ON ${DatabaseConstants.distributionsTable}(${DatabaseConstants.columnDistributionDate})
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades
    if (oldVersion < newVersion) {
      // Add migration logic here
    }
  }
Future<void> deleteDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DatabaseConstants.databaseName);

    // 1. إغلاق الاتصال الحالي إذا كان مفتوحاً
    if (_database != null) {
      await _database!.close();
      _database = null; // تصفير المتغير لضمان إعادة الفتح لاحقاً
    }

    // 2. حذف ملف قاعدة البيانات
    await deleteDatabase(path);
    
    // (اختياري) طباعة للتأكد
    // developer.log('Database deleted successfully', name: 'DatabaseHelper');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}