import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../models/stop_model.dart';
import '../models/truck_option_model.dart';
import '../models/vehicle_model.dart';
import 'analytics_service.dart';
import 'api_exceptions.dart';

class RoutingResult {
  /// Encoded Flexible Polyline strings (one per section).
  ///
  /// Why encoded?
  /// - Dart-side decoding is error-prone and not needed for Web.
  /// - HERE Maps JS can decode natively with `H.geo.LineString.fromFlexiblePolyline()`.
  ///
  /// Ref: HERE Maps API for JS examples use `H.geo.LineString.fromFlexiblePolyline(section.polyline)`.
  final List<String> polylinesEncoded;
  final double distanceKm;
  final double durationMin;

  RoutingResult({
    required this.polylinesEncoded,
    required this.distanceKm,
    required this.durationMin,
  });
}

class RoutingService {
  /// Build multi-stop route bằng HERE Routing v8
  static Future<RoutingResult?> buildRoute({
    required List<StopModel> stops,
    required VehicleModel vehicle,
    required TruckOptionModel truck,
    bool trafficEnabled = false,
  }) async {
    if (stops.length < 2) return null;

    if (!AppConfig.hasHereApiKey) {
      await AnalyticsService.track('route_failed', {
        'error_type': 'missing_api_key',
      });
      throw const MissingApiKeyException();
    }

    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    final transportMode = _mapVehicleModeToHere(vehicle.mode);

    // HERE Routing API v8 dùng origin/destination/via (không dùng waypoint0/1/2...).
    // via có thể lặp nhiều lần trong query string.
    final origin = '${stops.first.lat},${stops.first.lng}';
    final destination = '${stops.last.lat},${stops.last.lng}';
    final via = stops.length > 2
        ? stops
        .sublist(1, stops.length - 1)
        .map((s) => '${s.lat},${s.lng}')
        .toList()
        : <String>[];

    final query = <String, String>{
      'transportMode': transportMode,
      'routingMode': 'fast',
      'origin': origin,
      'destination': destination,
      'return': 'polyline,summary',
      'apiKey': AppConfig.hereApiKey,
    };

    // Traffic: dùng departureTime=any để HERE trả route có xét traffic (nếu khả dụng)
    if (trafficEnabled) {
      query['departureTime'] = 'any';
    }

    // Nếu là truck → thêm thông số truck
    if (transportMode == 'truck') {
      query.addAll({
        'truck[height]': truck.height.toString(),
        'truck[width]': truck.width.toString(),
        'truck[length]': truck.length.toString(),
        'truck[grossWeight]': truck.grossWeight.toString(),
        'truck[axleCount]': truck.axleCount.toString(),
      });
    }

    // Uri.https không hỗ trợ key lặp (via=...&via=...).
    // => build query string thủ công để đảm bảo multiple via hoạt động.
    final uri = _buildRoutingV8Uri(query, via);

    final t0 = DateTime.now();
    await AnalyticsService.track('route_requested', {
      'request_id': requestId,
      'stop_count': stops.length,
      'vehicle': transportMode,
      'traffic': trafficEnabled,
      'truck_params_present': transportMode == 'truck',
    });

    final res = await http.get(uri);
    final latencyMs = DateTime.now().difference(t0).inMilliseconds;

    if (res.statusCode != 200) {
      await AnalyticsService.track('route_failed', {
        'request_id': requestId,
        'status': res.statusCode,
        'latency_ms': latencyMs,
        'error_type': 'http_error',
      });
      throw ApiException(
        'Routing failed',
        statusCode: res.statusCode,
        endpoint: uri.toString(),
      );
    }

    final data = jsonDecode(res.body);

    final routes = data['routes'] as List<dynamic>? ?? [];
    if (routes.isEmpty) {
      await AnalyticsService.track('route_failed', {
        'request_id': requestId,
        'status': res.statusCode,
        'latency_ms': latencyMs,
        'error_type': 'no_routes',
      });
      return null;
    }

    final firstRoute = routes.first;
    final sections = firstRoute['sections'] as List<dynamic>? ?? [];
    if (sections.isEmpty) {
      await AnalyticsService.track('route_failed', {
        'request_id': requestId,
        'status': res.statusCode,
        'latency_ms': latencyMs,
        'error_type': 'no_sections',
      });
      return null;
    }

    double distanceMeters = 0.0;
    double durationSeconds = 0.0;

    final List<String> encodedSections = [];

    for (int i = 0; i < sections.length; i++) {
      final sec = sections[i];
      final summary = sec['summary'] ?? {};
      distanceMeters += (summary['length'] as num?)?.toDouble() ?? 0.0;
      durationSeconds += (summary['duration'] as num?)?.toDouble() ?? 0.0;

      final polylineEncoded = sec['polyline'] as String?;
      if (polylineEncoded != null && polylineEncoded.isNotEmpty) {
        encodedSections.add(polylineEncoded);
      }
    }

    final distanceKm = distanceMeters / 1000.0;
    final durationMin = durationSeconds / 60.0;

    await AnalyticsService.track('route_succeeded', {
      'request_id': requestId,
      'status': res.statusCode,
      'latency_ms': latencyMs,
      'distance_km': double.parse(distanceKm.toStringAsFixed(3)),
      'duration_min': double.parse(durationMin.toStringAsFixed(2)),
      'polyline_sections': encodedSections.length,
    });

    return RoutingResult(
      polylinesEncoded: encodedSections,
      distanceKm: distanceKm,
      durationMin: durationMin,
    );
  }

  static String _mapVehicleModeToHere(String mode) {
    switch (mode) {
      case 'scooter':
        return 'scooter';
      case 'truck':
        return 'truck';
      case 'car':
      default:
        return 'car';
    }
  }

  static Uri _buildRoutingV8Uri(Map<String, String> query, List<String> via) {
    final parts = <String>[];
    void addKV(String k, String v) {
      parts.add('${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}');
    }

    // deterministic ordering helps caching/debugging
    final keys = query.keys.toList()..sort();
    for (final k in keys) {
      addKV(k, query[k] ?? '');
    }
    for (final v in via) {
      addKV('via', v);
    }

    final qs = parts.join('&');
    return Uri.parse('https://router.hereapi.com/v8/routes?$qs');
  }
}
