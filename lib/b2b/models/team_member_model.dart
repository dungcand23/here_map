import 'b2b_role.dart';

class TeamMemberModel {
  final String userId;
  final String email;
  final String displayName;
  final B2BRole role;
  final DateTime joinedAt;

  const TeamMemberModel({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'displayName': displayName,
        'role': role.value,
        'joinedAt': joinedAt.toIso8601String(),
      };

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamMemberModel(
      userId: (json['userId'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      role: B2BRole.fromString((json['role'] ?? 'driver').toString()),
      joinedAt: DateTime.tryParse((json['joinedAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
