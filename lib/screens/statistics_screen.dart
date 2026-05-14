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
    final hotspots = provider.hotspots;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          _SummaryRow(
            income: provider.totalIncome,
            expense: provider.totalExpense,
            balance: provider.balance,
          ),
          const SizedBox(height: 16),

          if (total == 0)
            _emptyCard('尚無支出資料', Icons.pie_chart_outline)
          else ...[
            // 圓餅圖
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(
                        icon: Icons.pie_chart, title: '支出分類佔比'),
                    const SizedBox(height: 12),
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
                    _Legend(byCategory: byCategory),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 7天長條圖
          _WeeklyBarChart(transactions: provider.transactions),

          const SizedBox(height: 16),

          // 消費熱點
          if (hotspots.isNotEmpty)
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(
                        icon: Icons.location_on, title: '消費熱點 Top 5'),
                    const SizedBox(height: 8),
                    ...hotspots.asMap().entries.map((e) {
                      final idx = e.key;
                      final entry = e.value;
                      final maxValue = hotspots.first.value;
                      final ratio =
                          maxValue > 0 ? entry.value / maxValue : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(13)),
                              alignment: Alignment.center,
                              child: Text('${idx + 1}',
                                  style: TextStyle(
                                      color: theme.colorScheme
                                          .onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(entry.key,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: ratio.toDouble(),
                                      minHeight: 4,
                                      backgroundColor:
                                          theme.colorScheme.surfaceContainerHighest,
                                      valueColor: AlwaysStoppedAnimation(
                                          theme.colorScheme.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                                '\$${NumberFormat('#,##0').format(entry.value)}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyCard(String text, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 56, color: Colors.grey),
              const SizedBox(height: 8),
              Text(text, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
      Map<String, double> byCategory, double total) {
    return byCategory.entries.map((e) {
      final pct = e.value / total * 100;
      final cat = categoryOf(e.key);
      return PieChartSectionData(
        color: cat.color,
        value: e.value,
        title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
        radius: 60,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Map<String, double> byCategory;
  const _Legend({required this.byCategory});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: byCategory.entries.map((e) {
        final cat = categoryOf(e.key);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: cat.color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Icon(cat.icon, size: 13, color: cat.color),
            const SizedBox(width: 2),
            Text('${e.key}  \$${fmt.format(e.value)}',
                style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }
}

class _WeeklyBarChart extends StatefulWidget {
  final List<Transaction> transactions;
  const _WeeklyBarChart({required this.transactions});

  @override
  State<_WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<_WeeklyBarChart> {
  int _rangeDays = 7;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(_rangeDays, (i) {
      final d = now.subtract(Duration(days: _rangeDays - 1 - i));
      return DateTime(d.year, d.month, d.day);
    });

    final amounts = days.map((day) {
      return widget.transactions
          .where((t) =>
              t.isExpense &&
              t.date.year == day.year &&
              t.date.month == day.month &&
              t.date.day == day.day)
          .fold(0.0, (sum, t) => sum + t.amount);
    }).toList();

    final maxValue = amounts.isEmpty
        ? 0.0
        : amounts.reduce((a, b) => a > b ? a : b);
    final maxY = maxValue <= 0 ? 100.0 : (maxValue * 1.2).ceilToDouble();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SectionTitle(
                    icon: Icons.bar_chart, title: '近 $_rangeDays 天支出'),
                const Spacer(),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7日')),
                    ButtonSegment(value: 30, label: Text('30日')),
                    ButtonSegment(value: 90, label: Text('90日')),
                  ],
                  selected: {_rangeDays},
                  onSelectionChanged: (s) =>
                      setState(() => _rangeDays = s.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStateProperty.all(
                        const TextStyle(fontSize: 11)),
                    padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 4)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barGroups: List.generate(_rangeDays, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: amounts[i],
                          color: Theme.of(context).colorScheme.primary,
                          width: _rangeDays > 30 ? 4 : (_rangeDays > 7 ? 8 : 16),
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
                          final i = value.toInt();
                          if (i < 0 || i >= days.length) {
                            return const SizedBox.shrink();
                          }
                          // 多日時只顯示每幾天一個標籤避免擠在一起
                          final step = _rangeDays > 30 ? 14 : (_rangeDays > 7 ? 5 : 1);
                          if (i % step != 0) return const SizedBox.shrink();
                          final d = days[i];
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('${d.month}/${d.day}',
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
}

class _SummaryRow extends StatelessWidget {
  final double income, expense, balance;
  const _SummaryRow(
      {required this.income, required this.expense, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryCard(
            label: '收入', amount: income, color: const Color(0xFF7C9070)),
        const SizedBox(width: 8),
        _SummaryCard(
            label: '支出', amount: expense, color: const Color(0xFFB57C70)),
        const SizedBox(width: 8),
        _SummaryCard(
            label: '結餘',
            amount: balance,
            color: balance >= 0
                ? const Color(0xFF5C6B7A)
                : const Color(0xFFC9A86A)),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('\$${fmt.format(amount)}',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
