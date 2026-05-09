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
import '../services/review_request_service.dart';
import '../services/data_reset_service.dart';
import '../models/review_request.dart';

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
  DataResetService? _resetListenerRef;
  bool _wasSessionActive = false;
  int _lastReadResetVersion = 0;

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
    // V3.12.7：监听 DataResetService 主动重置→ 错题集即时清零
    final r = context.read<DataResetService>();
    if (_resetListenerRef != r) {
      _resetListenerRef?.removeListener(_onResetChanged);
      _resetListenerRef = r;
      r.addListener(_onResetChanged);
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

  void _onResetChanged() {
    if (!mounted) return;
    setState(() => _future = _dao.getReviewKnowledgePoints());
    context.read<AssessmentService>().refresh();
  }

  @override
  void dispose() {
    _practiceListenerRef?.removeListener(_onPracticeChanged);
    _resetListenerRef?.removeListener(_onResetChanged);
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
    // V3.12.9: watch resetVersion 强制重 fetch 错题集（每次 reset 重新读 DB）
    final resetVersion = context.select<DataResetService, int>((s) => s.resetVersion);
    final futureWithKey = (resetVersion > _lastReadResetVersion)
        ? _dao.getReviewKnowledgePoints()
        : _future;
    if (resetVersion > _lastReadResetVersion) {
      _future = futureWithKey;
      _lastReadResetVersion = resetVersion;
    }
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
                // V3.8.3: 详情页隐藏 KP 名称（避免做"练相似题"时暴露考点）
                Text(
                  '错题复盘',
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
    // V3.8.3: 申诉机制 - 监听 ReviewRequestService
    final reviewService = context.watch<ReviewRequestService>();
    final existing = reviewService.requestForRecord(record.practiceRecordId);
    final age = DateTime.now().difference(record.practicedAt);
    final inWindow = age < ReviewRequestService.appealWindow;

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
                if (q.round != null) ...[
                  const SizedBox(width: 6),
                  _Tag(_roundLabel(q.round!),
                      _roundColor(q.round!).withOpacity(0.12),
                      _roundColor(q.round!)),
                ],
                const Spacer(),
                Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
            const SizedBox(height: 8),
            MathText(q.content,
                style: const TextStyle(fontSize: 14, height: 1.5)),
            // V3.8.2: 选择题展示完整选项（标正解 + 用户错选）
            if (q.type == QuestionType.multipleChoice && q.options != null) ...[
              const SizedBox(height: 8),
              ..._buildOptionRows(q, record.userAnswer),
            ],
            const SizedBox(height: 10),
            _kvRow('当时填的：', record.userAnswer, Colors.red.shade700),
            _kvRow('正确答案：', q.displayAnswer, Colors.green.shade700),
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
            // V3.8.3: 申诉行（窗口内 / 已申诉 都显示）
            if (existing != null || inWindow) ...[
              const SizedBox(height: 10),
              _AppealRow(record: record, existing: existing, inWindow: inWindow),
            ],
          ],
        ),
      ),
    );
  }

  /// V3.8.2: 错题集详情页选择题选项展示，标出正解 + 用户错选
  List<Widget> _buildOptionRows(Question q, String userAnswer) {
    final correctLetter = q.displayAnswer.trim().toUpperCase();
    final userLetter = userAnswer.trim().toUpperCase();
    return q.options!.map((opt) {
      final letter = opt.isNotEmpty ? opt[0].toUpperCase() : '';
      final isCorrect = letter == correctLetter;
      final isUserChoice = letter == userLetter;
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
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg, border: Border.all(color: border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 6),
          ],
          Expanded(child: MathText(opt, style: const TextStyle(fontSize: 12.5))),
        ]),
      );
    }).toList();
  }

  String _roundLabel(int r) {
    switch (r) { case 1: return '基础'; case 2: return '中等'; case 3: return '较难'; case 4: return '竞赛'; default: return 'R$r'; }
  }

  Color _roundColor(int r) {
    switch (r) { case 1: return Colors.green; case 2: return Colors.blue; case 3: return Colors.orange; case 4: return Colors.red; default: return Colors.grey; }
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

/// V3.8.3：错题集 / 答题完成页通用申诉行
class _AppealRow extends StatelessWidget {
  final WrongQuestionRecord record;
  final ReviewRequest? existing;
  final bool inWindow;
  const _AppealRow({
    required this.record,
    required this.existing,
    required this.inWindow,
  });

  @override
  Widget build(BuildContext context) {
    final ex = existing;
    if (ex != null) {
      return _statusChip(context, ex);
    }
    if (!inWindow) return const SizedBox.shrink();
    return _appealButton(context);
  }

  Widget _statusChip(BuildContext context, ReviewRequest ex) {
    Color bg, fg;
    String text;
    IconData icon;
    switch (ex.status) {
      case ReviewRequestStatus.pending:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        text = '已提交申诉，等家长审核';
        icon = Icons.hourglass_top;
        break;
      case ReviewRequestStatus.approved:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        text = ex.requestType == ReviewRequestType.appeal
            ? '已平反 +0.5⭐'
            : '主观题评分：${ex.parentScore?.label ?? "-"}';
        icon = Icons.verified;
        break;
      case ReviewRequestStatus.rejected:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        text = '申诉被驳回';
        icon = Icons.cancel_outlined;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: fg)),
          ),
          if (ex.parentNote != null && ex.parentNote!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.message_outlined, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: ex.parentNote,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('家长备注：${ex.parentNote}')),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _appealButton(BuildContext context) {
    final remaining = ReviewRequestService.appealWindow -
        DateTime.now().difference(record.practicedAt);
    final remainText = remaining.inMinutes > 60
        ? '剩 ${remaining.inHours}h${remaining.inMinutes.remainder(60)}m'
        : '剩 ${remaining.inMinutes}m';
    return Row(
      children: [
        Icon(Icons.flag_outlined, size: 14, color: Colors.orange.shade700),
        const SizedBox(width: 6),
        Text('觉得这题判错了？', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        const Spacer(),
        Text(remainText, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(width: 8),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => _onTap(context),
          child: const Text('申诉', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Future<void> _onTap(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('申诉判错'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '提交后由家长审核。审核通过后这道题会改成对的，并补⭐。',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
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
        .submitAppeal(practiceRecordId: record.practiceRecordId, childNote: note);
    if (!context.mounted) return;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法提交（已申诉过 / 超出 2 小时窗口 / 题目状态不符）')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已提交，等家长审核')),
      );
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
