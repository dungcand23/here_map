class AppConfig {
  /// HERE API key
  ///
  /// ✅ Không hardcode trong repo. Truyền bằng:
  /// flutter run --dart-define=HERE_API_KEY=YOUR_KEY
  static const String hereApiKey = String.fromEnvironment('HERE_API_KEY', defaultValue: '');

  /// Base URL dùng để build share link (B2B-lite).
  /// Ví dụ web prod: https://route.yourdomain.com
  /// Dev: http://localhost:8080
  static const String appBaseUrl = String.fromEnvironment('APP_BASE_URL', defaultValue: 'http://localhost:8080');

  /// Backend mode cho B2B-lite.
  ///
  /// - local: dùng local storage (SharedPreferences) để demo/pilot offline.
  /// - wms: gọi API backend của dự án WMS (Phase 3/4). Ở Phase 2.5, chỉ chuẩn hoá contract
  ///        và để sẵn stub implementation để sau này cắm nhanh.
  static const String b2bBackendMode = String.fromEnvironment('B2B_BACKEND_MODE', defaultValue: 'local');

  /// Base URL của backend WMS (chỉ dùng khi B2B_BACKEND_MODE=wms).
  /// Ví dụ: https://wms-api.yourdomain.com
  static const String wmsBaseUrl = String.fromEnvironment('WMS_BASE_URL', defaultValue: '');

  static bool get hasHereApiKey => hereApiKey.trim().isNotEmpty;

  static bool get useWmsBackend => b2bBackendMode.trim().toLowerCase() == 'wms';

  static String get safeWmsBaseUrl {
    final v = wmsBaseUrl.trim();
    if (v.isEmpty) return '';
    return v.endsWith('/') ? v.substring(0, v.length - 1) : v;
  }

  static String get safeBaseUrl {
    final v = appBaseUrl.trim();
    if (v.isEmpty) return 'http://localhost:8080';
    return v.endsWith('/') ? v.substring(0, v.length - 1) : v;
  }

  // Default center map
  static const defaultLat = 10.762622;
  static const defaultLng = 106.660172;

  // Default zoom
  static const defaultZoom = 12.0;
}
