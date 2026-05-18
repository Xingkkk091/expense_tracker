import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/transaction_provider.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/carrier_service.dart';
import '../services/locale_controller.dart';
import '../services/notification_service.dart';

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
            title: Text(l.appLock),
            subtitle:
                Text(_lockEnabled ? l.appLockEnabled : l.appLockDisabled),
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
              title: Text(l.biometric),
              subtitle: Text(l.biometricSub),
              value: _bioEnabled,
              onChanged: (v) async {
                await _auth.setBiometricEnabled(v);
                await _load();
              },
            ),
          if (_lockEnabled)
            ListTile(
              leading: const Icon(Icons.pin),
              title: Text(l.changePin),
              onTap: _setupPin,
            ),

          _section(l.sectionLedger),
          ListTile(
            leading: const Icon(Icons.savings),
            title: Text(l.monthlyBudget),
            subtitle: Text(context.watch<TransactionProvider>().monthlyBudget > 0
                ? '\$${context.watch<TransactionProvider>().monthlyBudget.toStringAsFixed(0)}'
                : l.notSet),
            onTap: () => _editBudget(),
          ),
          ListTile(
            leading: const Icon(Icons.timeline),
            title: Text(l.menuBudgetHistory),
            subtitle: Text(l.menuBudgetHistorySub),
            onTap: () => Navigator.pushNamed(context, '/budget-history'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: Text(l.menuWallets),
            subtitle: Text(l.menuWalletsSub),
            onTap: () async {
              await Navigator.pushNamed(context, '/wallets');
              await _load();
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: Text(l.menuCategories),
            subtitle: Text(l.menuCategoriesSub),
            onTap: () => Navigator.pushNamed(context, '/categories'),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: Text(l.menuRecurring),
            subtitle: Text(l.menuRecurringSub),
            onTap: () => Navigator.pushNamed(context, '/recurring'),
          ),
          ListTile(
            leading: const Icon(Icons.subscriptions),
            title: const Text('訂閱 / 定期費用'),
            subtitle: const Text('Netflix、房租、訂閱費月支出一覽'),
            onTap: () => Navigator.pushNamed(context, '/subscriptions'),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_2),
            title: Text(l.myCarrier),
            subtitle: Text(_carrierCode ?? l.notSet),
            onTap: () async {
              await Navigator.pushNamed(context, '/carrier');
              await _load();
            },
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('統一發票對獎'),
            subtitle: const Text('自動比對掃描過的電子發票'),
            onTap: () => Navigator.pushNamed(context, '/invoice-lottery'),
          ),

          _section('通知'),
          const _NotificationTile(),

          _section(l.sectionData),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('自動備份'),
            subtitle: const Text('每次變動自動存檔，保留最近 5 份'),
            onTap: () => Navigator.pushNamed(context, '/auto-backup'),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: Text(l.exportJson),
            subtitle: Text(l.exportJsonSub),
            onTap: _exportJson,
          ),
          ListTile(
            leading: const Icon(Icons.table_view),
            title: Text(l.exportCsv),
            subtitle: Text(l.exportCsvSub),
            onTap: _exportCsv,
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: Text(l.importJson),
            subtitle: Text(l.importJsonSub),
            onTap: _importJson,
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red.shade400),
            title: Text(l.clearData),
            subtitle: Text(l.clearDataSub),
            textColor: Colors.red.shade600,
            onTap: _clearAll,
          ),

          _section(l.sectionAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l.version),
            subtitle: Text(_appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(l.sourceCode),
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

class _NotificationTile extends StatefulWidget {
  const _NotificationTile();

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  final _notif = NotificationService();
  bool _dailyEnabled = false;
  int _hour = 21;
  int _minute = 0;
  bool _budgetEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await _notif.isDailyEnabled();
    final t = await _notif.getDailyTime();
    final b = await _notif.isBudgetAlertEnabled();
    if (!mounted) return;
    setState(() {
      _dailyEnabled = d;
      _hour = t.hour;
      _minute = t.minute;
      _budgetEnabled = b;
      _loading = false;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked == null) return;
    await _notif.setDailyReminder(
      enabled: true,
      hour: picked.hour,
      minute: picked.minute,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ListTile(
        leading: Icon(Icons.notifications_outlined),
        title: Text('讀取中…'),
      );
    }
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: const Text('每日記帳提醒'),
          subtitle: Text(_dailyEnabled
              ? '每天 ${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} 提醒'
              : '關閉'),
          value: _dailyEnabled,
          onChanged: (v) async {
            await _notif.setDailyReminder(
              enabled: v,
              hour: _hour,
              minute: _minute,
            );
            await _load();
          },
        ),
        if (_dailyEnabled)
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('提醒時間'),
            subtitle:
                Text('${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}'),
            onTap: _pickTime,
          ),
        SwitchListTile(
          secondary: const Icon(Icons.warning_amber),
          title: const Text('預算超支提醒'),
          subtitle: const Text('預算用到 70%、90%、100% 時通知'),
          value: _budgetEnabled,
          onChanged: (v) async {
            await _notif.setBudgetAlertEnabled(v);
            await _load();
          },
        ),
      ],
    );
  }
}
