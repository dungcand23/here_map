import '../../models/team_route_model.dart';
import '../../services/local_b2b_backend_service.dart';
import '../route_repository.dart';

class LocalRouteRepository implements RouteRepository {
  const LocalRouteRepository();

  @override
  Future<List<TeamRouteModel>> listTeamRoutes(String teamId) {
    return LocalB2BBackendService.listTeamRoutes(teamId);
  }

  @override
  Future<TeamRouteModel> createTeamRoute(TeamRouteModel route) {
    return LocalB2BBackendService.createTeamRoute(route);
  }

  @override
  Future<bool> deleteTeamRoute({required String teamId, required String routeId}) {
    return LocalB2BBackendService.deleteTeamRoute(teamId: teamId, routeId: routeId);
  }

  @override
  Future<TeamRouteModel?> getTeamRoute({required String teamId, required String routeId}) {
    return LocalB2BBackendService.getTeamRoute(teamId: teamId, routeId: routeId);
  }
}
