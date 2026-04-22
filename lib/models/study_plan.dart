import 'subject.dart';

enum PlanStatus { pending, inProgress, completed, overdue }
enum PlanType { daily, weekly, monthly }

class StudyPlan {
  final int? id;
  final Subject subject;
  final int grade;           // 6/7/8/9
  final int? chapterId;      // 关联 curriculum.id
  final String chapterName;  // 冗余存储，方便显示
  final String? knowledgePoint; // 可选的具体知识点
  final String? description;
  final DateTime dueDate;
  final PlanType type;
  final PlanStatus status;
  final int estimatedMinutes;
  final DateTime createdAt;

  const StudyPlan({
    this.id,
    required this.subject,
    required this.grade,
    this.chapterId,
    required this.chapterName,
    this.knowledgePoint,
    this.description,
    required this.dueDate,
    required this.type,
    this.status = PlanStatus.pending,
    required this.estimatedMinutes,
    required this.createdAt,
  });

  /// 计划的显示标题：章节名 + 可选知识点
  String get displayTitle {
    if (knowledgePoint != null && knowledgePoint!.isNotEmpty) {
      return '$chapterName · $knowledgePoint';
    }
    return chapterName;
  }

  String get gradeLabel {
    const map = {6: '六年级', 7: '初一', 8: '初二', 9: '初三'};
    return map[grade] ?? '$grade年级';
  }

  StudyPlan copyWith({
    int? id,
    Subject? subject,
    int? grade,
    int? chapterId,
    String? chapterName,
    String? knowledgePoint,
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
      grade: grade ?? this.grade,
      chapterId: chapterId ?? this.chapterId,
      chapterName: chapterName ?? this.chapterName,
      knowledgePoint: knowledgePoint ?? this.knowledgePoint,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      type: type ?? this.type,
      status: status ?? this.status,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'subject': subject.index,
    'grade': grade,
    'chapter_id': chapterId,
    'chapter_name': chapterName,
    'knowledge_point': knowledgePoint,
    'description': description,
    'due_date': dueDate.toIso8601String(),
    'type': type.index,
    'status': status.index,
    'estimated_minutes': estimatedMinutes,
    'created_at': createdAt.toIso8601String(),
  };

  factory StudyPlan.fromMap(Map<String, dynamic> m) => StudyPlan(
    id: m['id'] as int?,
    subject: Subject.values[m['subject'] as int],
    grade: m['grade'] as int? ?? 6,
    chapterId: m['chapter_id'] as int?,
    chapterName: m['chapter_name'] as String? ?? m['title'] as String? ?? '',
    knowledgePoint: m['knowledge_point'] as String?,
    description: m['description'] as String?,
    dueDate: DateTime.parse(m['due_date'] as String),
    type: PlanType.values[m['type'] as int],
    status: PlanStatus.values[m['status'] as int],
    estimatedMinutes: m['estimated_minutes'] as int,
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}
