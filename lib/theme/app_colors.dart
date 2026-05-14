import 'package:flutter/material.dart';

/// 全 App 共用的語意色（日系低彩度）。
/// 取代散落各處的 magic color literal。
class AppColors {
  AppColors._();

  /// 支出 — 弁柄っぽい赤
  static const expense = Color(0xFFB57C70);

  /// 收入 — 苔色っぽい緑
  static const income = Color(0xFF7C9070);

  /// 結餘正 / 中性藍鼠
  static const neutral = Color(0xFF5C6B7A);

  /// 預算 70% 警示 — 山吹っぽい黃
  static const warning = Color(0xFFC9A86A);

  /// 依「是否支出」回傳語意色
  static Color amount(bool isExpense) => isExpense ? expense : income;
}
