/// V3.8.3 申诉与主观题评分共用模型。V3.13 扩展加 aiDispute。
/// 一张表承载三类需家长介入的请求：
///   - appeal：小孩对错题判定不服，请家长复核（windowing：2h 内可发起）
///   - subjective_grading：主观题没有标准答案，提交后自动入家长打分队列
///   - ai_dispute（V3.13 新增）：worker 入库时发现答案算法冲突，做这道题后自动入家长审核
///     - 数据：Question.aiDispute 元数据描述差异点 + AI 推荐的 alt_answer
///     - 不影响奖励/任务（学情冻结）
///     - 家长决策后：approve 改 answer / reject 不动
enum ReviewRequestType { appeal, subjectiveGrading, aiDispute }

enum ReviewRequestStatus { pending, approved, rejected }

/// 主观题家长评分档位（appeal 类型为 null）
enum SubjectiveScore { perfect, good, pass, fail }

extension ReviewRequestTypeExt on ReviewRequestType {
  String get key {
    switch (this) {
      case ReviewRequestType.appeal: return 'appeal';
      case ReviewRequestType.subjectiveGrading: return 'subjective_grading';
      case ReviewRequestType.aiDispute: return 'ai_dispute';
    }
  }

  String get label {
    switch (this) {
      case ReviewRequestType.appeal: return '判错申诉';
      case ReviewRequestType.subjectiveGrading: return '主观题待批';
      case ReviewRequestType.aiDispute: return 'AI 标注争议';
    }
  }

  static ReviewRequestType fromKey(String s) {
    switch (s) {
      case 'subjective_grading': return ReviewRequestType.subjectiveGrading;
      case 'ai_dispute': return ReviewRequestType.aiDispute;
      default: return ReviewRequestType.appeal;
    }
  }
}

extension ReviewRequestStatusExt on ReviewRequestStatus {
  String get key {
    switch (this) {
      case ReviewRequestStatus.pending: return 'pending';
      case ReviewRequestStatus.approved: return 'approved';
      case ReviewRequestStatus.rejected: return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case ReviewRequestStatus.pending: return '待审核';
      case ReviewRequestStatus.approved: return '已通过';
      case ReviewRequestStatus.rejected: return '已驳回';
    }
  }

  static ReviewRequestStatus fromKey(String s) {
    switch (s) {
      case 'approved': return ReviewRequestStatus.approved;
      case 'rejected': return ReviewRequestStatus.rejected;
      default: return ReviewRequestStatus.pending;
    }
  }
}

extension SubjectiveScoreExt on SubjectiveScore {
  String get key {
    switch (this) {
      case SubjectiveScore.perfect: return 'perfect';
      case SubjectiveScore.good: return 'good';
      case SubjectiveScore.pass: return 'pass';
      case SubjectiveScore.fail: return 'fail';
    }
  }

  String get label {
    switch (this) {
      case SubjectiveScore.perfect: return '满分';
      case SubjectiveScore.good: return '良好';
      case SubjectiveScore.pass: return '合格';
      case SubjectiveScore.fail: return '不合格';
    }
  }

  /// 评分对应的奖励星数（与 RewardService 普通题 0.5⭐ 形成档差）
  double get stars {
    switch (this) {
      case SubjectiveScore.perfect: return 1.0;
      case SubjectiveScore.good:    return 0.7;
      case SubjectiveScore.pass:    return 0.5;
      case SubjectiveScore.fail:    return 0.0;
    }
  }

  /// 评分映射到 practice_records.is_correct（fail 不算对，其他都算对）
  bool get isCorrect => this != SubjectiveScore.fail;

  static SubjectiveScore? fromKey(String? s) {
    switch (s) {
      case 'perfect': return SubjectiveScore.perfect;
      case 'good': return SubjectiveScore.good;
      case 'pass': return SubjectiveScore.pass;
      case 'fail': return SubjectiveScore.fail;
      default: return null;
    }
  }
}

class ReviewRequest {
  final int? id;
  final ReviewRequestType requestType;
  final int questionId;
  /// 对应 practice_records.id；approve 时 UPDATE 这条 is_correct
  final int practiceRecordId;
  /// 来源 session id（重算 session 通过状态用；老练习无 session_id 时为 null）
  final String? sessionId;
  final String userAnswer;
  /// 申诉时的标准答案快照（题包将来如改答案不影响审核语境）；主观题为 null
  final String? standardAnswer;
  final ReviewRequestStatus status;
  final String? childNote;
  final String? parentNote;
  /// 主观题评分（appeal 类型为 null）
  final SubjectiveScore? parentScore;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const ReviewRequest({
    this.id,
    required this.requestType,
    required this.questionId,
    required this.practiceRecordId,
    this.sessionId,
    required this.userAnswer,
    this.standardAnswer,
    required this.status,
    this.childNote,
    this.parentNote,
    this.parentScore,
    required this.createdAt,
    this.reviewedAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'request_type': requestType.key,
        'question_id': questionId,
        'practice_record_id': practiceRecordId,
        'session_id': sessionId,
        'user_answer': userAnswer,
        'standard_answer': standardAnswer,
        'status': status.key,
        'child_note': childNote,
        'parent_note': parentNote,
        'parent_score': parentScore?.key,
        'created_at': createdAt.toIso8601String(),
        'reviewed_at': reviewedAt?.toIso8601String(),
      };

  factory ReviewRequest.fromMap(Map<String, dynamic> m) => ReviewRequest(
        id: m['id'] as int?,
        requestType:
            ReviewRequestTypeExt.fromKey(m['request_type'] as String),
        questionId: m['question_id'] as int,
        practiceRecordId: m['practice_record_id'] as int,
        sessionId: m['session_id'] as String?,
        userAnswer: m['user_answer'] as String,
        standardAnswer: m['standard_answer'] as String?,
        status: ReviewRequestStatusExt.fromKey(m['status'] as String),
        childNote: m['child_note'] as String?,
        parentNote: m['parent_note'] as String?,
        parentScore: SubjectiveScoreExt.fromKey(m['parent_score'] as String?),
        createdAt: DateTime.parse(m['created_at'] as String),
        reviewedAt: m['reviewed_at'] == null
            ? null
            : DateTime.parse(m['reviewed_at'] as String),
      );

  ReviewRequest copyWith({
    ReviewRequestStatus? status,
    String? parentNote,
    SubjectiveScore? parentScore,
    DateTime? reviewedAt,
  }) =>
      ReviewRequest(
        id: id,
        requestType: requestType,
        questionId: questionId,
        practiceRecordId: practiceRecordId,
        sessionId: sessionId,
        userAnswer: userAnswer,
        standardAnswer: standardAnswer,
        status: status ?? this.status,
        childNote: childNote,
        parentNote: parentNote ?? this.parentNote,
        parentScore: parentScore ?? this.parentScore,
        createdAt: createdAt,
        reviewedAt: reviewedAt ?? this.reviewedAt,
      );
}
