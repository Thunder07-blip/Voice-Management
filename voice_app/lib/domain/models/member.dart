class Member {
  final String id;
  final String name;
  final String? profilePhoto;
  final String? college;
  final String? year;
  final String memberType; // 'student' | 'working'
  final String? groupId;
  final String? roleId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Joined data
  final Group? group;
  final Role? role;

  const Member({
    required this.id,
    required this.name,
    this.profilePhoto,
    this.college,
    this.year,
    this.memberType = 'student',
    this.groupId,
    this.roleId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.group,
    this.role,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      name: json['name'] as String,
      profilePhoto: json['profilePhoto'] as String?,
      college: json['college'] as String?,
      year: json['year'] as String?,
      memberType: json['memberType'] as String? ?? 'student',
      groupId: json['groupId'] as String?,
      roleId: json['roleId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      group: json['group'] != null
          ? Group.fromJson(json['group'] as Map<String, dynamic>)
          : null,
      role: json['role'] != null
          ? Role.fromJson(json['role'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'profilePhoto': profilePhoto,
        'college': college,
        'year': year,
        'memberType': memberType,
        'groupId': groupId,
        'roleId': roleId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  /// Returns initials for avatar (e.g., "SP" for "Sajal Patil")
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  bool get isStudent => memberType == 'student';
}

class Group {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Group({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class Role {
  final String id;
  final String name;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Role({
    required this.id,
    required this.name,
    this.permissions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) => Role(
        id: json['id'] as String,
        name: json['name'] as String,
        permissions: (json['permissions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'permissions': permissions,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
