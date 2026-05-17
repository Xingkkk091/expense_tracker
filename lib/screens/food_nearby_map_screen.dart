import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/place_search_service.dart';
import '../theme/app_colors.dart';
import 'add_transaction_screen.dart';

/// 顯示「附近的 ${food}」店家地圖
class FoodNearbyMapScreen extends StatefulWidget {
  final String food;
  const FoodNearbyMapScreen({super.key, required this.food});

  @override
  State<FoodNearbyMapScreen> createState() => _FoodNearbyMapScreenState();
}

class _FoodNearbyMapScreenState extends State<FoodNearbyMapScreen> {
  final _placeService = PlaceSearchService();
  final _mapController = MapController();

  bool _loading = true;
  String? _errorMessage;
  double? _myLat;
  double? _myLng;
  List<PlaceResult> _places = [];
  double _radiusKm = 3;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final loc = await LocationService().getCurrentLocation();
      _myLat = loc.latitude;
      _myLng = loc.longitude;
      await _searchPlaces();
    } on LocationFailure catch (f) {
      setState(() {
        _loading = false;
        _errorMessage = f.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = '無法取得位置：$e';
      });
    }
  }

  Future<void> _searchPlaces() async {
    if (_myLat == null || _myLng == null) return;
    setState(() => _loading = true);
    final results = await _placeService.searchNearby(
      widget.food,
      centerLat: _myLat!,
      centerLng: _myLng!,
      radiusKm: _radiusKm,
      limit: 20,
    );
    // 依距離由近到遠排序
    results.sort((a, b) {
      final da = PlaceSearchService.distanceKm(
          _myLat!, _myLng!, a.latitude, a.longitude);
      final db = PlaceSearchService.distanceKm(
          _myLat!, _myLng!, b.latitude, b.longitude);
      return da.compareTo(db);
    });
    if (!mounted) return;
    setState(() {
      _places = results;
      _loading = false;
    });
  }

  void _showPlaceDetail(PlaceResult p) {
    final distance = PlaceSearchService.distanceKm(
        _myLat!, _myLng!, p.latitude, p.longitude);
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.expense,
                  child: const Icon(Icons.restaurant, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.displayLabel,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      Text('距離約 ${_fmtDistance(distance)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (p.address.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(p.address,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddTransactionScreen(
                        prefillTitle: p.name.isNotEmpty ? p.name : widget.food,
                        prefillCategory: '餐飲',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('來這家吃・記一筆'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDistance(double km) {
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} 公尺';
    return '${km.toStringAsFixed(1)} 公里';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('附近的「${widget.food}」'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新搜尋',
            onPressed: _loading ? null : _bootstrap,
          ),
        ],
      ),
      body: _errorMessage != null
          ? _errorView(scheme)
          : _loading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        _myLat == null
                            ? '正在取得位置…'
                            : '搜尋附近的「${widget.food}」…',
                        style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // 搜尋結果統計 + 範圍切換
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        border: Border(
                            bottom: BorderSide(color: scheme.outline)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.place,
                              size: 16, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _places.isEmpty
                                  ? '附近 ${_radiusKm.toStringAsFixed(0)} 公里內找不到「${widget.food}」'
                                  : '${_radiusKm.toStringAsFixed(0)} 公里內找到 ${_places.length} 間',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          SegmentedButton<double>(
                            segments: const [
                              ButtonSegment(value: 1, label: Text('1km')),
                              ButtonSegment(value: 3, label: Text('3km')),
                              ButtonSegment(value: 5, label: Text('5km')),
                            ],
                            selected: {_radiusKm},
                            onSelectionChanged: (s) {
                              setState(() => _radiusKm = s.first);
                              _searchPlaces();
                            },
                            showSelectedIcon: false,
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              textStyle: WidgetStateProperty.all(
                                  const TextStyle(fontSize: 10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(_myLat!, _myLng!),
                          initialZoom: _places.isEmpty ? 14 : 15,
                          minZoom: 3,
                          maxZoom: 19,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.example.expense_tracker',
                          ),
                          // 範圍圓圈
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: LatLng(_myLat!, _myLng!),
                                radius: _radiusKm * 1000,
                                useRadiusInMeter: true,
                                color: scheme.primary.withValues(alpha: 0.08),
                                borderColor:
                                    scheme.primary.withValues(alpha: 0.5),
                                borderStrokeWidth: 1,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              // 我的位置
                              Marker(
                                point: LatLng(_myLat!, _myLng!),
                                width: 24,
                                height: 24,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                  ),
                                ),
                              ),
                              // 店家
                              ..._places.asMap().entries.map((e) {
                                final i = e.key;
                                final p = e.value;
                                return Marker(
                                  point: LatLng(p.latitude, p.longitude),
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () => _showPlaceDetail(p),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.expense,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text('${i + 1}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_places.isNotEmpty)
                      Container(
                        height: 116,
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          border: Border(
                              top: BorderSide(color: scheme.outline)),
                        ),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          itemCount: _places.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final p = _places[i];
                            final dist =
                                PlaceSearchService.distanceKm(
                                    _myLat!, _myLng!, p.latitude, p.longitude);
                            return GestureDetector(
                              onTap: () {
                                _mapController.move(
                                    LatLng(p.latitude, p.longitude), 17);
                                _showPlaceDetail(p);
                              },
                              child: Container(
                                width: 200,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: scheme.outline),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                              color: AppColors.expense,
                                              shape: BoxShape.circle),
                                          alignment: Alignment.center,
                                          child: Text('${i + 1}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            p.displayLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(p.address,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: scheme.onSurfaceVariant)),
                                    const Spacer(),
                                    Text('距離 ${_fmtDistance(dist)}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: scheme.primary)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _errorView(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off,
                size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(_errorMessage ?? '無法取得位置',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _bootstrap,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重試'),
            ),
          ],
        ),
      ),
    );
  }
}
