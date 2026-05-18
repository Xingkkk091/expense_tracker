import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../services/invoice_lottery_service.dart';
import '../theme/app_colors.dart';

/// 統一發票對獎：使用者輸入本期中獎號碼，自動掃所有 scanned 發票配對
class InvoiceLotteryScreen extends StatefulWidget {
  const InvoiceLotteryScreen({super.key});

  @override
  State<InvoiceLotteryScreen> createState() => _InvoiceLotteryScreenState();
}

class _InvoiceLotteryScreenState extends State<InvoiceLotteryScreen> {
  final _service = InvoiceLotteryService();
  WinningNumbers? _winning;
  bool _loading = true;
  List<_CheckedInvoice> _checked = [];

  @override
  void initState() {
    super.initState();
    _loadAndCheck();
  }

  Future<void> _loadAndCheck() async {
    final w = await _service.loadWinning();
    if (!mounted) return;
    setState(() => _winning = w);
    _runCheck();
  }

  void _runCheck() {
    final txs = context.read<TransactionProvider>().allTransactions;
    final w = _winning;
    final list = <_CheckedInvoice>[];
    for (final t in txs) {
      final inv = InvoiceLotteryService.extractInvoiceNumber(t.note);
      if (inv == null) continue;
      final hit = w == null ? null : InvoiceLotteryService.check(inv, w);
      list.add(_CheckedInvoice(
        invoiceNumber: inv,
        title: t.title,
        date: t.date,
        hit: hit,
      ));
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _checked = list;
      _loading = false;
    });
  }

  Future<void> _editWinning() async {
    final result = await showDialog<WinningNumbers>(
      context: context,
      builder: (_) => _WinningInputDialog(initial: _winning),
    );
    if (result == null) return;
    await _service.saveWinning(result);
    if (!mounted) return;
    setState(() => _winning = result);
    _runCheck();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,##0');
    final totalWin = _checked
        .where((c) => c.hit != null)
        .fold<int>(0, (s, c) => s + c.hit!.prize);
    final winCount = _checked.where((c) => c.hit != null).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('統一發票對獎'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '輸入中獎號碼',
            onPressed: _editWinning,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // 中獎金額卡
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: totalWin > 0
                        ? AppColors.income.withValues(alpha: 0.12)
                        : scheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: totalWin > 0
                          ? AppColors.income
                          : scheme.outline,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _winning == null ? '尚未輸入本期中獎號碼' : '${_winning!.period} 期',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        totalWin > 0
                            ? '中 NT\$ ${fmt.format(totalWin)}'
                            : '${_checked.length} 張發票 · 未中獎',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: totalWin > 0
                              ? AppColors.income
                              : scheme.onSurface,
                        ),
                      ),
                      if (winCount > 0) ...[
                        const SizedBox(height: 4),
                        Text('共中 $winCount 張',
                            style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (_winning == null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16,
                                color: scheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text('如何取得本期中獎號碼？',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. 至「財政部統一發票」官網查詢開獎結果\n'
                          '2. 點上方鉛筆 icon 輸入：\n'
                          '   • 特別獎 8 碼（千萬獎）\n'
                          '   • 特獎 8 碼（200 萬）\n'
                          '   • 頭獎 3 組 8 碼（20 萬）\n'
                          '3. 自動比對你掃描過的所有電子發票',
                          style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: _editWinning,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('輸入中獎號碼'),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
                Text(
                  '掃描過的發票（${_checked.length} 張）',
                  style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                if (_checked.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('尚未掃描任何電子發票\n首頁「掃發票」可建立掃描記錄',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  )
                else
                  for (final c in _checked) _row(c, scheme),
              ],
            ),
    );
  }

  Widget _row(_CheckedInvoice c, ColorScheme scheme) {
    final fmt = NumberFormat('#,##0');
    final formatted =
        '${c.invoiceNumber.substring(0, 2)}-${c.invoiceNumber.substring(2)}';
    final win = c.hit != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: win ? AppColors.income : scheme.outline,
          width: win ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            win
                ? Icons.emoji_events
                : Icons.receipt_long_outlined,
            color: win ? AppColors.income : scheme.onSurfaceVariant,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatted,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600)),
                Text(
                  '${c.title} · ${DateFormat('yyyy/MM/dd').format(c.date)}',
                  style: TextStyle(
                      fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (win)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(c.hit!.label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.income)),
                Text('NT\$ ${fmt.format(c.hit!.prize)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.income)),
              ],
            ),
        ],
      ),
    );
  }
}

class _CheckedInvoice {
  final String invoiceNumber;
  final String title;
  final DateTime date;
  final LotteryHit? hit;
  _CheckedInvoice({
    required this.invoiceNumber,
    required this.title,
    required this.date,
    required this.hit,
  });
}

class _WinningInputDialog extends StatefulWidget {
  final WinningNumbers? initial;
  const _WinningInputDialog({this.initial});

  @override
  State<_WinningInputDialog> createState() => _WinningInputDialogState();
}

class _WinningInputDialogState extends State<_WinningInputDialog> {
  late final TextEditingController _periodCtrl;
  late final TextEditingController _specialCtrl;
  late final TextEditingController _grandCtrl;
  late final List<TextEditingController> _firstCtrls;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _periodCtrl = TextEditingController(text: i?.period ?? _defaultPeriod());
    _specialCtrl = TextEditingController(text: i?.special ?? '');
    _grandCtrl = TextEditingController(text: i?.grand ?? '');
    _firstCtrls = List.generate(3,
        (idx) => TextEditingController(text: i?.first.elementAtOrNull(idx) ?? ''));
  }

  String _defaultPeriod() {
    final now = DateTime.now();
    // 民國年 + 雙月期數（1=1月2月期）
    final rocYear = now.year - 1911;
    final period = ((now.month - 1) ~/ 2) * 2 + 1;
    return '$rocYear-${period.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _periodCtrl.dispose();
    _specialCtrl.dispose();
    _grandCtrl.dispose();
    for (final c in _firstCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('輸入中獎號碼'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _periodCtrl,
              decoration: const InputDecoration(
                labelText: '期別（民國年-月份）',
                hintText: '例：113-11',
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            _numberField(_specialCtrl, '特別獎 (1000 萬)'),
            const SizedBox(height: 8),
            _numberField(_grandCtrl, '特獎 (200 萬)'),
            const SizedBox(height: 8),
            for (int i = 0; i < 3; i++) ...[
              _numberField(_firstCtrls[i], '頭獎 ${i + 1} (20 萬)'),
              if (i < 2) const SizedBox(height: 6),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消')),
        FilledButton(
          onPressed: () {
            final w = WinningNumbers(
              period: _periodCtrl.text.trim(),
              special: _specialCtrl.text.trim(),
              grand: _grandCtrl.text.trim(),
              first: _firstCtrls
                  .map((c) => c.text.trim())
                  .where((s) => s.isNotEmpty)
                  .toList(),
            );
            Navigator.pop(context, w);
          },
          child: const Text('儲存'),
        ),
      ],
    );
  }

  Widget _numberField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      maxLength: 8,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        hintText: '8 位數字',
        isDense: true,
        counterText: '',
      ),
      style: const TextStyle(fontFamily: 'monospace', letterSpacing: 1.5),
    );
  }
}
