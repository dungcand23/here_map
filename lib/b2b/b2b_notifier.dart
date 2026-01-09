import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/stop_model.dart';
import '../models/truck_option_model.dart';
import '../models/vehicle_model.dart';
import '../services/analytics_service.dart';
import 'models/b2b_role.dart';
import 'models/team_member_model.dart';
import 'models/team_model.dart';
import 'models/team_route_model.dart';
import 'models/user_profile_model.dart';
import 'repositories/b2b_container.dart';

class B2BNotifier extends ChangeNotifier {
  final B2BContainer _c;

  UserProfileModel? _user;
  TeamModel? _team;
  B2BRole? _role;

  List<TeamMemberModel> _members = const [];
  List<TeamRouteModel> _routes = const [];

  UserProfileModel? get user => _user;
  TeamModel? get team => _team;
  B2BRole? get role => _role;
  List<TeamMemberModel> get members => _members;
  List<TeamRouteModel> get routes => _routes;

  bool get isSignedIn => _user != null;
  bool get hasTeam => _team != null;
  bool get canEditRoutes => (_role ?? B2BRole.driver).canEditRoutes;
  bool get canManageTeam => (_role ?? B2BRole.driver).canManageTeam;

  B2BNotifier(this._c) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _user = await _c.auth.getCurrentUser();
    final teamId = await _c.session.getCurrentTeamId();
    if (teamId != null && teamId.trim().isNotEmpty && _user != null) {
      _team = await _c.teams.getTeamById(teamId);
      if (_team != null) {
        await _refreshTeamData();
      }
    }
    notifyListeners();
  }

  String authLabel() {
    if (_user == null) return 'Chưa đăng nhập';
    if (_team == null) return '${_user!.displayName} • chưa có team';
    final role = _role?.value ?? 'driver';
    return '${_user!.displayName} • ${_team!.name} ($role)';
  }

  Future<void> signIn({required String email, required String displayName}) async {
    _user = await _c.auth.signIn(email: email, displayName: displayName);
    await AnalyticsService.track('b2b_signed_in', {
      'user_id': _user!.id,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
    });
    notifyListeners();
  }

  Future<void> signOut() async {
    await _c.auth.signOut();
    await _c.session.setCurrentTeamId(null);
    _user = null;
    _team = null;
    _role = null;
    _members = const [];
    _routes = const [];
    await AnalyticsService.track('b2b_signed_out', {});
    notifyListeners();
  }

  Future<TeamModel?> createTeam(String name) async {
    final u = _user;
    if (u == null) return null;

    final team = await _c.teams.createTeam(
      name: name,
      createdByUserId: u.id,
      ownerUserId: u.id,
      ownerEmail: u.email,
      ownerDisplayName: u.displayName,
    );
    _team = team;
    await _c.session.setCurrentTeamId(team.id);
    await _refreshTeamData();

    await AnalyticsService.track('b2b_team_created', {'team_id': team.id, 'join_code': team.joinCode});
    notifyListeners();
    return team;
  }

  Future<TeamModel?> joinTeamByCode(String joinCode) async {
    final u = _user;
    if (u == null) return null;

    final team = await _c.teams.joinTeamByCode(
      joinCode: joinCode,
      userId: u.id,
      email: u.email,
      displayName: u.displayName,
    );
    if (team == null) return null;

    _team = team;
    await _c.session.setCurrentTeamId(team.id);
    await _refreshTeamData();

    await AnalyticsService.track('b2b_team_joined', {'team_id': team.id});
    notifyListeners();
    return team;
  }

  Future<void> leaveTeam() async {
    await _c.session.setCurrentTeamId(null);
    _team = null;
    _role = null;
    _members = const [];
    _routes = const [];
    await AnalyticsService.track('b2b_team_left', {});
    notifyListeners();
  }

  Future<void> _refreshTeamData() async {
    final u = _user;
    final t = _team;
    if (u == null || t == null) return;
    _members = await _c.teams.listMembers(t.id);
    _routes = await _c.routes.listTeamRoutes(t.id);
    _role = await _c.teams.getUserRole(teamId: t.id, userId: u.id) ?? B2BRole.driver;
  }

  Future<void> refresh() async {
    await _refreshTeamData();
    notifyListeners();
  }

  Future<bool> updateMemberRole(String userId, B2BRole role) async {
    if (!canManageTeam) return false;
    final t = _team;
    if (t == null) return false;
    final ok = await _c.teams.updateMemberRole(teamId: t.id, userId: userId, role: role);
    if (ok) {
      await _refreshTeamData();
      await AnalyticsService.track('b2b_member_role_updated', {'user_id': userId, 'role': role.value});
      notifyListeners();
    }
    return ok;
  }

  Future<TeamRouteModel?> saveCurrentRouteToTeam({
    required String name,
    required double distanceKm,
    required double durationMin,
    required List<StopModel> stops,
    required VehicleModel? vehicle,
    required TruckOptionModel truck,
    required bool trafficEnabled,
    required String mapMode,
  }) async {
    final u = _user;
    final t = _team;
    if (u == null || t == null) return null;
    if (!canEditRoutes) return null;

    final route = TeamRouteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teamId: t.id,
      name: name.trim().isEmpty ? 'Route' : name.trim(),
      distanceKm: distanceKm,
      durationMin: durationMin,
      stops: List<StopModel>.from(stops),
      vehicleMode: vehicle?.mode ?? 'car',
      truckOption: truck,
      trafficEnabled: trafficEnabled,
      mapMode: mapMode,
      createdBy: u.id,
      createdAt: DateTime.now(),
    );

    await _c.routes.createTeamRoute(route);
    await _refreshTeamData();

    await AnalyticsService.track('b2b_team_route_created', {
      'team_id': t.id,
      'route_id': route.id,
      'stop_count': stops.length,
    });

    notifyListeners();
    return route;
  }

  Future<bool> deleteTeamRoute(String routeId) async {
    if (!canEditRoutes) return false;
    final t = _team;
    if (t == null) return false;
    final ok = await _c.routes.deleteTeamRoute(teamId: t.id, routeId: routeId);
    if (ok) {
      await _refreshTeamData();
      await AnalyticsService.track('b2b_team_route_deleted', {'route_id': routeId});
      notifyListeners();
    }
    return ok;
  }
}
