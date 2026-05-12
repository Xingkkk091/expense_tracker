import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final byCategory = provider.expenseByCategory;
    final total = provider.totalExpense;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: total == 0
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('尚無支出資料', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 總覽卡片
                _SummaryRow(
                  income: provider.totalIncome,
                  expense: provider.totalExpense,
                  balance: provider.balance,
                ),
                const SizedBox(height: 20),

                // 圓餅圖
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('支出分類佔比',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: PieChart(
                            PieChartData(
                              sections: _buildSections(byCategory, total),
                              centerSpaceRadius: 50,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Legend(byCategory: byCategory, total: total),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 長條圖 - 近7天支出
                _WeeklyBarChart(transactions: provider.transactions),
              ],
            ),
    );
  }

  List<PieChartSectionData> _buildSections(
      Map<String, double> byCategory, double total) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.green,
    ];
    int i = 0;
    return byCategory.entries.map((e) {
      final pct = e.value / total * 100;
      final color = colors[i++ % colors.length];
      return PieChartSectionData(
        color: color,
        value: e.value,
        title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
        radius: 60,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }
}

class _Legend extends StatelessWidget {
  final Map<String, double> byCategory;
  final double total;
  const _Legend({required this.byCategory, required this.total});

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.blue, Colors.orange, Colors.purple, Colors.red,
      Colors.teal, Colors.pink, Colors.amber, Colors.indigo, Colors.green,
    ];
    final fmt = NumberFormat('#,##0');
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: byCategory.entries.toList().asMap().entries.map((entry) {
        final i = entry.key;
        final e = entry.value;
        final icon = kCategories
            .firstWhere((c) => c['label'] == e.key,
                orElse: () => {'icon': '📋'})['icon'] as String;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('$icon ${e.key}  \$${fmt.format(e.value)}',
                style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<Transaction> transactions;
  const _WeeklyBarChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    final amounts = days.map((day) {
      return transactions
          .where((t) =>
              t.isExpense &&
              t.date.year == day.year &&
              t.date.month == day.month &&
              t.date.day == day.day)
          .fold(0.0, (sum, t) => sum + t.amount);
    }).toList();

    final maxY =
        (amounts.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble();

    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('近 7 天支出',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY <= 0 ? 100 : maxY,
                  barGroups: List.generate(7, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: amounts[i],
                          color: Theme.of(context).colorScheme.primary,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        )
                      ],
                    );
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
                          final d = days[value.toInt()];
                          return Text('${d.month}/${d.day}',
                              style: const TextStyle(fontSize: 10));
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
}

class _SummaryRow extends StatelessWidget {
  final double income, expense, balance;
  const _SummaryRow(
      {required this.income, required this.expense, required this.balance});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    return Row(
      children: [
        _SummaryCard(label: '總收入', amount: income, color: Colors.green.shade600),
        const SizedBox(width: 8),
        _SummaryCard(label: '總支出', amount: expense, color: Colors.red.shade500),
        const SizedBox(width: 8),
        _SummaryCard(
            label: '結餘',
            amount: balance,
            color: balance >= 0
                ? Colors.blue.shade600
                : Colors.orange.shade700),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _SummaryCard(
      {required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text('\$${fmt.format(amount)}',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
