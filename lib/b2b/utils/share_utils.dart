import 'dart:convert';

import '../../models/saved_route_model.dart';
import '../../models/stop_model.dart';
import '../../models/truck_option_model.dart';
import '../../models/vehicle_model.dart';
import '../models/route_share_payload.dart';

class ShareUtils {
  /// Encode payload -> base64url (không padding) để share qua link/QR.
  static String encodeRouteSharePayload(RouteSharePayload payload) {
    final jsonStr = jsonEncode(payload.toJson());
    final b = utf8.encode(jsonStr);
    return base64UrlEncode(b).replaceAll('=', '');
  }

  /// Decode base64url (có/không padding) -> payload.
  static RouteSharePayload? decodeRouteSharePayload(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;

    // add padding back
    String padded = trimmed;
    final mod = trimmed.length % 4;
    if (mod > 0) {
      padded = trimmed + ('=' * (4 - mod));
    }

    try {
      final jsonStr = utf8.decode(base64Url.decode(padded));
      final json = jsonDecode(jsonStr);
      if (json is! Map) return null;
      return RouteSharePayload.fromJson(Map<String, dynamic>.from(json as Map));
    } catch (_) {
      return null;
    }
  }

  static RouteSharePayload fromCurrentRoute({
    required String name,
    required double distanceKm,
    required double durationMin,
    required List<StopModel> stops,
    required VehicleModel? vehicle,
    required TruckOptionModel truck,
    required bool trafficEnabled,
    required String mapMode,
  }) {
    final vehicleMode = vehicle?.mode ?? 'car';
    return RouteSharePayload(
      v: 1,
      name: name,
      distanceKm: distanceKm,
      durationMin: durationMin,
      stops: List<StopModel>.from(stops),
      vehicleMode: vehicleMode,
      truckOption: truck,
      trafficEnabled: trafficEnabled,
      mapMode: mapMode,
    );
  }

  static SavedRouteModel toSavedRoute(RouteSharePayload payload) {
    final now = DateTime.now();
    return SavedRouteModel(
      id: now.millisecondsSinceEpoch.toString(),
      createdAt: now,
      name: payload.name.isNotEmpty ? payload.name : 'Shared route',
      distanceKm: payload.distanceKm,
      durationMin: payload.durationMin,
      stops: payload.stops,
      // vehicle sẽ được set ở UI layer (pick theo mode) để không phải tạo IconData.
      vehicle: null,
      truckOption: payload.truckOption,
      mapMode: payload.mapMode,
      trafficEnabled: payload.trafficEnabled,
    );
  }
}
