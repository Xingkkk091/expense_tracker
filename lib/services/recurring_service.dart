import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import 'database_service.dart';

enum RecurFrequency { daily, weekly, monthly }

extension RecurFrequencyLabel on RecurFrequency {
  String get label {
    switch (this) {
      case RecurFrequency.daily:
        return '每天';
      case RecurFrequency.weekly:
        return '每週';
      case RecurFrequency.monthly:
        return '每月';
    }
  }

  String get key => name;

  static RecurFrequency fromKey(String k) {
    return RecurFrequency.values.firstWhere((e) => e.name == k,
        orElse: () => RecurFrequency.monthly);
  }
}

class RecurringRule {
  final String id;
  final String title;
  final double amount;
  final bool isExpense;
  final String category;
  final String note;
  final RecurFrequency frequency;
  final DateTime startDate;
  final DateTime? lastGenerated;
  final bool active;
  final String wallet;

  RecurringRule({
    required this.id,
    required this.title,
    required this.amount,
    required this.isExpense,
    required this.category,
    required this.note,
    required this.frequency,
    required this.startDate,
    this.lastGenerated,
    this.active = true,
    this.wallet = kDefaultWallet,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'isExpense': isExpense ? 1 : 0,
        'category': category,
        'note': note,
        'frequency': frequency.key,
        'startDate': startDate.toIso8601String(),
        'lastGenerated': lastGenerated?.toIso8601String(),
        'active': active ? 1 : 0,
        'wallet': wallet,
      };

  factory RecurringRule.fromMap(Map<String, dynamic> m) => RecurringRule(
        id: m['id'],
        title: m['title'],
        amount: m['amount'],
        isExpense: m['isExpense'] == 1,
        category: m['category'],
        note: m['note'] ?? '',
        frequency: RecurFrequencyLabel.fromKey(m['frequency']),
        startDate: DateTime.parse(m['startDate']),
        lastGenerated: m['lastGenerated'] != null
            ? DateTime.parse(m['lastGenerated'])
            : null,
        active: m['active'] == 1,
        wallet: (m['wallet'] as String?) ?? kDefaultWallet,
      );
}

class RecurringService {
  final DatabaseService _db;
  RecurringService([DatabaseService? db]) : _db = db ?? DatabaseService();

  Future<List<RecurringRule>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('recurring_rules', orderBy: 'startDate DESC');
    return rows.map((r) => RecurringRule.fromMap(r)).toList();
  }

  Future<void> save(RecurringRule rule) async {
    final db = await _db.database;
    await db.insert('recurring_rules', rule.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> remove(String id) async {
    final db = await _db.database;
    await db.delete('recurring_rules', where: 'id = ?', whereArgs: [id]);
  }

  /// 啟動時呼叫：把每條規則「應發生但尚未產生」的交易補進 transactions。
  /// 回傳新產生的筆數。
  Future<int> generateDue() async {
    final db = await _db.database;
    final rules = await getAll();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int created = 0;

    for (final rule in rules) {
      if (!rule.active) continue;
      var cursor = rule.lastGenerated == null
          ? rule.startDate
          : _next(rule.lastGenerated!, rule.frequency);
      cursor = DateTime(cursor.year, cursor.month, cursor.day);

      DateTime? lastMade;
      // 上限保護：一次最多補 365 筆，避免極端情況卡死
      int guard = 0;
      while (!cursor.isAfter(today) && guard < 365) {
        guard++;
        final tx = Transaction(
          id: const Uuid().v4(),
          title: rule.title,
          amount: rule.amount,
          isExpense: rule.isExpense,
          category: rule.category,
          note: rule.note.isEmpty ? '（自動 ${rule.frequency.label}）' : rule.note,
          address: '',
          date: cursor,
          wallet: rule.wallet,
        );
        await db.insert('transactions', tx.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
        created++;
        lastMade = cursor;
        cursor = _next(cursor, rule.frequency);
      }

      if (lastMade != null) {
        await db.update(
          'recurring_rules',
          {'lastGenerated': lastMade.toIso8601String()},
          where: 'id = ?',
          whereArgs: [rule.id],
        );
      }
    }
    if (created > 0) {
      debugPrint('RecurringService: generated $created transactions');
    }
    return created;
  }

  DateTime _next(DateTime d, RecurFrequency f) {
    switch (f) {
      case RecurFrequency.daily:
        return d.add(const Duration(days: 1));
      case RecurFrequency.weekly:
        return d.add(const Duration(days: 7));
      case RecurFrequency.monthly:
        var y = d.year;
        var m = d.month + 1;
        if (m > 12) {
          m = 1;
          y++;
        }
        final lastDay = DateTime(y, m + 1, 0).day;
        final day = d.day > lastDay ? lastDay : d.day;
        return DateTime(y, m, day, d.hour, d.minute);
    }
  }
}
