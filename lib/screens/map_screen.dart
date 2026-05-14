import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _categoryFilter; // null = 全部
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txs = context.watch<TransactionProvider>().allTransactions;
    var withLocation = txs
        .where((t) => t.latitude != null && t.longitude != null)
        .toList();
    if (_categoryFilter != null) {
      withLocation =
          withLocation.where((t) => t.category == _categoryFilter).toList();
    }

    if (withLocation.isEmpty) {
      return Stack(
        children: [
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 72, color: Colors.grey),
                SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    '此條件下沒有含位置的記錄',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          _filterBar(),
        ],
      );
    }

    final initialCenter = LatLng(
      withLocation.first.latitude!,
      withLocation.first.longitude!,
    );

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
            MarkerLayer(
              markers: withLocation.map((t) {
                final cat = categoryOf(t.category);
                return Marker(
                  point: LatLng(t.latitude!, t.longitude!),
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () => _showDetail(context, t),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cat.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: Icon(cat.icon, color: Colors.white, size: 22),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        _filterBar(),
      ],
    );
  }

  Widget _filterBar() {
    final theme = Theme.of(context);
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('全部'),
                  selected: _categoryFilter == null,
                  onSelected: (_) => setState(() => _categoryFilter = null),
                ),
                const SizedBox(width: 4),
                for (final c in kCategories)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FilterChip(
                      avatar: Icon(c.icon, size: 16, color: c.color),
                      label: Text(c.label),
                      selected: _categoryFilter == c.label,
                      selectedColor: c.color.withValues(alpha: 0.25),
                      onSelected: (s) => setState(
                          () => _categoryFilter = s ? c.label : null),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Transaction t) {
    final cat = categoryOf(t.category);
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cat.color,
                  child: Icon(cat.icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                          '${t.category} · ${DateFormat('MM/dd HH:mm').format(t.date)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor)),
                    ],
                  ),
                ),
                Text(
                  '${t.isExpense ? '-' : '+'}\$${NumberFormat('#,##0').format(t.amount)}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: t.isExpense
                          ? Colors.red.shade500
                          : Colors.green.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (t.address.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(t.address,
                          style: const TextStyle(fontSize: 13))),
                ],
              ),
            if (t.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(t.note, style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
