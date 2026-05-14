import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _categoryFilter;
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// 把同經緯度(取小數4位)的交易聚成同一個點，以便「點地點看歷史」
  Map<String, List<Transaction>> _groupByLocation(List<Transaction> txs) {
    final map = <String, List<Transaction>>{};
    for (final t in txs) {
      final key =
          '${t.latitude!.toStringAsFixed(4)},${t.longitude!.toStringAsFixed(4)}';
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final txs = context.watch<TransactionProvider>().allTransactions;
    var withLocation =
        txs.where((t) => t.latitude != null && t.longitude != null).toList();
    if (_categoryFilter != null) {
      withLocation =
          withLocation.where((t) => t.category == _categoryFilter).toList();
    }

    if (withLocation.isEmpty) {
      return Stack(
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('此條件下沒有含位置的記錄',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            ),
          ),
          _filterBar(),
        ],
      );
    }

    final groups = _groupByLocation(withLocation);
    final initialCenter =
        LatLng(withLocation.first.latitude!, withLocation.first.longitude!);

    final markers = groups.entries.map((entry) {
      final items = entry.value;
      final first = items.first;
      final cat = categoryOf(first.category);
      return Marker(
        point: LatLng(first.latitude!, first.longitude!),
        width: 46,
        height: 46,
        child: GestureDetector(
          onTap: () => _showLocationHistory(context, items),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: cat.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(cat.icon, color: Colors.white, size: 22),
              ),
              if (items.length > 1)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3D3A34),
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text('${items.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 14,
            minZoom: 3,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.expense_tracker',
            ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 48,
                size: const Size(40, 40),
                markers: markers,
                builder: (context, clusterMarkers) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${clusterMarkers.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        _filterBar(),
      ],
    );
  }

  Widget _filterBar() {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outline),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('全部', _categoryFilter == null,
                    () => setState(() => _categoryFilter = null)),
                for (final c in kCategories)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _chip(
                      c.label,
                      _categoryFilter == c.label,
                      () => setState(() => _categoryFilter =
                          _categoryFilter == c.label ? null : c.label),
                      icon: c.icon,
                      color: c.color,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap,
      {IconData? icon, Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected ? scheme.primary : scheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: selected ? scheme.onPrimary : (color ?? scheme.onSurface)),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color:
                        selected ? scheme.onPrimary : scheme.onSurface)),
          ],
        ),
      ),
    );
  }

  /// 點地點 → 列出該地所有交易（歷史）
  void _showLocationHistory(BuildContext context, List<Transaction> items) {
    final fmt = NumberFormat('#,##0');
    final total = items.fold<double>(
        0, (s, t) => s + (t.isExpense ? t.amount : 0));
    final addr = items.first.address;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        builder: (context, scrollCtrl) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            addr.isEmpty ? '此地點' : addr,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '共 ${items.length} 筆 · 累計支出 NT\$ ${fmt.format(total)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = items[i];
                    final cat = categoryOf(t.category);
                    return ListTile(
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:
                            Icon(cat.icon, color: cat.color, size: 18),
                      ),
                      title: Text(t.title),
                      subtitle: Text(
                        '${t.category} · ${DateFormat('yyyy/MM/dd HH:mm').format(t.date)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        '${t.isExpense ? '-' : '+'}\$${fmt.format(t.amount)}',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: t.isExpense
                                ? AppColors.expense
                                : AppColors.income),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
