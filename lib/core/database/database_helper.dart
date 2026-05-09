import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'budgeto.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        currency TEXT NOT NULL DEFAULT 'EUR',
        created_at TEXT NOT NULL
      )
    ''');

    // Categories
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    // Transactions
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // Budgets
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // Goals
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0,
        deadline TEXT,
        image_key TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Recurring Transactions
    await db.execute('''
      CREATE TABLE recurring_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        description TEXT,
        period TEXT NOT NULL,
        start_date TEXT NOT NULL,
        next_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // Monthly Plans
    await db.execute('''
      CREATE TABLE monthly_plans (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        needs REAL NOT NULL DEFAULT 0,
        expectations REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await _seedCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE recurring_transactions (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          category_id TEXT NOT NULL,
          description TEXT,
          period TEXT NOT NULL,
          start_date TEXT NOT NULL,
          next_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id),
          FOREIGN KEY (category_id) REFERENCES categories(id)
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE monthly_plans (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          month INTEGER NOT NULL,
          year INTEGER NOT NULL,
          needs REAL NOT NULL DEFAULT 0,
          expectations REAL NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id)
        )
      ''');
    }
  }

  Future<void> _seedCategories(Database db) async {
    final categories = [
      {'id': 'cat_food', 'name': 'Alimentation', 'icon': 'food', 'color': '0xFFFF6B35', 'type': 'expense'},
      {'id': 'cat_transport', 'name': 'Transport', 'icon': 'transport', 'color': '0xFF4ECDC4', 'type': 'expense'},
      {'id': 'cat_home', 'name': 'Logement', 'icon': 'home', 'color': '0xFF45B7D1', 'type': 'expense'},
      {'id': 'cat_leisure', 'name': 'Loisirs', 'icon': 'leisure', 'color': '0xFF96CEB4', 'type': 'expense'},
      {'id': 'cat_health', 'name': 'Santé', 'icon': 'health', 'color': '0xFFFF6584', 'type': 'expense'},
      {'id': 'cat_other_exp', 'name': 'Autres', 'icon': 'other', 'color': '0xFFB8B8B8', 'type': 'expense'},
      {'id': 'cat_salary', 'name': 'Salaire', 'icon': 'salary', 'color': '0xFF2E7D32', 'type': 'income'},
      {'id': 'cat_freelance', 'name': 'Freelance', 'icon': 'freelance', 'color': '0xFF66BB6A', 'type': 'income'},
      {'id': 'cat_invest', 'name': 'Investissement', 'icon': 'invest', 'color': '0xFF81C784', 'type': 'income'},
      {'id': 'cat_other_inc', 'name': 'Autres', 'icon': 'other', 'color': '0xFFA5D6A7', 'type': 'income'},
    ];
    for (final cat in categories) {
      await db.insert('categories', cat);
    }
  }

  // --- Generic CRUD ---
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy, limit: limit);
  }

  Future<int> update(String table, Map<String, dynamic> data, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? args]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }
}
