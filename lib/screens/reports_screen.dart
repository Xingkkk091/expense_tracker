import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final all = context.watch<TransactionProvider>().allTransactions;
    return Scaffold(
      appBar: AppBar(title: const Text('進階報表')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MonthCompareCard(all: all),
          const SizedBox(height: 16),
          _YearlyCard(
            all: all,
            year: _year,
            onYearChange: (d) => setState(() => _year += d),
          ),
          const SizedBox(height: 16),
          _RangeStatsCard(all: all),
        ],
      ),
    );
  }
}

/// 本月 vs 上月，分類比較
class _MonthCompareCard extends StatelessWidget {
  final List<Transaction> all;
  const _MonthCompareCard({required this.all});

  Map<String, double> _byCategory(DateTime month) {
    final map = <String, double>{};
    for (final t in all.where((t) =>
        t.isExpense &&
        t.date.year == month.year &&
        t.date.month == month.month)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,##0');
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);
    final thisData = _byCategory(thisMonth);
    final lastData = _byCategory(lastMonth);
    final cats = <String>{...thisData.keys, ...lastData.keys}.toList();
    final thisTotal = thisData.values.fold<double>(0, (s, v) => s + v);
    final lastTotal = lastData.values.fold<double>(0, (s, v) => s + v);
    final diff = thisTotal - lastTotal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('本月 vs 上月',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('本月支出 NT\$ ${fmt.format(thisTotal)}',
                    style: const TextStyle(fontSize: 12)),
                const Spacer(),
                Text(
                  diff >= 0
                      ? '↑ 比上月多 ${fmt.format(diff)}'
                      : '↓ 比上月少 ${fmt.format(-diff)}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: diff >= 0
                          ? AppColors.expense
                          : AppColors.income),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (cats.isEmpty)
              Text('近兩個月沒有支出資料',
                  style: TextStyle(color: scheme.onSurfaceVariant))
            else
              ...cats.map((c) {
                final tv = thisData[c] ?? 0;
                final lv = lastData[c] ?? 0;
                final maxv = [tv, lv, 1.0].reduce((a, b) => a > b ? a : b);
                final cat = categoryOf(c);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(cat.icon, size: 14, color: cat.color),
                          const SizedBox(width: 4),
                          Text(c, style: const TextStyle(fontSize: 12)),
                          const Spacer(),
                          Text(
                            '${fmt.format(tv)}  (上月 ${fmt.format(lv)})',
                            style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // 本月 bar
                      _bar(tv / maxv, cat.color),
                      const SizedBox(height: 2),
                      // 上月 bar
                      _bar(lv / maxv,
                          scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _bar(double ratio, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: ratio.clamp(0, 1),
        minHeight: 4,
        backgroundColor: color.withValues(alpha: 0.12),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

/// 年度收支總覽（12 個月柱狀）
class _YearlyCard extends StatelessWidget {
  final List<Transaction> all;
  final int year;
  final ValueChanged<int> onYearChange;
  const _YearlyCard({
    required this.all,
    required this.year,
    required this.onYearChange,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,##0');
    final income = List<double>.filled(12, 0);
    final expense = List<double>.filled(12, 0);
    for (final t in all.where((t) => t.date.year == year)) {
      final m = t.date.month - 1;
      if (t.isExpense) {
        expense[m] += t.amount;
      } else {
        income[m] += t.amount;
      }
    }
    final maxV = [
      ...income,
      ...expense,
      1.0,
    ].reduce((a, b) => a > b ? a : b);
    final maxY = (maxV * 1.2).ceilToDouble();
    final yearIncome = income.fold<double>(0, (s, v) => s + v);
    final yearExpense = expense.fold<double>(0, (s, v) => s + v);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('年度收支',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: () => onYearChange(-1),
                ),
                Text('$year',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () => onYearChange(1),
                ),
              ],
            ),
            Row(
              children: [
                _legendDot(AppColors.income,
                    '收入 ${fmt.format(yearIncome)}'),
                const SizedBox(width: 16),
                _legendDot(AppColors.expense,
                    '支出 ${fmt.format(yearExpense)}'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barGroups: List.generate(12, (i) {
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: income[i],
                        color: AppColors.income,
                        width: 5,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(2)),
                      ),
                      BarChartRodData(
                        toY: expense[i],
                        color: AppColors.expense,
                        width: 5,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(2)),
                      ),
                    ]);
                  }),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i % 2 != 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('${i + 1}',
                                style: const TextStyle(fontSize: 9)),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => scheme.inverseSurface,
                      getTooltipItem: (group, gi, rod, ri) {
                        final label = ri == 0 ? '收入' : '支出';
                        return BarTooltipItem(
                          '${group.x + 1}月 $label\n${fmt.format(rod.toY)}',
                          TextStyle(
                              color: scheme.onInverseSurface, fontSize: 11),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

/// 收支區間分析
class _RangeStatsCard extends StatelessWidget {
  final List<Transaction> all;
  const _RangeStatsCard({required this.all});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,##0');
    final expenses = all.where((t) => t.isExpense).toList();
    if (expenses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('尚無支出資料',
              style: TextStyle(color: scheme.onSurfaceVariant)),
        ),
      );
    }
    final amounts = expenses.map((t) => t.amount).toList()..sort();
    final total = amounts.fold<double>(0, (s, v) => s + v);
    final avg = total / amounts.length;
    final median = amounts[amounts.length ~/ 2];
    final max = amounts.last;
    final min = amounts.first;
    // 找出單筆最大的那筆
    final biggest =
        expenses.reduce((a, b) => a.amount >= b.amount ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('支出區間分析',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _statRow('總筆數', '${amounts.length} 筆'),
            _statRow('平均每筆', 'NT\$ ${fmt.format(avg)}'),
            _statRow('中位數', 'NT\$ ${fmt.format(median)}'),
            _statRow('最大單筆', 'NT\$ ${fmt.format(max)}'),
            _statRow('最小單筆', 'NT\$ ${fmt.format(min)}'),
            const Divider(height: 20),
            Row(
              children: [
                Icon(categoryOf(biggest.category).icon,
                    size: 16, color: categoryOf(biggest.category).color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('最大一筆：${biggest.title}',
                      style: const TextStyle(fontSize: 12)),
                ),
                Text('NT\$ ${fmt.format(biggest.amount)}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
