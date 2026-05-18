import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/recurring_service.dart';
import '../theme/app_colors.dart';

/// 訂閱 / 定期費用一覽：聚合 recurring_rules 中所有「支出」項目，
/// 換算成每月固定費用，依頻率排序。
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _service = RecurringService();
  List<RecurringRule> _rules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _service.getAll();
    if (!mounted) return;
    setState(() {
      _rules = all.where((r) => r.isExpense && r.active).toList();
      _loading = false;
    });
  }

  /// 把每條規則換算成「每月支出」
  double _monthlyOf(RecurringRule r) {
    switch (r.frequency) {
      case RecurFrequency.daily:
        return r.amount * 30;
      case RecurFrequency.weekly:
        return r.amount * 4.33;
      case RecurFrequency.monthly:
        return r.amount;
    }
  }

  /// 下次扣款日（依 lastGenerated 或 startDate 推算）
  DateTime _nextDate(RecurringRule r) {
    final base = r.lastGenerated ?? r.startDate;
    switch (r.frequency) {
      case RecurFrequency.daily:
        return base.add(const Duration(days: 1));
      case RecurFrequency.weekly:
        return base.add(const Duration(days: 7));
      case RecurFrequency.monthly:
        var y = base.year;
        var m = base.month + 1;
        if (m > 12) {
          m = 1;
          y++;
        }
        final lastDay = DateTime(y, m + 1, 0).day;
        final day = base.day > lastDay ? lastDay : base.day;
        return DateTime(y, m, day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,##0');
    final total = _rules.fold<double>(0, (s, r) => s + _monthlyOf(r));
    // 依下次扣款日排序
    final sorted = [..._rules]
      ..sort((a, b) => _nextDate(a).compareTo(_nextDate(b)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('訂閱 / 定期費用'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新增定期項目',
            onPressed: () async {
              await Navigator.pushNamed(context, '/recurring');
              await _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.subscriptions,
                            size: 56, color: scheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        const Text('尚無訂閱項目'),
                        const SizedBox(height: 4),
                        Text('Netflix、Spotify、健身房、房租等可在「重複記帳」設定',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () async {
                            await Navigator.pushNamed(context, '/recurring');
                            await _load();
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('新增定期項目'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    // 月支出總覽卡
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scheme.outline),
                      ),
                      child: Column(
                        children: [
                          Text('每月固定支出',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text('NT\$ ${fmt.format(total)}',
                              style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w300,
                                  color: AppColors.expense)),
                          const SizedBox(height: 4),
                          Text('共 ${_rules.length} 項',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('下次扣款',
                        style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    for (final r in sorted) ...[
                      _SubscriptionTile(
                        rule: r,
                        monthly: _monthlyOf(r),
                        nextDate: _nextDate(r),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  final RecurringRule rule;
  final double monthly;
  final DateTime nextDate;
  const _SubscriptionTile({
    required this.rule,
    required this.monthly,
    required this.nextDate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,##0');
    final cat = categoryOf(rule.category);
    final daysToNext = nextDate.difference(DateTime.now()).inDays;
    final dayLabel = daysToNext <= 0
        ? '即將扣款'
        : '$daysToNext 天後';
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(cat.icon, color: cat.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.title,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  '${rule.frequency.label} · ${rule.wallet} · $dayLabel',
                  style: TextStyle(
                      fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('NT\$ ${fmt.format(rule.amount)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.expense)),
              if (rule.frequency != RecurFrequency.monthly)
                Text(
                  '≈ ${fmt.format(monthly)}/月',
                  style: TextStyle(
                      fontSize: 10, color: scheme.onSurfaceVariant),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
