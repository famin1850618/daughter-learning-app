import 'package:flutter/foundation.dart';
import '../database/assessment_dao.dart';
import '../database/plan_group_dao.dart';
import '../database/plan_item_dao.dart';
import '../database/question_dao.dart';
import '../models/assessment.dart';
import '../models/plan_group.dart';
import '../models/question.dart';
import '../utils/plan_date_utils.dart';
import 'reward_service.dart';

/// 测评单元：按 (chapter[+KP]) 维度抽题
class _Unit {
  final String chapterName;
  final String? knowledgePoint;
  final String subjectName;
  final int grade;
  _Unit({
    required this.chapterName,
    required this.knowledgePoint,
    required this.subjectName,
    required this.grade,
  });
  String get key => '$subjectName|$grade|$chapterName|${knowledgePoint ?? ''}';
  String get label =>
      knowledgePoint != null ? '$chapterName · $knowledgePoint' : chapterName;
}

class AssessmentBuildResult {
  final List<Question> questions;
  final List<String> warnings; // 题不足等提示
  AssessmentBuildResult(this.questions, this.warnings);
}

class AssessmentSnapshot {
  final AssessmentType type;
  final String periodKey;
  final AssessmentStatus status;
  final int unitCount;
  final int targetTotal; // KP×3
  final Assessment? latest;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  AssessmentSnapshot({
    required this.type,
    required this.periodKey,
    required this.status,
    required this.unitCount,
    required this.targetTotal,
    this.latest,
    this.periodStart,
    this.periodEnd,
  });
}

class AssessmentService extends ChangeNotifier {
  final _planGroupDao = PlanGroupDao();
  final _planItemDao = PlanItemDao();
  final _questionDao = QuestionDao();
  final _dao = AssessmentDao();

  AssessmentSnapshot? _weekly;
  AssessmentSnapshot? _monthly;

  AssessmentSnapshot? get weekly => _weekly;
  AssessmentSnapshot? get monthly => _monthly;

  /// 重新计算当周/月解锁状态
  Future<void> refresh() async {
    final now = DateTime.now();
    _weekly = await _buildSnapshot(AssessmentType.weekly, now);
    _monthly = await _buildSnapshot(AssessmentType.monthly, now);
    notifyListeners();
  }

  Future<AssessmentSnapshot?> _buildSnapshot(
      AssessmentType type, DateTime now) async {
    final group = await _findCurrentGroup(type, now);
    if (group == null) {
      return null; // 当期没有计划
    }
    final items = await _itemsForGroup(type, group);
    if (items.isEmpty) return null;

    final allDone = items.every((i) => i.status == PlanItemStatus.completed);
    final units = _collectUnits(items);

    final periodKey = type == AssessmentType.weekly
        ? weekKey(group.startDate)
        : monthKey(group.startDate);
    final latest = await _dao.getLatest(type, periodKey);

    AssessmentStatus status;
    if (latest?.status == AssessmentStatus.passed) {
      status = AssessmentStatus.passed;
    } else if (!allDone) {
      status = AssessmentStatus.locked;
    } else {
      status = latest?.status == AssessmentStatus.failed
          ? AssessmentStatus.failed
          : AssessmentStatus.available;
    }

    return AssessmentSnapshot(
      type: type,
      periodKey: periodKey,
      status: status,
      unitCount: units.length,
      targetTotal: units.length * 3,
      latest: latest,
      periodStart: group.startDate,
      periodEnd: group.endDate,
    );
  }

  Future<PlanGroup?> _findCurrentGroup(
      AssessmentType type, DateTime now) async {
    if (type == AssessmentType.weekly) {
      final list = await _planGroupDao.getWeekPlansForDate(now);
      return list.isEmpty ? null : list.first;
    } else {
      final list = await _planGroupDao.getMonthPlansForDate(now);
      return list.isEmpty ? null : list.first;
    }
  }

  Future<List<PlanItem>> _itemsForGroup(
      AssessmentType type, PlanGroup group) async {
    if (type == AssessmentType.weekly) {
      final byOrigin = await _planItemDao.getByOriginWeekPlan(group.id!);
      if (byOrigin.isNotEmpty) return byOrigin;
      return _planItemDao.getInDateRange(group.startDate, group.endDate);
    } else {
      final byOrigin = await _planItemDao.getByOriginMonthPlan(group.id!);
      if (byOrigin.isNotEmpty) return byOrigin;
      return _planItemDao.getInDateRange(group.startDate, group.endDate);
    }
  }

  List<_Unit> _collectUnits(List<PlanItem> items) {
    final seen = <String, _Unit>{};
    for (final i in items) {
      final u = _Unit(
        chapterName: i.chapterName,
        knowledgePoint: (i.knowledgePoint == null || i.knowledgePoint!.isEmpty)
            ? null
            : i.knowledgePoint,
        subjectName: i.subjectName,
        grade: i.grade,
      );
      seen.putIfAbsent(u.key, () => u);
    }
    return seen.values.toList();
  }

  /// 错题加权题数分配：基础 2 + 倾斜池（共 N 题，权重 1+errCount）按 round
  Map<_Unit, int> _allocate(List<_Unit> units, Map<String, int> errCount) {
    final alloc = <_Unit, int>{for (final u in units) u: 2};
    if (units.isEmpty) return alloc;

    final pool = units.length; // 倾斜池总题数
    final weights = <_Unit, double>{};
    double sumW = 0;
    for (final u in units) {
      final w = 1.0 + (errCount[u.key] ?? 0).toDouble();
      weights[u] = w;
      sumW += w;
    }
    // 按 round 分配，处理舍入误差：先取整数部分，再把剩余按小数部分排序补齐
    final raw = <_Unit, double>{};
    for (final u in units) {
      raw[u] = pool * weights[u]! / sumW;
    }
    final base = <_Unit, int>{for (final u in units) u: raw[u]!.floor()};
    int assigned = base.values.fold(0, (a, b) => a + b);
    final remainders = units.toList()
      ..sort((a, b) {
        final fa = raw[a]! - base[a]!;
        final fb = raw[b]! - base[b]!;
        return fb.compareTo(fa);
      });
    int i = 0;
    while (assigned < pool && i < remainders.length) {
      base[remainders[i]] = base[remainders[i]]! + 1;
      assigned++;
      i++;
    }
    for (final u in units) {
      alloc[u] = alloc[u]! + (base[u] ?? 0);
    }
    return alloc;
  }

  /// 构造测评题目，返回 List<Question> + 警告
  Future<AssessmentBuildResult> buildAssessmentQuestions(
      AssessmentType type) async {
    final snap = type == AssessmentType.weekly ? _weekly : _monthly;
    if (snap == null || snap.status == AssessmentStatus.locked) {
      return AssessmentBuildResult([], ['当期测评未解锁']);
    }
    final now = DateTime.now();
    final group = await _findCurrentGroup(type, now);
    if (group == null) {
      return AssessmentBuildResult([], ['当期无计划']);
    }
    final items = await _itemsForGroup(type, group);
    final units = _collectUnits(items);
    if (units.isEmpty) {
      return AssessmentBuildResult([], ['当期计划无可测评单元']);
    }

    // 错次：在当期 [start, end] 范围内
    final periodStart = PlanDateUtils.dateOnly(group.startDate);
    final periodEnd = group.endDate.add(const Duration(days: 1));

    final errCount = <String, int>{};
    for (final u in units) {
      errCount[u.key] = await _questionDao.countWrongInRange(
        start: periodStart,
        end: periodEnd,
        chapterName: u.chapterName,
        knowledgePoint: u.knowledgePoint,
      );
    }

    final alloc = _allocate(units, errCount);
    final result = <Question>[];
    final warnings = <String>[];

    for (final u in units) {
      final wantN = alloc[u]!;
      if (wantN <= 0) continue;

      // 排除当期错题原题
      final excluded = await _questionDao.getWrongQuestionIdsInRange(
        start: periodStart,
        end: periodEnd,
        chapterName: u.chapterName,
        knowledgePoint: u.knowledgePoint,
      );

      final qs = await _questionDao.getQuestionsForAssessmentUnit(
        subjectName: u.subjectName,
        grade: u.grade,
        chapterName: u.chapterName,
        knowledgePoint: u.knowledgePoint,
        difficulty: null, // 测评不强求难度，由题库实际分布决定
        excludeIds: excluded,
        limit: wantN,
      );
      if (qs.length < wantN) {
        warnings.add('${u.label}: 需 $wantN 题，实抽 ${qs.length} 题（题库待扩）');
      }
      result.addAll(qs);
    }

    if (result.isEmpty) {
      warnings.add('题库不足，无法生成测评');
    }
    return AssessmentBuildResult(result, warnings);
  }

  /// 提交测评结果，返回奖励明细
  Future<SessionRewardSummary?> submitResult({
    required AssessmentType type,
    required String periodKey,
    required int score,
    required int total,
    required RewardService rewardService,
  }) async {
    if (total == 0) return null;
    final pct = score / total;
    final passed = pct >= 0.85;

    final status = passed
        ? AssessmentStatus.passed
        : AssessmentStatus.failed;
    await _dao.upsert(Assessment(
      type: type,
      periodKey: periodKey,
      status: status,
      score: score,
      total: total,
      takenAt: DateTime.now(),
    ));

    final kind = type == AssessmentType.weekly
        ? SessionKind.weeklyTest
        : SessionKind.monthlyTest;

    SessionRewardSummary? summary;
    if (passed) {
      summary = await rewardService.recordSession(
        kind: kind,
        score: score,
        total: total,
        sessionId: '${kind.name}:$periodKey',
      );
    } else {
      // 不通过也给每题 0.5 ⭐（鼓励），但无加成
      summary = await rewardService.recordSession(
        kind: kind,
        score: score,
        total: total,
        sessionId: '${kind.name}:$periodKey',
      );
    }
    await refresh();
    return summary;
  }
}
