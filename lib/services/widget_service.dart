import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

/// 推資料給 Android 桌面 Widget。
/// 全部操作都靜默失敗——widget 不該影響 App 本體運作。
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

  Future<Uri?> initialUri() async {
    try {
      return await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (_) {
      return null;
    }
  }

  /// 監聽 widget 點擊。若 plugin 未註冊就回傳空 Stream。
  Stream<Uri?> get clicks {
    try {
      return HomeWidget.widgetClicked;
    } catch (e) {
      debugPrint('widgetClicked stream unavailable: $e');
      return const Stream<Uri?>.empty();
    }
  }
}
