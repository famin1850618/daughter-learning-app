import 'package:flutter/foundation.dart';
import '../database/question_dao.dart';
import '../database/review_request_dao.dart';
import '../models/question.dart';
import '../models/review_request.dart';
import 'reward_service.dart';

/// 申诉资格检查结果
enum AppealEligibility {
  ok,
  alreadySubmitted, // 这条 record 已发起过申诉
  outOfWindow,      // 超出 2 小时窗口
  notWrong,         // 答对的题不能申诉
  recordNotFound,   // 找不到答题记录
}

/// 审核通过后的回调上下文（main.dart 用来触发 plan/assessment 重算）
class ApproveContext {
  final ReviewRequestType requestType;
  final int questionId;
  /// V3.13 修正：aiDispute 无关联做题，practiceRecordId 为 null
  final int? practiceRecordId;
  final String? sessionId;
  final SubjectiveScore? score;
  final bool nowCorrect;

  const ApproveContext({
    required this.requestType,
    required this.questionId,
    required this.practiceRecordId,
    required this.sessionId,
    required this.score,
    required this.nowCorrect,
  });
}

/// V3.8.3：判错申诉 + 主观题评分共用 service
///
/// 副作用全套：
///   1. UPDATE review_requests.status
///   2. UPDATE practice_records.is_correct
///   3. 补发⭐（申诉=0.5⭐，主观题按评分档位）
///   4. 通过 onApproved 回调通知 main.dart：
///      - 重判 session 通过状态（必要时用 RewardService.recordBonusOnly 补发加成）
///      - 重新触发 PlanService.autoCompleteFromPractice
///      - AssessmentService.refresh
///   5. notifyListeners 让 UI 重绘 pending count / 错题集
///
/// 申诉窗口：基于 practice_records.practiced_at，2 小时内可发起。
class ReviewRequestService extends ChangeNotifier {
  final ReviewRequestDao _dao = ReviewRequestDao();
  final QuestionDao _qDao = QuestionDao();
  final RewardService _rewardService;

  ReviewRequestService(this._rewardService);

  static const Duration appealWindow = Duration(hours: 2);

  /// main.dart 注入：审核通过后触发 plan/assessment 重算
  Future<void> Function(ApproveContext)? onApproved;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  Map<int, ReviewRequest> _byRecordId = {};

  /// 已发起过申诉/审核的 record id → 最新一条 request；UI 用于显示状态徽章
  ReviewRequest? requestForRecord(int recordId) => _byRecordId[recordId];

  bool _aiDisputesSeeded = false;

  Future<void> refresh() async {
    // V3.13 修正：首次 refresh 时扫题库 INSERT aiDispute review_requests（小孩不做题直接审核）
    if (!_aiDisputesSeeded) {
      try {
        await seedAiDisputesFromQuestions();
      } catch (_) {/* 失败不阻塞 refresh */}
      _aiDisputesSeeded = true;
    }
    final all = await _dao.listByStatus(ReviewRequestStatus.pending);
    final approved = await _dao.listByStatus(ReviewRequestStatus.approved);
    final rejected = await _dao.listByStatus(ReviewRequestStatus.rejected);
    _pendingCount = all.length;
    final map = <int, ReviewRequest>{};
    for (final r in [...approved, ...rejected, ...all]) {
      // 后写覆盖前写：pending 最新
      // V3.13 修正：aiDispute 的 practiceRecordId 为 null，不入此 map（map 仅给做题历史用）
      if (r.practiceRecordId != null) map[r.practiceRecordId!] = r;
    }
    _byRecordId = map;
    notifyListeners();
  }

  // ── 提交申诉 ──────────────────────────────────────

  /// 检查这条 practice_record 是否可申诉
  Future<AppealEligibility> checkAppealEligibility(int recordId) async {
    final existing = await _dao.findByPracticeRecordId(recordId);
    if (existing != null) return AppealEligibility.alreadySubmitted;
    final record = await _qDao.findPracticeRecord(recordId);
    if (record == null) return AppealEligibility.recordNotFound;
    if (record.isCorrect) return AppealEligibility.notWrong;
    final age = DateTime.now().difference(record.practicedAt);
    if (age >= appealWindow) return AppealEligibility.outOfWindow;
    return AppealEligibility.ok;
  }

  /// 申诉提交。返回新 request id；不可申诉返回 null（UI 应先 checkAppealEligibility）
  Future<int?> submitAppeal({
    required int practiceRecordId,
    String? childNote,
  }) async {
    final eligibility = await checkAppealEligibility(practiceRecordId);
    if (eligibility != AppealEligibility.ok) return null;

    final record = await _qDao.findPracticeRecord(practiceRecordId);
    if (record == null) return null;
    final question = await _qDao.findById(record.questionId);
    if (question == null) return null;

    final id = await _dao.insert(ReviewRequest(
      requestType: ReviewRequestType.appeal,
      questionId: record.questionId,
      practiceRecordId: practiceRecordId,
      sessionId: record.sessionId,
      userAnswer: record.userAnswer,
      standardAnswer: question.answer,
      status: ReviewRequestStatus.pending,
      childNote: childNote,
      createdAt: DateTime.now(),
    ));
    await refresh();
    return id;
  }

  /// 主观题答完后由 PracticeService 调用，自动入审核队列。
  /// 不限 2h 窗口，不要求是错题（主观题 is_correct=false 是默认的"待批"标记）。
  Future<int?> submitSubjectiveGrading({
    required int practiceRecordId,
    String? childNote,
  }) async {
    final existing = await _dao.findByPracticeRecordId(practiceRecordId);
    if (existing != null) return null;
    final record = await _qDao.findPracticeRecord(practiceRecordId);
    if (record == null) return null;

    final id = await _dao.insert(ReviewRequest(
      requestType: ReviewRequestType.subjectiveGrading,
      questionId: record.questionId,
      practiceRecordId: practiceRecordId,
      sessionId: record.sessionId,
      userAnswer: record.userAnswer,
      standardAnswer: null,
      status: ReviewRequestStatus.pending,
      childNote: childNote,
      createdAt: DateTime.now(),
    ));
    await refresh();
    return id;
  }

  /// V3.13 修正（Famin 反馈）：AI 争议题在题库导入后由启动钩子直接 INSERT review_request，
  /// 不让小孩做题。practice_record_id 为 null。
  /// 调用入口：app 启动 / 题库更新后 → seedAiDisputesFromQuestions()
  Future<int?> createAiDisputeFromQuestion({
    required int questionId,
    required Map<String, dynamic> aiDisputeMeta,
    required String currentAnswer,
  }) async {
    // 去重：同 question_id + type=aiDispute 已存在则跳（含 pending/已审）
    final existing = await _dao.findExistingByQuestionAndType(
        questionId, ReviewRequestType.aiDispute);
    if (existing != null) return null;

    final reason = aiDisputeMeta['reason'] as String? ?? 'AI 标注答案有疑问';
    final alt = aiDisputeMeta['alt_answer'] as String? ?? '';
    final summary = alt.isEmpty ? reason : '$reason\nAI 推荐答案: $alt';

    final id = await _dao.insert(ReviewRequest(
      requestType: ReviewRequestType.aiDispute,
      questionId: questionId,
      practiceRecordId: null, // V3.13 修正：不关联做题
      sessionId: null,
      userAnswer: '', // 没小孩答
      standardAnswer: currentAnswer,
      status: ReviewRequestStatus.pending,
      childNote: summary,
      createdAt: DateTime.now(),
    ));
    await refresh();
    return id;
  }

  /// V3.13 启动钩子：扫题库找含 ai_dispute_json 的题，自动 INSERT 待审核 review_request。
  /// app 启动 / 题库更新后调用。已存在的不重复 INSERT（findExistingByQuestionAndType 去重）。
  Future<int> seedAiDisputesFromQuestions() async {
    final questions = await _qDao.findAllWithAiDispute();
    int inserted = 0;
    for (final q in questions) {
      if (q.id == null || q.aiDispute == null) continue;
      final id = await createAiDisputeFromQuestion(
        questionId: q.id!,
        aiDisputeMeta: q.aiDispute!,
        currentAnswer: q.answer,
      );
      if (id != null) inserted++;
    }
    return inserted;
  }

  // ── 审核 ──────────────────────────────────────────

  /// 审核通过 - 副作用全套
  /// [score]：主观题必传；申诉类传 null
  Future<void> approve({
    required int requestId,
    String? parentNote,
    SubjectiveScore? score,
  }) async {
    final req = await _dao.findById(requestId);
    if (req == null || req.status != ReviewRequestStatus.pending) return;
    if (req.requestType == ReviewRequestType.subjectiveGrading && score == null) {
      throw ArgumentError('subjective_grading approve requires SubjectiveScore');
    }

    // 1) 决定 record 状态 + 奖励
    final bool nowCorrect;
    final double rewardStars;
    final String rewardSource;
    final String rewardNote;

    if (req.requestType == ReviewRequestType.appeal) {
      nowCorrect = true;
      rewardStars = 0.5;
      rewardSource = 'appeal_approved';
      rewardNote = '申诉通过补发';
    } else if (req.requestType == ReviewRequestType.aiDispute) {
      // V3.13 修正：AI 争议题不关联做题（practice_record_id 为 null）
      // approve = 家长认 "AI 推荐答案对" → 标 nowCorrect=true（仅记录，无 record 重判）
      nowCorrect = true;
      rewardStars = 0.0; // 不发奖励（小孩没做题）
      rewardSource = 'ai_dispute_approved';
      rewardNote = '家长采纳 AI 推荐答案';
    } else {
      // subjective_grading
      final s = score!;
      nowCorrect = s.isCorrect;
      rewardStars = s.stars;
      rewardSource = 'subjective_${s.key}';
      rewardNote = '主观题评分：${s.label}';
    }

    // 2) UPDATE review_requests
    await _dao.updateStatus(
      id: requestId,
      status: ReviewRequestStatus.approved,
      parentNote: parentNote,
      parentScore: score,
      reviewedAt: DateTime.now(),
    );

    // 3) UPDATE practice_records.is_correct（subjective 默认 false，approve 后视评分调整）
    // V3.13 修正：aiDispute 无关联 record，跳过
    if (req.practiceRecordId != null) {
      await _qDao.updatePracticeRecordIsCorrect(req.practiceRecordId!, nowCorrect);
    }

    // 4) 补发⭐
    if (rewardStars > 0) {
      await _rewardService.recordAdHoc(
        source: rewardSource,
        stars: rewardStars,
        sessionId: req.sessionId,
        note: rewardNote,
      );
    }

    // 5) 通知 main.dart 编排副作用（plan/assessment/session bonus 重判）
    await onApproved?.call(ApproveContext(
      requestType: req.requestType,
      questionId: req.questionId,
      practiceRecordId: req.practiceRecordId,
      sessionId: req.sessionId,
      score: score,
      nowCorrect: nowCorrect,
    ));

    await refresh();
  }

  /// 审核驳回 - 仅状态更新（subjective fail 等价于 reject 也可以，但这里保留 reject 让家长直接驳回 = 不打分）
  Future<void> reject({
    required int requestId,
    String? parentNote,
  }) async {
    final req = await _dao.findById(requestId);
    if (req == null || req.status != ReviewRequestStatus.pending) return;
    await _dao.updateStatus(
      id: requestId,
      status: ReviewRequestStatus.rejected,
      parentNote: parentNote,
      reviewedAt: DateTime.now(),
    );
    await refresh();
  }

  // ── 列表查询（UI 家长审核屏用）────────────────────────

  Future<List<ReviewRequest>> listPending({ReviewRequestType? type}) =>
      _dao.listByStatus(ReviewRequestStatus.pending, type: type);

  Future<List<ReviewRequest>> listApproved({ReviewRequestType? type}) =>
      _dao.listByStatus(ReviewRequestStatus.approved, type: type);

  Future<List<ReviewRequest>> listRejected({ReviewRequestType? type}) =>
      _dao.listByStatus(ReviewRequestStatus.rejected, type: type);

  /// 联动 question 取完整审核上下文（家长审核屏卡片用）
  Future<({ReviewRequest req, Question? q})> loadDetail(int requestId) async {
    final req = await _dao.findById(requestId);
    if (req == null) {
      throw StateError('ReviewRequest $requestId not found');
    }
    final q = await _qDao.findById(req.questionId);
    return (req: req, q: q);
  }

  /// 学情同步用：所有非 pending 条目
  Future<List<ReviewRequest>> listReviewedForExport() =>
      _dao.listReviewedForExport();
}
