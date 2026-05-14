import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart' as model;
import 'database_service.dart';

class BackupService {
  final DatabaseService _db;
  BackupService([DatabaseService? db]) : _db = db ?? DatabaseService();

  /// 匯出 JSON 完整備份並分享
  Future<File> exportJson() async {
    final snapshot = await _db.exportSnapshot();
    final json = const JsonEncoder.withIndent('  ').convert(snapshot);
    final dir = await getTemporaryDirectory();
    final name =
        'expense_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
    final file = File('${dir.path}/$name');
    await file.writeAsString(json);
    return file;
  }

  Future<void> shareJsonBackup() async {
    final file = await exportJson();
    await Share.shareXFiles([XFile(file.path)],
        text: '記帳本備份 ${DateTime.now().toIso8601String()}');
  }

  /// 從檔案匯入 JSON 備份
  /// 回傳 true 表示成功（會覆蓋既有資料）
  Future<bool> importFromPickedFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return false;
    final path = result.files.single.path;
    if (path == null) return false;
    final raw = await File(path).readAsString();
    final snapshot = json.decode(raw) as Map<String, dynamic>;
    if (snapshot['version'] == null || snapshot['transactions'] == null) {
      throw const FormatException('檔案格式不正確');
    }
    await _db.importSnapshot(snapshot);
    return true;
  }

  /// 匯出 CSV 並分享
  Future<File> exportCsv(List<model.Transaction> all) async {
    final rows = <List<dynamic>>[
      ['ID', '日期', '時間', '類型', '分類', '標題', '金額', '地址', '緯度', '經度', '備註'],
    ];
    final df = DateFormat('yyyy-MM-dd');
    final tf = DateFormat('HH:mm');
    for (final t in all) {
      rows.add([
        t.id,
        df.format(t.date),
        tf.format(t.date),
        t.isExpense ? '支出' : '收入',
        t.category,
        t.title,
        t.amount,
        t.address,
        t.latitude ?? '',
        t.longitude ?? '',
        t.note.replaceAll('\n', ' '),
      ]);
    }
    // 加上 BOM 讓 Excel 不會亂碼
    final csvBody = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final name =
        'expense_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${dir.path}/$name');
    await file.writeAsString('﻿$csvBody');
    return file;
  }

  Future<void> shareCsv(List<model.Transaction> all) async {
    final file = await exportCsv(all);
    await Share.shareXFiles([XFile(file.path)],
        text: '記帳本 CSV 匯出 ${DateTime.now().toIso8601String()}');
  }

  Future<void> clearAll() async {
    try {
      await _db.clearAll();
    } catch (e, st) {
      debugPrint('clearAll failed: $e\n$st');
      rethrow;
    }
  }
}
