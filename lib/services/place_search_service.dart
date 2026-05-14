import 'dart:convert';
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
