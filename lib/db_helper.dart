import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get db async => _db ??= await _init();

  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'sales.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute(
            'CREATE TABLE products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, price REAL NOT NULL, stock INTEGER NOT NULL DEFAULT 0)');
        await db.execute(
            'CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT)');
        await db.execute(
            'CREATE TABLE orders(id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, product_id INTEGER, quantity INTEGER, total REAL, date TEXT)');
      },
    );
  }

  // Products
  static Future<List<Map<String, dynamic>>> getProducts([String q = '']) async {
    final d = await db;
    return d.query('products',
        where: q.isEmpty ? null : 'name LIKE ?', whereArgs: q.isEmpty ? null : ['%' + q + '%']);
  }

  static Future<int> addProduct(String name, double price, int stock) async =>
      (await db).insert('products', {'name': name, 'price': price, 'stock': stock});

  static Future<int> deleteProduct(int id) async =>
      (await db).delete('products', where: 'id = ?', whereArgs: [id]);

  // Customers
  static Future<List<Map<String, dynamic>>> getCustomers([String q = '']) async {
    final d = await db;
    return d.query('customers',
        where: q.isEmpty ? null : 'name LIKE ?', whereArgs: q.isEmpty ? null : ['%' + q + '%']);
  }

  static Future<int> addCustomer(String name, String phone) async =>
      (await db).insert('customers', {'name': name, 'phone': phone});

  static Future<int> deleteCustomer(int id) async =>
      (await db).delete('customers', where: 'id = ?', whereArgs: [id]);

  // Orders
  static Future<int> addOrder(int customerId, int productId, int qty, double price) async {
  final d = await db;

  if (qty <= 0) return -1;

  return await d.transaction((txn) async {
    final products = await txn.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (products.isEmpty) return -1;

    final stock = products.first['stock'] as int;

    if (stock < qty) return -1;

    final id = await txn.insert('orders', {
      'customer_id': customerId,
      'product_id': productId,
      'quantity': qty,
      'total': qty * price,
      'date': DateTime.now().toIso8601String(),
    });

    await txn.update(
      'products',
      {'stock': stock - qty},
      where: 'id = ?',
      whereArgs: [productId],
    );

    return id;
  });
}
      'customer_id': customerId,
      'product_id': productId,
      'quantity': qty,
      'total': (qty * price),
      'date': DateTime.now().toIso8601String(),
    });
    await d.rawUpdate('UPDATE products SET stock = stock - ? WHERE id = ?', [qty, productId]);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getOrders() async => (await db).rawQuery('''
      SELECT o.id, c.name AS customer, p.name AS product, o.quantity, o.total, o.date
      FROM orders o
      JOIN customers c ON c.id = o.customer_id
      JOIN products p ON p.id = o.product_id
      ORDER BY o.id DESC''');

  static Future<Map<String, dynamic>> monthlyReport() async {
    final d = await db;
    final now = DateTime.now();
    final prefix = now.year.toString() + '-' + now.month.toString().padLeft(2, '0');
    final row = await d.rawQuery(
        "SELECT COUNT(*) AS orders, COALESCE(SUM(total),0) AS revenue FROM orders WHERE date LIKE ?",
        [prefix + '%']);
    return row.first;
  }
}
