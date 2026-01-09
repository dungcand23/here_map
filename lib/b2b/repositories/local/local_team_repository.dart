import '../../models/b2b_role.dart';
import '../../models/team_member_model.dart';
import '../../models/team_model.dart';
import '../../services/local_b2b_backend_service.dart';
import '../team_repository.dart';

class LocalTeamRepository implements TeamRepository {
  const LocalTeamRepository();

  @override
  Future<TeamModel> createTeam({
    required String name,
    required String createdByUserId,
    required String ownerUserId,
    required String ownerEmail,
    required String ownerDisplayName,
  }) {
    return LocalB2BBackendService.createTeam(
      name: name,
      createdBy: createdByUserId,
      ownerUserId: ownerUserId,
      ownerEmail: ownerEmail,
      ownerDisplayName: ownerDisplayName,
    );
  }

  @override
  Future<TeamModel?> joinTeamByCode({
    required String joinCode,
    required String userId,
    required String email,
    required String displayName,
  }) async {
    final team = await LocalB2BBackendService.findTeamByJoinCode(joinCode);
    if (team == null) return null;
    await LocalB2BBackendService.upsertMember(
      team: team,
      userId: userId,
      email: email,
      displayName: displayName,
      role: B2BRole.driver,
    );
    return team;
  }

  @override
  Future<TeamModel?> getTeamById(String teamId) async {
    final teams = await LocalB2BBackendService.listTeams();
    for (final t in teams) {
      if (t.id == teamId) return t;
    }
    return null;
  }

  @override
  Future<List<TeamMemberModel>> listMembers(String teamId) => LocalB2BBackendService.getTeamMembers(teamId);

  @override
  Future<B2BRole?> getUserRole({required String teamId, required String userId}) {
    return LocalB2BBackendService.getUserRole(teamId, userId);
  }

  @override
  Future<bool> updateMemberRole({required String teamId, required String userId, required B2BRole role}) {
    return LocalB2BBackendService.updateMemberRole(teamId: teamId, userId: userId, role: role);
  }
}
