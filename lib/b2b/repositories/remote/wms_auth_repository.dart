import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_config.dart';
import '../../models/user_profile_model.dart';
import '../auth_repository.dart';

/// Stub implementation cho backend WMS.
///
/// Ở Phase 2.5, class này chủ yếu để:
/// - Chuẩn hoá nơi sẽ gọi backend (cắm vào WMS sau này).
/// - App compile được khi chuyển B2B_BACKEND_MODE=wms.
///
/// Bạn sẽ cần align endpoint + response với API thật của WMS.
class WmsAuthRepository implements AuthRepository {
  static const _kToken = 'wms_access_token';
  static const _kUser = 'wms_current_user';

  final String baseUrl;
  final http.Client _client;

  WmsAuthRepository({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = (baseUrl ?? AppConfig.safeWmsBaseUrl),
        _client = client ?? http.Client();

  @override
  Future<UserProfileModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUser);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      return UserProfileModel.fromJson(Map<String, dynamic>.from(json as Map));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserProfileModel> signIn({required String email, required String displayName}) async {
    if (baseUrl.isEmpty) {
      throw StateError('WMS_BASE_URL is empty. Set WMS_BASE_URL or use B2B_BACKEND_MODE=local');
    }

    // NOTE: Đây là contract gợi ý. Align với API WMS của bạn.
    final uri = Uri.parse('$baseUrl/auth/login');
    final res = await _client.post(
      uri,
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'displayName': displayName.trim()}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('WMS auth failed (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw StateError('Unexpected WMS auth response');
    }

    final map = Map<String, dynamic>.from(decoded as Map);
    final token = (map['accessToken'] ?? map['token'] ?? '').toString();
    final userJson = map['user'] is Map ? Map<String, dynamic>.from(map['user'] as Map) : <String, dynamic>{};

    final user = UserProfileModel.fromJson({
      'id': (userJson['id'] ?? userJson['userId'] ?? email.trim()).toString(),
      'email': (userJson['email'] ?? email.trim()).toString(),
      'displayName': (userJson['displayName'] ?? displayName.trim()).toString(),
      'createdAt': (userJson['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
    if (token.trim().isNotEmpty) {
      await prefs.setString(_kToken, token.trim());
    }
    return user;
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUser);
    await prefs.remove(_kToken);
  }

  @override
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_kToken);
    if (t == null || t.trim().isEmpty) return null;
    return t.trim();
  }
}
