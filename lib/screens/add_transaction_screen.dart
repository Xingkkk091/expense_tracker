import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/invoice_parser.dart';
import '../services/location_service.dart';
import '../widgets/amount_keypad.dart';
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

  String _amountText = '0';
  bool _isExpense = true;
  String _category = '餐飲';
  DateTime _date = DateTime.now();
  double? _lat, _lng;
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _titleCtrl.text = t.title;
      _amountText = t.amount.toStringAsFixed(t.amount.truncateToDouble() == t.amount ? 0 : 2);
      _noteCtrl.text = t.note;
      _addressCtrl.text = t.address;
      _isExpense = t.isExpense;
      _category = t.category;
      _date = t.date;
      _lat = t.latitude;
      _lng = t.longitude;
    }
    final inv = widget.invoicePrefill;
    if (inv != null) {
      _amountText = inv.total.toStringAsFixed(
          inv.total.truncateToDouble() == inv.total ? 0 : 2);
      _date = inv.date;
      // 標題：第一個品項或發票號碼
      if (inv.items.isNotEmpty) {
        _titleCtrl.text = inv.items.first.name;
      } else {
        _titleCtrl.text = '發票 ${inv.displayNumber}';
      }
      // 備註：品項清單 + 發票號碼
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

  void _onKey(String k) {
    setState(() {
      if (k == '.') {
        if (!_amountText.contains('.')) _amountText += '.';
        return;
      }
      if (_amountText == '0') {
        _amountText = k;
      } else {
        if (_amountText.length < 10) _amountText += k;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amountText.length <= 1) {
        _amountText = '0';
      } else {
        _amountText = _amountText.substring(0, _amountText.length - 1);
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message),
          behavior: SnackBarBehavior.floating,
          action: f.reason == LocationFailureReason.permissionDeniedForever
              ? SnackBarAction(
                  label: '開啟設定',
                  onPressed: () {/* requires app_settings package; skip */},
                )
              : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('無法取得位置：$e')),
      );
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountText);
    if (_titleCtrl.text.trim().isEmpty) {
      _toast('請輸入標題');
      return;
    }
    if (amount == null || amount <= 0) {
      _toast('請輸入有效金額');
      return;
    }
    final provider = context.read<TransactionProvider>();
    final t = Transaction(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      amount: amount,
      isExpense: _isExpense,
      category: _category,
      note: _noteCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      latitude: _lat,
      longitude: _lng,
      date: _date,
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
    final cat = categoryOf(_category);
    final templates =
        context.watch<TransactionProvider>().recentTemplates;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(widget.existing != null ? '編輯記錄' : '新增記錄'),
        backgroundColor: cat.color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          // 金額大字顯示 + 收支切換
          Container(
            decoration: BoxDecoration(
              color: cat.color,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
            margin: const EdgeInsets.fromLTRB(-16, 0, -16, 16),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TypeButton(
                          label: '支出',
                          icon: Icons.arrow_upward,
                          selected: _isExpense,
                          onTap: () => setState(() => _isExpense = true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TypeButton(
                          label: '收入',
                          icon: Icons.arrow_downward,
                          selected: !_isExpense,
                          onTap: () => setState(() => _isExpense = false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '\$ $_amountText',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2),
                ),
              ],
            ),
          ),

          // 最近使用範本
          if (templates.isNotEmpty && widget.existing == null) ...[
            Row(
              children: [
                const Icon(Icons.history, size: 16),
                const SizedBox(width: 4),
                Text('最近使用',
                    style: TextStyle(
                        fontSize: 13,
                        color: theme.hintColor,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final t = templates[i];
                  final c = categoryOf(t.category);
                  return ActionChip(
                    avatar: Icon(c.icon, size: 16, color: c.color),
                    label: Text(t.title),
                    onPressed: () => _applyTemplate(t),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 分類 Grid
          Text('分類',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.hintColor,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CategoryGrid(
            selected: _category,
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 16),

          // 標題
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: '標題',
              prefixIcon: Icon(Icons.title),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // 日期
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '日期時間',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              child: Text(
                '${_date.year}/${_date.month.toString().padLeft(2, '0')}/${_date.day.toString().padLeft(2, '0')}  '
                '${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}',
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 地址 + 店家搜尋
          PlaceSearchField(
            controller: _addressCtrl,
            loadingCurrentLocation: _loadingLocation,
            onUseCurrentLocation: _getLocation,
            onPicked: (r) {
              setState(() {
                _addressCtrl.text = r.address;
                _lat = r.latitude;
                _lng = r.longitude;
                // 若使用者標題還是空的，順便帶入店家名稱
                if (_titleCtrl.text.trim().isEmpty && r.name.isNotEmpty) {
                  _titleCtrl.text = r.name;
                }
              });
            },
          ),
          const SizedBox(height: 12),

          // 備註
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: '備註',
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // 金額 numpad
          Text('金額',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.hintColor,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          AmountKeypad(
            onKeyTap: _onKey,
            onBackspace: _onBackspace,
            onQuickAdd: (v) {
              final current = double.tryParse(_amountText) ?? 0;
              setState(() {
                final n = current + v;
                _amountText = n == n.truncateToDouble()
                    ? n.toStringAsFixed(0)
                    : n.toStringAsFixed(2);
              });
            },
          ),
          const SizedBox(height: 16),

          // 儲存按鈕
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: Text(widget.existing != null ? '儲存修改' : '新增記錄',
                style: const TextStyle(fontSize: 16)),
            style: FilledButton.styleFrom(
              backgroundColor: cat.color,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: Colors.white.withValues(alpha: selected ? 1 : 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
