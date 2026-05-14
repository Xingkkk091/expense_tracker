import 'package:flutter/material.dart';
import 'database_service.dart';
import '../models/transaction.dart';

class CategoryService {
  final DatabaseService _db;
  CategoryService([DatabaseService? db]) : _db = db ?? DatabaseService();

  /// 讀取所有分類：內建 + 使用者自訂
  Future<List<CategoryInfo>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('custom_categories', orderBy: 'sortOrder');
    final custom = rows.map((r) {
      return CategoryInfo(
        r['label'] as String,
        IconData(r['icon'] as int, fontFamily: 'MaterialIcons'),
        Color(r['color'] as int),
      );
    }).toList();
    return [...kCategories, ...custom];
  }

  Future<void> add(CategoryInfo cat) async {
    final db = await _db.database;
    final maxOrder = await db.rawQuery(
        'SELECT IFNULL(MAX(sortOrder), 0) AS m FROM custom_categories');
    final next = (maxOrder.first['m'] as int) + 1;
    await db.insert('custom_categories', {
      'label': cat.label,
      'icon': cat.icon.codePoint,
      'color': cat.color.toARGB32(),
      'sortOrder': next,
    });
  }

  Future<void> remove(String label) async {
    final db = await _db.database;
    await db.delete('custom_categories',
        where: 'label = ?', whereArgs: [label]);
  }

  bool isBuiltIn(String label) =>
      kCategories.any((c) => c.label == label);
}
