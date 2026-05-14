import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'error_reporter.dart';

class UpdateInfo {
  final String version;
  final String notes;
  final String apkUrl;

  UpdateInfo({required this.version, required this.notes, required this.apkUrl});
}

class UpdateService {
  static const String _owner = 'Xingkkk091';
  static const String _repo = 'expense_tracker';
  static const String _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final response = await http.get(Uri.parse(_apiUrl)).timeout(
            const Duration(seconds: 8),
          );
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final tag = (data['tag_name'] as String?) ?? '';
      final latestVersion = tag.startsWith('v') ? tag.substring(1) : tag;
      final notes = (data['body'] as String?) ?? '';
      final assets = (data['assets'] as List?) ?? [];

      String? apkUrl;
      for (final a in assets) {
        final name = (a['name'] as String?) ?? '';
        if (name.toLowerCase().endsWith('.apk')) {
          apkUrl = a['browser_download_url'] as String?;
          break;
        }
      }
      if (apkUrl == null || latestVersion.isEmpty) return null;

      if (_isNewer(latestVersion, currentVersion)) {
        return UpdateInfo(
          version: latestVersion,
          notes: notes,
          apkUrl: apkUrl,
        );
      }
      return null;
    } catch (e, st) {
      ErrorReporter().log('UpdateService.check', e, st);
      return null;
    }
  }

  bool _isNewer(String latest, String current) {
    final l = latest.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final c = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final len = l.length > c.length ? l.length : c.length;
    while (l.length < len) {
      l.add(0);
    }
    while (c.length < len) {
      c.add(0);
    }
    for (int i = 0; i < len; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  Future<File?> downloadApk(
    String url, {
    required void Function(double progress) onProgress,
  }) async {
    try {
      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/update.apk';
      final file = File(filePath);
      if (await file.exists()) await file.delete();

      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress(received / total);
        },
      );
      return file;
    } catch (e, st) {
      ErrorReporter().log('UpdateService.download', e, st);
      return null;
    }
  }

  Future<void> installApk(File apk) async {
    await OpenFilex.open(apk.path, type: 'application/vnd.android.package-archive');
  }
}
