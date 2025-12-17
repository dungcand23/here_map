import 'dart:convert';
import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../models/stop_model.dart';

class NearbyService {
  /// type: atm | gas | food
  static Future<List<StopModel>> searchNearby({
    required double lat,
    required double lng,
    required String type,
  }) async {
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

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(res.body);
    final items = data['items'] as List<dynamic>? ?? [];

    return items
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
  }
}
