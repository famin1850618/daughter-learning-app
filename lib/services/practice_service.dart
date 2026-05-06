import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../models/subject.dart';
import '../database/question_dao.dart';
import '../database/practice_session_dao.dart';
import '../utils/answer_matcher.dart';
import 'reward_service.dart';

class PracticeService extends ChangeNotifier {
  final QuestionDao _dao = QuestionDao();
  final PracticeSessionDao _sessionDao = PracticeSessionDao();
  final RewardService _rewardService;

  PracticeService(this._rewardService) {
    _restoreOnStart();
  }

  List<Question> _currentQuestions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _sessionActive = false;
  bool _hintShown = false;
  DateTime? _questionStartTime;

  SessionKind _kind = SessionKind.normal;
  String? _sessionId;
  bool _rewardClaimed = false;
  SessionRewardSummary? _lastReward;
  bool _restoring = false;
  bool _restored = false;

  List<Question> get currentQuestions => _currentQuestions;
  int get currentIndex => _currentIndex;
  int get score => _score;
  bool get sessionActive => _sessionActive;
  bool get hintShown => _hintShown;
  SessionKind get kind => _kind;
  SessionRewardSummary? get lastReward => _lastReward;
  bool get isRestoring => _restoring;
  bool get isRestored => _restored;
  Question? get currentQuestion =>
      _currentIndex < _currentQuestions.length ? _currentQuestions[_currentIndex] : null;

  int get elapsedSeconds =>
      _questionStartTime == null ? 0 : DateTime.now().difference(_questionStartTime!).inSeconds;

  Future<void> _restoreOnStart() async {
    _restoring = true;
    try {
      final row = await _sessionDao.load();
      if (row == null) return;
      final qsJson = row['questions_json'] as String?;
      if (qsJson == null || qsJson.isEmpty) return;
      final list = (jsonDecode(qsJson) as List).cast<Map<String, dynamic>>();
      if (list.isEmpty) return;
      _currentQuestions = list.map(Question.fromMap).toList();
      _currentIndex = (row['current_index'] as int?) ?? 0;
      _score = (row['score'] as int?) ?? 0;
      _kind = SessionKind.values[(row['kind'] as int?) ?? 0];
      _sessionActive = ((row['session_active'] as int?) ?? 0) == 1;
      _sessionId = row['session_id'] as String?;
      _hintShown = ((row['hint_shown'] as int?) ?? 0) == 1;
      _rewardClaimed = ((row['reward_claimed'] as int?) ?? 0) == 1;
      final rewardJson = row['last_reward_json'] as String?;
      if (rewardJson != null && rewardJson.isNotEmpty) {
        _lastReward = SessionRewardSummary.fromJson(
            jsonDecode(rewardJson) as Map<String, dynamic>);
      }
      if (_currentIndex >= _currentQuestions.length) {
        _sessionActive = false;
      }
      _questionStartTime = DateTime.now();
    } catch (e) {
      debugPrint('Failed to restore practice session: $e');
    } finally {
      _restoring = false;
      _restored = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    if (_currentQuestions.isEmpty) {
      await _sessionDao.clear();
      return;
    }
    try {
      final qsJson = jsonEncode(_currentQuestions.map((q) => q.toMap()).toList());
      final rewardJson =
          _lastReward == null ? null : jsonEncode(_lastReward!.toJson());
      await _sessionDao.save(
        questionsJson: qsJson,
        currentIndex: _currentIndex,
        score: _score,
        kind: _kind.index,
        sessionActive: _sessionActive,
        sessionId: _sessionId,
        hintShown: _hintShown,
        rewardClaimed: _rewardClaimed,
        lastRewardJson: rewardJson,
      );
    } catch (e) {
      debugPrint('Failed to persist practice session: $e');
    }
  }

  Future<void> startSession({
    required Subject subject,
    required int grade,
    String? chapter,
    QuestionType? type,
    Difficulty? difficulty,
    int count = 10,
  }) async {
    _currentQuestions = await _dao.getRandom(
      subject: subject,
      grade: grade,
      chapter: chapter,
      type: type,
      difficulty: difficulty,
      limit: count,
    );
    _kind = SessionKind.normal;
    _sessionId = null;
    _resetSessionState();
    await _persist();
  }

  /// 单 KP 举一反三：抽该 KP 同难度未做过的题；难度按"该 KP 最近一次错过的题"
  Future<void> startKpReviewSession(String kpPath, {int count = 10}) async {
    final difficulty = await _dao.getMostRecentErrorDifficulty(kpPath) ?? Difficulty.medium;
    _currentQuestions = await _dao.getQuestionsForKnowledgePoint(
      kpPath: kpPath,
      difficulty: difficulty,
      limit: count,
    );
    _kind = SessionKind.normal;
    _sessionId = null;
    _resetSessionState();
    await _persist();
  }

  /// 聚合：从所有待掌握 KP 各抽 [perKp] 题，按累计错次降序优先
  Future<void> startAggregatedReviewSession({int perKp = 2, int totalLimit = 20}) async {
    final summaries = await _dao.getReviewKnowledgePoints();
    final result = <Question>[];
    for (final s in summaries) {
      if (result.length >= totalLimit) break;
      final difficulty =
          await _dao.getMostRecentErrorDifficulty(s.fullPath) ?? Difficulty.medium;
      final qs = await _dao.getQuestionsForKnowledgePoint(
        kpPath: s.fullPath,
        difficulty: difficulty,
        limit: perKp,
      );
      result.addAll(qs);
    }
    _currentQuestions = result.take(totalLimit).toList();
    _kind = SessionKind.normal;
    _sessionId = null;
    _resetSessionState();
    await _persist();
  }

  /// 周/月测评 session：题目由 AssessmentService 准备好后注入
  void startAssessmentSession({
    required List<Question> questions,
    required SessionKind kind,
    required String periodKey,
  }) {
    _currentQuestions = questions;
    _kind = kind;
    _sessionId = '${kind.name}:$periodKey';
    _resetSessionState();
    _persist();
  }

  void _resetSessionState() {
    _currentIndex = 0;
    _score = 0;
    _sessionActive = _currentQuestions.isNotEmpty;
    _hintShown = false;
    _questionStartTime = DateTime.now();
    _rewardClaimed = false;
    _lastReward = null;
    notifyListeners();
  }

  void showHint() {
    _hintShown = true;
    notifyListeners();
    _persist();
  }

  Future<bool> submitAnswer(String answer) async {
    final q = currentQuestion;
    if (q == null) return false;
    final spent = _questionStartTime == null
        ? 0
        : DateTime.now().difference(_questionStartTime!).inSeconds;
    final correct = AnswerMatcher.isCorrect(
      userAns: answer,
      correctAnswerField: q.answer,
      type: q.type,
    );
    if (correct) _score++;
    await _dao.insertRecord(PracticeRecord(
      questionId: q.id!,
      userAnswer: answer,
      isCorrect: correct,
      practicedAt: DateTime.now(),
      timeSpent: spent,
      usedHint: _hintShown,
    ));
    notifyListeners();
    await _persist();
    return correct;
  }

  void nextQuestion() {
    if (_currentIndex < _currentQuestions.length - 1) {
      _currentIndex++;
      _hintShown = false;
      _questionStartTime = DateTime.now();
      notifyListeners();
      _persist();
    } else {
      _sessionActive = false;
      _claimRewardIfNeeded();
      notifyListeners();
      _persist();
    }
  }

  Future<void> _claimRewardIfNeeded() async {
    if (_rewardClaimed) return;
    if (_currentQuestions.isEmpty) return;
    // 测评类型由 _ResultScreen 调用 AssessmentService.submitResult 统一发奖（避免重复）
    if (_kind != SessionKind.normal) {
      _rewardClaimed = true;
      await _persist();
      return;
    }
    _rewardClaimed = true;
    _lastReward = await _rewardService.recordSession(
      kind: _kind,
      score: _score,
      total: _currentQuestions.length,
      sessionId: _sessionId,
    );
    notifyListeners();
    await _persist();
  }

  /// 测评结果由外部（_ResultScreen 调 AssessmentService）回填
  void setLastReward(SessionRewardSummary summary) {
    _lastReward = summary;
    notifyListeners();
    _persist();
  }

  void endSession() {
    _sessionActive = false;
    _currentQuestions = [];
    _currentIndex = 0;
    _score = 0;
    _kind = SessionKind.normal;
    _sessionId = null;
    _rewardClaimed = false;
    _lastReward = null;
    notifyListeners();
    _sessionDao.clear();
  }
}
