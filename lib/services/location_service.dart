import '../app_config.dart';

class LocationService {
  /// Tạm thời trả về toạ độ default (HCM),
  /// để code My Location chạy không văng.
  static Future<Map<String, double>> getMyLocation() async {
    return {
      'lat': AppConfig.defaultLat,
      'lng': AppConfig.defaultLng,
    };
  }
}
