import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class PlaceResult {
  final String name;        // 店家名稱
  final String address;     // 完整地址
  final double latitude;
  final double longitude;

  PlaceResult({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  String get displayLabel => name.isNotEmpty ? name : address;
}

/// 使用 OpenStreetMap Nominatim 免費 API 搜尋店家/地址
/// https://nominatim.org/release-docs/develop/api/Search/
class PlaceSearchService {
  static const _endpoint = 'https://nominatim.openstreetmap.org/search';
  static const _ua =
      'expense_tracker/1.0 (https://github.com/Xingkkk091/expense_tracker)';
  // Naive LRU-like cache (in-memory only)
  static final Map<String, List<PlaceResult>> _cache = {};
  static const int _maxCacheEntries = 50;

  Future<List<PlaceResult>> search(String query,
      {String language = 'zh-TW', int limit = 8}) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final cacheKey = '$language|$q';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'q': q,
      'format': 'json',
      'addressdetails': '1',
      'namedetails': '1',
      'limit': '$limit',
      'accept-language': language,
    });

    // 重試 2 次（網路偶發失敗）
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final resp = await http.get(uri, headers: {
          'User-Agent': _ua,
        }).timeout(const Duration(seconds: 8));
        if (resp.statusCode != 200) continue;

        final body = utf8.decode(resp.bodyBytes);
        final list = json.decode(body) as List<dynamic>;
        final results =
            list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
        _putCache(cacheKey, results);
        return results;
      } catch (_) {
        if (attempt == 1) return [];
      }
    }
    return [];
  }

  /// 在指定座標的附近搜尋（用 Nominatim 的 viewbox + bounded=1）
  Future<List<PlaceResult>> searchNearby(
    String query, {
    required double centerLat,
    required double centerLng,
    double radiusKm = 3,
    String language = 'zh-TW',
    int limit = 15,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    // 算 bounding box (左,上,右,下)
    final dLat = radiusKm / 111.0;
    final cosLat = cos(centerLat * pi / 180);
    final dLng = radiusKm / (111.0 * (cosLat.abs() < 0.0001 ? 0.0001 : cosLat));
    final left = centerLng - dLng;
    final right = centerLng + dLng;
    final top = centerLat + dLat;
    final bottom = centerLat - dLat;

    final cacheKey = '$language|$q|$centerLat,$centerLng|$radiusKm';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'q': q,
      'format': 'json',
      'addressdetails': '1',
      'namedetails': '1',
      'limit': '$limit',
      'accept-language': language,
      'viewbox': '$left,$top,$right,$bottom',
      'bounded': '1',
    });

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final resp = await http.get(uri, headers: {
          'User-Agent': _ua,
        }).timeout(const Duration(seconds: 10));
        if (resp.statusCode != 200) continue;
        final body = utf8.decode(resp.bodyBytes);
        final list = json.decode(body) as List<dynamic>;
        final results =
            list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
        _putCache(cacheKey, results);
        return results;
      } catch (_) {
        if (attempt == 1) return [];
      }
    }
    return [];
  }

  /// 兩點距離（公里），用 Haversine 公式
  static double distanceKm(
      double lat1, double lng1, double lat2, double lng2) {
    const earth = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earth * c;
  }

  void _putCache(String key, List<PlaceResult> value) {
    if (_cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  PlaceResult _fromJson(Map<String, dynamic> j) {
    final fullAddress = (j['display_name'] as String?) ?? '';
    final namedetails = j['namedetails'] as Map<String, dynamic>?;
    final addressDetails = j['address'] as Map<String, dynamic>?;

    // 嘗試取得店家「名稱」
    String name = '';
    if (namedetails != null) {
      name = (namedetails['name:zh-TW'] ??
              namedetails['name:zh'] ??
              namedetails['name'] ??
              '')
          .toString();
    }
    if (name.isEmpty && addressDetails != null) {
      // 地址細節中如果有特定的店家標籤
      for (final key in ['shop', 'amenity', 'tourism', 'leisure', 'office']) {
        final v = addressDetails[key];
        if (v != null && v.toString().isNotEmpty) {
          name = v.toString();
          break;
        }
      }
    }

    return PlaceResult(
      name: name,
      address: fullAddress,
      latitude: double.tryParse(j['lat']?.toString() ?? '') ?? 0,
      longitude: double.tryParse(j['lon']?.toString() ?? '') ?? 0,
    );
  }
}
