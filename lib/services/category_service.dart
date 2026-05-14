import 'package:flutter/material.dart';
import '../models/app_icons.dart';
import '../models/transaction.dart';
import 'database_service.dart';

/// 使用者自訂分類資料
class CustomCategory {
  final String label;
  final int iconIndex;
  final int colorValue;
  final int sortOrder;

  CustomCategory({
    required this.label,
    required this.iconIndex,
    required this.colorValue,
    this.sortOrder = 0,
  });

  CategoryInfo toInfo() =>
      CategoryInfo(label, iconByIndex(iconIndex), Color(colorValue));
}

class CategoryService {
  final DatabaseService _db;
  CategoryService([DatabaseService? db]) : _db = db ?? DatabaseService();

  /// 讀取自訂分類並同步進 CategoryRegistry
  Future<void> loadIntoRegistry() async {
    final list = await getCustom();
    CategoryRegistry.instance
        .setCustom(list.map((c) => c.toInfo()).toList());
  }

  Future<List<CustomCategory>> getCustom() async {
    final db = await _db.database;
    final rows = await db.query('custom_categories', orderBy: 'sortOrder');
    return rows
        .map((r) => CustomCategory(
              label: r['label'] as String,
              iconIndex: r['icon'] as int,
              colorValue: r['color'] as int,
              sortOrder: r['sortOrder'] as int,
            ))
        .toList();
  }

  Future<void> add(CustomCategory cat) async {
    final db = await _db.database;
    final maxOrder = await db.rawQuery(
        'SELECT IFNULL(MAX(sortOrder), 0) AS m FROM custom_categories');
    final next = (maxOrder.first['m'] as int) + 1;
    await db.insert('custom_categories', {
      'label': cat.label,
      'icon': cat.iconIndex,
      'color': cat.colorValue,
      'sortOrder': next,
    });
    await loadIntoRegistry();
  }

  Future<void> update(CustomCategory cat) async {
    final db = await _db.database;
    await db.update(
      'custom_categories',
      {'icon': cat.iconIndex, 'color': cat.colorValue},
      where: 'label = ?',
      whereArgs: [cat.label],
    );
    await loadIntoRegistry();
  }

  Future<void> remove(String label) async {
    final db = await _db.database;
    await db.delete('custom_categories',
        where: 'label = ?', whereArgs: [label]);
    await loadIntoRegistry();
  }

  bool isBuiltIn(String label) =>
      CategoryRegistry.instance.isBuiltIn(label);
}
