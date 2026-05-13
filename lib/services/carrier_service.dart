import 'package:shared_preferences/shared_preferences.dart';

/// 儲存使用者的「手機條碼載具」
/// 格式：開頭 / + 7 個字元（0-9 A-Z + - . 空白）
/// 例：/AB12+34
class CarrierService {
  static const _key = 'mobile_carrier_code';

  Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    if (v == null || v.isEmpty) return null;
    return v;
  }

  Future<void> set(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// 驗證手機條碼格式
  static bool isValid(String code) {
    return RegExp(r'^/[0-9A-Z+\-\. ]{7}$').hasMatch(code);
  }
}
