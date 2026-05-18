import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../services/auto_backup_service.dart';

class AutoBackupScreen extends StatefulWidget {
  const AutoBackupScreen({super.key});

  @override
  State<AutoBackupScreen> createState() => _AutoBackupScreenState();
}

class _AutoBackupScreenState extends State<AutoBackupScreen> {
  final _service = AutoBackupService();
  bool _enabled = true;
  DateTime? _lastTime;
  List<AutoBackupInfo> _backups = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await _service.isEnabled();
    final t = await _service.getLastBackupTime();
    final list = await _service.list();
    if (!mounted) return;
    setState(() {
      _enabled = e;
      _lastTime = t;
      _backups = list;
      _loading = false;
    });
  }

  Future<void> _backupNow() async {
    setState(() => _busy = true);
    final f = await _service.runBackup();
    if (!mounted) return;
    setState(() => _busy = false);
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(f != null ? '已備份' : '備份失敗'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _restore(AutoBackupInfo b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('從備份還原？'),
        content: Text(
            '會覆蓋目前所有資料，改成 ${DateFormat('MM/dd HH:mm').format(b.createdAt)} 的版本。\n\n還原前是否先做一次當前資料的備份？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('確認還原'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    // 還原前先做一次當前資料備份（保險）
    await _service.runBackup();
    final ok = await _service.restoreFromFile(b.path);
    if (!mounted) return;
    if (ok) {
      await context.read<TransactionProvider>().load();
    }
    setState(() => _busy = false);
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '已還原' : '還原失敗'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _delete(AutoBackupInfo b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('刪除備份'),
        content: Text('確認刪除 ${DateFormat('MM/dd HH:mm').format(b.createdAt)} 的備份？'),
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
    await _service.deleteBackup(b.path);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('自動備份'),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: '立即備份',
              onPressed: _busy ? null : _backupNow,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('App 內備份',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '每次新增/編輯/刪除交易自動存一份 JSON 到 App 私有目錄，'
                        '最多保留 5 份。萬一誤刪或想回到先前狀態，可從清單還原。\n\n'
                        '注意：App 私有目錄會在「解除安裝」時被清掉。Android 自動備份'
                        '（Google 雲端）會把這些檔案備份到你的 Google 帳號，'
                        '重灌時若使用同一帳號會自動還原。',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('啟用自動備份'),
                  subtitle: Text(_lastTime == null
                      ? '尚未備份'
                      : '上次備份：${DateFormat('yyyy/MM/dd HH:mm').format(_lastTime!)}'),
                  value: _enabled,
                  onChanged: (v) async {
                    await _service.setEnabled(v);
                    await _load();
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '備份檔（最多 5 份）',
                  style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                if (_backups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('尚無備份檔',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  )
                else
                  for (final b in _backups)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scheme.outline),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.archive_outlined),
                        title: Text(
                            DateFormat('yyyy/MM/dd HH:mm').format(b.createdAt)),
                        subtitle: Text(
                          '${b.txCount != null ? "${b.txCount} 筆 · " : ""}'
                          '${(b.sizeBytes / 1024).toStringAsFixed(1)} KB',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restore, size: 20),
                              tooltip: '還原',
                              onPressed: _busy ? null : () => _restore(b),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: const Color(0xFFB57C70),
                              tooltip: '刪除',
                              onPressed: _busy ? null : () => _delete(b),
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
