import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../services/budget_service.dart';
import '../theme/app_colors.dart';

class BudgetHistoryScreen extends StatefulWidget {
  const BudgetHistoryScreen({super.key});

  @override
  State<BudgetHistoryScreen> createState() => _BudgetHistoryScreenState();
}

class _BudgetHistoryScreenState extends State<BudgetHistoryScreen> {
  final _service = BudgetService();
  Map<String, double> _history = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await _service.getAllHistory();
    if (!mounted) return;
    setState(() {
      _history = h;
      _loading = false;
    });
  }

  /// 各月實際支出（從交易資料即時計算）
  Map<String, double> _actualByMonth() {
    final all = context.read<TransactionProvider>().allTransactions;
    final map = <String, double>{};
    for (final t in all.where((t) => t.isExpense)) {
      final key = DateFormat('yyyy-MM').format(t.date);
      map[key] = (map[key] ?? 0) + t.amount;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,##0');

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final actual = _actualByMonth();
    // 整合所有月份（預算 + 實際）
    final months = <String>{..._history.keys, ...actual.keys}.toList()
      ..sort();
    final recent = months.length > 12
        ? months.sublist(months.length - 12)
        : months;

    return Scaffold(
      appBar: AppBar(title: const Text('預算歷史')),
      body: recent.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history,
                        size: 56, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    const Text('尚無預算歷史'),
                    const SizedBox(height: 4),
                    Text('在設定頁設定月預算後，每月達成率會記錄於此',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _chartCard(recent, actual, scheme),
                const SizedBox(height: 16),
                _listCard(recent, actual, fmt, scheme),
              ],
            ),
    );
  }

  Widget _chartCard(List<String> months, Map<String, double> actual,
      ColorScheme scheme) {
    double maxY = 100;
    for (final m in months) {
      final b = _history[m] ?? 0;
      final a = actual[m] ?? 0;
      if (b > maxY) maxY = b;
      if (a > maxY) maxY = a;
    }
    maxY = (maxY * 1.2).ceilToDouble();

    List<FlSpot> spots(double Function(String) pick) => [
          for (int i = 0; i < months.length; i++)
            FlSpot(i.toDouble(), pick(months[i])),
        ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('預算 vs 實際支出',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                _legendDot(scheme.primary, '預算'),
                const SizedBox(width: 16),
                _legendDot(AppColors.expense, '實際支出'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  maxY: maxY,
                  minY: 0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots((m) => _history[m] ?? 0),
                      color: scheme.primary,
                      barWidth: 2,
                      isCurved: false,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: spots((m) => actual[m] ?? 0),
                      color: AppColors.expense,
                      barWidth: 2,
                      isCurved: false,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
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
                          if (i < 0 || i >= months.length) {
                            return const SizedBox.shrink();
                          }
                          final step =
                              months.length > 6 ? 2 : 1;
                          if (i % step != 0) {
                            return const SizedBox.shrink();
                          }
                          // 顯示 MM
                          final mm = months[i].substring(5);
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(mm,
                                style: const TextStyle(fontSize: 9)),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _listCard(List<String> months, Map<String, double> actual,
      NumberFormat fmt, ColorScheme scheme) {
    return Card(
      child: Column(
        children: [
          for (final m in months.reversed) ...[
            Builder(builder: (context) {
              final budget = _history[m] ?? 0;
              final spent = actual[m] ?? 0;
              final pct = budget > 0 ? (spent / budget) : null;
              Color statusColor = scheme.onSurfaceVariant;
              String status = '無預算';
              if (pct != null) {
                if (pct > 1) {
                  statusColor = AppColors.expense;
                  status = '超支 ${((pct - 1) * 100).toStringAsFixed(0)}%';
                } else {
                  statusColor = AppColors.income;
                  status = '達成率 ${(pct * 100).toStringAsFixed(0)}%';
                }
              }
              return ListTile(
                title: Text(m),
                subtitle: Text(
                  budget > 0
                      ? '預算 ${fmt.format(budget)} · 支出 ${fmt.format(spent)}'
                      : '支出 ${fmt.format(spent)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(status,
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              );
            }),
            if (m != months.reversed.last)
              Divider(height: 1, color: scheme.outline),
          ],
        ],
      ),
    );
  }
}
