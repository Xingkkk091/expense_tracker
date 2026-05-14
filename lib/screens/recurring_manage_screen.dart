import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/recurring_service.dart';
import '../widgets/category_grid.dart';
import '../theme/app_colors.dart';

class RecurringManageScreen extends StatefulWidget {
  const RecurringManageScreen({super.key});

  @override
  State<RecurringManageScreen> createState() => _RecurringManageScreenState();
}

class _RecurringManageScreenState extends State<RecurringManageScreen> {
  final _service = RecurringService();
  List<RecurringRule> _rules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _service.getAll();
    if (!mounted) return;
    setState(() {
      _rules = list;
      _loading = false;
    });
  }

  Future<void> _editDialog({RecurringRule? existing}) async {
    final result = await showModalBottomSheet<RecurringRule>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RecurringEditSheet(existing: existing),
    );
    if (result == null) return;
    await _service.save(result);
    await _load();
  }

  Future<void> _delete(RecurringRule r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('刪除規則'),
        content: Text('停止「${r.title}」的自動記帳？已產生的記錄會保留。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.remove(r.id);
    await _load();
  }

  Future<void> _runNow() async {
    final n = await _service.generateDue();
    if (!mounted) return;
    await context.read<TransactionProvider>().load();
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(n > 0 ? '已補產生 $n 筆記錄' : '目前沒有待產生的記錄')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,##0');
    return Scaffold(
      appBar: AppBar(
        title: const Text('重複記帳'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: '立即檢查產生',
            onPressed: _runNow,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editDialog(),
        icon: const Icon(Icons.add),
        label: const Text('新增規則'),
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
                        Icon(Icons.repeat,
                            size: 56, color: scheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        const Text('尚無重複記帳規則'),
                        const SizedBox(height: 4),
                        Text('房租、訂閱、薪水等定期項目可在此設定',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  children: [
                    for (final r in _rules)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: scheme.outline),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: categoryOf(r.category)
                                  .color
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(categoryOf(r.category).icon,
                                color: categoryOf(r.category).color,
                                size: 20),
                          ),
                          title: Text(r.title),
                          subtitle: Text(
                            '${r.frequency.label} · ${r.category} · ${r.wallet}'
                            '${r.lastGenerated != null ? "\n上次產生 ${DateFormat('yyyy/MM/dd').format(r.lastGenerated!)}" : ""}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          isThreeLine: r.lastGenerated != null,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${r.isExpense ? '-' : '+'}\$${fmt.format(r.amount)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: r.isExpense
                                        ? AppColors.expense
                                        : AppColors.income),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.delete_outline,
                                    size: 18),
                                color: scheme.onSurfaceVariant,
                                onPressed: () => _delete(r),
                              ),
                            ],
                          ),
                          onTap: () => _editDialog(existing: r),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _RecurringEditSheet extends StatefulWidget {
  final RecurringRule? existing;
  const _RecurringEditSheet({this.existing});

  @override
  State<_RecurringEditSheet> createState() => _RecurringEditSheetState();
}

class _RecurringEditSheetState extends State<_RecurringEditSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isExpense = true;
  String _category = '住房';
  RecurFrequency _freq = RecurFrequency.monthly;
  DateTime _startDate = DateTime.now();
  String _wallet = kDefaultWallet;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _amountCtrl.text = e.amount.toStringAsFixed(0);
      _noteCtrl.text = e.note;
      _isExpense = e.isExpense;
      _category = e.category;
      _freq = e.frequency;
      _startDate = e.startDate;
      _wallet = e.wallet;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = context.read<TransactionProvider>().wallets;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.existing != null ? '編輯規則' : '新增重複規則',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _typeBtn('支出', true)),
                const SizedBox(width: 8),
                Expanded(child: _typeBtn('收入', false)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: '項目名稱'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: '金額', prefixText: 'NT\$ '),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<RecurFrequency>(
              initialValue: _freq,
              decoration: const InputDecoration(labelText: '頻率'),
              items: RecurFrequency.values
                  .map((f) => DropdownMenuItem(
                      value: f, child: Text(f.label)))
                  .toList(),
              onChanged: (v) => setState(() => _freq = v!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue:
                  wallets.any((w) => w.name == _wallet) ? _wallet : null,
              decoration: const InputDecoration(labelText: '錢包'),
              items: wallets
                  .map((w) => DropdownMenuItem(
                      value: w.name, child: Text(w.name)))
                  .toList(),
              onChanged: (v) => setState(() => _wallet = v ?? kDefaultWallet),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '起始日'),
                child: Text(
                    DateFormat('yyyy/MM/dd').format(_startDate)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('分類', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            CategoryGrid(
              selected: _category,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: '備註（可留空）'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('儲存規則'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn(String label, bool expense) {
    final selected = _isExpense == expense;
    final color = expense
        ? AppColors.expense
        : AppColors.income;
    return GestureDetector(
      onTap: () => setState(() => _isExpense = expense),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected
                  ? color
                  : Theme.of(context).colorScheme.outline),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: selected
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請輸入名稱與金額')));
      return;
    }
    Navigator.pop(
      context,
      RecurringRule(
        id: widget.existing?.id ?? const Uuid().v4(),
        title: title,
        amount: amount,
        isExpense: _isExpense,
        category: _category,
        note: _noteCtrl.text.trim(),
        frequency: _freq,
        startDate: _startDate,
        lastGenerated: widget.existing?.lastGenerated,
        active: true,
        wallet: _wallet,
      ),
    );
  }
}
