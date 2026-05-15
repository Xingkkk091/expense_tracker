import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 「今晚吃什麼」主題
enum FoodTheme {
  any,
  gentle, // 腸胃不適 / 清淡
  meaty,
  budget,
  lateNight,
  soup,
}

extension FoodThemeInfo on FoodTheme {
  String get label {
    switch (this) {
      case FoodTheme.any:
        return '隨便都好';
      case FoodTheme.gentle:
        return '腸胃不適';
      case FoodTheme.meaty:
        return '想吃肉';
      case FoodTheme.budget:
        return '想省錢';
      case FoodTheme.lateNight:
        return '宵夜';
      case FoodTheme.soup:
        return '想喝湯';
    }
  }

  IconData get icon {
    switch (this) {
      case FoodTheme.any:
        return Icons.casino;
      case FoodTheme.gentle:
        return Icons.spa;
      case FoodTheme.meaty:
        return Icons.kebab_dining;
      case FoodTheme.budget:
        return Icons.savings;
      case FoodTheme.lateNight:
        return Icons.nightlife;
      case FoodTheme.soup:
        return Icons.ramen_dining;
    }
  }

  String get key => name;
}

/// 預設食物清單（依主題）
const Map<FoodTheme, List<String>> _defaultFoods = {
  FoodTheme.any: [
    '便當', '牛肉麵', '滷肉飯', '火鍋', '日式定食', '義大利麵',
    '壽司', '咖哩飯', '炒飯', '水餃', '鍋燒意麵', '麥當勞',
    '鹹酥雞', '披薩', '韓式料理', '泰式料理', '早午餐', '自助餐',
  ],
  FoodTheme.gentle: [
    '白粥', '清湯麵', '蒸蛋', '雞肉飯', '味噌湯', '烏龍麵',
    '茶碗蒸', '地瓜粥', '蔬菜湯', '魚湯', '豆腐料理', '蘿蔔糕',
    '雞湯', '燕麥粥', '蒸魚便當',
  ],
  FoodTheme.meaty: [
    '燒肉', '牛排', '炸雞', '漢堡', '烤肉', '鹽酥雞',
    '排骨飯', '羊肉爐', '薑母鴨', '香腸', '豬腳飯', '雞排',
    '韓式烤肉', '德國豬腳',
  ],
  FoodTheme.budget: [
    '銅板便當', '陽春麵', '滷味', '自助餐', '滷肉飯', '蛋餅',
    '飯糰', '關東煮', '大腸麵線', '車輪餅', '地瓜球', '鹹粥',
  ],
  FoodTheme.lateNight: [
    '鹹酥雞', '滷味', '泡麵', '宵夜場熱炒', '燒烤', '麥當勞',
    '便利商店', '鍋貼', '炸物', '雞排', '深夜食堂',
  ],
  FoodTheme.soup: [
    '牛肉麵', '拉麵', '味噌湯', '羊肉爐', '薑母鴨', '麻辣鍋',
    '酸辣湯', '雞湯', '魚湯', '海帶湯', '貢丸湯', '關東煮',
  ],
};

class FoodPickerService {
  static String _prefKey(FoodTheme t) => 'food_custom_${t.key}';

  /// 取得某主題的完整清單（預設 + 使用者自訂）
  Future<List<String>> getFoods(FoodTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList(_prefKey(theme)) ?? [];
    final defaults = _defaultFoods[theme] ?? const [];
    // 去重，自訂的排前面
    final seen = <String>{};
    final out = <String>[];
    for (final f in [...custom, ...defaults]) {
      if (seen.add(f)) out.add(f);
    }
    return out;
  }

  Future<List<String>> getCustom(FoodTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefKey(theme)) ?? [];
  }

  Future<void> addCustom(FoodTheme theme, String food) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefKey(theme)) ?? [];
    if (!list.contains(food)) {
      list.insert(0, food);
      await prefs.setStringList(_prefKey(theme), list);
    }
  }

  Future<void> removeCustom(FoodTheme theme, String food) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefKey(theme)) ?? [];
    list.remove(food);
    await prefs.setStringList(_prefKey(theme), list);
  }

  bool isDefault(FoodTheme theme, String food) =>
      (_defaultFoods[theme] ?? const []).contains(food);
}
