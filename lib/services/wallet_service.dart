import 'package:flutter/material.dart';
import '../models/app_icons.dart';
import '../models/transaction.dart';
import 'database_service.dart';

class WalletInfo {
  final String name;
  final int iconIndex;
  final int sortOrder;

  WalletInfo({required this.name, required this.iconIndex, this.sortOrder = 0});

  IconData get icon => walletIconByIndex(iconIndex);
}

class WalletService {
  final DatabaseService _db;
  WalletService([DatabaseService? db]) : _db = db ?? DatabaseService();

  /// 取得所有錢包；若空則回傳預設「現金」
  Future<List<WalletInfo>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('wallets', orderBy: 'sortOrder');
    if (rows.isEmpty) {
      return [WalletInfo(name: kDefaultWallet, iconIndex: 0)];
    }
    return rows
        .map((r) => WalletInfo(
              name: r['name'] as String,
              iconIndex: r['icon'] as int,
              sortOrder: r['sortOrder'] as int,
            ))
        .toList();
  }

  Future<void> add(String name, int iconIndex) async {
    final db = await _db.database;
    final maxOrder = await db.rawQuery(
        'SELECT IFNULL(MAX(sortOrder), 0) AS m FROM wallets');
    final next = (maxOrder.first['m'] as int) + 1;
    await db.insert('wallets', {
      'name': name,
      'icon': iconIndex,
      'sortOrder': next,
    });
  }

  Future<void> update(String name, int iconIndex) async {
    final db = await _db.database;
    await db.update('wallets', {'icon': iconIndex},
        where: 'name = ?', whereArgs: [name]);
  }

  Future<void> remove(String name) async {
    final db = await _db.database;
    await db.delete('wallets', where: 'name = ?', whereArgs: [name]);
  }

  /// 確保至少有預設錢包存在
  Future<void> ensureDefault() async {
    final db = await _db.database;
    final rows = await db.query('wallets', limit: 1);
    if (rows.isEmpty) {
      await db.insert('wallets', {
        'name': kDefaultWallet,
        'icon': 0,
        'sortOrder': 0,
      });
    }
  }
}
