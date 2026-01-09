import '../models/b2b_role.dart';
import '../models/team_member_model.dart';
import '../models/team_model.dart';

/// Contract quản lý team/workspace.
abstract class TeamRepository {
  Future<TeamModel> createTeam({
    required String name,
    required String createdByUserId,
    required String ownerUserId,
    required String ownerEmail,
    required String ownerDisplayName,
  });

  /// Join team dựa theo joinCode.
  /// Implementation nên tự upsert member (role default: driver) nếu join thành công.
  Future<TeamModel?> joinTeamByCode({
    required String joinCode,
    required String userId,
    required String email,
    required String displayName,
  });

  Future<TeamModel?> getTeamById(String teamId);

  Future<List<TeamMemberModel>> listMembers(String teamId);

  Future<B2BRole?> getUserRole({required String teamId, required String userId});

  Future<bool> updateMemberRole({
    required String teamId,
    required String userId,
    required B2BRole role,
  });
}
