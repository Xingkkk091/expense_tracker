import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  const UpdateDialog({super.key, required this.info});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final _service = UpdateService();
  bool _downloading = false;
  double _progress = 0;

  Future<void> _startUpdate() async {
    setState(() => _downloading = true);
    final file = await _service.downloadApk(
      widget.info.apkUrl,
      onProgress: (p) => setState(() => _progress = p),
    );
    if (file != null && mounted) {
      await _service.installApk(file);
      if (mounted) Navigator.pop(context);
    } else if (mounted) {
      setState(() => _downloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('下載失敗，請稍後再試')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.blue),
          const SizedBox(width: 8),
          Text('發現新版本 v${widget.info.version}'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('更新內容：',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Text(widget.info.notes.isEmpty ? '（無說明）' : widget.info.notes,
                style: const TextStyle(fontSize: 13)),
            if (_downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 6),
              Text('下載中... ${(_progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ],
        ),
      ),
      actions: _downloading
          ? null
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('稍後再說'),
              ),
              FilledButton.icon(
                onPressed: _startUpdate,
                icon: const Icon(Icons.download),
                label: const Text('立即更新'),
              ),
            ],
    );
  }
}
