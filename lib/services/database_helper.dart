import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('warehouse_elite.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        spanish_name TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL,
        cost_price REAL NOT NULL DEFAULT 0,
        sale_price REAL NOT NULL DEFAULT 0,
        quantity INTEGER NOT NULL DEFAULT 0,
        location TEXT NOT NULL DEFAULT '',
        weight REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        stock_before INTEGER,
        stock_after INTEGER,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute(
        'CREATE INDEX idx_movements_product ON stock_movements(product_id)');
    await db.execute(
        'CREATE INDEX idx_movements_created ON stock_movements(created_at)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE products ADD COLUMN spanish_name TEXT NOT NULL DEFAULT ''");
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE stock_movements ADD COLUMN stock_before INTEGER');
      await db.execute('ALTER TABLE stock_movements ADD COLUMN stock_after INTEGER');
    }
  }

  String _normalizeBarcode(String barcode) => barcode.trim();

  Product _productWithNormalizedBarcode(Product product) {
    return product.copyWith(
      barcode: _normalizeBarcode(product.barcode),
      name: product.name.trim(),
      spanishName: product.spanishName.trim(),
    );
  }

  // ===================== PRODUCT CRUD =====================

  Future<int> insertProduct(Product product) async {
    final db = await database;
    final normalizedProduct = _productWithNormalizedBarcode(product);
    return await db.insert('products', normalizedProduct.toMap()..remove('id'));
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final normalizedBarcode = _normalizeBarcode(barcode);
    final maps = await db.query(
      'products',
      where: 'UPPER(TRIM(barcode)) = UPPER(?)',
      whereArgs: [normalizedBarcode],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'updated_at DESC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    product.updatedAt = DateTime.now();
    final normalizedProduct = _productWithNormalizedBarcode(product);
    return await db.update(
      'products',
      normalizedProduct.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> getLowStockProducts({int threshold = 25}) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'quantity <= ?',
      whereArgs: [threshold],
      orderBy: 'quantity ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  // ===================== STOCK MOVEMENTS =====================

  Future<int> insertStockMovement(StockMovement movement) async {
    final db = await database;
    return await db.insert('stock_movements', movement.toMap()..remove('id'));
  }

  Future<List<StockMovement>> getRecentMovements({int limit = 20}) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT sm.*, p.name as product_name, p.barcode as product_barcode, p.spanish_name as product_spanish_name, p.location as product_location
      FROM stock_movements sm
      LEFT JOIN products p ON sm.product_id = p.id
      ORDER BY sm.created_at DESC
      LIMIT ?
    ''', [limit]);
    return maps.map((m) => StockMovement.fromMap(m)).toList();
  }

  Future<List<StockMovement>> getAllMovements() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT sm.*, p.name as product_name, p.barcode as product_barcode, p.spanish_name as product_spanish_name, p.location as product_location
      FROM stock_movements sm
      LEFT JOIN products p ON sm.product_id = p.id
      ORDER BY sm.created_at DESC
    ''');
    return maps.map((m) => StockMovement.fromMap(m)).toList();
  }

  Future<List<StockMovement>> getMovementsByProduct(int productId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT sm.*, p.name as product_name, p.barcode as product_barcode, p.spanish_name as product_spanish_name, p.location as product_location
      FROM stock_movements sm
      LEFT JOIN products p ON sm.product_id = p.id
      WHERE sm.product_id = ?
      ORDER BY sm.created_at DESC
    ''', [productId]);
    return maps.map((m) => StockMovement.fromMap(m)).toList();
  }

  // ===================== STOCK OPERATIONS =====================

  Future<void> processStockMovement({
    required Product product,
    required String type,
    required int quantity,
    String? note,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final stockBefore = product.quantity;
      int newQuantity = stockBefore;
      switch (type) {
        case 'mal_kabul':
          newQuantity += quantity;
          break;
        case 'sevkiyat':
        case 'fire_iade':
          newQuantity -= quantity;
          if (newQuantity < 0) newQuantity = 0;
          break;
        case 'sayim':
          newQuantity = quantity; // Direct set for counting
          break;
      }

      final movement = StockMovement(
        productId: product.id!,
        type: type,
        quantity: quantity,
        stockBefore: stockBefore,
        stockAfter: newQuantity,
        note: note,
      );
      await txn.insert('stock_movements', movement.toMap()..remove('id'));

      await txn.update(
        'products',
        {
          'quantity': newQuantity,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [product.id],
      );
    });
  }

  // ===================== DASHBOARD STATS =====================

  Future<Map<String, dynamic>> getTodayStats() async {
    final db = await database;
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final inboundResult = await db.rawQuery('''
      SELECT COALESCE(SUM(quantity), 0) as total
      FROM stock_movements
      WHERE type = 'mal_kabul' AND created_at LIKE '$todayStr%'
    ''');

    final outboundResult = await db.rawQuery('''
      SELECT COALESCE(SUM(quantity), 0) as total
      FROM stock_movements
      WHERE type IN ('sevkiyat', 'fire_iade') AND created_at LIKE '$todayStr%'
    ''');

    final lowStockResult = await db.rawQuery('''
      SELECT COUNT(*) as total FROM products WHERE quantity <= 25
    ''');

    return {
      'inbound': (inboundResult.first['total'] as num).toInt(),
      'outbound': (outboundResult.first['total'] as num).toInt(),
      'lowStock': (lowStockResult.first['total'] as num).toInt(),
    };
  }

  // ===================== BULK INSERT =====================

  Future<int> bulkInsertProducts(List<Product> products) async {
    final db = await database;
    int count = 0;
    await db.transaction((txn) async {
      for (final product in products) {
        try {
          await txn.insert(
            'products',
            _productWithNormalizedBarcode(product).toMap()..remove('id'),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          count++;
        } catch (e) {
          debugPrint('Bulk insert error for ${product.barcode}: $e');
        }
      }
    });
    return count;
  }

  Future<Map<String, int>> restoreFullBackup({
    required List<Product> products,
    required List<StockMovement> movements,
  }) async {
    final db = await database;
    var productCount = 0;
    var movementCount = 0;
    await db.transaction((txn) async {
      await txn.delete('stock_movements');
      await txn.delete('products');

      final productIdsByBarcode = <String, int>{};
      for (final product in products) {
        final normalizedProduct = _productWithNormalizedBarcode(product);
        final id = await txn.insert('products', normalizedProduct.toMap()..remove('id'));
        productIdsByBarcode[_normalizeBarcode(normalizedProduct.barcode).toUpperCase()] = id;
        productCount++;
      }

      for (final movement in movements) {
        final barcode = movement.productBarcode == null ? '' : _normalizeBarcode(movement.productBarcode!).toUpperCase();
        final productId = productIdsByBarcode[barcode];
        if (productId == null) continue;
        final restoredMovement = StockMovement(
          productId: productId,
          type: movement.type,
          quantity: movement.quantity,
          stockBefore: movement.stockBefore,
          stockAfter: movement.stockAfter,
          note: movement.note,
          createdAt: movement.createdAt,
        );
        await txn.insert('stock_movements', restoredMovement.toMap()..remove('id'));
        movementCount++;
      }
    });

    return {'products': productCount, 'movements': movementCount};
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
