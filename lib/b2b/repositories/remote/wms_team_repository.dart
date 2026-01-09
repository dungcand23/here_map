import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../app_config.dart';
import '../../models/b2b_role.dart';
import '../../models/team_member_model.dart';
import '../../models/team_model.dart';
import '../auth_repository.dart';
import '../team_repository.dart';

/// Stub implementation cho backend WMS.
///
/// Align endpoint + auth header theo WMS API của bạn.
class WmsTeamRepository implements TeamRepository {
  final String baseUrl;
  final AuthRepository _auth;
  final http.Client _client;

  WmsTeamRepository({
    required AuthRepository auth,
    String? baseUrl,
    http.Client? client,
  })  : _auth = auth,
        baseUrl = (baseUrl ?? AppConfig.safeWmsBaseUrl),
        _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getAccessToken();
    final h = <String, String>{'content-type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      h['authorization'] = 'Bearer $token';
    }
    return h;
  }

  void _ensureConfigured() {
    if (baseUrl.isEmpty) {
      throw StateError('WMS_BASE_URL is empty. Set WMS_BASE_URL or use B2B_BACKEND_MODE=local');
    }
  }

  @override
  Future<TeamModel> createTeam({
    required String name,
    required String createdByUserId,
    required String ownerUserId,
    required String ownerEmail,
    required String ownerDisplayName,
  }) async {
    _ensureConfigured();
    final uri = Uri.parse('$baseUrl/teams');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'createdBy': createdByUserId,
        'ownerUserId': ownerUserId,
        'ownerEmail': ownerEmail,
        'ownerDisplayName': ownerDisplayName,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('WMS createTeam failed (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map) throw StateError('Unexpected createTeam response');
    return TeamModel.fromJson(Map<String, dynamic>.from(decoded as Map));
  }

  @override
  Future<TeamModel?> joinTeamByCode({
    required String joinCode,
    required String userId,
    required String email,
    required String displayName,
  }) async {
    _ensureConfigured();
    final uri = Uri.parse('$baseUrl/teams/join');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'joinCode': joinCode,
        'userId': userId,
        'email': email,
        'displayName': displayName,
      }),
    );
    if (res.statusCode == 404) return null;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('WMS joinTeam failed (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map) throw StateError('Unexpected joinTeam response');
    return TeamModel.fromJson(Map<String, dynamic>.from(decoded as Map));
  }

  @override
  Future<TeamModel?> getTeamById(String teamId) async {
    _ensureConfigured();
    final uri = Uri.parse('$baseUrl/teams/$teamId');
    final res = await _client.get(uri, headers: await _headers());
    if (res.statusCode == 404) return null;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('WMS getTeam failed (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map) throw StateError('Unexpected getTeam response');
    return TeamModel.fromJson(Map<String, dynamic>.from(decoded as Map));
  }

  @override
  Future<List<TeamMemberModel>> listMembers(String teamId) async {
    _ensureConfigured();
    final uri = Uri.parse('$baseUrl/teams/$teamId/members');
    final res = await _client.get(uri, headers: await _headers());
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('WMS listMembers failed (${res.statusCode}): ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    final list = decoded is List ? decoded : (decoded is Map ? (decoded['members'] as List? ?? const []) : const []);
    return list
        .map((e) => TeamMemberModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<B2BRole?> getUserRole({required String teamId, required String userId}) async {
    final members = await listMembers(teamId);
    for (final m in members) {
      if (m.userId == userId) return m.role;
    }
    return null;
  }

  @override
  Future<bool> updateMemberRole({required String teamId, required String userId, required B2BRole role}) async {
    _ensureConfigured();
    final uri = Uri.parse('$baseUrl/teams/$teamId/members/$userId');
    final res = await _client.patch(
      uri,
      headers: await _headers(),
      body: jsonEncode({'role': role.value}),
    );
    if (res.statusCode == 404) return false;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('WMS updateMemberRole failed (${res.statusCode}): ${res.body}');
    }
    return true;
  }
}
