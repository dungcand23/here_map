import 'package:flutter/foundation.dart' show kIsWeb;

/// Cấu hình fallback đóng gói sẵn để app có thể chạy ngay sau khi giải nén.
/// Khi cần override cho từng môi trường, vẫn ưu tiên dùng:
///   flutter run --dart-define-from-file=env.dev.json
class AppEnvDefaults {
  AppEnvDefaults._();

  static const String hereApiKey = '7dahCUUCYcOErx2Pu7Wn32sY2seNTIRub1Hgl5ATw5E';
  static const String appBaseUrl = 'http://localhost:8080';
  static const String b2bBackendMode = 'local';
  static const String wmsBaseUrl = '';
}

class AppConfig {
  AppConfig._();

  static const String _envHereApiKey =
      String.fromEnvironment('HERE_API_KEY', defaultValue: '');
  static const String _envAppBaseUrl =
      String.fromEnvironment('APP_BASE_URL', defaultValue: '');
  static const String _envB2BBackendMode =
      String.fromEnvironment('B2B_BACKEND_MODE', defaultValue: '');
  static const String _envWmsBaseUrl =
      String.fromEnvironment('WMS_BASE_URL', defaultValue: '');
  static const String _envGoogleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

  static String _pick(String envValue, String fallbackValue) {
    final env = envValue.trim();
    if (env.isNotEmpty) return env;
    return fallbackValue.trim();
  }

  static String get hereApiKey => _pick(_envHereApiKey, AppEnvDefaults.hereApiKey);
  static String get appBaseUrl => _pick(_envAppBaseUrl, AppEnvDefaults.appBaseUrl);
  static String get b2bBackendMode =>
      _pick(_envB2BBackendMode, AppEnvDefaults.b2bBackendMode).toLowerCase();
  static String get wmsBaseUrl => _pick(_envWmsBaseUrl, AppEnvDefaults.wmsBaseUrl);
  static String get googleWebClientId => _envGoogleWebClientId.trim();

  static bool get hasHereApiKey => hereApiKey.isNotEmpty;

  static bool get isUsingBundledHereApiKey =>
      _envHereApiKey.trim().isEmpty && AppEnvDefaults.hereApiKey.trim().isNotEmpty;

  static bool get useWmsBackend => b2bBackendMode == 'wms';

  static String get safeWmsBaseUrl {
    final v = wmsBaseUrl.trim();
    if (v.isEmpty) return '';
    return v.endsWith('/') ? v.substring(0, v.length - 1) : v;
  }

  static String get safeBaseUrl {
    final v = appBaseUrl.trim();
    if (v.isNotEmpty) {
      return v.endsWith('/') ? v.substring(0, v.length - 1) : v;
    }

    if (kIsWeb) {
      final origin = Uri.base.origin.trim();
      if (origin.isNotEmpty && origin.toLowerCase() != 'null') {
        return origin.endsWith('/') ? origin.substring(0, origin.length - 1) : origin;
      }
    }

    return 'http://localhost:8080';
  }

  static bool get hasConfiguredAppBaseUrl => safeBaseUrl.isNotEmpty;
  static bool get hasConfiguredWmsBaseUrl => safeWmsBaseUrl.isNotEmpty;

  static String get hereKeySourceLabel {
    if (_envHereApiKey.trim().isNotEmpty) return 'dart-define / env file';
    if (AppEnvDefaults.hereApiKey.trim().isNotEmpty) return 'bundle sẵn trong app';
    return 'chưa cấu hình';
  }

  static String maskSecret(String value, {int visible = 4}) {
    final v = value.trim();
    if (v.isEmpty) return '(trống)';
    if (v.length <= visible * 2) {
      return '${v.substring(0, 1)}***${v.substring(v.length - 1)}';
    }
    return '${v.substring(0, visible)}...${v.substring(v.length - visible)}';
  }

  static List<String> get blockingIssues {
    final issues = <String>[];
    if (!hasHereApiKey) {
      issues.add('Thiếu HERE_API_KEY. App cần key để autosuggest, routing và render bản đồ.');
    }
    if (useWmsBackend && safeWmsBaseUrl.isEmpty) {
      issues.add('B2B_BACKEND_MODE đang là wms nhưng WMS_BASE_URL đang trống.');
    }
    return issues;
  }

  static String get runtimeConfigSummary {
    final source = isUsingBundledHereApiKey ? 'bundled-default' : 'dart-define';
    return 'HERE=$source • backend=$b2bBackendMode • baseUrl=$safeBaseUrl'
        '${useWmsBackend ? ' • wms=${safeWmsBaseUrl.isEmpty ? '(missing)' : safeWmsBaseUrl}' : ''}';
  }

  static const defaultLat = 10.762622;
  static const defaultLng = 106.660172;
  static const defaultZoom = 12.0;
}
