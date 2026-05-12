import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/update_service.dart';
import '../widgets/transaction_card.dart';
import '../widgets/update_dialog.dart';
import 'add_transaction_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().load();
      _checkUpdate();
    });
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: const Text('我的記帳本', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => setState(() => _tab = 1),
            tooltip: '統計',
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          _TransactionList(),
          StatisticsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: '記錄'),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: '統計'),
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
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            )
          : null,
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final transactions = provider.transactions;
    final fmt = NumberFormat('#,##0');

    if (transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text('尚無記錄\n點擊右下角「新增」開始記帳',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }

    // 依日期分組
    final Map<String, List<Transaction>> grouped = {};
    for (final t in transactions) {
      final key = DateFormat('yyyy/MM/dd').format(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return Column(
      children: [
        // 頂部餘額
        _BalanceHeader(
          income: provider.totalIncome,
          expense: provider.totalExpense,
          balance: provider.balance,
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: grouped.length,
            itemBuilder: (context, i) {
              final date = grouped.keys.elementAt(i);
              final items = grouped[date]!;
              final dayTotal = items.fold(
                  0.0,
                  (sum, t) =>
                      sum + (t.isExpense ? -t.amount : t.amount));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(date,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                                fontSize: 13)),
                        Text(
                          '${dayTotal >= 0 ? '+' : ''}\$${fmt.format(dayTotal.abs())}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: dayTotal >= 0
                                  ? Colors.green.shade600
                                  : Colors.red.shade600),
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
          ),
        ),
      ],
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
              child:
                  const Text('刪除', style: TextStyle(color: Colors.red))),
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
  const _BalanceHeader(
      {required this.income, required this.expense, required this.balance});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          Text('總結餘',
              style: TextStyle(
                  color: colorScheme.onPrimary.withOpacity(0.8),
                  fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            '\$${fmt.format(balance)}',
            style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MiniStat(
                  label: '總收入',
                  value: '\$${fmt.format(income)}',
                  icon: Icons.arrow_downward,
                  color: Colors.greenAccent),
              Container(
                  width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
              _MiniStat(
                  label: '總支出',
                  value: '\$${fmt.format(expense)}',
                  icon: Icons.arrow_upward,
                  color: Colors.redAccent.shade100),
            ],
          ),
        ],
      ),
    );
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
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
