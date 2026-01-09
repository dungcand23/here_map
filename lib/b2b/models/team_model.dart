class TeamModel {
  final String id;
  final String name;
  /// Code ngắn để join team (share qua Zalo/Slack...)
  final String joinCode;
  final String createdBy;
  final DateTime createdAt;

  const TeamModel({
    required this.id,
    required this.name,
    required this.joinCode,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'joinCode': joinCode,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      joinCode: (json['joinCode'] ?? '').toString(),
      createdBy: (json['createdBy'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
