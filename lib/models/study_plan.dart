import 'subject.dart';

enum PlanStatus { pending, inProgress, completed, overdue }
enum PlanType { daily, weekly, monthly }

class StudyPlan {
  final int? id;
  final Subject subject;
  final String title;
  final String? description;
  final DateTime dueDate;
  final PlanType type;
  final PlanStatus status;
  final int estimatedMinutes;
  final DateTime createdAt;

  const StudyPlan({
    this.id,
    required this.subject,
    required this.title,
    this.description,
    required this.dueDate,
    required this.type,
    this.status = PlanStatus.pending,
    required this.estimatedMinutes,
    required this.createdAt,
  });

  StudyPlan copyWith({
    int? id,
    Subject? subject,
    String? title,
    String? description,
    DateTime? dueDate,
    PlanType? type,
    PlanStatus? status,
    int? estimatedMinutes,
    DateTime? createdAt,
  }) {
    return StudyPlan(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      type: type ?? this.type,
      status: status ?? this.status,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'subject': subject.index,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'type': type.index,
      'status': status.index,
      'estimated_minutes': estimatedMinutes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StudyPlan.fromMap(Map<String, dynamic> map) {
    return StudyPlan(
      id: map['id'] as int?,
      subject: Subject.values[map['subject'] as int],
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: DateTime.parse(map['due_date'] as String),
      type: PlanType.values[map['type'] as int],
      status: PlanStatus.values[map['status'] as int],
      estimatedMinutes: map['estimated_minutes'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
