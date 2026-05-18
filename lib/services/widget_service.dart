import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

/// 推資料給 Android 桌面 Widget
class WidgetService {
  static const _kAndroidName = 'ExpenseWidgetProvider';

  Future<void> push({
    required double monthBalance,
    required double monthIncome,
    required double monthExpense,
    String label = '本月結餘',
  }) async {
    final fmt = NumberFormat('#,##0');
    try {
      await HomeWidget.saveWidgetData<String>(
          'balance', 'NT\$ ${fmt.format(monthBalance)}');
      await HomeWidget.saveWidgetData<String>(
          'income', fmt.format(monthIncome));
      await HomeWidget.saveWidgetData<String>(
          'expense', fmt.format(monthExpense));
      await HomeWidget.saveWidgetData<String>('label', label);
      await HomeWidget.updateWidget(
        name: _kAndroidName,
        androidName: _kAndroidName,
      );
    } catch (e) {
      debugPrint('widget push failed: $e');
    }
  }

  /// 取得啟動時的 URI（widget 點擊冷啟動）
  Future<Uri?> initialUri() async {
    try {
      return await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (_) {
      return null;
    }
  }

  /// 監聽 widget 點擊（app 在背景時點 widget）
  Stream<Uri?> get clicks => HomeWidget.widgetClicked;
}
