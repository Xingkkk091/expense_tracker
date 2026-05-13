import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/carrier_service.dart';
import '../widgets/category_grid.dart';

class CarrierScreen extends StatefulWidget {
  const CarrierScreen({super.key});

  @override
  State<CarrierScreen> createState() => _CarrierScreenState();
}

class _CarrierScreenState extends State<CarrierScreen> {
  final _carrierService = CarrierService();
  String? _code;
  bool _loading = true;

  // 快速記帳
  String _amountText = '0';
  String _category = '餐飲';
  final _titleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _setMaxBrightness();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
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

  /// 把螢幕亮度開到最高（讓店員的掃描槍好掃）
  void _setMaxBrightness() {
    // 純 UI 效果，正式版可加 screen_brightness 套件控制系統亮度
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
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
            const Text(
              '請輸入您的手機條碼\n(格式: / 開頭 + 7 個字元)',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[/0-9A-Z+\-\. ]')),
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: const InputDecoration(
                hintText: '/ABCDEFG',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              '※ 載具不會上傳，僅儲存於本機',
              style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
            ),
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

  void _onKey(String k) {
    setState(() {
      if (k == '.') {
        if (!_amountText.contains('.')) _amountText += '.';
        return;
      }
      if (_amountText == '0') {
        _amountText = k;
      } else if (_amountText.length < 10) {
        _amountText += k;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _amountText = _amountText.length <= 1
          ? '0'
          : _amountText.substring(0, _amountText.length - 1);
    });
  }

  Future<void> _quickSave() async {
    final amount = double.tryParse(_amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請輸入金額')));
      return;
    }
    final title = _titleCtrl.text.trim().isEmpty
        ? _category
        : _titleCtrl.text.trim();
    final tx = Transaction(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
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
      _amountText = '0';
      _titleCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已記錄 \$${amount.toStringAsFixed(0)}'),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('我的載具'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '修改載具碼',
            onPressed: _editCarrier,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _code == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_2,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('尚未設定載具',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _editCarrier,
                          icon: const Icon(Icons.add),
                          label: const Text('設定手機條碼'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 條碼顯示卡
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      child: Column(
                        children: [
                          Text(
                            '請對準掃描器',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          // Code39 條碼
                          BarcodeWidget(
                            barcode: Barcode.code39(),
                            data: _code!,
                            width: double.infinity,
                            height: 120,
                            drawText: false,
                            color: Colors.black,
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            _code!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 22,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Divider(height: 32),
                          // 也提供 QR 版本（部分系統可掃）
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              BarcodeWidget(
                                barcode: Barcode.qrCode(),
                                data: _code!,
                                width: 90,
                                height: 90,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'QR Code 備用\n(部分終端機可使用)',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 快速記帳區
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.flash_on,
                                    size: 18,
                                    color: theme.colorScheme.primary),
                                const SizedBox(width: 6),
                                const Text('順便記一筆',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // 金額顯示
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '\$ $_amountText',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // numpad
                            _MiniKeypad(
                              onKey: _onKey,
                              onBackspace: _onBackspace,
                            ),
                            const SizedBox(height: 12),
                            // 標題（可選）
                            TextField(
                              controller: _titleCtrl,
                              decoration: const InputDecoration(
                                labelText: '標題（可留空）',
                                border: OutlineInputBorder(),
                                isDense: true,
                                prefixIcon: Icon(Icons.title),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // 分類
                            CategoryGrid(
                              selected: _category,
                              onChanged: (v) =>
                                  setState(() => _category = v),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _quickSave,
                                icon: const Icon(Icons.save),
                                label: const Text('記一筆'),
                                style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }
}

class _MiniKeypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;

  const _MiniKeypad({required this.onKey, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 2.2,
      ),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final k = keys[i];
        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => k == '⌫' ? onBackspace() : onKey(k),
            child: Center(
              child: k == '⌫'
                  ? const Icon(Icons.backspace_outlined, size: 18)
                  : Text(k,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
        );
      },
    );
  }
}
