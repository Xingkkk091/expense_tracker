import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/invoice_parser.dart';
import '../services/update_service.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/transaction_card.dart';
import '../widgets/update_dialog.dart';
import '../l10n/app_localizations.dart';
import '../widgets/animated_widgets.dart';
import 'add_transaction_screen.dart';
import 'carrier_screen.dart';
import 'invoice_scanner_screen.dart';
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

  Future<void> _scanInvoice() async {
    final invoice = await Navigator.push<InvoiceData>(
      context,
      MaterialPageRoute(builder: (_) => const InvoiceScannerScreen()),
    );
    if (invoice != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddTransactionScreen(invoicePrefill: invoice),
        ),
      );
    }
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
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: _searching && _tab == 0
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l.searchHint,
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: provider.setSearch,
              )
            : Text(_titleByTab(l)),
        actions: [
          if (_tab == 0) ...[
            IconButton(
              icon: Icon(_searching ? Icons.close : Icons.search),
              tooltip: l.search,
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
              tooltip: l.filter,
              onPressed: _openFilter,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: l.myCarrier,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CarrierScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l.settings,
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
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
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.list_alt), label: l.navRecords),
          NavigationDestination(
              icon: const Icon(Icons.pie_chart), label: l.navStats),
          NavigationDestination(
              icon: const Icon(Icons.map), label: l.navMap),
        ],
      ),
      floatingActionButton: _tab == 0
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'scan_invoice',
                  onPressed: _scanInvoice,
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outline),
                  ),
                  tooltip: l.scanInvoice,
                  child: const Icon(Icons.qr_code_scanner),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'add_tx',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddTransactionScreen()),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(l.add),
                ),
              ],
            )
          : _tab == 1
              ? FloatingActionButton(
                  onPressed: _editBudget,
                  child: const Icon(Icons.savings),
                )
              : null,
    );
  }

  String _titleByTab(AppLocalizations l) {
    switch (_tab) {
      case 0:
        return l.homeTitle;
      case 1:
        return l.statsTitle;
      case 2:
        return l.mapTitle;
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
        if (provider.wallets.length > 1) _WalletFilterBar(provider: provider),
        Expanded(
          child: transactions.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long,
                  title: AppLocalizations.of(context).emptyRecords,
                  subtitle: AppLocalizations.of(context).emptyRecordsHint,
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
    int runningIndex = 0;
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
                            ? const Color(0xFF7C9070)
                            : const Color(0xFFB57C70)),
                  ),
                ],
              ),
            ),
            ...items.map((t) => StaggeredItem(
                  index: runningIndex++,
                  child: TransactionCard(
                    transaction: t,
                    onDelete: () => _confirmDelete(context, t),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              AddTransactionScreen(existing: t)),
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Transaction t) async {
    // 先刪除 + SnackBar 復原
    final provider = context.read<TransactionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    await provider.remove(t.id);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(l.deleted(t.title)),
        action: SnackBarAction(
          label: l.undo,
          onPressed: () => provider.add(t),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class _WalletFilterBar extends StatelessWidget {
  final TransactionProvider provider;
  const _WalletFilterBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            child: ChoiceChip(
              label: Text(AppLocalizations.of(context).allWallets),
              selected: provider.walletFilter == null,
              onSelected: (_) => provider.setWalletFilter(null),
              labelStyle: TextStyle(
                  fontSize: 12,
                  color: provider.walletFilter == null
                      ? scheme.onPrimary
                      : scheme.onSurface),
            ),
          ),
          for (final w in provider.wallets)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              child: ChoiceChip(
                avatar: Icon(w.icon,
                    size: 15,
                    color: provider.walletFilter == w.name
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant),
                label: Text(w.name),
                selected: provider.walletFilter == w.name,
                onSelected: (_) => provider.setWalletFilter(w.name),
                labelStyle: TextStyle(
                    fontSize: 12,
                    color: provider.walletFilter == w.name
                        ? scheme.onPrimary
                        : scheme.onSurface),
              ),
            ),
        ],
      ),
    );
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
    final l = AppLocalizations.of(context);
    const expenseColor = Color(0xFFB57C70);
    const incomeColor = Color(0xFF7C9070);

    Color progressColor = incomeColor;
    if (budgetProgress >= 0.9) {
      progressColor = expenseColor;
    } else if (budgetProgress >= 0.7) {
      progressColor = const Color(0xFFC9A86A);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        children: [
          // 時間範圍切換
          SegmentedButton<TimeRange>(
            segments: [
              ButtonSegment(value: TimeRange.week, label: Text(l.rangeWeek)),
              ButtonSegment(value: TimeRange.month, label: Text(l.rangeMonth)),
              ButtonSegment(value: TimeRange.all, label: Text(l.rangeAll)),
            ],
            selected: {timeRange},
            onSelectionChanged: (s) => onChangeRange(s.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 18),
          Text(_rangeLabel(l),
              style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          AnimatedAmount(
            value: balance,
            prefix: 'NT\$ ',
            style: TextStyle(
                color: cs.onSurface,
                fontSize: 32,
                fontWeight: FontWeight.w300,
                letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                    label: l.income,
                    value: fmt.format(income),
                    color: incomeColor),
              ),
              Container(width: 1, height: 28, color: cs.outline),
              Expanded(
                child: _MiniStat(
                    label: l.expense,
                    value: fmt.format(expense),
                    color: expenseColor),
              ),
            ],
          ),
          // 預算進度條
          if (monthlyBudget > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.monthlyBudget,
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 11)),
                Text(
                  '${fmt.format(monthExpense)} / ${fmt.format(monthlyBudget)}',
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: budgetProgress,
                minHeight: 4,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _rangeLabel(AppLocalizations l) {
    switch (timeRange) {
      case TimeRange.week:
        return l.balanceWeek;
      case TimeRange.month:
        return l.balanceMonth;
      case TimeRange.all:
        return l.balanceTotal;
    }
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
                letterSpacing: 1)),
        const SizedBox(height: 2),
        Text('NT\$ $value',
            style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
