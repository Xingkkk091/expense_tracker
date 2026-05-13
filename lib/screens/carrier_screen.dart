import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/carrier_service.dart';
import '../widgets/category_grid.dart';

enum _BarcodeMode { code39, qr }

class CarrierScreen extends StatefulWidget {
  const CarrierScreen({super.key});

  @override
  State<CarrierScreen> createState() => _CarrierScreenState();
}

class _CarrierScreenState extends State<CarrierScreen>
    with SingleTickerProviderStateMixin {
  final _carrierService = CarrierService();
  String? _code;
  bool _loading = true;

  _BarcodeMode _mode = _BarcodeMode.code39;
  late final AnimationController _pulseCtrl;

  // 快速記帳
  String _amountText = '0';
  String _category = '餐飲';
  final _titleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _pulseCtrl.dispose();
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

  Future<void> _editCarrier() async {
    final ctrl = TextEditingController(text: _code ?? '/');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_2),
            SizedBox(width: 8),
            Text('設定手機條碼載具'),
          ],
        ),
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
              style:
                  TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
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
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('已記錄 \$${amount.toStringAsFixed(0)}'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 把載具碼格式化得更易讀，如 /ABC1234 -> / A B C 1 2 3 4
  String _formattedCode(String code) {
    if (code.isEmpty) return '';
    return code.split('').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1115) : const Color(0xFFF2F4F8),
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        title: const Text('我的載具',
            style: TextStyle(fontWeight: FontWeight.w600)),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '修改載具碼',
            onPressed: _editCarrier,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _code == null
              ? _buildEmptyState(theme)
              : _buildContent(theme, isDark),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.qr_code_2,
                  size: 48, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            const Text('尚未設定載具',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('設定後即可在結帳時亮給店員掃',
                style: TextStyle(color: theme.hintColor)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _editCarrier,
              icon: const Icon(Icons.add),
              label: const Text('設定手機條碼'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              _buildHeroCard(theme, isDark),
              const SizedBox(height: 24),
              _buildQuickEntryCard(theme),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  /// 主視覺：類似「數位錢包卡片」的條碼顯示
  Widget _buildHeroCard(ThemeData theme, bool isDark) {
    const cardColor = Color(0xFF1E3A8A);   // deep navy
    const accent = Color(0xFF60A5FA);      // light blue accent

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B5BDB), Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(isDark ? 0.5 : 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 裝飾性圓圈
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 卡片頂部 label + pulse 指示
                Row(
                  children: [
                    const Icon(Icons.receipt_long,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    const Text('電子發票載具',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1)),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(
                                0.4 + _pulseCtrl.value * 0.6),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '可掃描',
                      style: TextStyle(
                          color: accent, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 條碼/QR 切換
                _modeSwitch(),
                const SizedBox(height: 20),
                // 條碼或 QR
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  child: _mode == _BarcodeMode.code39
                      ? BarcodeWidget(
                          barcode: Barcode.code39(),
                          data: _code!,
                          height: 110,
                          drawText: false,
                          color: Colors.black,
                        )
                      : Center(
                          child: BarcodeWidget(
                            barcode: Barcode.qrCode(),
                            data: _code!,
                            width: 180,
                            height: 180,
                            color: Colors.black,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                // 載具碼（格式化顯示）
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tag, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SelectableText(
                          _formattedCode(_code!),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          await Clipboard.setData(
                              ClipboardData(text: _code!));
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('載具碼已複製'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 1)),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.content_copy,
                              color: Colors.white70, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 提示
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.white.withOpacity(0.7), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '請將螢幕對準掃描器，必要時將亮度調至最高',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: _modeButton(_BarcodeMode.code39, '一維條碼', Icons.barcode_reader)),
          Expanded(child: _modeButton(_BarcodeMode.qr, 'QR Code', Icons.qr_code)),
        ],
      ),
    );
  }

  Widget _modeButton(_BarcodeMode mode, String label, IconData icon) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? const Color(0xFF1E3A8A) : Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? const Color(0xFF1E3A8A)
                        : Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickEntryCard(ThemeData theme) {
    final amount = double.tryParse(_amountText) ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
                theme.brightness == Brightness.dark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.flash_on,
                    color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('順便記一筆',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (amount > 0)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Chip(
                    key: ValueKey(amount),
                    label: Text('\$ ${amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // 金額顯示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.1),
                  theme.colorScheme.primary.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '\$',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _amountText,
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _MiniKeypad(onKey: _onKey, onBackspace: _onBackspace),
          const SizedBox(height: 14),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: '標題（可留空，預設使用分類名）',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              isDense: true,
              prefixIcon: const Icon(Icons.title, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.category_outlined, size: 16),
              const SizedBox(width: 6),
              Text('選擇分類',
                  style: TextStyle(
                      fontSize: 13,
                      color: theme.hintColor,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          CategoryGrid(
            selected: _category,
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _quickSave,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('記一筆',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
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
    final theme = Theme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 2.4,
      ),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final k = keys[i];
        final isBackspace = k == '⌫';
        return Material(
          color: isBackspace
              ? theme.colorScheme.errorContainer.withOpacity(0.4)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => isBackspace ? onBackspace() : onKey(k),
            child: Center(
              child: isBackspace
                  ? Icon(Icons.backspace_outlined,
                      size: 18, color: theme.colorScheme.error)
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
