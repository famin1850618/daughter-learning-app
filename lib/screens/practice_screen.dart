import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../utils/app_theme.dart';
import '../utils/math_text.dart';
import '../utils/settings_action.dart';
import '../services/difficulty_settings_service.dart';
import '../models/subject.dart';
import '../models/question.dart';
import '../models/curriculum.dart';
import '../database/curriculum_dao.dart';
import '../database/question_dao.dart';
import '../services/practice_service.dart';
import '../services/reward_service.dart';
import '../services/assessment_service.dart';
import '../models/assessment.dart';

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

  int _grade = 7;
  Subject? _subject;
  String? _chapter;
  QuestionType? _type;
  Difficulty? _difficulty;
  int _count = 10;
  int _totalAvailable = 0;

  List<Chapter> _chapters = [];

  static const _gradeLabels = {6: '六年级', 7: '初一', 8: '初二', 9: '初三'};

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  Future<void> _onGradeChanged(int g) async {
    setState(() { _grade = g; _subject = null; _chapter = null; _chapters = []; });
    _refreshCount();
  }

  Future<void> _onSubjectChanged(Subject? s) async {
    setState(() { _subject = s; _chapter = null; _chapters = []; });
    if (s != null) {
      final chapters = await _currDao.getChapters(s.displayName, _grade);
      setState(() => _chapters = chapters);
    }
    _refreshCount();
  }

  Future<void> _refreshCount() async {
    if (_subject == null) { setState(() => _totalAvailable = 0); return; }
    final qs = await _questionDao.getRandom(
      subject: _subject!,
      grade: _grade,
      chapter: _chapter,
      type: _type,
      difficulty: _difficulty,
      limit: 999,
    );
    setState(() => _totalAvailable = qs.length);
  }

  Future<void> _start() async {
    if (_subject == null) return;
    await context.read<PracticeService>().startSession(
      subject: _subject!,
      grade: _grade,
      chapter: _chapter,
      type: _type,
      difficulty: _difficulty,
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

          // 难度
          _chips<Difficulty>(
            label: '难度',
            options: [(null, '全部'), ...Difficulty.values.map((d) => (d, d.label))],
            selected: _difficulty,
            onSelect: (d) => setState(() => _difficulty = d),
          ),

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

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void didUpdateWidget(_QuestionScreen old) {
    super.didUpdateWidget(old);
    if (old.question.id != widget.question.id) {
      _selectedOption = null;
      _result = null;
      _answerCtrl.clear();
      _seconds = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerCtrl.dispose();
    super.dispose();
  }

  String get _timerLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  Future<void> _submit() async {
    final q = widget.question;
    final answer = q.type == QuestionType.multipleChoice
        ? (_selectedOption ?? '')
        : _answerCtrl.text.trim();
    if (answer.isEmpty) return;
    final correct = await context.read<PracticeService>().submitAnswer(answer);
    setState(() => _result = correct);
    _timer?.cancel();
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
      body: SingleChildScrollView(
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

            // 元信息
            Row(children: [
              _Tag(q.type.label, AppTheme.primary.withOpacity(0.15), AppTheme.primary),
              const SizedBox(width: 6),
              _Tag(q.difficulty.label,
                  _diffColor(q.difficulty).withOpacity(0.15), _diffColor(q.difficulty)),
              if (q.knowledgePoint != null) ...[
                const SizedBox(width: 6),
                _Tag(q.knowledgePoint!, Colors.grey[100]!, Colors.grey[600]!),
              ],
            ]),
            const SizedBox(height: 12),

            // 听力题播放按钮
            if (q.audioText != null && q.audioText!.isNotEmpty)
              _ListenButton(text: q.audioText!),

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

            // 答题区域
            if (_result == null) ...[
              _buildInputArea(q),
              const SizedBox(height: 12),

              // 提示按钮
              if (q.explanation != null && !service.hintShown)
                TextButton.icon(
                  icon: const Icon(Icons.lightbulb_outline, size: 18),
                  label: const Text('查看提示'),
                  onPressed: () => context.read<PracticeService>().showHint(),
                ),
              if (service.hintShown && q.explanation != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: MathText('💡 ${q.explanation}',
                      style: const TextStyle(color: Colors.black87, fontSize: 13)),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _canSubmit(q) ? _submit : null,
                  child: const Text('提交答案', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],

            // 结果反馈
            if (_result != null) ...[
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
    );
  }

  bool _canSubmit(Question q) {
    if (q.type == QuestionType.multipleChoice) return _selectedOption != null;
    return _answerCtrl.text.trim().isNotEmpty;
  }

  Widget _buildInputArea(Question q) {
    switch (q.type) {
      case QuestionType.multipleChoice:
        return Column(
          children: q.options!.map((opt) {
            final letter = opt.substring(0, 1);
            final isSelected = _selectedOption == letter;
            return GestureDetector(
              onTap: () => setState(() => _selectedOption = letter),
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
                child: Row(children: [
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
                  Expanded(child: Text(opt.length > 2 ? opt.substring(2) : opt,
                      style: const TextStyle(fontSize: 15))),
                ]),
              ),
            );
          }).toList(),
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
    }
  }

  Widget _buildResult(Question q, bool correct) {
    final color = correct ? AppTheme.success : AppTheme.secondary;
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
            const SizedBox(height: 6),
            Text('正确答案：${q.displayAnswer}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
          if (q.explanation != null) ...[
            const SizedBox(height: 8),
            MathText('解析：${q.explanation}',
                style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5)),
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
      appBar: AppBar(title: Text('${_kindLabel()}完成')),
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

// ── 听力按钮（TTS 朗读 audioText）─────────────────
class _ListenButton extends StatefulWidget {
  final String text;
  const _ListenButton({required this.text});

  @override
  State<_ListenButton> createState() => _ListenButtonState();
}

class _ListenButtonState extends State<_ListenButton> {
  final _tts = FlutterTts();
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.45);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
    } else {
      setState(() => _speaking = true);
      await _tts.speak(widget.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        icon: Icon(_speaking ? Icons.stop : Icons.volume_up, size: 18),
        label: Text(_speaking ? '停止' : '🔊 播放听力'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          foregroundColor: AppTheme.primary,
          elevation: 0,
        ),
        onPressed: _toggle,
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
