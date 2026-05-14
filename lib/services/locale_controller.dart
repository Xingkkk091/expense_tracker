import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 管理 App 語言。null = 跟隨系統。
class LocaleController extends ChangeNotifier {
  static const _key = 'app_locale';
  Locale? _locale;
  Locale? get locale => _locale;

  static const supported = [
    Locale('zh'),
    Locale('en'),
    Locale('ja'),
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
    notifyListeners();
  }
}
