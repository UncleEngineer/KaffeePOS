import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final db = await openDatabase(
      join(await getDatabasesPath(), 'pos.db'),
      onCreate: (db, version) async {
        // Create categories table first
        await db.execute('''CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          code TEXT NOT NULL,
          color_code TEXT NOT NULL
        )''');
        
        // Create products table with category reference
        await db.execute('''CREATE TABLE products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          category_id INTEGER NOT NULL,
          FOREIGN KEY (category_id) REFERENCES categories (id)
        )''');
        
        await db.execute('''CREATE TABLE bills (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT
        )''');
        
        await db.execute('''CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )''');

        // Create orders table
        await db.execute('''CREATE TABLE orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bill_number TEXT NOT NULL,
          date TEXT NOT NULL,
          total REAL NOT NULL,
          shop_name TEXT NOT NULL
        )''');

        // Create order_items table
        await db.execute('''CREATE TABLE order_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER NOT NULL,
          product_name TEXT NOT NULL,
          product_price REAL NOT NULL,
          quantity INTEGER NOT NULL,
          FOREIGN KEY (order_id) REFERENCES orders (id)
        )''');
        
        // Insert default shop name
        await db.insert('settings', {'key': 'shop_name', 'value': 'Uncle Coffee Shop'});
        
        // Insert default categories
        await db.insert('categories', {'title': 'ทั่วไป', 'code': 'GEN', 'color_code': '#2196F3'});
        await db.insert('categories', {'title': 'เครื่องดื่ม', 'code': 'BEV', 'color_code': '#4CAF50'});
        await db.insert('categories', {'title': 'อาหาร', 'code': 'FOOD', 'color_code': '#FF9800'});
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )''');
          
          final result = await db.query('settings', where: 'key = ?', whereArgs: ['shop_name']);
          if (result.isEmpty) {
            await db.insert('settings', {'key': 'shop_name', 'value': 'Uncle Coffee Shop'});
          }
        }
        
        if (oldVersion < 3) {
          await db.execute('''CREATE TABLE IF NOT EXISTS categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            code TEXT NOT NULL,
            color_code TEXT NOT NULL
          )''');
          
          await db.execute('ALTER TABLE products ADD COLUMN category_id INTEGER DEFAULT 1');
          
          final categoryResult = await db.query('categories');
          if (categoryResult.isEmpty) {
            await db.insert('categories', {'title': 'ทั่วไป', 'code': 'GEN', 'color_code': '#2196F3'});
            await db.insert('categories', {'title': 'เครื่องดื่ม', 'code': 'BEV', 'color_code': '#4CAF50'});
            await db.insert('categories', {'title': 'อาหาร', 'code': 'FOOD', 'color_code': '#FF9800'});
          }
        }

        if (oldVersion < 4) {
          await db.execute('''CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bill_number TEXT NOT NULL,
            date TEXT NOT NULL,
            total REAL NOT NULL,
            shop_name TEXT NOT NULL
          )''');

          await db.execute('''CREATE TABLE IF NOT EXISTS order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            product_name TEXT NOT NULL,
            product_price REAL NOT NULL,
            quantity INTEGER NOT NULL,
            FOREIGN KEY (order_id) REFERENCES orders (id)
          )''');
        }
      },
      version: 4,
    );
    
    // Ensure all tables exist
    await db.execute('''CREATE TABLE IF NOT EXISTS bills (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT
    )''');
    
    await db.execute('''CREATE TABLE IF NOT EXISTS settings (
      key TEXT PRIMARY KEY,
      value TEXT
    )''');
    
    await db.execute('''CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      code TEXT NOT NULL,
      color_code TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bill_number TEXT NOT NULL,
      date TEXT NOT NULL,
      total REAL NOT NULL,
      shop_name TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE IF NOT EXISTS order_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER NOT NULL,
      product_name TEXT NOT NULL,
      product_price REAL NOT NULL,
      quantity INTEGER NOT NULL,
      FOREIGN KEY (order_id) REFERENCES orders (id)
    )''');
    
    // Insert defaults if not exist
    final shopNameResult = await db.query('settings', where: 'key = ?', whereArgs: ['shop_name']);
    if (shopNameResult.isEmpty) {
      await db.insert('settings', {'key': 'shop_name', 'value': 'Uncle Coffee Shop'});
    }
    
    final categoryResult = await db.query('categories');
    if (categoryResult.isEmpty) {
      await db.insert('categories', {'title': 'ทั่วไป', 'code': 'GEN', 'color_code': '#2196F3'});
      await db.insert('categories', {'title': 'เครื่องดื่ม', 'code': 'BEV', 'color_code': '#4CAF50'});
      await db.insert('categories', {'title': 'อาหาร', 'code': 'FOOD', 'color_code': '#FF9800'});
    }
    
    return db;
  }

  // Product methods
  static Future<List<Product>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  static Future<List<Product>> getProductsByCategory(int categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  static Future<void> addProduct(String name, double price, int categoryId) async {
    final db = await database;
    await db.insert('products', {
      'name': name,
      'price': price,
      'category_id': categoryId,
    });
  }

  static Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  static Future<void> deleteProduct(Product product) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [product.id]);
  }

  // Category methods
  static Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  static Future<void> addCategory(String title, String code, String colorCode) async {
    final db = await database;
    await db.insert('categories', {
      'title': title,
      'code': code,
      'color_code': colorCode,
    });
  }

  static Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  static Future<void> deleteCategory(Category category) async {
    final db = await database;
    final products = await db.query('products', where: 'category_id = ?', whereArgs: [category.id]);
    if (products.isNotEmpty) {
      throw Exception('ไม่สามารถลบหมวดหมู่ที่มีสินค้าอยู่ได้');
    }
    await db.delete('categories', where: 'id = ?', whereArgs: [category.id]);
  }

  // Order methods
  static Future<void> saveOrder(List<CartItem> cart, double total, String billNumber, String shopName) async {
    final db = await database;
    
    // Insert order
    final orderId = await db.insert('orders', {
      'bill_number': billNumber,
      'date': DateTime.now().toIso8601String(),
      'total': total,
      'shop_name': shopName,
    });

    // Insert order items
    for (final item in cart) {
      await db.insert('order_items', {
        'order_id': orderId,
        'product_name': item.product.name,
        'product_price': item.product.price,
        'quantity': item.quantity,
      });
    }
  }

  static Future<List<Order>> getOrders({String? searchQuery}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Allow searching by bill number (with or without #)
      String cleanQuery = searchQuery.replaceAll('#', '');
      whereClause = 'WHERE bill_number LIKE ?';
      whereArgs = ['%$cleanQuery%'];
    }

    final List<Map<String, dynamic>> orderMaps = await db.rawQuery('''
      SELECT * FROM orders 
      $whereClause
      ORDER BY date DESC
    ''', whereArgs);

    List<Order> orders = [];
    for (final orderMap in orderMaps) {
      final itemMaps = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderMap['id']],
      );
      
      final items = itemMaps.map((itemMap) => OrderItem.fromMap(itemMap)).toList();
      orders.add(Order.fromMap(orderMap, items));
    }

    return orders;
  }

  static Future<Order?> getOrderById(int id) async {
    final db = await database;
    final orderMaps = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    
    if (orderMaps.isEmpty) return null;

    final itemMaps = await db.query('order_items', where: 'order_id = ?', whereArgs: [id]);
    final items = itemMaps.map((itemMap) => OrderItem.fromMap(itemMap)).toList();
    
    return Order.fromMap(orderMaps.first, items);
  }

  static Future<String> generateBillNumber() async {
    final db = await database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM bills WHERE date = ?',
      [today],
    );

    int count = Sqflite.firstIntValue(result) ?? 0;
    await db.insert('bills', {'date': today});

    int billNumber = count + 1;
    return '#${billNumber.toString().padLeft(4, '0')}';
  }

  // Settings methods
  static Future<String> getShopName() async {
    final db = await database;
    final result = await db.query('settings', where: 'key = ?', whereArgs: ['shop_name']);
    if (result.isNotEmpty) {
      return result.first['value'] as String;
    }
    return 'Uncle Coffee Shop';
  }

  static Future<void> setShopName(String shopName) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': 'shop_name', 'value': shopName},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String> getSetting(String key, {String defaultValue = ''}) async {
    final db = await database;
    final result = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (result.isNotEmpty) {
      return result.first['value'] as String;
    }
    return defaultValue;
  }

  static Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}