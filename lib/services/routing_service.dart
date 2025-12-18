import 'dart:convert';
import 'package:http/http.dart' as http;

import '../app_config.dart';
import '../models/stop_model.dart';
import '../models/vehicle_model.dart';
import '../models/truck_option_model.dart';
import '../utils/polyline_utils.dart';

class RoutingResult {
  final List<Map<String, double>> polyline;
  final double distanceKm;
  final double durationMin;

  RoutingResult({
    required this.polyline,
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
  }) async {
    if (stops.length < 2) return null;

    final waypoints = <String, String>{};
    for (int i = 0; i < stops.length; i++) {
      waypoints['waypoint$i'] = '${stops[i].lat},${stops[i].lng}';
    }

    final transportMode = _mapVehicleModeToHere(vehicle.mode);

    final query = <String, String>{
      'transportMode': transportMode,
      'return': 'polyline,summary',
      'apiKey': AppConfig.hereApiKey,
      ...waypoints,
    };

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

    final uri = Uri.https('router.hereapi.com', '/v8/routes', query);

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(res.body);

    final routes = data['routes'] as List<dynamic>? ?? [];
    if (routes.isEmpty) return null;

    final firstRoute = routes.first;
    final sections = firstRoute['sections'] as List<dynamic>? ?? [];
    if (sections.isEmpty) return null;

    double distanceMeters = 0.0;
    double durationSeconds = 0.0;

    final List<Map<String, double>> polyPoints = [];

    for (int i = 0; i < sections.length; i++) {
      final sec = sections[i];
      final summary = sec['summary'] ?? {};
      distanceMeters += (summary['length'] as num?)?.toDouble() ?? 0.0;
      durationSeconds += (summary['duration'] as num?)?.toDouble() ?? 0.0;

      final polylineEncoded = sec['polyline'] as String?;
      if (polylineEncoded != null && polylineEncoded.isNotEmpty) {
        final pts = PolylineUtils.decodeFlexiblePolyline(polylineEncoded);
        if (pts.isNotEmpty) {
          // tránh trùng điểm nối giữa các section
          if (polyPoints.isNotEmpty) {
            pts.removeAt(0);
          }
          polyPoints.addAll(pts);
        }
      }
    }

    return RoutingResult(
      polyline: polyPoints,
      distanceKm: distanceMeters / 1000.0,
      durationMin: durationSeconds / 60.0,
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
}
