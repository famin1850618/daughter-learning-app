/// 周/月测评记录
enum AssessmentType { weekly, monthly }

enum AssessmentStatus { locked, available, passed, failed }

class Assessment {
  final int? id;
  final AssessmentType type;
  /// 周："2026-W18"，月："2026-05"
  final String periodKey;
  final AssessmentStatus status;
  final int score;
  final int total;
  final DateTime? takenAt;
  final String userId;

  Assessment({
    this.id,
    required this.type,
    required this.periodKey,
    required this.status,
    this.score = 0,
    this.total = 0,
    this.takenAt,
    this.userId = 'local',
  });

  double get percent => total == 0 ? 0 : score / total;
  bool get isPerfect => total > 0 && score == total;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'type': type.index,
        'period_key': periodKey,
        'status': status.index,
        'score': score,
        'total': total,
        'taken_at': takenAt?.toIso8601String(),
        'user_id': userId,
      };

  factory Assessment.fromMap(Map<String, dynamic> m) => Assessment(
        id: m['id'] as int?,
        type: AssessmentType.values[m['type'] as int],
        periodKey: m['period_key'] as String,
        status: AssessmentStatus.values[m['status'] as int],
        score: m['score'] as int? ?? 0,
        total: m['total'] as int? ?? 0,
        takenAt: m['taken_at'] == null
            ? null
            : DateTime.parse(m['taken_at'] as String),
        userId: (m['user_id'] as String?) ?? 'local',
      );

  Assessment copyWith({
    AssessmentStatus? status,
    int? score,
    int? total,
    DateTime? takenAt,
  }) =>
      Assessment(
        id: id,
        type: type,
        periodKey: periodKey,
        status: status ?? this.status,
        score: score ?? this.score,
        total: total ?? this.total,
        takenAt: takenAt ?? this.takenAt,
        userId: userId,
      );
}

/// 周键：基于 ISO 周（周一为周首）"2026-W18"
String weekKey(DateTime d) {
  final monday = d.subtract(Duration(days: (d.weekday - 1)));
  final firstDay = DateTime(monday.year, 1, 1);
  final dayOfYear = monday.difference(firstDay).inDays + 1;
  final weekNum = ((dayOfYear - monday.weekday + 10) / 7).floor();
  return '${monday.year}-W${weekNum.toString().padLeft(2, '0')}';
}

String monthKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';
