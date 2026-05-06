import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../models/subject.dart';
import '../database/curriculum_dao.dart';
import '../database/question_dao.dart';
import '../services/plan_service.dart';
import '../services/navigation_service.dart';
import '../services/practice_service.dart';
import 'chapter_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('学习小助手'),
          bottom: const TabBar(
            tabs: [Tab(text: '按科目'), Tab(text: '按年级')],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: const TabBarView(
          children: [_SubjectTab(), _GradeTab()],
        ),
      ),
    );
  }
}

// ── 按科目浏览 ─────────────────────────────
class _SubjectTab extends StatelessWidget {
  const _SubjectTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TodayPlanSummary(),
        const SizedBox(height: 12),
        const _WeakKpSummary(),
        const SizedBox(height: 16),
        const Text('选择科目', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...Subject.values.map((s) => _SubjectCard(subject: s)),
      ],
    );
  }
}

/// 首页摘要：薄弱知识点 Top3，单条点击直接开练，"查看全部"跳错题集
class _WeakKpSummary extends StatefulWidget {
  const _WeakKpSummary();
  @override
  State<_WeakKpSummary> createState() => _WeakKpSummaryState();
}

class _WeakKpSummaryState extends State<_WeakKpSummary> {
  late Future<List<ReviewKpSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = QuestionDao().getTopWeakKnowledgePoints(3);
  }

  Future<void> _practiceKp(BuildContext context, String fullPath) async {
    await context.read<PracticeService>().startKpReviewSession(fullPath);
    if (!context.mounted) return;
    final qs = context.read<PracticeService>().currentQuestions;
    if (qs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该知识点的题练完了，等新题包')),
      );
      return;
    }
    context.read<NavigationService>().goTo(2);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReviewKpSummary>>(
      future: _future,
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        if (list.isEmpty) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    const Text('薄弱知识点',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    InkWell(
                      onTap: () => context.read<NavigationService>().goTo(3),
                      child: Text('查看全部 →',
                          style: TextStyle(fontSize: 12, color: AppTheme.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...list.map((s) {
                  final emoji = s.totalErrors >= 6
                      ? '🔴'
                      : s.totalErrors >= 3
                          ? '🟠'
                          : '🟡';
                  return InkWell(
                    onTap: () => _practiceKp(context, s.fullPath),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${s.category} / ${s.name}',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('${s.totalErrors} 次',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(width: 4),
                          Icon(Icons.play_circle_outline,
                              size: 18, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(subject.emoji, style: const TextStyle(fontSize: 28)),
        title: Text(subject.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subject.gradeRangeLabel, style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => _GradeListScreen(subject: subject))),
      ),
    );
  }
}

// ── 按年级浏览 ─────────────────────────────
class _GradeTab extends StatelessWidget {
  const _GradeTab();

  @override
  Widget build(BuildContext context) {
    const grades = [
      (6, '六年级', '小学阶段'),
      (7, '初一',   '初中阶段'),
      (8, '初二',   '初中阶段'),
      (9, '初三',   '初中阶段'),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _WeakKpSummary(),
        const SizedBox(height: 12),
        const Text('选择年级', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...grades.map((g) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary,
              child: Text(
                g.$2.length > 2 ? g.$2.substring(0, 1) : g.$2,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            title: Text(g.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(g.$3),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => _SubjectListScreen(grade: g.$1, gradeLabel: g.$2))),
          ),
        )),
      ],
    );
  }
}

// ── 科目 → 年级列表 ────────────────────────
class _GradeListScreen extends StatefulWidget {
  final Subject subject;
  const _GradeListScreen({required this.subject});
  @override State<_GradeListScreen> createState() => _GradeListScreenState();
}

class _GradeListScreenState extends State<_GradeListScreen> {
  final _dao = CurriculumDao();
  List<int> _grades = [];
  static const _labels = {6: '六年级', 7: '初一', 8: '初二', 9: '初三'};

  @override
  void initState() {
    super.initState();
    _dao.getGradesForSubject(widget.subject.displayName)
        .then((g) => setState(() => _grades = g));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.subject.emoji} ${widget.subject.displayName}')),
      body: _grades.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _grades.map((g) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('${_labels[g]} ${widget.subject.displayName}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ChapterDetailScreen(
                      subject: widget.subject, grade: g))),
                ),
              )).toList(),
            ),
    );
  }
}

// ── 年级 → 科目列表 ────────────────────────
class _SubjectListScreen extends StatefulWidget {
  final int grade;
  final String gradeLabel;
  const _SubjectListScreen({required this.grade, required this.gradeLabel});
  @override State<_SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<_SubjectListScreen> {
  final _dao = CurriculumDao();
  List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    _dao.getSubjectsForGrade(widget.grade)
        .then((s) => setState(() => _subjects = s));
  }

  Subject? _toSubject(String name) {
    try { return Subject.values.firstWhere((s) => s.displayName == name); } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.gradeLabel)),
      body: _subjects.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _subjects.map((name) {
                final s = _toSubject(name);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Text(s?.emoji ?? '📚', style: const TextStyle(fontSize: 28)),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: s == null ? null : () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ChapterDetailScreen(
                        subject: s, grade: widget.grade))),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ── 今日计划摘要 ───────────────────────────
class _TodayPlanSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = context.watch<PlanService>().todayItems;
    final done = items.where((i) => i.status.index == 1).length;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? '早上好' : hour < 18 ? '下午好' : '晚上好';
    return Card(
      color: AppTheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const Text('🌟', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$greeting，加油！',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(items.isEmpty ? '今天还没有计划' : '今日计划 $done/${items.length} 已完成',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ]),
      ),
    );
  }
}
