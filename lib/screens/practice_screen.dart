import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../utils/math_text.dart';
import '../utils/settings_action.dart';
import '../services/difficulty_settings_service.dart';
import '../models/subject.dart';
import '../models/question.dart';
import '../models/speaker_profile.dart';
import '../models/curriculum.dart';
import '../database/curriculum_dao.dart';
import '../database/question_dao.dart';
import '../services/practice_service.dart';
import '../services/reward_service.dart';
import '../services/assessment_service.dart';
import '../services/review_request_service.dart';
import '../models/assessment.dart';
import '../models/review_request.dart';

// ── 入口：根据会话状态路由 ─────────────────────────────
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PracticeService>();
    if (!service.sessionActive) {
      return service.currentQuestions.isEmpty
          ? const _SelectionScreen()
          : _ResultScreen(
              score: service.score,
              total: service.currentQuestions.length,
              questions: service.currentQuestions,
              reward: service.lastReward,
              kind: service.kind,
            );
    }
    if (service.currentQuestion == null) {
      return _ResultScreen(
        score: service.score,
        total: service.currentQuestions.length,
        questions: service.currentQuestions,
        reward: service.lastReward,
        kind: service.kind,
      );
    }
    return _QuestionScreen(question: service.currentQuestion!);
  }
}

// ── 选题界面 ──────────────────────────────────────────
class _SelectionScreen extends StatefulWidget {
  const _SelectionScreen();
  @override
  State<_SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<_SelectionScreen> {
  final _currDao = CurriculumDao();
  final _questionDao = QuestionDao();

  // V3.8.1: 默认 grade=6（当前题库主要是六下；cron 跑后会扩到 7-9）
  // 真实运行时会从 SharedPreferences 复原上次选择
  int _grade = 6;
  Subject? _subject;
  String? _chapter;
  QuestionType? _type;
  int _count = 10;
  int _totalAvailable = 0;

  List<Chapter> _chapters = [];

  static const _gradeLabels = {6: '六年级', 7: '初一', 8: '初二', 9: '初三'};
  static const _kPrefsGrade = 'practice_last_grade';
  static const _kPrefsSubject = 'practice_last_subject';

  @override
  void initState() {
    super.initState();
    _restoreLastSelection();
  }

  Future<void> _restoreLastSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final g = prefs.getInt(_kPrefsGrade);
    final sIdx = prefs.getInt(_kPrefsSubject);
    if (mounted) {
      setState(() {
        if (g != null && g >= 6 && g <= 9) _grade = g;
        if (sIdx != null && sIdx >= 0 && sIdx < Subject.values.length) {
          final s = Subject.values[sIdx];
          if (s.isAvailableForGrade(_grade)) _subject = s;
        }
      });
    }
    if (_subject != null) {
      final chapters = await _currDao.getChapters(_subject!.displayName, _grade);
      if (mounted) setState(() => _chapters = chapters);
    }
    _refreshCount();
  }

  Future<void> _saveSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrefsGrade, _grade);
    if (_subject != null) {
      await prefs.setInt(_kPrefsSubject, _subject!.index);
    }
  }

  Future<void> _onGradeChanged(int g) async {
    setState(() { _grade = g; _subject = null; _chapter = null; _chapters = []; });
    _saveSelection();
    _refreshCount();
  }

  Future<void> _onSubjectChanged(Subject? s) async {
    setState(() { _subject = s; _chapter = null; _chapters = []; });
    if (s != null) {
      final chapters = await _currDao.getChapters(s.displayName, _grade);
      setState(() => _chapters = chapters);
    }
    _saveSelection();
    _refreshCount();
  }

  Future<void> _refreshCount() async {
    if (_subject == null) { setState(() => _totalAvailable = 0); return; }
    // V3.8.1: 应用全局 round 筛选，让 UI 显示真正能抽到的题数
    final settings = context.read<DifficultySettingsService>();
    final profile = settings.profileFor(_subject!.displayName);
    List<int>? rounds;
    List<int>? weights;
    if (profile.type == DifficultyType.precise) {
      rounds = profile.preciseRound == null ? null : [profile.preciseRound!];
    } else {
      rounds = [];
      weights = [];
      for (int i = 0; i < 4; i++) {
        if (profile.fuzzyWeights[i] > 0) {
          rounds.add(i + 1);
          weights.add(profile.fuzzyWeights[i]);
        }
      }
    }
    final qs = await _questionDao.getRandomByRound(
      subject: _subject!,
      grade: _grade,
      chapter: _chapter,
      rounds: rounds,
      weights: weights,
      limit: 999,
    );
    // type 筛选在前端 dart 侧过滤，避免 DB 复合 query 复杂度
    final filtered = _type == null ? qs : qs.where((q) => q.type == _type).toList();
    setState(() => _totalAvailable = filtered.length);
  }

  Future<void> _start() async {
    if (_subject == null) return;
    await context.read<PracticeService>().startSession(
      subject: _subject!,
      grade: _grade,
      chapter: _chapter,
      type: _type,
      count: _count,
    );
  }

  Widget _chips<T>({
    required String label,
    required List<(T?, String)> options,
    required T? selected,
    required void Function(T?) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: options.map((o) {
            final isSelected = o.$1 == selected;
            return ChoiceChip(
              label: Text(o.$2),
              selected: isSelected,
              onSelected: (_) { onSelect(o.$1); _refreshCount(); },
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 13,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableSubjects = Subject.values.where((s) => s.isAvailableForGrade(_grade)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('模拟练习'),
        actions: [settingsAction(context)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 针对薄弱点练习（聚合所有待掌握 KP，每个抽 1-2 题）
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('针对薄弱点练习'),
            onPressed: () async {
              final applyDiff = context.read<DifficultySettingsService>().applyToReviewSimilar;
              await context.read<PracticeService>().startAggregatedReviewSession(applyDifficulty: applyDiff);
              if (!context.mounted) return;
              if (context.read<PracticeService>().currentQuestions.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('暂无薄弱知识点（继续保持！）')),
                );
              }
            },
          ),
          const Divider(height: 24),

          // 年级
          _chips<int>(
            label: '年级',
            options: [6, 7, 8, 9].map((g) => (g, _gradeLabels[g]!)).toList(),
            selected: _grade,
            onSelect: (g) => _onGradeChanged(g ?? 7),
          ),

          // 科目
          _chips<Subject>(
            label: '科目',
            options: [(null, '全部'), ...availableSubjects.map((s) => (s, s.displayName))],
            selected: _subject,
            onSelect: _onSubjectChanged,
          ),

          // 章节（有科目才显示）
          if (_subject != null && _chapters.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('章节', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _chapter,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    hintText: '全部章节',
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全部章节')),
                    ..._chapters.map((c) => DropdownMenuItem(
                          value: c.chapterName,
                          child: Text(c.chapterName, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (v) { setState(() => _chapter = v); _refreshCount(); },
                ),
                const SizedBox(height: 12),
              ],
            ),

          // 题型
          _chips<QuestionType>(
            label: '题型',
            options: [(null, '全部'), ...QuestionType.values.map((t) => (t, t.label))],
            selected: _type,
            onSelect: (t) => setState(() => _type = t),
          ),

          // V3.8.1：难度档由全局设置统一管理（设置页 → 练习难度），不在此重复
          // 用户期望：单一难度入口，避免与 4 档 round 系统冲突

          // 题数
          _chips<int>(
            label: '题数',
            options: [5, 10, 20, 30].map((n) => (n, '$n题')).toList(),
            selected: _count,
            onSelect: (n) => setState(() => _count = n ?? 10),
          ),

          const SizedBox(height: 8),
          if (_subject != null)
            Text(
              '可用题目：$_totalAvailable 道',
              style: TextStyle(
                color: _totalAvailable == 0 ? Colors.red : Colors.grey,
                fontSize: 13,
              ),
            ),
          if (_subject != null && _totalAvailable == 0)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('题库暂无该条件题目，请调整筛选条件',
                  style: TextStyle(color: Colors.orange, fontSize: 12)),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始练习', style: TextStyle(fontSize: 16)),
              onPressed: (_subject != null && _totalAvailable > 0) ? _start : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 答题界面 ──────────────────────────────────────────
class _QuestionScreen extends StatefulWidget {
  final Question question;
  const _QuestionScreen({required this.question});
  @override
  State<_QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<_QuestionScreen> {
  String? _selectedOption;
  bool? _result;
  final _answerCtrl = TextEditingController();
  Timer? _timer;
  int _seconds = 0;
  /// V3.8.3: 计时暂停（小孩走神/被打断时按）。仅 UI 层实现，重启后默认 resume
  bool _paused = false;
  /// V3.8.3: 该题在小孩历史中累计做过的次数（替代选项随机的"做过 N 次"标签）
  int _attemptCount = 0;
  int? _attemptCountForQid;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_paused) return; // V3.8.3: 暂停时不累加
      setState(() => _seconds++);
    });
    _maybeLoadAttemptCount();
    _prefillPendingAnswer();
  }

  @override
  void didUpdateWidget(_QuestionScreen old) {
    super.didUpdateWidget(old);
    if (old.question.id != widget.question.id) {
      _selectedOption = null;
      _result = null;
      _answerCtrl.clear();
      _seconds = 0;
      _paused = false;
      _maybeLoadAttemptCount();
      _prefillPendingAnswer();
    }
  }

  /// V3.14: 组合题里如果当前题已暂存过答案，预填回去（让用户能修改）
  void _prefillPendingAnswer() {
    final q = widget.question;
    if (q.groupId == null) return;
    final service = context.read<PracticeService>();
    final stashed = service.pendingAnswerFor(q);
    if (stashed == null || stashed.isEmpty) return;
    if (q.type == QuestionType.multipleChoice || q.type == QuestionType.judgment) {
      _selectedOption = stashed;
    } else {
      _answerCtrl.text = stashed;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerCtrl.dispose();
    super.dispose();
  }

  void _maybeLoadAttemptCount() {
    final qid = widget.question.id;
    if (qid == null) return;
    if (_attemptCountForQid == qid) return;
    _attemptCountForQid = qid;
    _attemptCount = 0;
    QuestionDao().getAttemptCountForQuestion(qid).then((c) {
      if (!mounted) return;
      if (_attemptCountForQid != qid) return;
      // 加 1 表示"算上这次是第 N 次"
      setState(() => _attemptCount = c + 1);
    });
  }

  String get _timerLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    final base = m > 0 ? '${m}m ${s}s' : '${s}s';
    return _paused ? '$base · 已暂停' : base;
  }

  void _togglePause() {
    if (_result != null) return; // 已答完不可暂停
    setState(() => _paused = !_paused);
  }

  Future<void> _submit() async {
    final q = widget.question;
    final answer = (q.type == QuestionType.multipleChoice ||
            q.type == QuestionType.judgment)
        ? (_selectedOption ?? '')
        : _answerCtrl.text.trim();
    if (answer.isEmpty) return;
    final service = context.read<PracticeService>();
    // V3.14: 组合题分支处理
    if (q.groupId != null) {
      if (service.isLastInGroup) {
        // 组内最后一题：暂存当前 + 整组判分（弹结果页由 build watcher 处理）
        await service.submitGroup(answer);
        _timer?.cancel();
      } else {
        // 组内非末位：暂存 + 跳到组内下一题（不显示对错）
        service.stashGroupAnswer(answer);
        service.goToNextInGroup();
      }
      return;
    }
    final correct = await service.submitAnswer(answer);
    setState(() => _result = correct);
    _timer?.cancel();
  }

  /// V3.14: 组合题里"上一题"按钮回调（暂存当前答案 + 跳上一题）
  void _prevInGroup() {
    final q = widget.question;
    if (q.groupId == null) return;
    final service = context.read<PracticeService>();
    // 暂存当前答案（如有）
    final answer = (q.type == QuestionType.multipleChoice ||
            q.type == QuestionType.judgment)
        ? (_selectedOption ?? '')
        : _answerCtrl.text.trim();
    if (answer.isNotEmpty) service.stashGroupAnswer(answer);
    service.goToPrevInGroup();
  }

  /// V3.14: 整组结果展示视图（替代普通答题区）
  Widget _buildGroupResultView(BuildContext context, PracticeService service) {
    final results = service.lastGroupResult ?? [];
    final allCorrect = results.isNotEmpty && results.every((r) => r.isCorrect);
    final hasSubj = results.any((r) =>
        r.question.type == QuestionType.subjective || r.question.aiDispute != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 整组判定 banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hasSubj
                ? Colors.amber.shade50
                : (allCorrect ? Colors.green.shade50 : Colors.red.shade50),
            border: Border.all(
              color: hasSubj
                  ? Colors.amber.shade400
                  : (allCorrect ? Colors.green.shade400 : Colors.red.shade300),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                hasSubj
                    ? Icons.hourglass_top
                    : (allCorrect ? Icons.check_circle : Icons.cancel),
                size: 28,
                color: hasSubj
                    ? Colors.amber.shade800
                    : (allCorrect ? Colors.green.shade700 : Colors.red.shade700),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasSubj
                      ? '整组含主观题或 AI 争议题，等爸爸审核后定结果'
                      : (allCorrect ? '整组全对！🎉' : '整组未全对（任一错就算错）'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasSubj
                        ? Colors.amber.shade900
                        : (allCorrect ? Colors.green.shade900 : Colors.red.shade900),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 各子题答案对照
        ...results.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: r.isCorrect ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: r.isCorrect ? Colors.green.shade300 : Colors.red.shade300,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      r.isCorrect ? Icons.check : Icons.close,
                      color: r.isCorrect ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '小题 ${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: r.isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                MathText(r.question.content, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 6),
                Row(children: [
                  Text('你答：', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  Expanded(
                    child: MathText(r.userAnswer.isEmpty ? '（未填）' : r.userAnswer,
                        style: TextStyle(
                            fontSize: 13,
                            color: r.isCorrect ? Colors.green.shade700 : Colors.red.shade700)),
                  ),
                ]),
                if (!r.isCorrect && r.question.type != QuestionType.subjective) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('正解：', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                    Expanded(
                      child: MathText(r.question.displayAnswer,
                          style: TextStyle(fontSize: 13, color: Colors.green.shade700)),
                    ),
                  ]),
                ],
                if (r.question.explanation != null && r.question.explanation!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: MathText('💡 ${r.question.explanation}',
                        style: const TextStyle(fontSize: 12.5, height: 1.5)),
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        // 下一题按钮
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('下一题', style: TextStyle(fontSize: 16)),
            onPressed: () {
              service.clearLastGroupResult();
              service.nextQuestion();
            },
          ),
        ),
      ],
    );
  }

  /// V3.14: 组合题导航栏（上一题 / 下一题或完成整组）
  Widget _buildGroupNavBar(BuildContext context, Question q, PracticeService service) {
    final isLast = service.isLastInGroup;
    final isFirst = service.isFirstInGroup;
    final groupSize = service.currentGroupIndices().length;
    final pos = service.currentGroupIndices().indexOf(service.currentIndex) + 1;

    return Row(
      children: [
        // 上一题（组内非首位才可点）
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('上一题'),
            onPressed: isFirst ? null : _prevInGroup,
          ),
        ),
        const SizedBox(width: 8),
        // 进度提示
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$pos / $groupSize',
            style: const TextStyle(fontSize: 13, color: Colors.deepPurple, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        // 下一题（非末位）/ 完成整组（末位）
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(isLast ? Icons.check_circle : Icons.arrow_forward, size: 18),
            label: Text(isLast ? '完成整组' : '下一题'),
            onPressed: _canSubmit(q) ? _submit : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final service = context.watch<PracticeService>();
    final total = service.currentQuestions.length;
    final index = service.currentIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text('第 ${index + 1} / $total 题'),
        actions: [
          settingsAction(context),
          // V3.8.3: 暂停按钮（仅未答完时可点）
          if (_result == null)
            IconButton(
              icon: Icon(_paused ? Icons.play_circle_outline : Icons.pause_circle_outline),
              tooltip: _paused ? '恢复' : '暂停',
              onPressed: _togglePause,
            ),
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined),
            tooltip: '中止练习',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('中止练习？'),
                  content: const Text('已答的题目对错会保留（错的会进错题集），未答的题不计分，本次不发奖。'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('继续')),
                    TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('中止')),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                context.read<PracticeService>().endSession();
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(_timerLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: Stack(children: [
        SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (index + 1) / total,
              backgroundColor: Colors.grey[200],
              color: AppTheme.primary,
            ),
            const SizedBox(height: 12),

            // 元信息（V3.8.3: 不显示 KP 标签——KP 是答题后复盘维度，做题中暴露相当于给提示）
            // V3.12.17: 加组合题进度标签（同 groupId 题数 ≥ 2 时显示），让用户感知"这是连续 N 题"
            Row(children: [
              _Tag(q.type.label, AppTheme.primary.withOpacity(0.15), AppTheme.primary),
              if (q.round != null) ...[
                const SizedBox(width: 6),
                _Tag(_roundLabel(q.round!),
                    _roundColor(q.round!).withOpacity(0.15), _roundColor(q.round!)),
              ],
              if (_attemptCount >= 2) ...[
                const SizedBox(width: 6),
                _Tag('📚 第 $_attemptCount 次',
                    Colors.deepPurple.withOpacity(0.10), Colors.deepPurple),
              ],
              ..._groupTags(service.currentQuestions, q),
            ]),

            // V3.13: AI 争议题 banner（学情冻结提示）
            if (q.aiDispute != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade400, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI 标注：这题答案有疑问',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '做完会提交爸爸审核，对错先不算分。',
                            style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // 听力题播放按钮（V3.12 多角色：按 audioText 中 "角色:文本" 行切 turn，
            // 配合 question.speakers 切 voice/pitch；单角色独白走默认 profile）
            if (q.audioText != null && q.audioText!.isNotEmpty)
              _ListenButton(
                audioText: q.audioText!,
                speakers: q.speakers,
              ),

            // 题目附图
            if (q.imageData != null && q.imageData!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _QuestionImage(data: q.imageData!),
              const SizedBox(height: 8),
            ],

            // 题目内容
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: MathText(q.content,
                  style: const TextStyle(fontSize: 17, height: 1.6, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 16),

            // V3.14: 组合题整组判分后显示整组结果（覆盖普通答题区）
            if (q.groupId != null && service.lastGroupResult != null) ...[
              _buildGroupResultView(context, service),
            ]
            // 答题区域（V3.8.3：废弃"查看提示"——explanation 是答题推导，相当于给答案）
            else if (_result == null) ...[
              _buildInputArea(q),
              const SizedBox(height: 16),
              // V3.14: 组合题里有"上一题/下一题"双按钮；非组合题单"提交"按钮
              if (q.groupId != null) ...[
                _buildGroupNavBar(context, q, service),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '组合题：做完所有小题统一判分（全对才算对）。可上下翻页修改答案。',
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _canSubmit(q) ? _submit : null,
                    child: const Text('提交答案', style: TextStyle(fontSize: 16)),
                  ),
                ),
            ],

            // 结果反馈（V3.8.2：选择题答完保留选项可见，标正解 + 用户错选）
            if (_result != null) ...[
              if (q.type == QuestionType.multipleChoice && q.options != null) ...[
                _buildAnsweredOptions(q),
                const SizedBox(height: 12),
              ],
              _buildResult(q, _result!),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => context.read<PracticeService>().nextQuestion(),
                  child: Text(index < total - 1 ? '下一题' : '查看结果'),
                ),
              ),
            ],
          ],
        ),
      ),
        // V3.8.3 暂停遮罩
        if (_paused)
          Positioned.fill(
            child: GestureDetector(
              onTap: _togglePause,
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.pause_circle_filled,
                        size: 80, color: Colors.white),
                    SizedBox(height: 12),
                    Text('已暂停',
                        style: TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('点击屏幕任意位置恢复',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
      ]),
    );
  }

  bool _canSubmit(Question q) {
    if (q.type == QuestionType.multipleChoice ||
        q.type == QuestionType.judgment) {
      return _selectedOption != null;
    }
    return _answerCtrl.text.trim().isNotEmpty;
  }

  /// V3.12.14: 多选题 toggle（点击 letter 加入/移除 _selectedOption）
  /// _selectedOption 永远保持"AC"格式（排序去重）
  void _toggleOption(String letter) {
    final cur = _selectedOption ?? '';
    String next;
    if (cur.contains(letter)) {
      next = cur.replaceAll(letter, '');
    } else {
      final letters = (cur + letter).split('').toSet().toList()..sort();
      next = letters.join();
    }
    setState(() => _selectedOption = next.isEmpty ? null : next);
  }

  Widget _buildInputArea(Question q) {
    switch (q.type) {
      case QuestionType.multipleChoice:
        final isMulti = q.isMultiSelect;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isMulti)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(children: [
                  const Icon(Icons.check_box, size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text('多选题（请勾选所有正确项）',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
                ]),
              ),
            ...q.options!.asMap().entries.map((e) {
              final idx = e.key;
              final opt = e.value;
              final letter = opt.substring(0, 1);
              final isSelected = (_selectedOption ?? '').contains(letter);
              // V3.12.22 A3: 选项图（可选）
              final optImage = (q.optionImages != null && idx < q.optionImages!.length)
                  ? q.optionImages![idx]
                  : null;
              return GestureDetector(
                onTap: () {
                  if (isMulti) {
                    _toggleOption(letter);
                  } else {
                    setState(() => _selectedOption = letter);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (isMulti)
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          )
                        else
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: isSelected ? AppTheme.primary : Colors.grey[200],
                            child: Text(letter,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                )),
                          ),
                        const SizedBox(width: 10),
                        if (isMulti)
                          Text('$letter. ',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Expanded(child: MathText(opt.length > 2 ? opt.substring(2) : opt,
                            style: const TextStyle(fontSize: 15))),
                      ]),
                      // V3.12.22 A3: 选项图（PNG/JPEG base64 或 SVG）
                      if (optImage != null && optImage.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 34),
                          child: _renderOptionImage(optImage),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        );

      case QuestionType.fillBlank:
        return TextField(
          controller: _answerCtrl,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: '填入答案',
            border: OutlineInputBorder(),
          ),
        );

      case QuestionType.calculation:
        return TextField(
          controller: _answerCtrl,
          onChanged: (_) => setState(() {}),
          minLines: 3,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            labelText: '写出答案（可包含计算过程）',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        );

      case QuestionType.subjective:
        // V3.8.3: 主观题用大文本框；提交后自动入家长审核队列
        return TextField(
          controller: _answerCtrl,
          onChanged: (_) => setState(() {}),
          minLines: 5,
          maxLines: 12,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            labelText: '写出你的答案 / 作文 / 解答过程',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
            helperText: '提交后由家长批改打分',
          ),
        );

      case QuestionType.judgment:
        // V3.10: 判断题用 对/错 两个大按钮
        return Row(
          children: [
            for (final v in const ['对', '错']) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedOption = v),
                  child: Container(
                    height: 64,
                    margin: EdgeInsets.only(right: v == '对' ? 8 : 0, left: v == '错' ? 8 : 0),
                    decoration: BoxDecoration(
                      color: _selectedOption == v
                          ? AppTheme.primary.withOpacity(0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedOption == v ? AppTheme.primary : Colors.grey[300]!,
                        width: _selectedOption == v ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        v == '对' ? '✓ 对' : '✗ 错',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _selectedOption == v ? AppTheme.primary : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
    }
  }

  /// V3.8.2: 答完后展示选项（disabled），标正解 + 用户选择
  /// V3.12.14: 多选题用 contains 而非 == 判断（correct/user 都可能多字母）
  Widget _buildAnsweredOptions(Question q) {
    final correctSet = RegExp(r'[A-DZ]')
        .allMatches(q.displayAnswer.toUpperCase())
        .map((m) => m.group(0)!)
        .toSet();
    final userSet = RegExp(r'[A-DZ]')
        .allMatches((_selectedOption ?? '').toUpperCase())
        .map((m) => m.group(0)!)
        .toSet();
    return Column(
      children: q.options!.map((opt) {
        final letter = opt.isNotEmpty ? opt[0].toUpperCase() : '';
        final isCorrect = correctSet.contains(letter);
        final isUserChoice = userSet.contains(letter);
        Color? bg;
        Color border = Colors.grey.shade300;
        IconData? icon;
        Color iconColor = Colors.grey;
        if (isCorrect) {
          bg = Colors.green.shade50; border = Colors.green; icon = Icons.check_circle; iconColor = Colors.green;
        } else if (isUserChoice) {
          bg = Colors.red.shade50; border = Colors.red; icon = Icons.cancel; iconColor = Colors.red;
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg ?? Colors.white,
            border: Border.all(color: border, width: isCorrect || isUserChoice ? 2 : 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: isCorrect
                  ? Colors.green
                  : (isUserChoice ? Colors.red : Colors.grey[200]),
              child: Text(letter,
                  style: TextStyle(
                    fontSize: 12,
                    color: (isCorrect || isUserChoice) ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  )),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MathText(opt.length > 2 ? opt.substring(2) : opt,
                  style: const TextStyle(fontSize: 15)),
            ),
            if (icon != null) Icon(icon, color: iconColor, size: 20),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildResult(Question q, bool correct) {
    // V3.8.3: 主观题答完显示"等家长批改"，不判对错
    if (q.type == QuestionType.subjective) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.purple.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📝 已提交，等家长批改',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 15)),
            const SizedBox(height: 8),
            Text('我的答案：',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _answerCtrl.text.trim().isEmpty ? '（空）' : _answerCtrl.text.trim(),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    final color = correct ? AppTheme.success : AppTheme.secondary;
    final userAnswer = q.type == QuestionType.multipleChoice
        ? (_selectedOption ?? '')
        : _answerCtrl.text.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(correct ? '✅ 回答正确！' : '❌ 回答错误',
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
          if (!correct) ...[
            // V3.8.3: 显式展示我填的 vs 正解，方便小孩判断是否申诉
            const SizedBox(height: 8),
            Text('我填的：$userAnswer',
                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('正确答案：${q.displayAnswer}',
                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
          ],
          if (q.explanation != null) ...[
            const SizedBox(height: 8),
            MathText('解析：${q.explanation}',
                style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5)),
          ],
          // V3.8.3: 申诉快捷入口（错题 + 非主观题）
          if (!correct) ...[
            const SizedBox(height: 10),
            _InlineAppealButton(),
          ],
        ],
      ),
    );
  }

  Color _diffColor(Difficulty d) {
    switch (d) {
      case Difficulty.easy:   return Colors.green;
      case Difficulty.medium: return Colors.orange;
      case Difficulty.hard:   return Colors.red;
    }
  }

  /// V3.12.17: 组合题位置标签（同 groupId ≥ 2 题时显示「📑 组合题 X/N」）
  List<Widget> _groupTags(List<Question> all, Question q) {
    final gid = q.groupId;
    if (gid == null || gid.isEmpty) return const [];
    final mates = all.where((x) => x.groupId == gid).toList()
      ..sort((a, b) => (a.groupOrder ?? 0).compareTo(b.groupOrder ?? 0));
    if (mates.length < 2) return const [];
    final pos = mates.indexWhere((x) => x.id == q.id) + 1;
    if (pos == 0) return const [];
    return [
      const SizedBox(width: 6),
      _Tag('📑 组合题 $pos/${mates.length}',
          Colors.teal.withOpacity(0.15), Colors.teal),
    ];
  }

  String _roundLabel(int r) {
    switch (r) {
      case 1: return '基础';
      case 2: return '中等';
      case 3: return '较难';
      case 4: return '竞赛';
      default: return 'R$r';
    }
  }

  Color _roundColor(int r) {
    switch (r) {
      case 1: return Colors.green;
      case 2: return Colors.blue;
      case 3: return Colors.orange;
      case 4: return Colors.red;
      default: return Colors.grey;
    }
  }
}

/// V3.8.3：答题完成页错题旁的"申诉"快捷按钮（练习中实时申诉）
class _InlineAppealButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final practice = context.watch<PracticeService>();
    final review = context.watch<ReviewRequestService>();
    final recordId = practice.lastSubmittedRecordId;
    if (recordId == null) return const SizedBox.shrink();
    final existing = review.requestForRecord(recordId);

    if (existing != null) {
      // 已申诉过 → 显示状态徽章
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: existing.status == ReviewRequestStatus.approved
              ? Colors.green.shade50
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(children: [
          Icon(
            existing.status == ReviewRequestStatus.approved
                ? Icons.verified
                : Icons.hourglass_top,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            existing.status == ReviewRequestStatus.approved
                ? '已平反 +0.5⭐'
                : '已提交申诉，等家长审核',
            style: const TextStyle(fontSize: 12),
          ),
        ]),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        icon: const Icon(Icons.flag_outlined, size: 16),
        label: const Text('觉得判错了？申诉'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => _onTap(context, recordId),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, int recordId) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('申诉判错'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('提交后由家长审核。审核通过后这道题改成对的，并补⭐。',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '想对家长说点什么？（可空）',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('提交')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final note = ctrl.text.trim().isEmpty ? null : ctrl.text.trim();
    final id = await context
        .read<ReviewRequestService>()
        .submitAppeal(practiceRecordId: recordId, childNote: note);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(id == null ? '无法提交' : '已提交，等家长审核')),
    );
  }
}

// ── 结果界面 ──────────────────────────────────────────
class _ResultScreen extends StatefulWidget {
  final int score;
  final int total;
  final List<Question> questions;
  final SessionRewardSummary? reward;
  final SessionKind kind;
  const _ResultScreen({
    required this.score,
    required this.total,
    required this.questions,
    required this.reward,
    required this.kind,
  });

  @override
  State<_ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<_ResultScreen> {
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // 测评类型：在结果界面提交结果（写 assessments 表 + 发奖）
    if (widget.kind != SessionKind.normal && widget.reward == null) {
      _submitAssessment();
    }
  }

  Future<void> _submitAssessment() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final type = widget.kind == SessionKind.weeklyTest
        ? AssessmentType.weekly
        : AssessmentType.monthly;
    final svc = context.read<AssessmentService>();
    final reward = context.read<RewardService>();
    final practice = context.read<PracticeService>();
    final snap = type == AssessmentType.weekly ? svc.weekly : svc.monthly;
    if (snap == null) {
      setState(() => _submitting = false);
      return;
    }
    final summary = await svc.submitResult(
      type: type,
      periodKey: snap.periodKey,
      score: widget.score,
      total: widget.total,
      rewardService: reward,
    );
    if (summary != null) {
      practice.setLastReward(summary);
    }
    if (mounted) setState(() => _submitting = false);
  }

  String _kindLabel() {
    switch (widget.kind) {
      case SessionKind.weeklyTest:
        return '周测';
      case SessionKind.monthlyTest:
        return '月测';
      case SessionKind.normal:
        return '练习';
    }
  }

  int get score => widget.score;
  int get total => widget.total;
  SessionRewardSummary? get reward =>
      context.watch<PracticeService>().lastReward ?? widget.reward;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (score / total * 100).round() : 0;
    final emoji = pct >= 90 ? '🏆' : pct >= 70 ? '🎉' : pct >= 50 ? '😊' : '💪';

    return Scaffold(
      appBar: AppBar(
        title: Text('${_kindLabel()}完成'),
        actions: [settingsAction(context)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(children: [
              Text(emoji, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 12),
              Text('$score / $total',
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              Text('正确率 $pct%',
                  style: const TextStyle(fontSize: 18, color: Colors.grey)),
            ]),
          ),
          const SizedBox(height: 20),
          if (reward != null)
            _RewardSummaryCard(reward: reward!)
          else if (_submitting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.replay),
                label: const Text('再来一组'),
                onPressed: () => context.read<PracticeService>().endSession(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('针对薄弱点练习'),
                onPressed: () async {
                  final applyDiff = context.read<DifficultySettingsService>().applyToReviewSimilar;
              await context.read<PracticeService>().startAggregatedReviewSession(applyDifficulty: applyDiff);
                  if (!context.mounted) return;
                  if (context.read<PracticeService>().currentQuestions.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('暂无薄弱知识点')),
                    );
                  }
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _RewardSummaryCard extends StatelessWidget {
  final SessionRewardSummary reward;
  const _RewardSummaryCard({required this.reward});

  String _fmt(double s) =>
      s == s.toInt() ? s.toInt().toString() : s.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final headline = reward.perfect
        ? '满分通关！'
        : reward.passed
            ? '通过 🎯'
            : '继续加油，未达 80%';
    final color = reward.perfect
        ? Colors.amber.shade700
        : reward.passed
            ? AppTheme.success
            : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(reward.perfect ? Icons.workspace_premium : Icons.star,
                color: color, size: 22),
            const SizedBox(width: 6),
            Text(headline,
                style: TextStyle(
                    color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Text('答题获星',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const Spacer(),
            Text('${_fmt(reward.perQuestionStars)} ⭐',
                style: const TextStyle(fontSize: 14)),
          ]),
          if (reward.bonusStars > 0) ...[
            const SizedBox(height: 4),
            Row(children: [
              Text(reward.perfect ? '满分加成' : '通过加成',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const Spacer(),
              Text('+${_fmt(reward.bonusStars)} ⭐',
                  style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600)),
            ]),
          ],
          const Divider(),
          Row(children: [
            const Text('本次合计',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            Text('${_fmt(reward.total)} ⭐',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ]),
        ],
      ),
    );
  }
}

// V3.12.22 A3: 选项图渲染 helper（比题目图小，限制 100px 高度）
Widget _renderOptionImage(String data) {
  Widget child;
  if (data.trimLeft().startsWith('<svg')) {
    child = SvgPicture.string(data, height: 100, fit: BoxFit.contain,
      placeholderBuilder: (_) => const SizedBox(height: 100,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
    );
  } else if (data.startsWith('data:image/')) {
    try {
      final base64Str = data.split(',').last;
      child = Image.memory(base64Decode(base64Str), height: 100, fit: BoxFit.contain);
    } catch (_) {
      child = const Text('（选项图加载失败）', style: TextStyle(color: Colors.grey, fontSize: 12));
    }
  } else {
    child = const SizedBox.shrink();
  }
  return Align(alignment: Alignment.centerLeft, child: child);
}

// ── 题目附图（SVG 或 base64 image）───────────────
class _QuestionImage extends StatelessWidget {
  final String data;
  const _QuestionImage({required this.data});

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (data.trimLeft().startsWith('<svg')) {
      child = SvgPicture.string(
        data,
        height: 180,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      );
    } else if (data.startsWith('data:image/')) {
      try {
        final base64Str = data.split(',').last;
        child = Image.memory(base64Decode(base64Str), height: 180, fit: BoxFit.contain);
      } catch (_) {
        child = const Text('图片加载失败', style: TextStyle(color: Colors.grey));
      }
    } else {
      child = const Text('（无法识别的图片格式）', style: TextStyle(color: Colors.grey));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

// ── 听力按钮（V3.12 多角色 TTS）─────────────────
//
// audioText 解析：每行用 `^[A-Za-z]+:` 切 turn，无前缀的行附到上一 turn。
// 每 turn 按 speakers[role] 取 SpeakerProfile，调用 setPitch + speak 串行播放。
// awaitSpeakCompletion(true) 让 speak 自动 await 直到说完，turn 间留 300ms 间隙。
class _ListenButton extends StatefulWidget {
  final String audioText;
  final Map<String, SpeakerProfile>? speakers;
  const _ListenButton({required this.audioText, this.speakers});

  @override
  State<_ListenButton> createState() => _ListenButtonState();
}

class _ListenButtonState extends State<_ListenButton> {
  final _tts = FlutterTts();
  bool _speaking = false;
  bool _ready = false;

  // 单字母 / 短描述前缀：A: / B: / Boy: / Girl: / Man: / Woman: 等
  static final _turnPattern = RegExp(r'^([A-Za-z][A-Za-z]{0,9}):\s*(.*)$');

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.awaitSpeakCompletion(true);
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  /// 把 audioText 切成 turns。多角色：每行 `角色:文本`；纯独白：单 turn 角色 '_'。
  List<({String role, String text})> _parseTurns(String raw) {
    final lines = raw
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final turns = <({String role, String text})>[];
    for (final line in lines) {
      final match = _turnPattern.firstMatch(line);
      if (match != null && (widget.speakers?.containsKey(match.group(1)) ?? false)) {
        turns.add((role: match.group(1)!, text: match.group(2)!.trim()));
      } else if (turns.isNotEmpty) {
        // 续接上一 turn（独白被换行分段或角色名不在 speakers map 中的 fallback）
        final last = turns.last;
        turns[turns.length - 1] = (
          role: last.role,
          text: '${last.text} $line'.trim(),
        );
      } else {
        turns.add((role: '_', text: line));
      }
    }
    return turns.where((t) => t.text.isNotEmpty).toList();
  }

  Future<void> _toggle() async {
    if (!_ready) return;
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);

    final turns = _parseTurns(widget.audioText);
    for (var i = 0; i < turns.length; i++) {
      if (!mounted || !_speaking) break;
      final turn = turns[i];
      final profile = widget.speakers?[turn.role] ?? SpeakerProfile.defaultProfile;
      try {
        await _tts.setPitch(profile.fallbackPitch);
        await _tts.speak(turn.text);
      } catch (_) {/* 单 turn 失败不阻断后续 */}
      if (i < turns.length - 1 && _speaking) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    if (mounted) setState(() => _speaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleSpeakers =
        widget.speakers != null && widget.speakers!.length > 1;
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        icon: Icon(_speaking ? Icons.stop : Icons.volume_up, size: 18),
        label: Text(_speaking
            ? '停止'
            : (hasMultipleSpeakers ? '🔊 播放对话' : '🔊 播放听力')),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          foregroundColor: AppTheme.primary,
          elevation: 0,
        ),
        onPressed: _ready ? _toggle : null,
      ),
    );
  }
}

// ── 辅助 Widget ───────────────────────────────────────
class _Tag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Tag(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
