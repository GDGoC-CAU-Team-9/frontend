class TeamModel {
  final int teamMemberId;
  final int? teamId;
  final String teamName;
  final List<String> members;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TeamModel({
    required this.teamMemberId,
    this.teamId,
    required this.teamName,
    this.members = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      teamMemberId: json['teamMemberId'] as int,
      teamId: json['teamId'] as int?,
      teamName: json['teamName'] as String,
      members:
          (json['members'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamMemberId': teamMemberId,
      'teamId': teamId,
      'teamName': teamName,
      'members': members,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class TeamPageResult {
  final List<TeamModel> teamMembers;
  final int totalPages;
  final int totalElements;

  TeamPageResult({
    required this.teamMembers,
    required this.totalPages,
    required this.totalElements,
  });

  factory TeamPageResult.fromJson(Map<String, dynamic> json) {
    return TeamPageResult(
      teamMembers:
          (json['teamMembers'] as List<dynamic>?)
              ?.map((e) => TeamModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalPages: json['totalPages'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamMembers': teamMembers.map((e) => e.toJson()).toList(),
      'totalPages': totalPages,
      'totalElements': totalElements,
    };
  }
}
