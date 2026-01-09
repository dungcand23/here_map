import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../models/stop_model.dart';
import 'analytics_service.dart';
import 'api_exceptions.dart';

class SearchService {
  // Cache ngắn hạn để giảm quota + tăng cảm giác mượt.
  static final Map<String, ({DateTime t, List<StopModel> items})> _cache = {};

  /// HERE Autosuggest
  /// query: text người dùng nhập
  /// lat/lng: vị trí trung tâm (để ưu tiên kết quả gần)
  static Future<List<StopModel>> autosuggest({
    required String query,
    required double lat,
    required double lng,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    if (!AppConfig.hasHereApiKey) {
      throw const MissingApiKeyException();
    }

    final cacheKey =
        '${q.toLowerCase()}|${lat.toStringAsFixed(3)}|${lng.toStringAsFixed(3)}';
    final cached = _cache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.t).inSeconds < 30) {
      return cached.items;
    }

    final params = <String, String>{
      'q': q,
      'apiKey': AppConfig.hereApiKey,
      'limit': '12',
      // Improve Vietnamese UX (still works even if HERE falls back to default language)
      'lang': 'vi-VN',
      // Ask HERE to return richer address details when available.
      // This helps us show better suggestion subtitles (street/city/country).
      'show': 'details',
    };

    // TMS scope (VN) — nếu bạn muốn global, chỉ cần xoá dòng này.
    // 'in' giúp suggestion cụ thể hơn, tránh trả kết quả ở nước khác khi query ngắn.
    params['in'] = 'countryCode:VNM';

    // Nếu không có location (0,0) thì bỏ at để tránh bias sai.
    if (lat != 0 || lng != 0) {
      params['at'] = '$lat,$lng';
    }

    final uri = Uri.https(
      'autosuggest.search.hereapi.com',
      '/v1/autosuggest',
      params,
    );

    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    final t0 = DateTime.now();
    await AnalyticsService.track('autosuggest_requested', {
      'request_id': requestId,
      'q_len': q.length,
      'latlng_available': (lat != 0 || lng != 0),
    });

    final res = await http.get(uri);
    final latencyMs = DateTime.now().difference(t0).inMilliseconds;

    await AnalyticsService.track('autosuggest_received', {
      'request_id': requestId,
      'status': res.statusCode,
      'latency_ms': latencyMs,
    });

    if (res.statusCode != 200) {
      throw ApiException(
        'Autosuggest failed',
        statusCode: res.statusCode,
        endpoint: uri.toString(),
      );
    }

    final data = jsonDecode(res.body);
    final items = data['items'] as List<dynamic>? ?? [];

    final results = items
        .where((e) => e is Map && e['position'] != null)
        .map((e) {
      final m = e as Map;
      final pos = m['position'] as Map;

      final title = (m['title'] ?? '').toString();
      String subtitle = '';
      final addr = m['address'];
      if (addr is Map && addr['label'] != null) {
        subtitle = (addr['label'] ?? '').toString();
      }

      // Nếu label trùng title thì ẩn đi cho gọn.
      if (subtitle.trim() == title.trim()) subtitle = '';

      return StopModel(
        lat: (pos['lat'] as num).toDouble(),
        lng: (pos['lng'] as num).toDouble(),
        name: title,
        subtitle: subtitle,
      );
    })
        .toList(growable: false);

    _cache[cacheKey] = (t: DateTime.now(), items: results);
    return results;
  }

  /// HERE Geocode (fallback): dùng khi người dùng nhập xa/không chọn từ autosuggest.
  /// Endpoint: geocode.search.hereapi.com/v1/geocode
  static Future<List<StopModel>> geocode({
    required String query,
    int limit = 5,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    if (!AppConfig.hasHereApiKey) {
      throw const MissingApiKeyException();
    }

    final cacheKey = 'geocode|${q.toLowerCase()}|$limit';
    final cached = _cache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.t).inSeconds < 60) {
      return cached.items;
    }

    final uri = Uri.https(
      'geocode.search.hereapi.com',
      '/v1/geocode',
      {
        'q': q,
        'apiKey': AppConfig.hereApiKey,
        'limit': '$limit',
      },
    );

    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    final t0 = DateTime.now();
    await AnalyticsService.track('geocode_requested', {
      'request_id': requestId,
      'q_len': q.length,
    });

    final res = await http.get(uri);
    final latencyMs = DateTime.now().difference(t0).inMilliseconds;

    await AnalyticsService.track('geocode_received', {
      'request_id': requestId,
      'status': res.statusCode,
      'latency_ms': latencyMs,
    });

    if (res.statusCode != 200) {
      throw ApiException(
        'Geocode failed',
        statusCode: res.statusCode,
        endpoint: uri.toString(),
      );
    }

    final data = jsonDecode(res.body);
    final items = data['items'] as List<dynamic>? ?? [];

    final results = items
        .where((e) => e is Map && e['position'] != null)
        .map((e) {
      final m = e as Map;
      final pos = m['position'] as Map;

      final title = (m['title'] ?? '').toString();
      String subtitle = '';
      final addr = m['address'];
      if (addr is Map && addr['label'] != null) {
        subtitle = (addr['label'] ?? '').toString();
      }
      if (subtitle.trim() == title.trim()) subtitle = '';

      return StopModel(
        lat: (pos['lat'] as num).toDouble(),
        lng: (pos['lng'] as num).toDouble(),
        name: title,
        subtitle: subtitle,
      );
    })
        .toList(growable: false);

    _cache[cacheKey] = (t: DateTime.now(), items: results);
    return results;
  }
}
