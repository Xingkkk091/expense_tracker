import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/transaction_provider.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/carrier_service.dart';
import '../services/locale_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthService();
  final _backup = BackupService();
  final _carrier = CarrierService();

  bool _lockEnabled = false;
  bool _bioAvailable = false;
  bool _bioEnabled = false;
  String? _carrierCode;
  String _appVersion = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lock = await _auth.isLockEnabled();
    final canBio = await _auth.canCheckBiometric();
    final bio = await _auth.isBiometricEnabled();
    final carrier = await _carrier.get();
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _lockEnabled = lock;
      _bioAvailable = canBio;
      _bioEnabled = bio;
      _carrierCode = carrier;
      _appVersion = '${info.version}+${info.buildNumber}';
      _loading = false;
    });
  }

  Future<void> _setupPin() async {
    final pin = await _askPin(title: '設定 4 位 PIN');
    if (pin == null) return;
    final confirm = await _askPin(title: '再次輸入 PIN 確認');
    if (confirm != pin) {
      _snack('PIN 不一致');
      return;
    }
    await _auth.setPin(pin);
    await _load();
    _snack('PIN 已設定');
  }

  Future<String?> _askPin({required String title}) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
              hintText: '4 位數字', counterText: ''),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('需 4 位數字')));
                return;
              }
              Navigator.pop(context, ctrl.text);
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade600 : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _exportJson() async {
    try {
      await _backup.shareJsonBackup();
    } catch (e) {
      _snack('匯出失敗: $e', error: true);
    }
  }

  Future<void> _exportCsv() async {
    try {
      final all = context.read<TransactionProvider>().allTransactions;
      await _backup.shareCsv(all);
    } catch (e) {
      _snack('匯出失敗: $e', error: true);
    }
  }

  Future<void> _importJson() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('匯入備份？'),
        content: const Text('這會覆蓋所有現有的記帳資料，無法復原。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton.tonal(
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('確認匯入'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final ok = await _backup.importFromPickedFile();
      if (!mounted) return;
      if (ok) {
        await context.read<TransactionProvider>().load();
        _snack('匯入完成');
      }
    } catch (e) {
      _snack('匯入失敗: $e', error: true);
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清除所有資料？'),
        content: const Text(
            '所有交易、自訂分類、預算歷史都會刪除，且無法復原。\n建議先匯出備份。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('全部清除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _backup.clearAll();
      if (!mounted) return;
      await context.read<TransactionProvider>().load();
      _snack('已清除');
    } catch (e) {
      _snack('清除失敗: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        children: [
          _section(l.sectionAppearance),
          _LanguageTile(l: l),
          _section(l.sectionSecurity),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('App 鎖（PIN）'),
            subtitle: Text(_lockEnabled ? '已啟用' : '未啟用'),
            value: _lockEnabled,
            onChanged: (v) async {
              if (v) {
                await _setupPin();
              } else {
                await _auth.setLockEnabled(false);
                await _load();
              }
            },
          ),
          if (_lockEnabled && _bioAvailable)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('生物辨識解鎖'),
              subtitle: const Text('指紋 / 臉部'),
              value: _bioEnabled,
              onChanged: (v) async {
                await _auth.setBiometricEnabled(v);
                await _load();
              },
            ),
          if (_lockEnabled)
            ListTile(
              leading: const Icon(Icons.pin),
              title: const Text('變更 PIN'),
              onTap: _setupPin,
            ),

          _section(l.sectionLedger),
          ListTile(
            leading: const Icon(Icons.savings),
            title: const Text('月預算'),
            subtitle: Text(context.watch<TransactionProvider>().monthlyBudget > 0
                ? '\$${context.watch<TransactionProvider>().monthlyBudget.toStringAsFixed(0)}'
                : '未設定'),
            onTap: () => _editBudget(),
          ),
          ListTile(
            leading: const Icon(Icons.timeline),
            title: const Text('預算歷史'),
            subtitle: const Text('每月達成率趨勢'),
            onTap: () => Navigator.pushNamed(context, '/budget-history'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('帳本 / 錢包'),
            subtitle: const Text('現金、信用卡、電子支付分開記'),
            onTap: () async {
              await Navigator.pushNamed(context, '/wallets');
              await _load();
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('分類管理'),
            subtitle: const Text('新增、編輯自訂分類'),
            onTap: () => Navigator.pushNamed(context, '/categories'),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('重複記帳'),
            subtitle: const Text('房租、訂閱等定期項目'),
            onTap: () => Navigator.pushNamed(context, '/recurring'),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_2),
            title: const Text('我的載具'),
            subtitle: Text(_carrierCode ?? '未設定'),
            onTap: () async {
              await Navigator.pushNamed(context, '/carrier');
              await _load();
            },
          ),

          _section(l.sectionData),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('匯出 JSON 備份'),
            subtitle: const Text('完整備份所有資料'),
            onTap: _exportJson,
          ),
          ListTile(
            leading: const Icon(Icons.table_view),
            title: const Text('匯出 CSV'),
            subtitle: const Text('可用 Excel 開啟對帳'),
            onTap: _exportCsv,
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('匯入 JSON 備份'),
            subtitle: const Text('會覆蓋現有資料'),
            onTap: _importJson,
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red.shade400),
            title: const Text('清除所有資料'),
            subtitle: const Text('不可復原'),
            textColor: Colors.red.shade600,
            onTap: _clearAll,
          ),

          _section(l.sectionAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('版本'),
            subtitle: Text(_appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('原始碼'),
            subtitle: const Text('github.com/Xingkkk091/expense_tracker'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _editBudget() async {
    final provider = context.read<TransactionProvider>();
    final ctrl = TextEditingController(
        text: provider.monthlyBudget > 0
            ? provider.monthlyBudget.toStringAsFixed(0)
            : '');
    final value = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('設定月預算'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              prefixText: '\$ ',
              border: OutlineInputBorder(),
              hintText: '0 表示不設'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim()) ?? 0;
              Navigator.pop(context, v);
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
    if (value != null) await provider.setMonthlyBudget(value);
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final AppLocalizations l;
  const _LanguageTile({required this.l});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocaleController>();
    final current = controller.locale?.languageCode;
    String currentLabel;
    switch (current) {
      case 'zh':
        currentLabel = l.languageZh;
        break;
      case 'en':
        currentLabel = l.languageEn;
        break;
      case 'ja':
        currentLabel = l.languageJa;
        break;
      default:
        currentLabel = l.languageSystem;
    }
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l.language),
      subtitle: Text(currentLabel),
      onTap: () async {
        final picked = await showDialog<String>(
          context: context,
          builder: (_) => SimpleDialog(
            title: Text(l.language),
            children: [
              _opt(context, null, l.languageSystem, current),
              _opt(context, 'zh', l.languageZh, current),
              _opt(context, 'en', l.languageEn, current),
              _opt(context, 'ja', l.languageJa, current),
            ],
          ),
        );
        if (picked != null) {
          await controller.setLocale(
              picked == '__system__' ? null : Locale(picked));
        }
      },
    );
  }

  Widget _opt(
      BuildContext context, String? code, String label, String? current) {
    final selected = code == current;
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, code ?? '__system__'),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: 18,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
