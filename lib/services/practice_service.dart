import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../models/subject.dart';
import '../database/question_dao.dart';
import '../database/practice_session_dao.dart';
import '../utils/answer_matcher.dart';
import 'reward_service.dart';
import 'difficulty_settings_service.dart';

class PracticeService extends ChangeNotifier {
  final QuestionDao _dao = QuestionDao();
  final PracticeSessionDao _sessionDao = PracticeSessionDao();
  final RewardService _rewardService;
  final DifficultySettingsService _difficultySettings;

  PracticeService(this._rewardService, this._difficultySettings) {
    _restoreOnStart();
  }

  /// V3.8.1：选择题选项随机重排，避免孩子靠位置记答案。
  /// V3.8.2：同步重写 explanation 中的 letter ref（如"选 A"→"选 C"）。
  /// 检测有歧义时跳过 shuffle 该题，保证「题目顺序对应解析」始终成立。
  Question _shuffleOptions(Question q) {
    if (q.type != QuestionType.multipleChoice) return q;
    final orig = q.options;
    if (orig == null || orig.length < 2) return q;

    // 提取每项内容（去掉 "A. " 前缀）
    final letterRe = RegExp(r'^[A-Z][.\s]+');
    final contents = orig.map((o) {
      final m = letterRe.firstMatch(o);
      return m == null ? o : o.substring(m.end);
    }).toList();

    // 找原答案对应的内容
    final origAnswer = q.answer.split('|||').first.trim();
    if (origAnswer.isEmpty) return q;
    final origIdx = origAnswer.codeUnitAt(0) - 'A'.codeUnitAt(0);
    if (origIdx < 0 || origIdx >= contents.length) return q;
    final correctContent = contents[origIdx];

    // V3.8.2: 检测 explanation 是否含歧义 letter ref，含则跳过 shuffle
    // pattern A: 我们能识别且替换的 ("选 A" "答案 B" "选项 C")
    // pattern B: 歧义/孤立的字母（"A 项" "A 选项是" "其中 A"）—— 跳过
    final ambiguous = RegExp(r'(?<![选项答案])\b[A-D]\b(?!\s*[.．。])');
    if (q.explanation != null && ambiguous.hasMatch(q.explanation!)) {
      return q; // 含歧义字母引用，跳过 shuffle 保险
    }

    // 洗牌索引
    final indices = List<int>.generate(contents.length, (i) => i)..shuffle();
    final newOptions = <String>[];
    String newAnswer = origAnswer;
    // (旧字母 → 新字母) 映射，用于同步替换 explanation
    final letterMap = <String, String>{};
    for (int i = 0; i < indices.length; i++) {
      final newLetter = String.fromCharCode('A'.codeUnitAt(0) + i);
      final oldLetter = String.fromCharCode('A'.codeUnitAt(0) + indices[i]);
      letterMap[oldLetter] = newLetter;
      newOptions.add('$newLetter. ${contents[indices[i]]}');
      if (contents[indices[i]] == correctContent) {
        newAnswer = newLetter;
      }
    }

    // V3.8.2: 同步替换 explanation 中可识别的 letter ref
    String? newExplanation = q.explanation;
    if (newExplanation != null) {
      newExplanation = newExplanation.replaceAllMapped(
        RegExp(r'(选项?\s*|答案[是为]?\s*)([A-D])'),
        (m) {
          final prefix = m[1]!;
          final old = m[2]!;
          final newL = letterMap[old] ?? old;
          return '$prefix$newL';
        },
      );
    }

    return Question(
      id: q.id,
      subject: q.subject,
      grade: q.grade,
      chapter: q.chapter,
      knowledgePoint: q.knowledgePoint,
      content: q.content,
      type: q.type,
      difficulty: q.difficulty,
      options: newOptions,
      answer: newAnswer,
      explanation: newExplanation,
      imageData: q.imageData,
      audioText: q.audioText,
      round: q.round,
      groupId: q.groupId,
      groupOrder: q.groupOrder,
      source: q.source,
    );
  }

  List<Question> _shuffleAll(List<Question> qs) => qs.map(_shuffleOptions).toList();

  /// V3.8：把 profile 翻成 (rounds, weights) 给 QuestionDao
  ({List<int>? rounds, List<int>? weights}) _profileToFilter(DifficultyProfile p) {
    if (p.type == DifficultyType.precise) {
      return (rounds: p.preciseRound == null ? null : [p.preciseRound!], weights: null);
    }
    // fuzzy: 4 档 + weights（去除 0 权重档）
    final allRounds = [1, 2, 3, 4];
    final keepIdx = <int>[];
    for (int i = 0; i < 4; i++) {
      if (p.fuzzyWeights[i] > 0) keepIdx.add(i);
    }
    return (
      rounds: keepIdx.map((i) => allRounds[i]).toList(),
      weights: keepIdx.map((i) => p.fuzzyWeights[i]).toList(),
    );
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
    // V3.8: 应用难度档设置（普通练习/章节/计划项 强制应用）
    final profile = _difficultySettings.profileFor(subject.displayName);
    final f = _profileToFilter(profile);
    if (type != null || difficulty != null) {
      // 用户在 UI 选了 type/difficulty 时走老路径（精细筛选优先于 round）
      _currentQuestions = await _dao.getRandom(
        subject: subject,
        grade: grade,
        chapter: chapter,
        type: type,
        difficulty: difficulty,
        limit: count,
      );
    } else {
      _currentQuestions = await _dao.getRandomByRound(
        subject: subject,
        grade: grade,
        chapter: chapter,
        rounds: f.rounds,
        weights: f.weights,
        limit: count,
      );
    }
    _currentQuestions = _shuffleAll(_currentQuestions);
    _kind = SessionKind.normal;
    _sessionId = null;
    _resetSessionState();
    await _persist();
  }

  /// 单 KP 举一反三
  ///
  /// [applyDifficulty]：是否应用 V3.8 难度档设置（false 时按原有"匹配最近错难度"逻辑）。
  /// 调用方根据触发场景传：
  ///   - 首页薄弱 KP 卡 → settings.applyToWeakKp
  ///   - 错题集"练相似题" → settings.applyToReviewSimilar
  Future<void> startKpReviewSession(
    String kpPath, {
    int count = 10,
    bool applyDifficulty = true,
  }) async {
    if (applyDifficulty) {
      // 取该 KP 所属科目的 profile（从已知该 KP 任意题反查 subject）
      final subject = await _dao.getSubjectForKp(kpPath);
      final profile = _difficultySettings.profileFor(subject ?? '');
      final f = _profileToFilter(profile);
      _currentQuestions = await _dao.getQuestionsForKpByRound(
        kpPath: kpPath,
        rounds: f.rounds,
        weights: f.weights,
        limit: count,
      );
    } else {
      // 关闭难度档时回退原有"匹配最近错难度"逻辑
      final difficulty = await _dao.getMostRecentErrorDifficulty(kpPath) ?? Difficulty.medium;
      _currentQuestions = await _dao.getQuestionsForKnowledgePoint(
        kpPath: kpPath,
        difficulty: difficulty,
        limit: count,
      );
    }
    _currentQuestions = _shuffleAll(_currentQuestions);
    _kind = SessionKind.normal;
    _sessionId = null;
    _resetSessionState();
    await _persist();
  }

  /// 聚合：从所有待掌握 KP 各抽 [perKp] 题，按累计错次降序优先
  /// 严格排除"原题"：不抽用户曾做错过的题
  Future<void> startAggregatedReviewSession({
    int perKp = 2,
    int totalLimit = 20,
    bool applyDifficulty = true,
  }) async {
    final summaries = await _dao.getReviewKnowledgePoints();
    final result = <Question>[];
    for (final s in summaries) {
      if (result.length >= totalLimit) break;
      List<Question> qs;
      if (applyDifficulty) {
        final subject = await _dao.getSubjectForKp(s.fullPath);
        final profile = _difficultySettings.profileFor(subject ?? '');
        final f = _profileToFilter(profile);
        qs = await _dao.getQuestionsForKpByRound(
          kpPath: s.fullPath,
          rounds: f.rounds,
          weights: f.weights,
          limit: perKp,
        );
      } else {
        final difficulty =
            await _dao.getMostRecentErrorDifficulty(s.fullPath) ?? Difficulty.medium;
        qs = await _dao.getQuestionsForKpExcludingWrong(
          kpPath: s.fullPath,
          difficulty: difficulty,
          limit: perKp,
        );
      }
      result.addAll(qs);
    }
    _currentQuestions = result.take(totalLimit).toList();
    _currentQuestions = _shuffleAll(_currentQuestions);
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
    _currentQuestions = _shuffleAll(questions);
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
