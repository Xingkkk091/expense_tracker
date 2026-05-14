import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as model;

/// Database errors are wrapped so callers can show user-friendly messages
class DatabaseException implements Exception {
  final String message;
  final Object? cause;
  DatabaseException(this.message, [this.cause]);
  @override
  String toString() => 'DatabaseException: $message${cause != null ? ' ($cause)' : ''}';
}

class DatabaseService {
  static const int _dbVersion = 3;
  static const String _dbName = 'expense_tracker.db';
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<String> get databasePath async {
    return join(await getDatabasesPath(), _dbName);
  }

  Future<Database> _initDb() async {
    try {
      final path = await databasePath;
      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e, st) {
      debugPrint('DB init failed: $e\n$st');
      throw DatabaseException('資料庫開啟失敗', e);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
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
        date TEXT NOT NULL,
        modifiedAt TEXT,
        wallet TEXT NOT NULL DEFAULT '現金'
      )
    ''');
    await db.execute('''
      CREATE TABLE custom_categories(
        label TEXT PRIMARY KEY,
        icon INTEGER NOT NULL,
        color INTEGER NOT NULL,
        sortOrder INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE recurring_rules(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        isExpense INTEGER NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        frequency TEXT NOT NULL,
        startDate TEXT NOT NULL,
        lastGenerated TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        wallet TEXT NOT NULL DEFAULT '現金'
      )
    ''');
    await db.execute('''
      CREATE TABLE budget_history(
        yearMonth TEXT PRIMARY KEY,
        amount REAL NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE wallets(
        name TEXT PRIMARY KEY,
        icon INTEGER NOT NULL,
        sortOrder INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_tx_date ON transactions(date)');
    await db.execute(
        'CREATE INDEX idx_tx_category ON transactions(category)');
    await db.execute(
        'CREATE INDEX idx_tx_wallet ON transactions(wallet)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
            "ALTER TABLE transactions ADD COLUMN modifiedAt TEXT");
      } catch (_) {/* column may already exist */}
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_categories(
          label TEXT PRIMARY KEY,
          icon INTEGER NOT NULL,
          color INTEGER NOT NULL,
          sortOrder INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recurring_rules(
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          isExpense INTEGER NOT NULL,
          category TEXT NOT NULL,
          note TEXT,
          frequency TEXT NOT NULL,
          startDate TEXT NOT NULL,
          lastGenerated TEXT,
          active INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budget_history(
          yearMonth TEXT PRIMARY KEY,
          amount REAL NOT NULL
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_tx_date ON transactions(date)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_tx_category ON transactions(category)');
    }
    if (oldVersion < 3) {
      // v2 -> v3: multi-wallet
      try {
        await db.execute(
            "ALTER TABLE transactions ADD COLUMN wallet TEXT NOT NULL DEFAULT '現金'");
      } catch (_) {/* may exist */}
      try {
        await db.execute(
            "ALTER TABLE recurring_rules ADD COLUMN wallet TEXT NOT NULL DEFAULT '現金'");
      } catch (_) {/* may exist */}
      await db.execute('''
        CREATE TABLE IF NOT EXISTS wallets(
          name TEXT PRIMARY KEY,
          icon INTEGER NOT NULL,
          sortOrder INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_tx_wallet ON transactions(wallet)');
    }
  }

  // ============== transactions ==============

  Future<List<model.Transaction>> getAll() async {
    try {
      final db = await database;
      final rows = await db.query('transactions', orderBy: 'date DESC');
      return rows.map((r) => model.Transaction.fromMap(r)).toList();
    } catch (e) {
      throw DatabaseException('讀取交易失敗', e);
    }
  }

  Future<void> insert(model.Transaction t) async {
    try {
      final db = await database;
      final map = t.toMap();
      map['modifiedAt'] = DateTime.now().toIso8601String();
      await db.insert('transactions', map,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw DatabaseException('新增交易失敗', e);
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = await database;
      await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('刪除交易失敗', e);
    }
  }

  Future<void> update(model.Transaction t) async {
    try {
      final db = await database;
      final map = t.toMap();
      map['modifiedAt'] = DateTime.now().toIso8601String();
      await db.update('transactions', map,
          where: 'id = ?', whereArgs: [t.id]);
    } catch (e) {
      throw DatabaseException('更新交易失敗', e);
    }
  }

  // ============== bulk ops ==============

  Future<void> insertAll(List<model.Transaction> list) async {
    try {
      final db = await database;
      final batch = db.batch();
      for (final t in list) {
        batch.insert('transactions', t.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      throw DatabaseException('批次寫入失敗', e);
    }
  }

  Future<void> clearAll() async {
    try {
      final db = await database;
      await db.delete('transactions');
      await db.delete('custom_categories');
      await db.delete('recurring_rules');
      await db.delete('budget_history');
      await db.delete('wallets');
    } catch (e) {
      throw DatabaseException('清除資料失敗', e);
    }
  }

  /// 整個資料庫匯出成 Map（給 JSON 備份用）
  Future<Map<String, dynamic>> exportSnapshot() async {
    try {
      final db = await database;
      return {
        'version': _dbVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'transactions': await db.query('transactions'),
        'custom_categories': await db.query('custom_categories'),
        'recurring_rules': await db.query('recurring_rules'),
        'budget_history': await db.query('budget_history'),
        'wallets': await db.query('wallets'),
      };
    } catch (e) {
      throw DatabaseException('匯出失敗', e);
    }
  }

  /// 從 JSON snapshot 匯入（會先清空既有資料）
  Future<void> importSnapshot(Map<String, dynamic> snapshot) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        for (final table in const [
          'transactions',
          'custom_categories',
          'recurring_rules',
          'budget_history',
          'wallets',
        ]) {
          await txn.delete(table);
          for (final r in (snapshot[table] as List? ?? [])) {
            await txn.insert(table, Map<String, dynamic>.from(r as Map),
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      });
    } catch (e) {
      throw DatabaseException('匯入失敗', e);
    }
  }
}
