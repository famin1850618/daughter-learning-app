import 'package:flutter/foundation.dart';
import '../database/reward_dao.dart';
import '../models/reward.dart';

/// 一次 session 的类型（决定通过/满分加成额度）
enum SessionKind { normal, weeklyTest, monthlyTest }

/// 通过/满分加成规则
class _Bonus {
  final double pass;
  final double perfect;
  const _Bonus(this.pass, this.perfect);
}

const Map<SessionKind, _Bonus> _bonusTable = {
  SessionKind.normal: _Bonus(1.0, 2.0),
  SessionKind.weeklyTest: _Bonus(2.0, 4.0),
  // V3.8.2: 月测奖励通过 +5 / 满分 +10（之前 +3 / +6）
  SessionKind.monthlyTest: _Bonus(5.0, 10.0),
};

String _sourceFor(SessionKind k) {
  switch (k) {
    case SessionKind.normal:
      return 'practice';
    case SessionKind.weeklyTest:
      return 'weekly_test';
    case SessionKind.monthlyTest:
      return 'monthly_test';
  }
}

/// 一次 session 结算后返回的奖励明细（用于 UI 显示 + 持久化恢复）
class SessionRewardSummary {
  final double perQuestionStars; // score * 0.5
  final double bonusStars; // 通过/满分加成
  final bool passed;
  final bool perfect;
  final SessionKind kind;

  const SessionRewardSummary({
    required this.perQuestionStars,
    required this.bonusStars,
    required this.passed,
    required this.perfect,
    required this.kind,
  });

  double get total => perQuestionStars + bonusStars;

  Map<String, dynamic> toJson() => {
        'perQ': perQuestionStars,
        'bonus': bonusStars,
        'passed': passed,
        'perfect': perfect,
        'kind': kind.index,
      };

  factory SessionRewardSummary.fromJson(Map<String, dynamic> j) =>
      SessionRewardSummary(
        perQuestionStars: (j['perQ'] as num).toDouble(),
        bonusStars: (j['bonus'] as num).toDouble(),
        passed: j['passed'] as bool,
        perfect: j['perfect'] as bool,
        kind: SessionKind.values[j['kind'] as int],
      );
}

class RewardService extends ChangeNotifier {
  final RewardDao _dao = RewardDao();

  double _totalStars = 0;
  double get totalStars => _totalStars;

  Map<String, double> _bySource = {};
  Map<String, double> get bySource => _bySource;

  List<Reward> _recent = [];
  List<Reward> get recent => _recent;

  Future<void> refresh() async {
    _totalStars = await _dao.getTotalStars();
    _bySource = await _dao.getStarsBySource();
    _recent = await _dao.getRecent(limit: 30);
    notifyListeners();
  }

  /// session 结束结算：写每题 0.5 ⭐ + 通过/满分加成
  /// 通过线 80%；满分（100%）仅给 perfect 加成（不再叠加 pass）
  Future<SessionRewardSummary> recordSession({
    required SessionKind kind,
    required int score,
    required int total,
    String? sessionId,
  }) async {
    final perQ = score * 0.5;
    final pct = total > 0 ? score / total : 0.0;
    final passed = pct >= 0.80;
    final perfect = total > 0 && score == total;

    final bonus = _bonusTable[kind]!;
    double bonusStars = 0;
    if (perfect) {
      bonusStars = bonus.perfect;
    } else if (passed) {
      bonusStars = bonus.pass;
    }

    final source = _sourceFor(kind);
    final now = DateTime.now();

    if (perQ > 0) {
      await _dao.insert(Reward(
        source: source,
        stars: perQ,
        earnedAt: now,
        sessionId: sessionId,
        note: '$score 题答对（每题 0.5⭐）',
      ));
    }
    if (bonusStars > 0) {
      await _dao.insert(Reward(
        source: perfect ? 'bonus' : source,
        stars: bonusStars,
        earnedAt: now,
        sessionId: sessionId,
        note: perfect ? '满分加成（${rewardSourceLabel(source)}）' : '通过加成（${rewardSourceLabel(source)}）',
      ));
    }

    await refresh();

    return SessionRewardSummary(
      perQuestionStars: perQ,
      bonusStars: bonusStars,
      passed: passed,
      perfect: perfect,
      kind: kind,
    );
  }

  // ── V3.8.3 申诉 / 主观题评分补发 ────────────────────────

  /// 单条 ad-hoc 奖励（申诉通过补发单题⭐ / 主观题评分对应⭐）
  Future<void> recordAdHoc({
    required String source,
    required double stars,
    String? sessionId,
    String? note,
  }) async {
    if (stars <= 0) return;
    await _dao.insert(Reward(
      source: source,
      stars: stars,
      earnedAt: DateTime.now(),
      sessionId: sessionId,
      note: note,
    ));
    await refresh();
  }

  /// 检查 session 是否已发过通过/满分加成（note 含"加成"判断）
  Future<bool> hasBonusForSession(String sessionId) async {
    final rewards = await _dao.getBySessionId(sessionId);
    return rewards.any((r) => (r.note ?? '').contains('加成'));
  }

  /// 仅补发通过/满分加成（不再发 per-question，避免与申诉单题⭐重复）。
  /// 调用方负责确保 hasBonusForSession 为 false 才调用。
  Future<double> recordBonusOnly({
    required SessionKind kind,
    required int score,
    required int total,
    required String sessionId,
  }) async {
    if (total == 0) return 0;
    final pct = score / total;
    final passed = pct >= 0.80;
    final perfect = score == total;
    final bonus = _bonusTable[kind]!;
    double bonusStars = 0;
    if (perfect) {
      bonusStars = bonus.perfect;
    } else if (passed) {
      bonusStars = bonus.pass;
    }
    if (bonusStars <= 0) return 0;
    final source = _sourceFor(kind);
    await _dao.insert(Reward(
      source: perfect ? 'bonus' : source,
      stars: bonusStars,
      earnedAt: DateTime.now(),
      sessionId: sessionId,
      note: perfect
          ? '满分加成（${rewardSourceLabel(source)}）· 申诉补发'
          : '通过加成（${rewardSourceLabel(source)}）· 申诉补发',
    ));
    await refresh();
    return bonusStars;
  }
}
