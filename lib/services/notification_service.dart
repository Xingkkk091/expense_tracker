import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _kDailyEnabled = 'notif_daily_enabled';
  static const _kDailyHour = 'notif_daily_hour';
  static const _kDailyMinute = 'notif_daily_minute';
  static const _kBudgetEnabled = 'notif_budget_enabled';

  static const _dailyChannelId = 'daily_reminder';
  static const _budgetChannelId = 'budget_alert';
  static const _dailyId = 1001;
  static const _budgetId = 1002;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    tzdata.initializeTimeZones();
    // 預設 Asia/Taipei；若取得失敗就用 UTC
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Taipei'));
    } catch (_) {/* fallback to UTC */}

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));

    // 建立 channel
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _dailyChannelId,
        '每日記帳提醒',
        description: '提醒記錄今天的花費',
        importance: Importance.defaultImportance,
      ),
    );
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _budgetChannelId,
        '預算警示',
        description: '預算接近或超支時通知',
        importance: Importance.high,
      ),
    );

    // 重新依設定排程（App 重啟時調用）
    await applyDailyReminderFromPrefs();
  }

  Future<bool> requestPermissions() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted =
        await androidImpl?.requestNotificationsPermission() ?? false;
    await androidImpl?.requestExactAlarmsPermission();
    return granted;
  }

  Future<bool> isDailyEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDailyEnabled) ?? false;
  }

  Future<TimeOfDayPref> getDailyTime() async {
    final prefs = await SharedPreferences.getInstance();
    return TimeOfDayPref(
      prefs.getInt(_kDailyHour) ?? 21,
      prefs.getInt(_kDailyMinute) ?? 0,
    );
  }

  Future<void> setDailyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDailyEnabled, enabled);
    await prefs.setInt(_kDailyHour, hour);
    await prefs.setInt(_kDailyMinute, minute);
    if (enabled) {
      await requestPermissions();
      await _scheduleDaily(hour, minute);
    } else {
      await _plugin.cancel(_dailyId);
    }
  }

  Future<void> applyDailyReminderFromPrefs() async {
    final enabled = await isDailyEnabled();
    if (!enabled) {
      await _plugin.cancel(_dailyId);
      return;
    }
    final time = await getDailyTime();
    await _scheduleDaily(time.hour, time.minute);
  }

  Future<void> _scheduleDaily(int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    try {
      await _plugin.zonedSchedule(
        _dailyId,
        '記帳本',
        '今天有什麼花費要記嗎？',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _dailyChannelId,
            '每日記帳提醒',
            channelDescription: '提醒記錄今天的花費',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('schedule daily failed: $e');
    }
  }

  Future<bool> isBudgetAlertEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBudgetEnabled) ?? true;
  }

  Future<void> setBudgetAlertEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBudgetEnabled, enabled);
    if (!enabled) await _plugin.cancel(_budgetId);
  }

  /// 依目前預算用量觸發即時提醒（不重複發太多次）
  Future<void> notifyBudgetIfNeeded(double progress, double monthExpense,
      double monthlyBudget) async {
    if (!await isBudgetAlertEnabled()) return;
    if (monthlyBudget <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    // 每月每門檻只通知一次
    final monthKey =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    String? body;
    String thresholdKey = '';
    if (progress >= 1.0) {
      thresholdKey = 'budget_alert_${monthKey}_100';
      body = '本月預算已用完！已支出 \$${monthExpense.toStringAsFixed(0)}';
    } else if (progress >= 0.9) {
      thresholdKey = 'budget_alert_${monthKey}_90';
      body = '本月預算已用 90%（剩 \$${(monthlyBudget - monthExpense).toStringAsFixed(0)}）';
    } else if (progress >= 0.7) {
      thresholdKey = 'budget_alert_${monthKey}_70';
      body = '本月預算已用 70%';
    }
    if (body == null) return;
    if (prefs.getBool(thresholdKey) == true) return;
    await prefs.setBool(thresholdKey, true);
    try {
      await _plugin.show(
        _budgetId,
        '預算警示',
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _budgetChannelId,
            '預算警示',
            channelDescription: '預算接近或超支時通知',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      debugPrint('budget notify failed: $e');
    }
  }
}

class TimeOfDayPref {
  final int hour;
  final int minute;
  TimeOfDayPref(this.hour, this.minute);
  String get display =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
