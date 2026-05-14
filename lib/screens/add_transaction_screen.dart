import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/invoice_parser.dart';
import '../services/location_service.dart';
import '../widgets/calculator_keypad.dart';
import '../widgets/category_grid.dart';
import '../widgets/place_search_field.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? existing;
  final InvoiceData? invoicePrefill;
  const AddTransactionScreen({super.key, this.existing, this.invoicePrefill});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  double _amount = 0;
  bool _isExpense = true;
  String _category = '餐飲';
  DateTime _date = DateTime.now();
  double? _lat, _lng;
  bool _loadingLocation = false;
  String _wallet = kDefaultWallet;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _titleCtrl.text = t.title;
      _amount = t.amount;
      _noteCtrl.text = t.note;
      _addressCtrl.text = t.address;
      _isExpense = t.isExpense;
      _category = t.category;
      _date = t.date;
      _lat = t.latitude;
      _lng = t.longitude;
      _wallet = t.wallet;
    }
    final inv = widget.invoicePrefill;
    if (inv != null) {
      _amount = inv.total;
      _date = inv.date;
      if (inv.items.isNotEmpty) {
        _titleCtrl.text = inv.items.first.name;
      } else {
        _titleCtrl.text = '發票 ${inv.displayNumber}';
      }
      final lines = <String>['發票 ${inv.displayNumber}'];
      if (inv.sellerTaxId.isNotEmpty) {
        lines.add('賣方統編 ${inv.sellerTaxId}');
      }
      for (final it in inv.items) {
        lines.add('${it.name} x${it.quantity}  \$${it.price.toStringAsFixed(0)}');
      }
      _noteCtrl.text = lines.join('\n');
      _isExpense = true;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day,
          time?.hour ?? _date.hour, time?.minute ?? _date.minute);
    });
  }

  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final result = await LocationService().getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
        _addressCtrl.text = result.address;
        _loadingLocation = false;
      });
    } on LocationFailure catch (f) {
      if (!mounted) return;
      setState(() => _loadingLocation = false);
      _toast(f.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingLocation = false);
      _toast('無法取得位置：$e');
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _toast('請輸入標題');
      return;
    }
    if (_amount <= 0) {
      _toast('請輸入有效金額');
      return;
    }
    final provider = context.read<TransactionProvider>();
    final t = Transaction(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      amount: _amount,
      isExpense: _isExpense,
      category: _category,
      note: _noteCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      latitude: _lat,
      longitude: _lng,
      date: _date,
      wallet: _wallet,
    );
    if (widget.existing != null) {
      await provider.edit(t);
    } else {
      await provider.add(t);
    }
    if (mounted) Navigator.pop(context);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _applyTemplate(Transaction t) {
    setState(() {
      _titleCtrl.text = t.title;
      _category = t.category;
      _isExpense = t.isExpense;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cat = categoryOf(_category);
    final templates = context.watch<TransactionProvider>().recentTemplates;
    final fmt = NumberFormat('#,##0.##');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? '編輯記錄' : '新增記錄'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('儲存'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // 收支切換
          _SegToggle(
            isExpense: _isExpense,
            onChanged: (v) => setState(() => _isExpense = v),
          ),
          const SizedBox(height: 16),

          // 金額顯示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.outline),
            ),
            child: Column(
              children: [
                Text(
                  _isExpense ? '支出金額' : '收入金額',
                  style: TextStyle(
                      fontSize: 12, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text('NT\$ ',
                          style: TextStyle(
                              fontSize: 16,
                              color: scheme.onSurfaceVariant)),
                    ),
                    Text(
                      fmt.format(_amount),
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1,
                        color: _isExpense
                            ? AppExpenseColor.of(context)
                            : AppIncomeColor.of(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 計算機鍵盤
          CalculatorKeypad(
            initialValue: _amount,
            onChanged: (v) => setState(() => _amount = v),
          ),
          const SizedBox(height: 20),

          _label('分類'),
          const SizedBox(height: 8),
          CategoryGrid(
            selected: _category,
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 20),

          // 最近使用
          if (templates.isNotEmpty && widget.existing == null) ...[
            _label('最近使用'),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final t = templates[i];
                  final c = categoryOf(t.category);
                  return ActionChip(
                    avatar: Icon(c.icon, size: 15, color: c.color),
                    label: Text(t.title,
                        style: const TextStyle(fontSize: 12)),
                    onPressed: () => _applyTemplate(t),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          _label('明細'),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: '標題',
              prefixIcon: Icon(Icons.title, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(6),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '日期時間',
                prefixIcon: Icon(Icons.event, size: 18),
              ),
              child: Text(
                DateFormat('yyyy/MM/dd  HH:mm').format(_date),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Builder(builder: (context) {
            final wallets = context.watch<TransactionProvider>().wallets;
            final value =
                wallets.any((w) => w.name == _wallet) ? _wallet : null;
            return DropdownButtonFormField<String>(
              initialValue: value,
              decoration: const InputDecoration(
                labelText: '錢包',
                prefixIcon: Icon(Icons.account_balance_wallet, size: 18),
              ),
              items: wallets
                  .map((w) => DropdownMenuItem(
                        value: w.name,
                        child: Row(
                          children: [
                            Icon(w.icon, size: 16),
                            const SizedBox(width: 8),
                            Text(w.name),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _wallet = v ?? kDefaultWallet),
            );
          }),
          const SizedBox(height: 10),
          PlaceSearchField(
            controller: _addressCtrl,
            loadingCurrentLocation: _loadingLocation,
            onUseCurrentLocation: _getLocation,
            onPicked: (r) {
              setState(() {
                _addressCtrl.text = r.address;
                _lat = r.latitude;
                _lng = r.longitude;
                if (_titleCtrl.text.trim().isEmpty && r.name.isNotEmpty) {
                  _titleCtrl.text = r.name;
                }
              });
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: '備註',
              prefixIcon: Icon(Icons.notes, size: 18),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat.icon, size: 18, color: scheme.onPrimary),
                const SizedBox(width: 8),
                Text(widget.existing != null ? '儲存修改' : '新增記錄',
                    style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) {
    return Text(
      t,
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// 收支切換（日系扁平 segmented）
class _SegToggle extends StatelessWidget {
  final bool isExpense;
  final ValueChanged<bool> onChanged;
  const _SegToggle({required this.isExpense, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _seg(context, '支出', true),
          _seg(context, '收入', false),
        ],
      ),
    );
  }

  Widget _seg(BuildContext context, String label, bool expense) {
    final scheme = Theme.of(context).colorScheme;
    final selected = isExpense == expense;
    final activeColor =
        expense ? AppExpenseColor.of(context) : AppIncomeColor.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(expense),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? activeColor : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// 統一支出/收入色（沿用 theme palette）
class AppExpenseColor {
  static Color of(BuildContext context) => const Color(0xFFB57C70);
}

class AppIncomeColor {
  static Color of(BuildContext context) => const Color(0xFF7C9070);
}
