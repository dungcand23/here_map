import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../models/stop_model.dart';
import '../models/truck_option_model.dart';
import '../models/vehicle_model.dart';
import 'analytics_service.dart';
import 'api_exceptions.dart';

/// HERE Waypoints Sequence API v8
/// Dùng để sắp xếp (optimize) thứ tự các điểm dừng theo thời gian/độ dài.
///
/// Lưu ý: API này **không** trả về polyline. Sau khi có thứ tự tối ưu,
/// app cần gọi Routing v8 để lấy polyline & summary. citeturn5search8
class WaypointsSequenceService {
  /// Optimize route order.
  /// - start cố định là stops.first
  /// - các điểm còn lại là destinations
  /// - end để trống => HERE được quyền chọn điểm kết thúc (end-free)
  static Future<List<StopModel>> optimizeStops({
    required List<StopModel> stops,
    required VehicleModel vehicle,
    required TruckOptionModel truck,
    bool trafficEnabled = false,
    String improveFor = 'time', // 'time' hoặc 'distance'
  }) async {
    if (stops.length < 3) return stops;

    if (!AppConfig.hasHereApiKey) {
      throw const MissingApiKeyException();
    }

    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    final t0 = DateTime.now();

    // Build ID map
    final idToStop = <String, StopModel>{};
    final startId = 'START';
    idToStop[startId] = stops.first;

    // Waypoints Sequence API v8 dùng destination1..destinationN citeturn4search10
    final query = <String, String>{
      'start': '$startId;${stops.first.lat},${stops.first.lng}',
      'improveFor': improveFor,
      'mode': _mode(vehicle, trafficEnabled),
      'apiKey': AppConfig.hereApiKey,
    };

    // destinations: gồm tất cả điểm còn lại, kể cả điểm cuối hiện tại.
    for (int i = 1; i < stops.length; i++) {
      final id = 'D$i';
      idToStop[id] = stops[i];
      query['destination$i'] = '$id;${stops[i].lat},${stops[i].lng}';
    }

    if (_vehicleIsTruck(vehicle)) {
      // Parameter naming theo ví dụ HERE WPS v8 (height/width/length/limitedWeight). citeturn5search0turn4search10
      query.addAll({
        'height': truck.height.toString(),
        'width': truck.width.toString(),
        'length': truck.length.toString(),
        'limitedWeight': truck.grossWeight.toString(),
      });
    }

    final uri = Uri.https('wps.hereapi.com', '/v8/findsequence2', query);

    await AnalyticsService.track('wps_requested', {
      'request_id': requestId,
      'stop_count': stops.length,
      'improve_for': improveFor,
      'traffic': trafficEnabled,
      'vehicle': vehicle.mode,
    });

    final res = await http.get(uri);
    final latencyMs = DateTime.now().difference(t0).inMilliseconds;

    if (res.statusCode != 200) {
      await AnalyticsService.track('wps_failed', {
        'request_id': requestId,
        'status': res.statusCode,
        'latency_ms': latencyMs,
      });
      throw ApiException(
        'Optimize route failed',
        statusCode: res.statusCode,
        endpoint: uri.toString(),
      );
    }

    final data = jsonDecode(res.body);
    final results = (data['results'] as List?) ?? const [];
    if (results.isEmpty) {
      await AnalyticsService.track('wps_failed', {
        'request_id': requestId,
        'status': res.statusCode,
        'latency_ms': latencyMs,
        'error_type': 'no_results',
      });
      return stops;
    }

    final first = results.first as Map;
    final waypoints = (first['waypoints'] as List?) ?? const [];
    if (waypoints.isEmpty) return stops;

    final ordered = waypoints
        .whereType<Map>()
        .map((w) {
          final id = (w['id'] ?? '').toString();
          final seq = (w['sequence'] as num?)?.toInt() ?? 999999;
          return (id: id, seq: seq);
        })
        .toList();

    ordered.sort((a, b) => a.seq.compareTo(b.seq));

    final optimized = <StopModel>[];
    for (final w in ordered) {
      final stop = idToStop[w.id];
      if (stop != null) optimized.add(stop);
    }

    // fallback nếu parse lỗi
    if (optimized.length < 2) return stops;

    await AnalyticsService.track('wps_succeeded', {
      'request_id': requestId,
      'status': res.statusCode,
      'latency_ms': latencyMs,
      'optimized_count': optimized.length,
      'end_free': true,
    });

    return optimized;
  }

  static bool _vehicleIsTruck(VehicleModel vehicle) => vehicle.mode == 'truck';

  static String _mode(VehicleModel vehicle, bool trafficEnabled) {
    final traffic = trafficEnabled ? 'enabled' : 'disabled';
    final type = _vehicleIsTruck(vehicle) ? 'truck' : 'car';
    // format legacy vẫn được WPS v8 dùng trong ví dụ. citeturn4search10
    return 'fastest;$type;traffic:$traffic;';
  }
}
