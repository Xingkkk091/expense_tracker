import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_icons.dart';
import '../providers/transaction_provider.dart';
import '../services/wallet_service.dart';

class WalletManageScreen extends StatefulWidget {
  const WalletManageScreen({super.key});

  @override
  State<WalletManageScreen> createState() => _WalletManageScreenState();
}

class _WalletManageScreenState extends State<WalletManageScreen> {
  final _service = WalletService();
  List<WalletInfo> _wallets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.ensureDefault();
    final list = await _service.getAll();
    if (!mounted) return;
    setState(() {
      _wallets = list;
      _loading = false;
    });
  }

  Future<void> _refreshProvider() async {
    if (mounted) await context.read<TransactionProvider>().reloadMeta();
  }

  Future<void> _editDialog({WalletInfo? existing}) async {
    final result = await showDialog<WalletInfo>(
      context: context,
      builder: (_) => _WalletEditDialog(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      if (_wallets.any((w) => w.name == result.name)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('錢包名稱已存在')));
        }
        return;
      }
      await _service.add(result.name, result.iconIndex);
    } else {
      await _service.update(result.name, result.iconIndex);
    }
    await _load();
    await _refreshProvider();
  }

  Future<void> _delete(WalletInfo w) async {
    if (_wallets.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('至少需保留一個錢包')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('刪除錢包'),
        content: Text('確定刪除「${w.name}」？此錢包的記錄不會被刪除，但會失去歸屬。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB57C70)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.remove(w.name);
    await _load();
    await _refreshProvider();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final balances =
        context.watch<TransactionProvider>().walletBalances;
    final fmt = NumberFormat('#,##0');
    return Scaffold(
      appBar: AppBar(title: const Text('帳本 / 錢包')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editDialog(),
        icon: const Icon(Icons.add),
        label: const Text('新增錢包'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                for (final w in _wallets)
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
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(w.icon, size: 20),
                      ),
                      title: Text(w.name),
                      subtitle: Text(
                        '餘額 NT\$ ${fmt.format(balances[w.name] ?? 0)}',
                        style: TextStyle(
                            fontSize: 12,
                            color: (balances[w.name] ?? 0) >= 0
                                ? const Color(0xFF7C9070)
                                : const Color(0xFFB57C70)),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _editDialog(existing: w),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.delete_outline, size: 18),
                            color: const Color(0xFFB57C70),
                            onPressed: () => _delete(w),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _WalletEditDialog extends StatefulWidget {
  final WalletInfo? existing;
  const _WalletEditDialog({this.existing});

  @override
  State<_WalletEditDialog> createState() => _WalletEditDialogState();
}

class _WalletEditDialogState extends State<_WalletEditDialog> {
  late TextEditingController _nameCtrl;
  late int _iconIndex;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _iconIndex = widget.existing?.iconIndex ?? 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? '編輯錢包' : '新增錢包'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            enabled: !isEdit,
            decoration: const InputDecoration(labelText: '錢包名稱'),
            maxLength: 8,
          ),
          const SizedBox(height: 8),
          const Text('圖示', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < kWalletIcons.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _iconIndex = i),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _iconIndex == i
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _iconIndex == i
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Icon(kWalletIcons[i], size: 22),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消')),
        FilledButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('請輸入錢包名稱')));
              return;
            }
            Navigator.pop(
                context, WalletInfo(name: name, iconIndex: _iconIndex));
          },
          child: const Text('儲存'),
        ),
      ],
    );
  }
}
