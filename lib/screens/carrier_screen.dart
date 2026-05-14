import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/carrier_service.dart';
import '../widgets/calculator_keypad.dart';
import '../widgets/category_grid.dart';

enum _BarcodeMode { code39, qr }

class CarrierScreen extends StatefulWidget {
  const CarrierScreen({super.key});

  @override
  State<CarrierScreen> createState() => _CarrierScreenState();
}

class _CarrierScreenState extends State<CarrierScreen> {
  final _carrierService = CarrierService();
  String? _code;
  bool _loading = true;

  _BarcodeMode _mode = _BarcodeMode.code39;

  double _amount = 0;
  String _category = '餐飲';
  final _titleCtrl = TextEditingController();

  double? _prevBrightness;

  @override
  void initState() {
    super.initState();
    _load();
    _enableScreenWake();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _restoreScreenWake();
    super.dispose();
  }

  Future<void> _enableScreenWake() async {
    try {
      await WakelockPlus.enable();
      _prevBrightness = await ScreenBrightness.instance.application;
      await ScreenBrightness.instance.setApplicationScreenBrightness(1.0);
    } catch (e) {
      debugPrint('enableScreenWake failed: $e');
    }
  }

  Future<void> _restoreScreenWake() async {
    try {
      await WakelockPlus.disable();
      if (_prevBrightness != null) {
        await ScreenBrightness.instance.resetApplicationScreenBrightness();
      }
    } catch (e) {
      debugPrint('restoreScreenWake failed: $e');
    }
  }

  Future<void> _load() async {
    final code = await _carrierService.get();
    if (!mounted) return;
    setState(() {
      _code = code;
      _loading = false;
    });
    if (code == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _editCarrier());
    }
  }

  Future<void> _editCarrier() async {
    final ctrl = TextEditingController(text: _code ?? '/');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('設定手機條碼載具'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('格式：/ 開頭 + 7 個字元',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[/0-9A-Z+\-\. ]')),
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: const InputDecoration(hintText: '/ABCDEFG'),
              style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 18, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text('※ 載具僅儲存於本機，不會上傳',
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (!CarrierService.isValid(v)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('格式錯誤：需 / 開頭 + 7 個字元')),
                );
                return;
              }
              Navigator.pop(context, v);
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _carrierService.set(result);
      if (!mounted) return;
      setState(() => _code = result);
    }
  }

  Future<void> _quickSave() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請輸入金額')));
      return;
    }
    final title =
        _titleCtrl.text.trim().isEmpty ? _category : _titleCtrl.text.trim();
    final tx = Transaction(
      id: const Uuid().v4(),
      title: title,
      amount: _amount,
      isExpense: true,
      category: _category,
      note: '載具 $_code',
      address: '',
      latitude: null,
      longitude: null,
      date: DateTime.now(),
    );
    await context.read<TransactionProvider>().add(tx);
    if (!mounted) return;
    setState(() {
      _amount = 0;
      _titleCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已記錄 \$${NumberFormat('#,##0').format(tx.amount)}')),
    );
  }

  String _spacedCode(String c) => c.split('').join(' ');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的載具'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: '修改載具碼',
            onPressed: _editCarrier,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _code == null
              ? _emptyState(scheme)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _barcodeCard(scheme),
                    const SizedBox(height: 20),
                    _quickEntryCard(scheme),
                  ],
                ),
    );
  }

  Widget _emptyState(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('尚未設定載具'),
            const SizedBox(height: 4),
            Text('設定後可在結帳時亮給店員掃',
                style: TextStyle(
                    fontSize: 13, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _editCarrier,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('設定手機條碼'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barcodeCard(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, size: 16,
                  color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('電子發票載具',
                  style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1,
                      color: scheme.onSurfaceVariant)),
              const Spacer(),
              // 條碼/QR 切換
              _modeToggle(scheme),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: scheme.outline),
            ),
            child: _mode == _BarcodeMode.code39
                ? BarcodeWidget(
                    barcode: Barcode.code39(),
                    data: _code!,
                    height: 96,
                    drawText: false,
                    color: Colors.black,
                  )
                : Center(
                    child: BarcodeWidget(
                      barcode: Barcode.qrCode(),
                      data: _code!,
                      width: 168,
                      height: 168,
                      color: Colors.black,
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            _spacedCode(_code!),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 20,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '螢幕已自動調至最高亮度並保持喚醒',
            style: TextStyle(
                fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _modeToggle(ColorScheme scheme) {
    Widget btn(_BarcodeMode m, String label) {
      final sel = _mode == m;
      return GestureDetector(
        onTap: () => setState(() => _mode = m),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: sel ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: sel ? scheme.onPrimary : scheme.onSurfaceVariant)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(children: [
        btn(_BarcodeMode.code39, '條碼'),
        btn(_BarcodeMode.qr, 'QR'),
      ]),
    );
  }

  Widget _quickEntryCard(ColorScheme scheme) {
    final fmt = NumberFormat('#,##0.##');
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('順便記一筆',
                  style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1,
                      color: scheme.onSurfaceVariant)),
              const Spacer(),
              Text('NT\$ ${fmt.format(_amount)}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      color: scheme.onSurface)),
            ],
          ),
          const SizedBox(height: 14),
          CalculatorKeypad(
            initialValue: _amount,
            onChanged: (v) => setState(() => _amount = v),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: '標題（可留空）',
              prefixIcon: Icon(Icons.title, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          CategoryGrid(
            selected: _category,
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _quickSave,
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
            child: const Text('記一筆'),
          ),
        ],
      ),
    );
  }
}
