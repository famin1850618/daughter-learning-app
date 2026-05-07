import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../utils/app_theme.dart';
import '../utils/math_text.dart';
import '../utils/settings_action.dart';
import '../models/question.dart';
import '../models/subject.dart';
import '../models/assessment.dart';
import '../database/question_dao.dart';
import '../services/practice_service.dart';
import '../services/navigation_service.dart';
import '../services/assessment_service.dart';
import '../services/reward_service.dart';
import '../services/difficulty_settings_service.dart';

/// 错题集（按 KP 聚类）
///
/// 两层导航：
/// 1. KP 卡片列表（仅显示待掌握 KP，按一级 category 分组）
/// 2. 点 KP 进入错题历史详情页（题面/错答/正答/解析）
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _dao = QuestionDao();
  late Future<List<ReviewKpSummary>> _future;
  PracticeService? _practiceListenerRef;
  bool _wasSessionActive = false;

  @override
  void initState() {
    super.initState();
    _future = _dao.getReviewKnowledgePoints();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssessmentService>().refresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 监听 PracticeService：session 从 active 变 inactive 时自动刷新错题集
    final p = context.read<PracticeService>();
    if (_practiceListenerRef != p) {
      _practiceListenerRef?.removeListener(_onPracticeChanged);
      _practiceListenerRef = p;
      p.addListener(_onPracticeChanged);
      _wasSessionActive = p.sessionActive;
    }
  }

  void _onPracticeChanged() {
    final p = _practiceListenerRef;
    if (p == null || !mounted) return;
    final nowActive = p.sessionActive;
    if (_wasSessionActive && !nowActive) {
      // session 刚完成，刷新错题集 + 测评
      setState(() => _future = _dao.getReviewKnowledgePoints());
      context.read<AssessmentService>().refresh();
    }
    _wasSessionActive = nowActive;
  }

  @override
  void dispose() {
    _practiceListenerRef?.removeListener(_onPracticeChanged);
    super.dispose();
  }

  void _refresh() {
    setState(() => _future = _dao.getReviewKnowledgePoints());
    context.read<AssessmentService>().refresh();
  }

  // 错题集子 tab：6 个学科（AI 在题库设计前显示空态）
  static const _subjectTabs = [
    Subject.chinese,
    Subject.math,
    Subject.english,
    Subject.physics,
    Subject.chemistry,
    Subject.ai,
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('成效'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
              tooltip: '刷新',
            ),
            settingsAction(context),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.report_outlined), text: '错题集'),
              Tab(icon: Icon(Icons.assignment_outlined), text: '测试'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _wrongQuestionsTab(),
            _testTab(context),
          ],
        ),
      ),
    );
  }

  Widget _wrongQuestionsTab() {
    return FutureBuilder<List<ReviewKpSummary>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data ?? [];
        return DefaultTabController(
          length: _subjectTabs.length,
          child: Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.surface,
                elevation: 1,
                child: TabBar(
                  isScrollable: true,
                  indicatorColor: AppTheme.primary,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: _subjectTabs
                      .map((s) => Tab(text: '${s.emoji} ${s.displayName}'))
                      .toList(),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: _subjectTabs.map((subj) {
                    if (subj == Subject.ai) {
                      return const _AiPlaceholder();
                    }
                    final filtered =
                        all.where((s) => s.subject == subj).toList();
                    return _SubjectReviewList(
                      items: filtered,
                      onChanged: _refresh,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _testTab(BuildContext context) {
    final assessment = context.watch<AssessmentService>();
    final hasAny = assessment.weekly != null || assessment.monthly != null;
    if (!hasAny) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📋', style: TextStyle(fontSize: 56)),
            SizedBox(height: 12),
            Text('当前没有可挑战的测试',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('完成本周/本月计划后自动解锁',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (assessment.weekly != null)
          _AssessmentCard(snapshot: assessment.weekly!),
        if (assessment.monthly != null)
          _AssessmentCard(snapshot: assessment.monthly!),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AiPlaceholder extends StatelessWidget {
  const _AiPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🤖', style: TextStyle(fontSize: 56)),
            SizedBox(height: 12),
            Text('AI 题库待独立设计',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text(
              'AI 不走选择/填空模板，需要按编程引导/项目实战形态独立设计。\n暂无题目可练。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单科目错题集列表（按一级 category 二级分组）
class _SubjectReviewList extends StatelessWidget {
  final List<ReviewKpSummary> items;
  final VoidCallback onChanged;
  const _SubjectReviewList({required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎉', style: TextStyle(fontSize: 56)),
            SizedBox(height: 12),
            Text('暂无待掌握知识点',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('继续保持！',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }
    final grouped = <String, List<ReviewKpSummary>>{};
    for (final s in items) {
      grouped.putIfAbsent(s.category, () => []).add(s);
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
            child: Text(
              entry.key,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600),
            ),
          ),
          ...entry.value.map((s) => _KpCard(summary: s, onChanged: onChanged)),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// 周/月测评卡片
class _AssessmentCard extends StatelessWidget {
  final AssessmentSnapshot snapshot;
  const _AssessmentCard({required this.snapshot});

  String get _typeLabel =>
      snapshot.type == AssessmentType.weekly ? '周测' : '月测';

  IconData get _typeIcon => snapshot.type == AssessmentType.weekly
      ? Icons.calendar_view_week
      : Icons.calendar_month;

  ({Color color, String label, IconData icon}) get _statusStyle {
    switch (snapshot.status) {
      case AssessmentStatus.locked:
        return (
          color: Colors.grey.shade500,
          label: '计划完成后解锁',
          icon: Icons.lock_outline,
        );
      case AssessmentStatus.available:
        return (
          color: AppTheme.primary,
          label: '可挑战',
          icon: Icons.play_circle_outline,
        );
      case AssessmentStatus.passed:
        return (
          color: AppTheme.success,
          label: '已通过',
          icon: Icons.verified,
        );
      case AssessmentStatus.failed:
        return (
          color: Colors.orange,
          label: '需补练，可重试',
          icon: Icons.refresh,
        );
    }
  }

  Future<void> _start(BuildContext context) async {
    final svc = context.read<AssessmentService>();
    final result = await svc.buildAssessmentQuestions(snapshot.type);
    if (!context.mounted) return;
    if (result.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                result.warnings.isEmpty ? '题库不足' : result.warnings.join('；'))),
      );
      return;
    }
    if (result.warnings.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.warnings.first)),
      );
    }
    final kind = snapshot.type == AssessmentType.weekly
        ? SessionKind.weeklyTest
        : SessionKind.monthlyTest;
    context.read<PracticeService>().startAssessmentSession(
          questions: result.questions,
          kind: kind,
          periodKey: snapshot.periodKey,
        );
    context.read<NavigationService>().goTo(2);
  }

  @override
  Widget build(BuildContext context) {
    final st = _statusStyle;
    final canStart = snapshot.status == AssessmentStatus.available ||
        snapshot.status == AssessmentStatus.failed;
    final latest = snapshot.latest;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: st.color.withOpacity(0.4), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(_typeIcon, color: st.color, size: 22),
              const SizedBox(width: 8),
              Text('$_typeLabel · ${snapshot.periodKey}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              Icon(st.icon, color: st.color, size: 18),
              const SizedBox(width: 4),
              Text(st.label,
                  style: TextStyle(
                      color: st.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            Text(
              snapshot.unitCount == 0
                  ? '当期无可测评单元'
                  : '${snapshot.unitCount} 个知识单元 · 共 ${snapshot.targetTotal} 题',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            if (latest != null) ...[
              const SizedBox(height: 4),
              Text(
                '上次：${latest.score} / ${latest.total}（${(latest.percent * 100).round()}%）',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
            if (canStart) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(snapshot.status == AssessmentStatus.failed
                      ? Icons.refresh
                      : Icons.play_arrow),
                  label: Text(snapshot.status == AssessmentStatus.failed
                      ? '再试一次'
                      : '开始 $_typeLabel'),
                  onPressed: () => _start(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KpCard extends StatelessWidget {
  final ReviewKpSummary summary;
  final VoidCallback onChanged;
  const _KpCard({required this.summary, required this.onChanged});

  Color _gradeColor(int errors) {
    if (errors >= 6) return Colors.red;
    if (errors >= 3) return Colors.orange;
    return Colors.amber.shade600;
  }

  String _gradeEmoji(int errors) {
    if (errors >= 6) return '🔴';
    if (errors >= 3) return '🟠';
    return '🟡';
  }

  String _formatDate(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return DateFormat('M月d日').format(t);
  }

  Future<void> _practiceSimilar(BuildContext context) async {
    final applyDiff = context.read<DifficultySettingsService>().applyToReviewSimilar;
    await context.read<PracticeService>().startKpReviewSession(summary.fullPath, applyDifficulty: applyDiff);
    if (!context.mounted) return;
    final qs = context.read<PracticeService>().currentQuestions;
    if (qs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该知识点的题练完了，等新题包')),
      );
      return;
    }
    context.read<NavigationService>().goTo(2); // 跳到练习 tab
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _KpDetailScreen(summary: summary),
    )).then((_) => onChanged());
  }

  @override
  Widget build(BuildContext context) {
    final color = _gradeColor(summary.totalErrors);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.5), width: 1),
      ),
      child: InkWell(
        onTap: () => _openDetail(context),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(_gradeEmoji(summary.totalErrors),
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '累计错 ${summary.totalErrors} 次 · 最近 ${_formatDate(summary.lastWrongAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('练相似题'),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () => _practiceSimilar(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpDetailScreen extends StatefulWidget {
  final ReviewKpSummary summary;
  const _KpDetailScreen({required this.summary});

  @override
  State<_KpDetailScreen> createState() => _KpDetailScreenState();
}

class _KpDetailScreenState extends State<_KpDetailScreen> {
  final _dao = QuestionDao();
  late Future<List<WrongQuestionRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _dao.getWrongHistoryForKnowledgePoint(widget.summary.fullPath);
  }

  Future<void> _practiceSimilar() async {
    final applyDiff = context.read<DifficultySettingsService>().applyToReviewSimilar;
    await context.read<PracticeService>().startKpReviewSession(widget.summary.fullPath, applyDifficulty: applyDiff);
    if (!mounted) return;
    final qs = context.read<PracticeService>().currentQuestions;
    if (qs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该知识点的题练完了，等新题包')),
      );
      return;
    }
    context.read<NavigationService>().goTo(2);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.summary.name)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.summary.category} / ${widget.summary.name}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Text(
                  '累计错 ${widget.summary.totalErrors} 次',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('练相似题'),
                onPressed: _practiceSimilar,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<WrongQuestionRecord>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const Center(child: Text('暂无错题记录'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _WrongRecordCard(record: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WrongRecordCard extends StatelessWidget {
  final WrongQuestionRecord record;
  const _WrongRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final q = record.question;
    final dateStr = DateFormat('M月d日 HH:mm').format(record.practicedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Tag(q.type.label, AppTheme.primary.withOpacity(0.12), AppTheme.primary),
                const SizedBox(width: 6),
                _Tag(q.difficulty.label,
                    _diffColor(q.difficulty).withOpacity(0.12),
                    _diffColor(q.difficulty)),
                const Spacer(),
                Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
            const SizedBox(height: 8),
            MathText(q.content,
                style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 10),
            _kvRow('当时填的：', record.userAnswer, Colors.red.shade700),
            _kvRow('正确答案：', q.answer, Colors.green.shade700),
            if (q.explanation != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: MathText('💡 ${q.explanation}',
                    style: const TextStyle(fontSize: 12.5, height: 1.5)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kvRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Expanded(
            child: Text(
              value.isEmpty ? '（空）' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _diffColor(Difficulty d) {
    switch (d) {
      case Difficulty.easy: return Colors.green;
      case Difficulty.medium: return Colors.orange;
      case Difficulty.hard: return Colors.red;
    }
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Tag(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w600)),
    );
  }
}
