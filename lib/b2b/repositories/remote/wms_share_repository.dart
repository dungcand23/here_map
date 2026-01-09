import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../app_config.dart';
import '../../models/route_share_payload.dart';
import '../auth_repository.dart';
import '../share_repository.dart';

/// Stub implementation cho share token ở backend WMS.
class WmsShareRepository implements ShareRepository {
  final String baseUrl;
  final AuthRepository _auth;
  final http.Client _client;

  WmsShareRepository({
    required AuthRepository auth,
    String? baseUrl,
    http.Client? client,
  })  : _auth = auth,
        baseUrl = (baseUrl ?? AppConfig.safeWmsBaseUrl),
        _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getAccessToken();
    final h = <String, String>{'content-type': 'application/json'};
    if (token != null && token.isNotEmpty) h['authorization'] = 'Bearer $token';
    return h;
  }

  void _ensureConfigured() {
    if (baseUrl.isEmpty) {
      throw StateError('WMS_BASE_URL is empty. Set WMS_BASE_URL or use B2B_BACKEND_MODE=local');
    }
  }

  @override
  Future<String> createShareCode(RouteSharePayload payload) async {
    _ensureConfigured();
    final uri = Uri.parse('$baseUrl/shares');
    final res = await _client.post(uri, headers: await _headers(), body: jsonEncode(payload.toJson()));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('WMS createShare failed (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is Map) {
      final code = (decoded['code'] ?? decoded['shareCode'] ?? '').toString();
      if (code.trim().isNotEmpty) return code.trim();
    }
    // fallback: body chính là code
    final raw = res.body.trim();
    if (raw.isNotEmpty) return raw;
    throw StateError('Unexpected createShare response');
  }

  @override
  Future<RouteSharePayload?> resolveShareCode(String code) async {
    _ensureConfigured();
    final c = code.trim();
    if (c.isEmpty) return null;
    final uri = Uri.parse('$baseUrl/shares/$c');
    final res = await _client.get(uri, headers: await _headers());
    if (res.statusCode == 404) return null;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('WMS resolveShare failed (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map) return null;
    return RouteSharePayload.fromJson(Map<String, dynamic>.from(decoded as Map));
  }

  @override
  String? extractCode(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    if (text.contains('://') && text.contains('?')) {
      try {
        final uri = Uri.parse(text);
        final c = uri.queryParameters['code'];
        if (c != null && c.trim().isNotEmpty) return c.trim();
      } catch (_) {}
    }
    final idx = text.indexOf('code=');
    if (idx >= 0) {
      final rest = text.substring(idx + 5);
      final endIdx = rest.indexOf('&');
      final c = (endIdx >= 0 ? rest.substring(0, endIdx) : rest).trim();
      if (c.isNotEmpty) return c;
    }
    return text;
  }
}
