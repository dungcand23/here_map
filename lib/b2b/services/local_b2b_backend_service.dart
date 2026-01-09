import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/b2b_role.dart';
import '../models/team_member_model.dart';
import '../models/team_model.dart';
import '../models/team_route_model.dart';

class LocalB2BBackendService {
  static const _kTeams = 'b2b_teams';

  static String _kMembers(String teamId) => 'b2b_team_members_$teamId';
  static String _kRoutes(String teamId) => 'b2b_team_routes_$teamId';

  static final Uuid _uuid = Uuid();

  static String _newId() => _uuid.v4();

  static String _newJoinCode() {
    final raw = _uuid.v4().replaceAll('-', '').toUpperCase();
    return raw.substring(0, 8); // 8 ký tự đủ đọc
  }

  static Future<List<TeamModel>> listTeams() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kTeams) ?? const [];
    return list
        .map((e) => TeamModel.fromJson(Map<String, dynamic>.from(jsonDecode(e) as Map)))
        .toList();
  }

  static Future<void> _saveTeams(List<TeamModel> teams) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kTeams, teams.map((e) => jsonEncode(e.toJson())).toList());
  }

  static Future<TeamModel> createTeam({
    required String name,
    required String createdBy,
    required String ownerUserId,
    required String ownerEmail,
    required String ownerDisplayName,
  }) async {
    final team = TeamModel(
      id: _newId(),
      name: name.trim().isEmpty ? 'Team' : name.trim(),
      joinCode: _newJoinCode(),
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    final teams = await listTeams();
    await _saveTeams([...teams, team]);

    final members = <TeamMemberModel>[
      TeamMemberModel(
        userId: ownerUserId,
        email: ownerEmail,
        displayName: ownerDisplayName,
        role: B2BRole.owner,
        joinedAt: DateTime.now(),
      )
    ];
    await setTeamMembers(team.id, members);

    return team;
  }

  static Future<TeamModel?> findTeamByJoinCode(String joinCode) async {
    final code = joinCode.trim().toUpperCase();
    if (code.isEmpty) return null;
    final teams = await listTeams();
    for (final t in teams) {
      if (t.joinCode.toUpperCase() == code) return t;
    }
    return null;
  }

  static Future<List<TeamMemberModel>> getTeamMembers(String teamId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kMembers(teamId)) ?? const [];
    return list
        .map((e) => TeamMemberModel.fromJson(Map<String, dynamic>.from(jsonDecode(e) as Map)))
        .toList();
  }

  static Future<void> setTeamMembers(String teamId, List<TeamMemberModel> members) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kMembers(teamId),
      members.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<TeamMemberModel?> upsertMember({
    required TeamModel team,
    required String userId,
    required String email,
    required String displayName,
    required B2BRole role,
  }) async {
    final members = await getTeamMembers(team.id);
    final idx = members.indexWhere((m) => m.userId == userId);
    final next = TeamMemberModel(
      userId: userId,
      email: email,
      displayName: displayName,
      role: role,
      joinedAt: DateTime.now(),
    );
    if (idx >= 0) {
      members[idx] = TeamMemberModel(
        userId: userId,
        email: email,
        displayName: displayName,
        role: members[idx].role,
        joinedAt: members[idx].joinedAt,
      );
      await setTeamMembers(team.id, members);
      return members[idx];
    }
    await setTeamMembers(team.id, [...members, next]);
    return next;
  }

  static Future<B2BRole?> getUserRole(String teamId, String userId) async {
    final members = await getTeamMembers(teamId);
    for (final m in members) {
      if (m.userId == userId) return m.role;
    }
    return null;
  }

  static Future<bool> updateMemberRole({
    required String teamId,
    required String userId,
    required B2BRole role,
  }) async {
    final members = await getTeamMembers(teamId);
    final idx = members.indexWhere((m) => m.userId == userId);
    if (idx < 0) return false;
    members[idx] = TeamMemberModel(
      userId: members[idx].userId,
      email: members[idx].email,
      displayName: members[idx].displayName,
      role: role,
      joinedAt: members[idx].joinedAt,
    );
    await setTeamMembers(teamId, members);
    return true;
  }

  static Future<List<TeamRouteModel>> listTeamRoutes(String teamId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kRoutes(teamId)) ?? const [];
    return list
        .map((e) => TeamRouteModel.fromJson(Map<String, dynamic>.from(jsonDecode(e) as Map)))
        .toList();
  }

  static Future<void> _saveTeamRoutes(String teamId, List<TeamRouteModel> routes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kRoutes(teamId),
      routes.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<TeamRouteModel> createTeamRoute(TeamRouteModel route) async {
    final existing = await listTeamRoutes(route.teamId);
    await _saveTeamRoutes(route.teamId, [...existing, route]);
    return route;
  }

  static Future<bool> deleteTeamRoute({required String teamId, required String routeId}) async {
    final existing = await listTeamRoutes(teamId);
    final next = existing.where((r) => r.id != routeId).toList();
    await _saveTeamRoutes(teamId, next);
    return next.length != existing.length;
  }

  static Future<TeamRouteModel?> getTeamRoute({required String teamId, required String routeId}) async {
    final existing = await listTeamRoutes(teamId);
    for (final r in existing) {
      if (r.id == routeId) return r;
    }
    return null;
  }
}
