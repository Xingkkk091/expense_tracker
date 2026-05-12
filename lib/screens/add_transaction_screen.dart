import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/location_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? existing;
  const AddTransactionScreen({super.key, this.existing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

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
      _amountCtrl.text = t.amount.toString();
      _noteCtrl.text = t.note;
      _addressCtrl.text = t.address;
      _isExpense = t.isExpense;
      _category = t.category;
      _date = t.date;
      _lat = t.latitude;
      _lng = t.longitude;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
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
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_date),
      );
      setState(() {
        _date = DateTime(picked.year, picked.month, picked.day,
            time?.hour ?? _date.hour, time?.minute ?? _date.minute);
      });
    }
  }

  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);
    final result = await LocationService().getCurrentLocation();
    setState(() => _loadingLocation = false);
    if (result != null) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
        _addressCtrl.text = result.address;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法取得位置，請確認已開啟定位權限')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TransactionProvider>();
    final t = Transaction(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.trim()),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? '編輯記錄' : '新增記錄'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 收入/支出切換
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: _TypeButton(
                        label: '支出',
                        icon: Icons.arrow_upward,
                        selected: _isExpense,
                        color: Colors.red.shade400,
                        onTap: () => setState(() => _isExpense = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TypeButton(
                        label: '收入',
                        icon: Icons.arrow_downward,
                        selected: !_isExpense,
                        color: Colors.green.shade400,
                        onTap: () => setState(() => _isExpense = false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 標題
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: '標題 *',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '請輸入標題' : null,
            ),
            const SizedBox(height: 12),

            // 金額
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: '金額 *',
                prefixIcon: Icon(Icons.attach_money),
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '請輸入金額';
                if (double.tryParse(v.trim()) == null) return '請輸入有效數字';
                if (double.parse(v.trim()) <= 0) return '金額須大於 0';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // 分類（行為）
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: '消費行為分類',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: kCategories.map((c) {
                return DropdownMenuItem(
                  value: c['label'] as String,
                  child: Text('${c['icon']}  ${c['label']}'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),

            // 日期時間
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '日期時間',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  '${_date.year}/${_date.month.toString().padLeft(2, '0')}/${_date.day.toString().padLeft(2, '0')}  '
                  '${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 地址
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: '地址',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                      hintText: '手動輸入或點擊右側自動取得',
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    const SizedBox(height: 4),
                    _loadingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                          )
                        : IconButton.filled(
                            onPressed: _getLocation,
                            icon: const Icon(Icons.my_location),
                            tooltip: '自動取得位置',
                          ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 備註
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: '備註',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(widget.existing != null ? '儲存修改' : '新增記錄',
                  style: const TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.grey, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
