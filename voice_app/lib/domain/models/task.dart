class Task {
  final String id;
  final String title;
  final String? description;
  final String priority; // 'low' | 'medium' | 'high'
  final String status; // 'pending' | 'in_progress' | 'completed'
  final String? dueDate;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Joined data
  final TaskCreator? creator;
  final List<TaskAssignment> assignments;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.priority = 'medium',
    this.status = 'pending',
    this.dueDate,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.creator,
    this.assignments = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pending',
      dueDate: json['dueDate'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      creator: json['creator'] != null
          ? TaskCreator.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
      assignments: (json['assignments'] as List<dynamic>?)
              ?.map(
                  (e) => TaskAssignment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority,
        'status': status,
        'dueDate': dueDate,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  bool get isHighPriority => priority == 'high';
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
}

class TaskCreator {
  final String id;
  final String name;
  final String? profilePhoto;

  const TaskCreator({
    required this.id,
    required this.name,
    this.profilePhoto,
  });

  factory TaskCreator.fromJson(Map<String, dynamic> json) => TaskCreator(
        id: json['id'] as String,
        name: json['name'] as String,
        profilePhoto: json['profilePhoto'] as String?,
      );
}

class TaskAssignment {
  final String id;
  final String taskId;
  final String memberId;
  final TaskAssignedMember? member;

  const TaskAssignment({
    required this.id,
    required this.taskId,
    required this.memberId,
    this.member,
  });

  factory TaskAssignment.fromJson(Map<String, dynamic> json) =>
      TaskAssignment(
        id: json['id'] as String,
        taskId: json['taskId'] as String,
        memberId: json['memberId'] as String,
        member: json['member'] != null
            ? TaskAssignedMember.fromJson(
                json['member'] as Map<String, dynamic>)
            : null,
      );
}

class TaskAssignedMember {
  final String id;
  final String name;
  final String? profilePhoto;

  const TaskAssignedMember({
    required this.id,
    required this.name,
    this.profilePhoto,
  });

  factory TaskAssignedMember.fromJson(Map<String, dynamic> json) =>
      TaskAssignedMember(
        id: json['id'] as String,
        name: json['name'] as String,
        profilePhoto: json['profilePhoto'] as String?,
      );
}

class Notice {
  final String id;
  final String title;
  final String content;
  final String? postedBy;
  final String? department;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Notice({
    required this.id,
    required this.title,
    required this.content,
    this.postedBy,
    this.department,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        postedBy: json['postedBy'] as String?,
        department: json['department'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'postedBy': postedBy,
        'department': department,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class LeaveRequest {
  final String id;
  final String memberId;
  final String? reason;
  final String startDate;
  final String? endDate;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? approvedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LeaveRequest({
    required this.id,
    required this.memberId,
    this.reason,
    required this.startDate,
    this.endDate,
    this.status = 'pending',
    this.approvedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) => LeaveRequest(
        id: json['id'] as String,
        memberId: json['memberId'] as String,
        reason: json['reason'] as String?,
        startDate: json['startDate'] as String,
        endDate: json['endDate'] as String?,
        status: json['status'] as String? ?? 'pending',
        approvedBy: json['approvedBy'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'reason': reason,
        'startDate': startDate,
        'endDate': endDate,
        'status': status,
        'approvedBy': approvedBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
}
