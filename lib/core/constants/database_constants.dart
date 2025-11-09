class DatabaseConstants {
  static const String databaseName = 'dairy_distribution.db';
  static const int databaseVersion = 1;

  // Table Names
  static const String customersTable = 'customers';
  static const String productsTable = 'products';
  static const String distributionsTable = 'distributions';
  static const String distributionItemsTable = 'distribution_items';
  static const String paymentsTable = 'payments';
  static const String syncQueueTable = 'sync_queue';

  // Common Columns
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnSyncStatus = 'sync_status';
  static const String columnFirebaseId = 'firebase_id';

  // Customer Columns
  static const String columnPhone = 'phone';
  static const String columnEmail = 'email';
  static const String columnAddress = 'address';
  static const String columnBalance = 'balance';
  static const String columnStatus = 'status';

  // Product Columns
  static const String columnCategory = 'category';
  static const String columnUnit = 'unit';
  static const String columnPrice = 'price';
  static const String columnStock = 'stock';
  static const String columnMinStock = 'min_stock';

  // Distribution Columns
  static const String columnCustomerId = 'customer_id';
  static const String columnDistributionDate = 'distribution_date';
  static const String columnTotalAmount = 'total_amount';
  static const String columnPaidAmount = 'paid_amount';
  static const String columnPaymentStatus = 'payment_status';
  static const String columnNotes = 'notes';

  // Distribution Item Columns
  static const String columnDistributionId = 'distribution_id';
  static const String columnProductId = 'product_id';
  static const String columnQuantity = 'quantity';
  static const String columnSubtotal = 'subtotal';

  // Payment Columns
  static const String columnAmount = 'amount';
  static const String columnPaymentMethod = 'payment_method';
  static const String columnPaymentDate = 'payment_date';

  // Sync Queue Columns
  static const String columnEntityType = 'entity_type';
  static const String columnEntityId = 'entity_id';
  static const String columnOperation = 'operation';
  static const String columnData = 'data';
}