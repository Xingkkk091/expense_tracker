import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as model;

class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'expense_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE transactions(
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          isExpense INTEGER NOT NULL,
          category TEXT NOT NULL,
          note TEXT,
          address TEXT,
          latitude REAL,
          longitude REAL,
          date TEXT NOT NULL
        )
      '''),
    );
  }

  Future<List<model.Transaction>> getAll() async {
    final db = await database;
    final rows = await db.query('transactions', orderBy: 'date DESC');
    return rows.map((r) => model.Transaction.fromMap(r)).toList();
  }

  Future<void> insert(model.Transaction t) async {
    final db = await database;
    await db.insert('transactions', t.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> update(model.Transaction t) async {
    final db = await database;
    await db.update('transactions', t.toMap(),
        where: 'id = ?', whereArgs: [t.id]);
  }
}
