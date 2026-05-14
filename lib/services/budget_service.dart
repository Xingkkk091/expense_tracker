import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'database_service.dart';

class BudgetService {
  static const _key = 'monthly_budget';
  final DatabaseService _db;
  BudgetService([DatabaseService? db]) : _db = db ?? DatabaseService();

  /// 目前月份的「主預算」(SharedPreferences)
  Future<double> getMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key) ?? 0;
  }

  Future<void> setMonthlyBudget(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, value);
    // 同時寫一筆到歷史
    await setBudgetForMonth(DateTime.now(), value);
  }

  Future<void> setBudgetForMonth(DateTime month, double value) async {
    final key = DateFormat('yyyy-MM').format(month);
    final db = await _db.database;
    await db.insert(
      'budget_history',
      {'yearMonth': key, 'amount': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double?> getBudgetForMonth(DateTime month) async {
    final key = DateFormat('yyyy-MM').format(month);
    final db = await _db.database;
    final rows = await db.query('budget_history',
        where: 'yearMonth = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['amount'] as double;
  }

  Future<Map<String, double>> getAllHistory() async {
    final db = await _db.database;
    final rows = await db.query('budget_history', orderBy: 'yearMonth DESC');
    return {
      for (final r in rows)
        r['yearMonth'] as String: r['amount'] as double,
    };
  }
}
