import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/auto_backup_service.dart';
import '../services/database_service.dart';
import '../services/budget_service.dart';
import '../services/category_service.dart';
import '../services/notification_service.dart';
import '../services/wallet_service.dart';

enum TimeRange { week, month, all }

class TransactionFilter {
  final Set<String> categories;
  final DateTimeRange? dateRange;
  final double? minAmount;
  final double? maxAmount;

  const TransactionFilter({
    this.categories = const {},
    this.dateRange,
    this.minAmount,
    this.maxAmount,
  });

  bool get isActive =>
      categories.isNotEmpty ||
      dateRange != null ||
      minAmount != null ||
      maxAmount != null;

  TransactionFilter copyWith({
    Set<String>? categories,
    DateTimeRange? dateRange,
    double? minAmount,
    double? maxAmount,
    bool clearDateRange = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
  }) {
    return TransactionFilter(
      categories: categories ?? this.categories,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
    );
  }
}

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final BudgetService _budgetService = BudgetService();
  final CategoryService _categoryService = CategoryService();
  final WalletService _walletService = WalletService();

  List<Transaction> _all = [];
  TimeRange _timeRange = TimeRange.month;
  String _search = '';
  TransactionFilter _filter = const TransactionFilter();
  double _monthlyBudget = 0;
  String? _walletFilter; // null = 全部錢包
  List<WalletInfo> _wallets = [];

  // === Memoization cache ===
  List<Transaction>? _filteredCache;
  double? _incomeCache;
  double? _expenseCache;
  double? _monthExpenseCache;
  Map<String, double>? _byCategoryCache;
  List<MapEntry<String, double>>? _hotspotsCache;

  void _invalidate() {
    _filteredCache = null;
    _incomeCache = null;
    _expenseCache = null;
    _monthExpenseCache = null;
    _byCategoryCache = null;
    _hotspotsCache = null;
  }

  TimeRange get timeRange => _timeRange;
  String get search => _search;
  TransactionFilter get filter => _filter;
  double get monthlyBudget => _monthlyBudget;
  String? get walletFilter => _walletFilter;
  List<WalletInfo> get wallets => _wallets;

  List<Transaction> get allTransactions => _all;

  /// 各錢包餘額（收入−支出，全期間）
  Map<String, double> get walletBalances {
    final map = <String, double>{};
    for (final w in _wallets) {
      map[w.name] = 0;
    }
    for (final t in _all) {
      map[t.wallet] =
          (map[t.wallet] ?? 0) + (t.isExpense ? -t.amount : t.amount);
    }
    return map;
  }

  /// 套用搜尋 + filter + 時間範圍 + 錢包後的清單（給首頁列表用），結果被快取
  List<Transaction> get transactions {
    if (_filteredCache != null) return _filteredCache!;
    Iterable<Transaction> result = _all;

    // 錢包篩選
    if (_walletFilter != null) {
      result = result.where((t) => t.wallet == _walletFilter);
    }

    // 時間範圍
    final now = DateTime.now();
    if (_timeRange == TimeRange.week) {
      final start = now.subtract(Duration(days: now.weekday - 1));
      final startDay = DateTime(start.year, start.month, start.day);
      result = result.where((t) => !t.date.isBefore(startDay));
    } else if (_timeRange == TimeRange.month) {
      final startDay = DateTime(now.year, now.month, 1);
      result = result.where((t) => !t.date.isBefore(startDay));
    }

    // 搜尋
    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      result = result.where((t) =>
          t.title.toLowerCase().contains(q) ||
          t.address.toLowerCase().contains(q) ||
          t.note.toLowerCase().contains(q));
    }

    // 進階篩選
    if (_filter.categories.isNotEmpty) {
      result = result.where((t) => _filter.categories.contains(t.category));
    }
    if (_filter.dateRange != null) {
      final r = _filter.dateRange!;
      result = result.where(
          (t) => !t.date.isBefore(r.start) && !t.date.isAfter(r.end));
    }
    if (_filter.minAmount != null) {
      result = result.where((t) => t.amount >= _filter.minAmount!);
    }
    if (_filter.maxAmount != null) {
      result = result.where((t) => t.amount <= _filter.maxAmount!);
    }

    _filteredCache = result.toList();
    return _filteredCache!;
  }

  double get totalIncome {
    if (_incomeCache != null) return _incomeCache!;
    return _incomeCache = transactions
        .where((t) => !t.isExpense)
        .fold<double>(0, (s, t) => s + t.amount);
  }

  double get totalExpense {
    if (_expenseCache != null) return _expenseCache!;
    return _expenseCache = transactions
        .where((t) => t.isExpense)
        .fold<double>(0, (s, t) => s + t.amount);
  }

  double get balance => totalIncome - totalExpense;

  /// 本月支出（給預算進度條用，固定本月不受 timeRange 影響）
  double get monthExpense {
    if (_monthExpenseCache != null) return _monthExpenseCache!;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return _monthExpenseCache = _all
        .where((t) => t.isExpense && !t.date.isBefore(start))
        .fold<double>(0.0, (s, t) => s + t.amount);
  }

  double get budgetProgress {
    if (_monthlyBudget <= 0) return 0;
    return (monthExpense / _monthlyBudget).clamp(0.0, 1.0);
  }

  Map<String, double> get expenseByCategory {
    if (_byCategoryCache != null) return _byCategoryCache!;
    final Map<String, double> map = {};
    for (final t in transactions.where((t) => t.isExpense)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return _byCategoryCache = map;
  }

  /// 最近使用範本（依「標題+分類」分組取最近 5 筆）
  List<Transaction> get recentTemplates {
    final seen = <String>{};
    final out = <Transaction>[];
    for (final t in _all) {
      final key = '${t.title}|${t.category}';
      if (seen.add(key)) {
        out.add(t);
        if (out.length >= 5) break;
      }
    }
    return out;
  }

  /// 消費熱點 Top 5（依地址聚合），快取
  List<MapEntry<String, double>> get hotspots {
    if (_hotspotsCache != null) return _hotspotsCache!;
    final Map<String, double> map = {};
    for (final t in _all
        .where((t) => t.isExpense && t.address.trim().isNotEmpty)) {
      map[t.address] = (map[t.address] ?? 0) + t.amount;
    }
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _hotspotsCache = list.take(5).toList();
  }

  Future<void> load() async {
    _all = await _db.getAll();
    _monthlyBudget = await _budgetService.getMonthlyBudget();
    await _categoryService.loadIntoRegistry();
    await _walletService.ensureDefault();
    _wallets = await _walletService.getAll();
    _invalidate();
    notifyListeners();
  }

  /// 重新載入分類與錢包設定（自訂分類/錢包變更後呼叫）
  Future<void> reloadMeta() async {
    await _categoryService.loadIntoRegistry();
    _wallets = await _walletService.getAll();
    _invalidate();
    notifyListeners();
  }

  void setWalletFilter(String? wallet) {
    _walletFilter = wallet;
    _invalidate();
    notifyListeners();
  }

  Future<void> add(Transaction t) async {
    await _db.insert(t);
    await load();
    _checkBudgetAlert();
    _triggerAutoBackup();
  }

  void _triggerAutoBackup() {
    // 觸發背景備份，每 5 分鐘最多一次（避免每筆都寫）
    AutoBackupService().runBackup(minIntervalMinutes: 5);
  }

  void _checkBudgetAlert() {
    if (_monthlyBudget > 0 && budgetProgress >= 0.7) {
      NotificationService()
          .notifyBudgetIfNeeded(budgetProgress, monthExpense, _monthlyBudget);
    }
  }

  Future<void> remove(String id) async {
    await _db.delete(id);
    await load();
    _triggerAutoBackup();
  }

  Future<void> edit(Transaction t) async {
    await _db.update(t);
    await load();
    _triggerAutoBackup();
  }

  void setTimeRange(TimeRange r) {
    _timeRange = r;
    _invalidate();
    notifyListeners();
  }

  void setSearch(String s) {
    _search = s;
    _invalidate();
    notifyListeners();
  }

  void setFilter(TransactionFilter f) {
    _filter = f;
    _invalidate();
    notifyListeners();
  }

  void clearFilter() {
    _filter = const TransactionFilter();
    _invalidate();
    notifyListeners();
  }

  Future<void> setMonthlyBudget(double value) async {
    _monthlyBudget = value;
    await _budgetService.setMonthlyBudget(value);
    _invalidate();
    notifyListeners();
  }
}
