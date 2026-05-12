import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Transaction> _transactions = [];

  List<Transaction> get transactions => _transactions;

  double get totalIncome => _transactions
      .where((t) => !t.isExpense)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.isExpense)
      .fold(0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  Map<String, double> get expenseByCategory {
    final Map<String, double> map = {};
    for (final t in _transactions.where((t) => t.isExpense)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  Future<void> load() async {
    _transactions = await _db.getAll();
    notifyListeners();
  }

  Future<void> add(Transaction t) async {
    await _db.insert(t);
    await load();
  }

  Future<void> remove(String id) async {
    await _db.delete(id);
    await load();
  }

  Future<void> edit(Transaction t) async {
    await _db.update(t);
    await load();
  }
}
