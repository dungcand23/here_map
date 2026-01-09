import 'package:geolocator/geolocator.dart';

import '../app_config.dart';

class LocationService {
  /// Lấy vị trí hiện tại (best-effort).
  ///
  /// - Nếu user từ chối permission hoặc không có GPS -> fallback về default center
  static Future<Map<String, double>> getMyLocation({Duration timeout = const Duration(seconds: 6)}) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return _fallback();
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return _fallback();
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: timeout,
      );
      return {
        'lat': pos.latitude,
        'lng': pos.longitude,
      };
    } catch (_) {
      return _fallback();
    }
  }

  static Map<String, double> _fallback() => {
        'lat': AppConfig.defaultLat,
        'lng': AppConfig.defaultLng,
      };
}
