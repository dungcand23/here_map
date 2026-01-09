import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../app_config.dart';
import '../../models/team_route_model.dart';
import '../auth_repository.dart';
import '../route_repository.dart';

/// Stub implementation cho backend WMS.
class WmsRouteRepository implements RouteRepository {
  final String baseUrl;
  final AuthRepository _auth;
  final http.Client _client;

  WmsRouteRepository({
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
  Future<List<TeamRouteModel>> listTeamRoutes(String teamId) async {
    _ensureConfigured();
    final uri = Uri.parse('$baseUrl/teams/$teamId/routes');
    final res = await _client.get(uri, headers: await _headers());
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('WMS listRoutes failed (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    final list = decoded is List ? decoded : (decoded is Map ? (decoded['routes'] as List? ?? const []) : const []);
    return list
        .map((e) => TeamRouteModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<TeamRouteModel> createTeamRoute(TeamRouteModel route) async {
    _ensureConfigured();
    final uri = Uri.parse('$baseUrl/teams/${route.teamId}/routes');
    final res = await _client.post(uri, headers: await _headers(), body: jsonEncode(route.toJson()));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('WMS createRoute failed (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map) throw StateError('Unexpected createRoute response');
    return TeamRouteModel.fromJson(Map<String, dynamic>.from(decoded as Map));
  }

  @override
  Future<bool> deleteTeamRoute({required String teamId, required String routeId}) async {
    _ensureConfigured();
    final uri = Uri.parse('$baseUrl/teams/$teamId/routes/$routeId');
    final res = await _client.delete(uri, headers: await _headers());
    if (res.statusCode == 404) return false;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('WMS deleteRoute failed (${res.statusCode}): ${res.body}');
    }
    return true;
  }

  @override
  Future<TeamRouteModel?> getTeamRoute({required String teamId, required String routeId}) async {
    _ensureConfigured();
    final uri = Uri.parse('$baseUrl/teams/$teamId/routes/$routeId');
    final res = await _client.get(uri, headers: await _headers());
    if (res.statusCode == 404) return null;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('WMS getRoute failed (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map) throw StateError('Unexpected getRoute response');
    return TeamRouteModel.fromJson(Map<String, dynamic>.from(decoded as Map));
  }
}
