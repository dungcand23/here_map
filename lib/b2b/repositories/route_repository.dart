import '../models/team_route_model.dart';

/// Contract quản lý routes trong team.
abstract class RouteRepository {
  Future<List<TeamRouteModel>> listTeamRoutes(String teamId);

  Future<TeamRouteModel> createTeamRoute(TeamRouteModel route);

  Future<bool> deleteTeamRoute({required String teamId, required String routeId});

  Future<TeamRouteModel?> getTeamRoute({required String teamId, required String routeId});
}
