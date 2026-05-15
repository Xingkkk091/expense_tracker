import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/food_picker_service.dart';
import 'add_transaction_screen.dart';

class FoodPickerScreen extends StatefulWidget {
  const FoodPickerScreen({super.key});

  @override
  State<FoodPickerScreen> createState() => _FoodPickerScreenState();
}

class _FoodPickerScreenState extends State<FoodPickerScreen> {
  final _service = FoodPickerService();
  final _random = Random();

  FoodTheme _theme = FoodTheme.any;
  List<String> _foods = [];
  String _display = '？';
  String? _result;
  bool _rolling = false;
  Timer? _rollTimer;

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  @override
  void dispose() {
    _rollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFoods() async {
    final foods = await _service.getFoods(_theme);
    if (!mounted) return;
    setState(() {
      _foods = foods;
      _display = foods.isNotEmpty ? foods.first : '？';
      _result = null;
    });
  }

  void _roll() {
    if (_rolling || _foods.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _rolling = true;
      _result = null;
    });

    int elapsed = 0;
    const total = 1600; // ms
    int interval = 50;

    void tick() {
      _rollTimer = Timer(Duration(milliseconds: interval), () {
        if (!mounted) return;
        setState(() {
          _display = _foods[_random.nextInt(_foods.length)];
        });
        HapticFeedback.selectionClick();
        elapsed += interval;
        // 後段逐漸放慢，營造「快停下」的感覺
        if (elapsed > total * 0.6) interval += 14;
        if (elapsed >= total) {
          final picked = _foods[_random.nextInt(_foods.length)];
          setState(() {
            _display = picked;
            _result = picked;
            _rolling = false;
          });
          HapticFeedback.heavyImpact();
        } else {
          tick();
        }
      });
    }

    tick();
  }

  Future<void> _changeTheme(FoodTheme t) async {
    if (_rolling) return;
    setState(() => _theme = t);
    await _loadFoods();
  }

  Future<void> _manageFoods() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ManageFoodsSheet(theme: _theme, service: _service),
    );
    await _loadFoods();
  }

  void _recordIt() {
    if (_result == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          prefillTitle: _result,
          prefillCategory: '餐飲',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('今晚吃什麼'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: '管理選項',
            onPressed: _manageFoods,
          ),
        ],
      ),
      body: Column(
        children: [
          // 主題選擇
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final t in FoodTheme.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 3, vertical: 8),
                    child: ChoiceChip(
                      avatar: Icon(t.icon,
                          size: 16,
                          color: _theme == t
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant),
                      label: Text(t.label),
                      selected: _theme == t,
                      labelStyle: TextStyle(
                          fontSize: 12,
                          color: _theme == t
                              ? scheme.onPrimary
                              : scheme.onSurface),
                      onSelected: (_) => _changeTheme(t),
                    ),
                  ),
              ],
            ),
          ),
          if (_theme == FoodTheme.gentle)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('腸胃不適時，已過濾為清淡、好消化的選項',
                        style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ),

          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 轉盤結果卡
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 260,
                    padding: const EdgeInsets.symmetric(
                        vertical: 44, horizontal: 24),
                    decoration: BoxDecoration(
                      color: _result != null
                          ? scheme.primary
                          : scheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _result != null
                            ? scheme.primary
                            : scheme.outline,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _rolling
                              ? '抽選中…'
                              : (_result != null ? '就決定是你了！' : '今晚吃什麼？'),
                          style: TextStyle(
                            fontSize: 13,
                            color: _result != null
                                ? scheme.onPrimary.withValues(alpha: 0.8)
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _display,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                            color: _result != null
                                ? scheme.onPrimary
                                : scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // 轉動按鈕
                  SizedBox(
                    width: 200,
                    child: FilledButton.icon(
                      onPressed: _rolling ? null : _roll,
                      icon: Icon(_rolling
                          ? Icons.hourglass_top
                          : Icons.casino),
                      label: Text(_rolling
                          ? '抽選中…'
                          : (_result != null ? '再抽一次' : '開始抽選')),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_result != null)
                    SizedBox(
                      width: 200,
                      child: OutlinedButton.icon(
                        onPressed: _recordIt,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('吃這個・記一筆'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text('${_theme.label}：共 ${_foods.length} 個選項',
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 管理某主題的食物選項
class _ManageFoodsSheet extends StatefulWidget {
  final FoodTheme theme;
  final FoodPickerService service;
  const _ManageFoodsSheet({required this.theme, required this.service});

  @override
  State<_ManageFoodsSheet> createState() => _ManageFoodsSheetState();
}

class _ManageFoodsSheetState extends State<_ManageFoodsSheet> {
  final _ctrl = TextEditingController();
  List<String> _custom = [];
  List<String> _all = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final custom = await widget.service.getCustom(widget.theme);
    final all = await widget.service.getFoods(widget.theme);
    if (!mounted) return;
    setState(() {
      _custom = custom;
      _all = all;
    });
  }

  Future<void> _add() async {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    await widget.service.addCustom(widget.theme, v);
    _ctrl.clear();
    await _load();
  }

  Future<void> _remove(String f) async {
    await widget.service.removeCustom(widget.theme, f);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: scheme.outline,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('管理「${widget.theme.label}」選項',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    hintText: '新增自訂選項',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _add, child: const Text('新增')),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _all.map((f) {
                  final isCustom = _custom.contains(f);
                  return Chip(
                    label: Text(f, style: const TextStyle(fontSize: 12)),
                    backgroundColor: isCustom
                        ? scheme.primaryContainer
                        : scheme.surface,
                    deleteIcon: isCustom
                        ? const Icon(Icons.close, size: 14)
                        : null,
                    onDeleted: isCustom ? () => _remove(f) : null,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('灰色為內建選項，無法刪除；彩色為自訂',
              style: TextStyle(
                  fontSize: 11, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
