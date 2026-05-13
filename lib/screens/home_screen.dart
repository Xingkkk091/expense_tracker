import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/update_service.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/transaction_card.dart';
import '../widgets/update_dialog.dart';
import 'add_transaction_screen.dart';
import 'map_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  bool _searching = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().load();
      _checkUpdate();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkUpdate() async {
    final info = await UpdateService().checkForUpdate();
    if (info != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => UpdateDialog(info: info),
      );
    }
  }

  Future<void> _openFilter() async {
    final provider = context.read<TransactionProvider>();
    final result = await showModalBottomSheet<TransactionFilter>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => FilterSheet(initial: provider.filter),
    );
    if (result != null) provider.setFilter(result);
  }

  Future<void> _editBudget() async {
    final provider = context.read<TransactionProvider>();
    final ctrl = TextEditingController(
        text:
            provider.monthlyBudget > 0 ? provider.monthlyBudget.toStringAsFixed(0) : '');
    final value = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('設定月預算'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              prefixText: '\$ ', border: OutlineInputBorder(), hintText: '0 表示不設'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim()) ?? 0;
              Navigator.pop(context, v);
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
    if (value != null) await provider.setMonthlyBudget(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: _searching && _tab == 0
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: '搜尋標題、地址、備註...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: provider.setSearch,
              )
            : Text(_titleByTab,
                style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_tab == 0) ...[
            IconButton(
              icon: Icon(_searching ? Icons.close : Icons.search),
              tooltip: '搜尋',
              onPressed: () {
                setState(() {
                  _searching = !_searching;
                  if (!_searching) {
                    _searchCtrl.clear();
                    provider.setSearch('');
                  }
                });
              },
            ),
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.filter_list),
                  if (provider.filter.isActive)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Colors.orange, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
              tooltip: '篩選',
              onPressed: _openFilter,
            ),
          ],
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          _TransactionListTab(),
          StatisticsScreen(),
          MapScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() {
          _tab = i;
          if (i != 0) _searching = false;
        }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: '記錄'),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: '統計'),
          NavigationDestination(icon: Icon(Icons.map), label: '地圖'),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('新增'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            )
          : _tab == 1
              ? FloatingActionButton(
                  onPressed: _editBudget,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  child: const Icon(Icons.savings),
                )
              : null,
    );
  }

  String get _titleByTab {
    switch (_tab) {
      case 0:
        return '我的記帳本';
      case 1:
        return '統計分析';
      case 2:
        return '消費地圖';
      default:
        return '';
    }
  }
}

class _TransactionListTab extends StatelessWidget {
  const _TransactionListTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final transactions = provider.transactions;
    final fmt = NumberFormat('#,##0');

    return Column(
      children: [
        _BalanceHeader(
          income: provider.totalIncome,
          expense: provider.totalExpense,
          balance: provider.balance,
          timeRange: provider.timeRange,
          onChangeRange: provider.setTimeRange,
          monthlyBudget: provider.monthlyBudget,
          monthExpense: provider.monthExpense,
          budgetProgress: provider.budgetProgress,
        ),
        Expanded(
          child: transactions.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('此區間沒有記錄',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              : _buildGroupedList(context, transactions, fmt),
        ),
      ],
    );
  }

  Widget _buildGroupedList(
      BuildContext context, List<Transaction> transactions, NumberFormat fmt) {
    final Map<String, List<Transaction>> grouped = {};
    for (final t in transactions) {
      final key = DateFormat('yyyy/MM/dd').format(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 8),
      itemCount: grouped.length,
      itemBuilder: (context, i) {
        final date = grouped.keys.elementAt(i);
        final items = grouped[date]!;
        final dayTotal = items.fold(0.0,
            (sum, t) => sum + (t.isExpense ? -t.amount : t.amount));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(date,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).hintColor,
                          fontSize: 13)),
                  Text(
                    '${dayTotal >= 0 ? '+' : ''}\$${fmt.format(dayTotal.abs())}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: dayTotal >= 0
                            ? Colors.green.shade600
                            : Colors.red.shade500),
                  ),
                ],
              ),
            ),
            ...items.map((t) => TransactionCard(
                  transaction: t,
                  onDelete: () => _confirmDelete(context, t),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AddTransactionScreen(existing: t)),
                  ),
                )),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Transaction t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除「${t.title}」嗎？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('刪除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<TransactionProvider>().remove(t.id);
    }
  }
}

class _BalanceHeader extends StatelessWidget {
  final double income, expense, balance;
  final TimeRange timeRange;
  final ValueChanged<TimeRange> onChangeRange;
  final double monthlyBudget;
  final double monthExpense;
  final double budgetProgress;

  const _BalanceHeader({
    required this.income,
    required this.expense,
    required this.balance,
    required this.timeRange,
    required this.onChangeRange,
    required this.monthlyBudget,
    required this.monthExpense,
    required this.budgetProgress,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Color progressColor = Colors.greenAccent;
    if (budgetProgress >= 0.9) {
      progressColor = Colors.redAccent;
    } else if (budgetProgress >= 0.7) {
      progressColor = Colors.orangeAccent;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          // 時間範圍切換
          SegmentedButton<TimeRange>(
            segments: const [
              ButtonSegment(value: TimeRange.week, label: Text('本週')),
              ButtonSegment(value: TimeRange.month, label: Text('本月')),
              ButtonSegment(value: TimeRange.all, label: Text('全部')),
            ],
            selected: {timeRange},
            onSelectionChanged: (s) => onChangeRange(s.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.white.withOpacity(0.15);
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return cs.primary;
                }
                return Colors.white;
              }),
              side: WidgetStateProperty.all(
                  BorderSide(color: Colors.white.withOpacity(0.5))),
            ),
          ),
          const SizedBox(height: 16),
          Text(_rangeLabel,
              style: TextStyle(color: cs.onPrimary.withOpacity(0.85), fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            '\$${fmt.format(balance)}',
            style: TextStyle(
                color: cs.onPrimary,
                fontSize: 34,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MiniStat(
                  label: '收入',
                  value: '\$${fmt.format(income)}',
                  icon: Icons.arrow_downward,
                  color: Colors.greenAccent),
              Container(width: 1, height: 24, color: Colors.white24),
              _MiniStat(
                  label: '支出',
                  value: '\$${fmt.format(expense)}',
                  icon: Icons.arrow_upward,
                  color: Colors.redAccent.shade100),
            ],
          ),
          // 預算進度條
          if (monthlyBudget > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('月預算進度',
                          style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      Text(
                        '\$${fmt.format(monthExpense)} / \$${fmt.format(monthlyBudget)}',
                        style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: budgetProgress,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation(progressColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _rangeLabel {
    switch (timeRange) {
      case TimeRange.week:
        return '本週結餘';
      case TimeRange.month:
        return '本月結餘';
      case TimeRange.all:
        return '總結餘';
    }
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MiniStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
