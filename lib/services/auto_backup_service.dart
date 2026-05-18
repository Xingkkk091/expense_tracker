import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class AutoBackupInfo {
  final String path;
  final DateTime createdAt;
  final int sizeBytes;
  final int? txCount; // 若能解析則塞入

  AutoBackupInfo({
    required this.path,
    required this.createdAt,
    required this.sizeBytes,
    this.txCount,
  });
}

/// 自動備份：每次資料變動時靜默存一份 JSON 到 App 私有目錄的 auto_backups/。
/// 保留最近 5 份，舊的自動輪替。
class AutoBackupService {
  static const _kEnabled = 'auto_backup_enabled';
  static const _kLastTime = 'auto_backup_last_time';
  static const _maxKeep = 5;

  final DatabaseService _db;
  AutoBackupService([DatabaseService? db]) : _db = db ?? DatabaseService();

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? true; // 預設開啟
  }

  Future<void> setEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, v);
  }

  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_kLastTime);
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(docs.path, 'auto_backups'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// 立即執行一次備份（會檢查 isEnabled）
  /// 為了避免每筆交易都寫檔，可選 [minIntervalMinutes] 內若已備份就跳過
  Future<File?> runBackup({int? minIntervalMinutes}) async {
    if (!await isEnabled()) return null;
    if (minIntervalMinutes != null) {
      final last = await getLastBackupTime();
      if (last != null) {
        final diff = DateTime.now().difference(last);
        if (diff.inMinutes < minIntervalMinutes) return null;
      }
    }
    try {
      final snapshot = await _db.exportSnapshot();
      final json = const JsonEncoder.withIndent('  ').convert(snapshot);
      final dir = await _dir();
      final name =
          'auto_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final file = File(p.join(dir.path, name));
      await file.writeAsString(json);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kLastTime, DateTime.now().toIso8601String());

      await _rotate();
      return file;
    } catch (e, st) {
      debugPrint('auto backup failed: $e\n$st');
      return null;
    }
  }

  /// 輪替：保留最近 5 份，刪掉更舊的
  Future<void> _rotate() async {
    try {
      final dir = await _dir();
      final files = (await dir.list().toList())
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      if (files.length > _maxKeep) {
        for (final f in files.skip(_maxKeep)) {
          try {
            await f.delete();
          } catch (_) {/* ignore */}
        }
      }
    } catch (_) {/* ignore */}
  }

  /// 列出現有自動備份檔
  Future<List<AutoBackupInfo>> list() async {
    try {
      final dir = await _dir();
      final files = (await dir.list().toList())
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();
      final out = <AutoBackupInfo>[];
      for (final f in files) {
        final stat = f.statSync();
        int? txCount;
        try {
          // 嘗試讀取以取得交易筆數（如果檔案太大可跳過）
          if (stat.size < 10 * 1024 * 1024) {
            final json = jsonDecode(await f.readAsString())
                as Map<String, dynamic>;
            txCount = (json['transactions'] as List?)?.length;
          }
        } catch (_) {/* ignore */}
        out.add(AutoBackupInfo(
          path: f.path,
          createdAt: stat.modified,
          sizeBytes: stat.size,
          txCount: txCount,
        ));
      }
      out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return out;
    } catch (_) {
      return [];
    }
  }

  /// 從指定備份檔還原（會覆蓋現有資料）
  Future<bool> restoreFromFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      final raw = await file.readAsString();
      final snapshot = json.decode(raw) as Map<String, dynamic>;
      await _db.importSnapshot(snapshot);
      return true;
    } catch (e, st) {
      debugPrint('restore failed: $e\n$st');
      return false;
    }
  }

  Future<void> deleteBackup(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {/* ignore */}
  }

  /// App 啟動時呼叫：若 DB 沒交易但 auto_backups 有檔，回傳最近一份
  Future<AutoBackupInfo?> findRecoverableIfDbEmpty() async {
    try {
      final txs = await _db.getAll();
      if (txs.isNotEmpty) return null; // 有資料就不提議還原
      final backups = await list();
      if (backups.isEmpty) return null;
      return backups.first; // 最新的
    } catch (_) {
      return null;
    }
  }
}
