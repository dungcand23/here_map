import 'dart:convert';
import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../models/stop_model.dart';
import 'analytics_service.dart';
import 'api_exceptions.dart';

class NearbyService {
  /// type: atm | gas | food
  static Future<List<StopModel>> searchNearby({
    required double lat,
    required double lng,
    required String type,
  }) async {
    if (!AppConfig.hasHereApiKey) {
      throw const MissingApiKeyException();
    }
    String? categories;
    switch (type) {
      case 'atm':
        categories = '300-3000-0066'; // ATM
        break;
      case 'gas':
        categories = '700-7600-0154'; // fuel station
        break;
      case 'food':
        categories = '800-8000-0152'; // restaurant
        break;
      default:
        categories = null;
    }

    final params = <String, String>{
      'at': '$lat,$lng',
      'limit': '20',
      'apiKey': AppConfig.hereApiKey,
    };
    if (categories != null) {
      params['categories'] = categories;
    }

    final uri = Uri.https(
      'browse.search.hereapi.com',
      '/v1/browse',
      params,
    );
    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    final t0 = DateTime.now();

    await AnalyticsService.track('nearby_requested', {
      'request_id': requestId,
      'type': type,
    });

    final res = await http.get(uri);
    final latencyMs = DateTime.now().difference(t0).inMilliseconds;

    await AnalyticsService.track('nearby_received', {
      'request_id': requestId,
      'type': type,
      'status': res.statusCode,
      'latency_ms': latencyMs,
    });

    if (res.statusCode != 200) {
      throw ApiException(
        'Nearby search failed',
        statusCode: res.statusCode,
        endpoint: uri.toString(),
      );
    }

    final data = jsonDecode(res.body);
    final items = data['items'] as List<dynamic>? ?? [];

    final results = items
        .where((e) => e['position'] != null)
        .map((e) {
      final pos = e['position'];
      return StopModel(
        lat: (pos['lat'] as num).toDouble(),
        lng: (pos['lng'] as num).toDouble(),
        name: e['title'] ?? '',
      );
    })
        .toList();

    return results;
  }
}
