import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'inventory.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        priceInDollars REAL,
        quantity INTEGER,
        imagePath TEXT,
        category TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER,
        quantitySold INTEGER,
        totalDollars REAL,
        exchangeRate REAL,
        date TEXT,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE exchange_rates(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rate REAL,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE offers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        priceInLira REAL,
        imagePath TEXT,
        dateAdded TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE offer_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        offerId INTEGER,
        productId INTEGER,
        quantityPerOffer INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // إضافة عمود الملاحظة لجدول المبيعات
      await db.execute('ALTER TABLE sales ADD COLUMN note TEXT');
      // إنشاء جدول ربط المنتجات بالعروض
      await db.execute('''
        CREATE TABLE IF NOT EXISTS offer_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          offerId INTEGER,
          productId INTEGER,
          quantityPerOffer INTEGER
        )
      ''');
    }
  }

  // --- دالة جديدة لإغلاق قاعدة البيانات ---
  Future<void> closeDb() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null; // إعادة تعيين لفرض إعادة الفتح في المرة القادمة
    }
  }
}