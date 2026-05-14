import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_icons.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/category_service.dart';

class CategoryManageScreen extends StatefulWidget {
  const CategoryManageScreen({super.key});

  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen> {
  final _service = CategoryService();
  List<CustomCategory> _custom = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _service.getCustom();
    if (!mounted) return;
    setState(() {
      _custom = list;
      _loading = false;
    });
  }

  Future<void> _refreshProvider() async {
    if (mounted) {
      await context.read<TransactionProvider>().reloadMeta();
    }
  }

  Future<void> _editDialog({CustomCategory? existing}) async {
    final result = await showDialog<CustomCategory>(
      context: context,
      builder: (_) => _CategoryEditDialog(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      // 檢查名稱重複
      if (CategoryRegistry.instance.all.any((c) => c.label == result.label)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('分類名稱已存在')));
        }
        return;
      }
      await _service.add(result);
    } else {
      await _service.update(result);
    }
    await _load();
    await _refreshProvider();
  }

  Future<void> _delete(CustomCategory cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('刪除分類'),
        content: Text('確定刪除「${cat.label}」？已使用此分類的記錄不會被刪除。'),
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
    await _service.remove(cat.label);
    await _load();
    await _refreshProvider();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('分類管理')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editDialog(),
        icon: const Icon(Icons.add),
        label: const Text('新增分類'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                _sectionLabel('內建分類'),
                const SizedBox(height: 8),
                ...kBuiltInCategories.map((c) => _row(c, builtIn: true)),
                const SizedBox(height: 20),
                _sectionLabel('自訂分類'),
                const SizedBox(height: 8),
                if (_custom.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('尚無自訂分類，點右下角新增',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  )
                else
                  ..._custom.map((c) => _row(c.toInfo(),
                      builtIn: false, custom: c)),
              ],
            ),
    );
  }

  Widget _sectionLabel(String t) => Text(t,
      style: TextStyle(
          fontSize: 12,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant));

  Widget _row(CategoryInfo info,
      {required bool builtIn, CustomCategory? custom}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
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
            color: info.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(info.icon, color: info.color, size: 20),
        ),
        title: Text(info.label),
        subtitle: Text(builtIn ? '內建' : '自訂',
            style: TextStyle(
                fontSize: 11, color: scheme.onSurfaceVariant)),
        trailing: builtIn
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _editDialog(existing: custom),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: const Color(0xFFB57C70),
                    onPressed: () => _delete(custom!),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CategoryEditDialog extends StatefulWidget {
  final CustomCategory? existing;
  const _CategoryEditDialog({this.existing});

  @override
  State<_CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<_CategoryEditDialog> {
  late TextEditingController _nameCtrl;
  late int _iconIndex;
  late int _colorIndex;

  static const _palette = [
    Color(0xFFC17B6F), Color(0xFF6E8CA0), Color(0xFF9B8AA6),
    Color(0xFFB58AA0), Color(0xFFB57C70), Color(0xFF6F9089),
    Color(0xFF8A86A6), Color(0xFF7C9070), Color(0xFFC9A86A),
    Color(0xFF8C8678),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.label ?? '');
    _iconIndex = widget.existing?.iconIndex ?? 0;
    final existingColor = widget.existing?.colorValue;
    _colorIndex = existingColor != null
        ? _palette.indexWhere((c) => c.toARGB32() == existingColor).clamp(0, _palette.length - 1)
        : 0;
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
      title: Text(isEdit ? '編輯分類' : '新增分類'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              enabled: !isEdit, // 名稱當主鍵，編輯時不可改
              decoration: const InputDecoration(labelText: '分類名稱'),
              maxLength: 6,
            ),
            const SizedBox(height: 8),
            const Text('圖示', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (int i = 0; i < kSelectableIcons.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _iconIndex = i),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _iconIndex == i
                            ? _palette[_colorIndex].withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _iconIndex == i
                              ? _palette[_colorIndex]
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Icon(kSelectableIcons[i], size: 20),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('顏色', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < _palette.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _colorIndex = i),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _palette[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _colorIndex == i
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: _colorIndex == i
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
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
                  const SnackBar(content: Text('請輸入分類名稱')));
              return;
            }
            Navigator.pop(
              context,
              CustomCategory(
                label: name,
                iconIndex: _iconIndex,
                colorValue: _palette[_colorIndex].toARGB32(),
              ),
            );
          },
          child: const Text('儲存'),
        ),
      ],
    );
  }
}
