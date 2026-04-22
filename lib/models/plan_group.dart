enum PlanGroupType { day, week, month }

class PlanItemDraft {
  final int chapterId;
  final String chapterName;
  final String subjectName;
  final String subjectEmoji;
  final int grade;
  final String? knowledgePoint;

  const PlanItemDraft({
    required this.chapterId,
    required this.chapterName,
    required this.subjectName,
    required this.subjectEmoji,
    required this.grade,
    this.knowledgePoint,
  });

  String get displayTitle => knowledgePoint != null && knowledgePoint!.isNotEmpty
      ? '$chapterName · $knowledgePoint'
      : chapterName;
}
enum PlanGroupStatus { pending, completed }

class PlanGroup {
  final int? id;
  final PlanGroupType type;
  final int? parentId;
  final DateTime startDate;
  final DateTime endDate;
  PlanGroupStatus status;
  final DateTime createdAt;

  // 运行时聚合，不存库
  List<PlanItem> items = [];       // 仅日计划有直接 items
  List<PlanGroup> children = [];   // 周计划 children = 日; 月计划 children = 周
  double get completionRate {
    if (type == PlanGroupType.day) {
      if (items.isEmpty) return 0;
      return items.where((i) => i.status == PlanItemStatus.completed).length / items.length;
    }
    if (children.isEmpty) return 0;
    final allItems = children.expand((c) => c.allItems).toList();
    if (allItems.isEmpty) return 0;
    return allItems.where((i) => i.status == PlanItemStatus.completed).length / allItems.length;
  }

  List<PlanItem> get allItems {
    if (type == PlanGroupType.day) return items;
    return children.expand((c) => c.allItems).toList();
  }

  PlanGroup({
    this.id,
    required this.type,
    this.parentId,
    required this.startDate,
    required this.endDate,
    this.status = PlanGroupStatus.pending,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'type': type.index,
    'parent_id': parentId,
    'start_date': startDate.toIso8601String().substring(0, 10),
    'end_date': endDate.toIso8601String().substring(0, 10),
    'status': status.index,
    'created_at': createdAt.toIso8601String(),
  };

  factory PlanGroup.fromMap(Map<String, dynamic> m) => PlanGroup(
    id: m['id'] as int?,
    type: PlanGroupType.values[m['type'] as int],
    parentId: m['parent_id'] as int?,
    startDate: DateTime.parse(m['start_date'] as String),
    endDate: DateTime.parse(m['end_date'] as String),
    status: PlanGroupStatus.values[m['status'] as int],
    createdAt: DateTime.parse(m['created_at'] as String),
  );

  String get typeLabel => ['日', '周', '月'][type.index];
}

// ─────────────────────────────────────────
// 计划条目（永远挂在日计划下）
// ─────────────────────────────────────────
enum PlanItemStatus { pending, completed }

class PlanItem {
  final int? id;
  final int dayPlanId;
  final int chapterId;
  final String chapterName;
  final String subjectName;
  final String subjectEmoji;
  final int grade;
  final String? knowledgePoint;
  PlanItemStatus status;
  DateTime? completedAt;
  final int? originMonthPlanId;
  final int? originWeekPlanId;

  PlanItem({
    this.id,
    required this.dayPlanId,
    required this.chapterId,
    required this.chapterName,
    required this.subjectName,
    required this.subjectEmoji,
    required this.grade,
    this.knowledgePoint,
    this.status = PlanItemStatus.pending,
    this.completedAt,
    this.originMonthPlanId,
    this.originWeekPlanId,
  });

  String get displayTitle =>
      knowledgePoint != null && knowledgePoint!.isNotEmpty
          ? '$chapterName · $knowledgePoint'
          : chapterName;

  String get gradeLabel {
    const map = {6: '六年级', 7: '初一', 8: '初二', 9: '初三'};
    return map[grade] ?? '$grade年级';
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'day_plan_id': dayPlanId,
    'chapter_id': chapterId,
    'chapter_name': chapterName,
    'subject_name': subjectName,
    'subject_emoji': subjectEmoji,
    'grade': grade,
    'knowledge_point': knowledgePoint,
    'status': status.index,
    'completed_at': completedAt?.toIso8601String(),
    'origin_month_plan_id': originMonthPlanId,
    'origin_week_plan_id': originWeekPlanId,
  };

  factory PlanItem.fromMap(Map<String, dynamic> m) => PlanItem(
    id: m['id'] as int?,
    dayPlanId: m['day_plan_id'] as int,
    chapterId: m['chapter_id'] as int,
    chapterName: m['chapter_name'] as String,
    subjectName: m['subject_name'] as String,
    subjectEmoji: m['subject_emoji'] as String? ?? '📚',
    grade: m['grade'] as int,
    knowledgePoint: m['knowledge_point'] as String?,
    status: PlanItemStatus.values[m['status'] as int],
    completedAt: m['completed_at'] != null
        ? DateTime.parse(m['completed_at'] as String)
        : null,
    originMonthPlanId: m['origin_month_plan_id'] as int?,
    originWeekPlanId: m['origin_week_plan_id'] as int?,
  );
}
