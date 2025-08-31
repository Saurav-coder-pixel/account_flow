import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/person.dart';
import '../models/transaction.dart' as app_transaction;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'account_flow.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDb,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN split_id TEXT');
    }
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE persons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        split_id TEXT,
        FOREIGN KEY (person_id) REFERENCES persons (id) ON DELETE CASCADE
      )
    ''');
  }

  // Person operations
  Future<int> insertPerson(Person person) async {
    final db = await database;
    return await db.insert('persons', person.toMap());
  }

  Future<List<Person>> getAllPersons() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('persons', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Person.fromMap(maps[i]));
  }

  Future<Person?> getPersonById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'persons',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Person.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updatePerson(Person person) async {
    final db = await database;
    return await db.update(
      'persons',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<int> deletePerson(int id) async {
    final db = await database;
    // First delete all transactions for this person
    await db.delete('transactions', where: 'person_id = ?', whereArgs: [id]);
    // Then delete the person
    return await db.delete('persons', where: 'id = ?', whereArgs: [id]);
  }

  // Transaction operations
  Future<int> insertTransaction(app_transaction.Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<app_transaction.Transaction>> getTransactionsByPersonId(int personId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'person_id = ?',
      whereArgs: [personId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => app_transaction.Transaction.fromMap(maps[i]));
  }

  Future<List<app_transaction.Transaction>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => app_transaction.Transaction.fromMap(maps[i]));
  }

  Future<int> updateTransaction(app_transaction.Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getPersonBalance(int personId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 'credit' THEN amount ELSE -amount END) as balance
      FROM transactions 
      WHERE person_id = ?
    ''', [personId]);

    if (result.isNotEmpty && result.first['balance'] != null) {
      return (result.first['balance'] as num).toDouble();
    }
    return 0.0;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('persons');
  }
}
