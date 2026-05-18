import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/calculator_keypad.dart';

/// 錢包間轉帳：產生 2 筆共用 transferGroupId 的交易
/// （from 錢包扣支出、to 錢包記收入）
class WalletTransferScreen extends StatefulWidget {
  const WalletTransferScreen({super.key});

  @override
  State<WalletTransferScreen> createState() => _WalletTransferScreenState();
}

class _WalletTransferScreenState extends State<WalletTransferScreen> {
  String? _from;
  String? _to;
  double _amount = 0;
  DateTime _date = DateTime.now();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_from == null || _to == null) {
      _toast('請選擇來源與目標錢包');
      return;
    }
    if (_from == _to) {
      _toast('來源與目標需不同');
      return;
    }
    if (_amount <= 0) {
      _toast('請輸入轉帳金額');
      return;
    }
    final provider = context.read<TransactionProvider>();
    final groupId = const Uuid().v4();
    final note = _noteCtrl.text.trim();
    final fromTx = Transaction(
      id: const Uuid().v4(),
      title: '轉至 $_to',
      amount: _amount,
      isExpense: true,
      category: '其他',
      note: note.isEmpty ? '轉帳' : note,
      address: '',
      date: _date,
      wallet: _from!,
      transferGroupId: groupId,
    );
    final toTx = Transaction(
      id: const Uuid().v4(),
      title: '由 $_from 轉入',
      amount: _amount,
      isExpense: false,
      category: '其他',
      note: note.isEmpty ? '轉帳' : note,
      address: '',
      date: _date,
      wallet: _to!,
      transferGroupId: groupId,
    );
    await provider.add(fromTx);
    await provider.add(toTx);
    if (mounted) Navigator.pop(context);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _date = DateTime(
        picked.year, picked.month, picked.day, _date.hour, _date.minute));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wallets = context.watch<TransactionProvider>().wallets;
    final balances = context.watch<TransactionProvider>().walletBalances;
    final fmt = NumberFormat('#,##0');

    return Scaffold(
      appBar: AppBar(
        title: const Text('錢包轉帳'),
        actions: [
          TextButton(onPressed: _save, child: const Text('儲存')),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // From → To 視覺
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.outline),
            ),
            child: Column(
              children: [
                _walletPicker(
                  label: '從',
                  value: _from,
                  exclude: _to,
                  wallets: wallets,
                  balances: balances,
                  fmt: fmt,
                  onChanged: (v) => setState(() => _from = v),
                ),
                const SizedBox(height: 8),
                Icon(Icons.arrow_downward,
                    color: scheme.onSurfaceVariant, size: 22),
                const SizedBox(height: 8),
                _walletPicker(
                  label: '到',
                  value: _to,
                  exclude: _from,
                  wallets: wallets,
                  balances: balances,
                  fmt: fmt,
                  onChanged: (v) => setState(() => _to = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 金額
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.outline),
            ),
            child: Column(
              children: [
                Text('轉帳金額',
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(
                  'NT\$ ${NumberFormat('#,##0.##').format(_amount)}',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w300,
                      color: AppColors.neutral),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CalculatorKeypad(
            initialValue: _amount,
            onChanged: (v) => setState(() => _amount = v),
          ),
          const SizedBox(height: 16),

          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '日期',
                prefixIcon: Icon(Icons.event, size: 18),
              ),
              child: Text(DateFormat('yyyy/MM/dd').format(_date)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: '備註（可留空）',
              prefixIcon: Icon(Icons.notes, size: 18),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('完成轉帳'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '※ 將產生兩筆對應交易：來源錢包記為支出，目標錢包記為收入。刪除任一筆會一起移除。',
            style: TextStyle(
                fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _walletPicker({
    required String label,
    required String? value,
    required String? exclude,
    required List wallets,
    required Map<String, double> balances,
    required NumberFormat fmt,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.account_balance_wallet, size: 18),
      ),
      items: wallets
          .where((w) => w.name != exclude)
          .map<DropdownMenuItem<String>>((w) => DropdownMenuItem(
                value: w.name as String,
                child: Row(
                  children: [
                    Icon(w.icon, size: 16),
                    const SizedBox(width: 8),
                    Text(w.name),
                    const Spacer(),
                    Text('NT\$ ${fmt.format(balances[w.name] ?? 0)}',
                        style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
