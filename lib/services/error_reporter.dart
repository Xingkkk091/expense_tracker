import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 統一錯誤蒐集器，把 Flutter 與 platform 錯誤寫到本地 log
/// 目前單純寫檔，未來可換成 Sentry/Crashlytics
class ErrorReporter {
  static final ErrorReporter _instance = ErrorReporter._();
  factory ErrorReporter() => _instance;
  ErrorReporter._();

  File? _logFile;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _logFile = File('${dir.path}/error.log');
    } catch (_) {/* ignore */}

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _write('FlutterError', details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _write('PlatformError', error, stack);
      return true;
    };
  }

  Future<File?> get logFile async => _logFile;

  Future<String?> readLog() async {
    try {
      if (_logFile == null || !await _logFile!.exists()) return null;
      return await _logFile!.readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<void> clearLog() async {
    try {
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.delete();
      }
    } catch (_) {/* ignore */}
  }

  void log(String tag, Object error, [StackTrace? stack]) {
    _write(tag, error, stack);
  }

  Future<void> _write(String tag, Object error, StackTrace? stack) async {
    final entry =
        '[${DateTime.now().toIso8601String()}][$tag] $error\n${stack ?? ''}\n\n';
    debugPrint(entry);
    try {
      if (_logFile == null) return;
      await _logFile!.writeAsString(entry,
          mode: FileMode.append, flush: true);
    } catch (_) {/* ignore */}
  }
}
