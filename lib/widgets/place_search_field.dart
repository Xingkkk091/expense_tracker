import 'dart:async';
import 'package:flutter/material.dart';
import '../services/place_search_service.dart';

/// 地址欄位 + 店家搜尋下拉建議
/// - 輸入店家名稱（例 "星巴克 信義"），停頓後彈出候選清單
/// - 點選任一項把地址、經緯度回傳給父層
class PlaceSearchField extends StatefulWidget {
  final TextEditingController controller;
  final void Function(PlaceResult result) onPicked;
  final VoidCallback onUseCurrentLocation;
  final bool loadingCurrentLocation;

  const PlaceSearchField({
    super.key,
    required this.controller,
    required this.onPicked,
    required this.onUseCurrentLocation,
    this.loadingCurrentLocation = false,
  });

  @override
  State<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<PlaceSearchField> {
  final _service = PlaceSearchService();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<PlaceResult> _results = [];
  bool _searching = false;
  bool _showSuggestions = false;
  String _lastQueried = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // 失焦延遲關閉，讓 onTap 有時間觸發
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showSuggestions = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onChange() {
    final text = widget.controller.text.trim();
    if (text.isEmpty || text == _lastQueried) {
      setState(() {
        _results = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => _doSearch(text));
  }

  Future<void> _doSearch(String q) async {
    if (q.length < 2) return;
    setState(() {
      _searching = true;
      _showSuggestions = true;
    });
    final results = await _service.search(q);
    _lastQueried = q;
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  void _pick(PlaceResult r) {
    widget.onPicked(r);
    _lastQueried = widget.controller.text;
    setState(() => _showSuggestions = false);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  labelText: '地址 / 店家名稱',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: '輸入店家名稱（如：星巴克 信義）',
                ),
                textInputAction: TextInputAction.search,
              ),
            ),
            const SizedBox(width: 8),
            widget.loadingCurrentLocation
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton.filled(
                    onPressed: widget.onUseCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    tooltip: '使用目前位置',
                  ),
          ],
        ),
        if (_showSuggestions) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 240),
            child: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('搜尋中...'),
                      ],
                    ),
                  )
                : _results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('找不到「$_lastQueried」',
                            style: TextStyle(color: theme.hintColor)),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _results.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: theme.dividerColor),
                        itemBuilder: (context, i) {
                          final r = _results[i];
                          return ListTile(
                            dense: true,
                            leading: Icon(Icons.place,
                                color: theme.colorScheme.primary, size: 20),
                            title: Text(
                              r.name.isNotEmpty ? r.name : r.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            subtitle: r.name.isNotEmpty
                                ? Text(r.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12))
                                : null,
                            onTap: () => _pick(r),
                          );
                        },
                      ),
          ),
        ],
      ],
    );
  }
}
