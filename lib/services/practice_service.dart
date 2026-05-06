import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../models/subject.dart';
import '../database/question_dao.dart';
import 'reward_service.dart';

class PracticeService extends ChangeNotifier {
  final QuestionDao _dao = QuestionDao();
  final RewardService _rewardService;

  PracticeService(this._rewardService);

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

  List<Question> get currentQuestions => _currentQuestions;
  int get currentIndex => _currentIndex;
  int get score => _score;
  bool get sessionActive => _sessionActive;
  bool get hintShown => _hintShown;
  SessionKind get kind => _kind;
  SessionRewardSummary? get lastReward => _lastReward;
  Question? get currentQuestion =>
      _currentIndex < _currentQuestions.length ? _currentQuestions[_currentIndex] : null;

  int get elapsedSeconds =>
      _questionStartTime == null ? 0 : DateTime.now().difference(_questionStartTime!).inSeconds;

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
  }

  Future<bool> submitAnswer(String answer) async {
    final q = currentQuestion;
    if (q == null) return false;
    final spent = _questionStartTime == null
        ? 0
        : DateTime.now().difference(_questionStartTime!).inSeconds;
    final correct = answer.trim().toLowerCase() == q.answer.trim().toLowerCase();
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
    return correct;
  }

  void nextQuestion() {
    if (_currentIndex < _currentQuestions.length - 1) {
      _currentIndex++;
      _hintShown = false;
      _questionStartTime = DateTime.now();
      notifyListeners();
    } else {
      _sessionActive = false;
      _claimRewardIfNeeded();
      notifyListeners();
    }
  }

  Future<void> _claimRewardIfNeeded() async {
    if (_rewardClaimed) return;
    if (_currentQuestions.isEmpty) return;
    // 测评类型由 _ResultScreen 调用 AssessmentService.submitResult 统一发奖（避免重复）
    if (_kind != SessionKind.normal) {
      _rewardClaimed = true;
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
  }

  /// 测评结果由外部（_ResultScreen 调 AssessmentService）回填
  void setLastReward(SessionRewardSummary summary) {
    _lastReward = summary;
    notifyListeners();
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
  }
}
