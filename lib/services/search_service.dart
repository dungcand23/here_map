import 'dart:convert';
import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../models/stop_model.dart';

class SearchService {
  /// HERE Autosuggest
  /// query: text người dùng nhập
  /// lat/lng: vị trí trung tâm (để ưu tiên kết quả gần)
  static Future<List<StopModel>> autosuggest({
    required String query,
    required double lat,
    required double lng,
  }) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.https(
      'autosuggest.search.hereapi.com',
      '/v1/autosuggest',
      {
        'q': query,
        'at': '$lat,$lng',
        'apiKey': AppConfig.hereApiKey,
        'limit': '10',
      },
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
