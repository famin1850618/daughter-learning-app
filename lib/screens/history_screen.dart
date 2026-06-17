import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/question_dao.dart';
import '../services/plan_service.dart';
import '../models/subject.dart';
import '../utils/app_theme.dart';
import '../utils/math_text.dart';

/// V3.28 学习留痕：练习历史（时间线 → session 详情 + 计划对账 → 单题历次作答）。
/// 数据全来自 practice_records（按 session_id 聚合），不改数据层。

String _fmtTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.month}/${t.day} ${two(t.hour)}:${two(t.minute)}';
}

String _clip(String s, [int n = 60]) =>
    s.replaceAll('\n', ' ').length > n
        ? '${s.replaceAll('\n', ' ').substring(0, n)}…'
        : s.replaceAll('\n', ' ');

// ── 时间线（嵌入成效页 Tab）─────────────────────────────────
class HistoryTimeline extends StatefulWidget {
  const HistoryTimeline({super.key});
  @override
  State<HistoryTimeline> createState() => _HistoryTimelineState();
}

class _HistoryTimelineState extends State<HistoryTimeline> {
  final _dao = QuestionDao();
  late Future<List<SessionSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _dao.getSessionSummaries();
  }

  void _reload() => setState(() => _future = _dao.getSessionSummaries());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SessionSummary>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data!;
        if (all.isEmpty) {
          return const Center(child: Text('还没有练习记录'));
        }
        // 本周汇总
        final now = DateTime.now();
        final weekStart = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final week = all.where((s) => s.startedAt.isAfter(weekStart)).toList();
        final wQ = week.fold<int>(0, (a, s) => a + s.count);
        final wP = week.fold<double>(0, (a, s) => a + s.partialSum);
        final wAcc = wQ > 0 ? (wP / wQ * 100).round() : 0;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              color: AppTheme.primary.withOpacity(0.06),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('本周回顾',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text('练习 ${week.length} 次 · 做题 $wQ 道 · 正确率 $wAcc%',
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...all.map((s) => _sessionCard(context, s)),
          ],
        );
      },
    );
  }

  Widget _sessionCard(BuildContext context, SessionSummary s) {
    final emojis = s.subjectIdx
        .map((i) => i >= 0 && i < Subject.values.length
            ? Subject.values[i].emoji
            : '')
        .join();
    final acc = (s.accuracy * 100).round();
    return Card(
      child: ListTile(
        leading: Text(emojis.isEmpty ? '📝' : emojis,
            style: const TextStyle(fontSize: 22)),
        title: Text(_clip(s.chapters.join('、'), 40),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
            '${_fmtTime(s.startedAt)} · ${s.correctCount}/${s.count} 对 · 正确率 $acc%'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SessionDetailScreen(summary: s)),
          );
          _reload(); // 回来刷新（可能手动标记了完成）
        },
      ),
    );
  }
}

// ── session 详情 + 计划对账 ─────────────────────────────────
class SessionDetailScreen extends StatefulWidget {
  final SessionSummary summary;
  const SessionDetailScreen({super.key, required this.summary});
  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final _dao = QuestionDao();
  List<Map<String, Object?>> _records = [];
  List<dynamic> _matchingItems = []; // PlanItem
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plan = context.read<PlanService>(); // 在 await 前取，避免跨 async gap 用 context
    final recs = await _dao.getRecordsForSession(widget.summary.sessionId);
    // 覆盖的知识点元组 → 匹配的待办计划项
    final tuples = <PracticeKpTuple>[];
    final seen = <String>{};
    for (final r in recs) {
      final subjIdx = (r['subject'] as int?) ?? -1;
      if (subjIdx < 0 || subjIdx >= Subject.values.length) continue;
      final key =
          '$subjIdx|${r['grade']}|${r['chapter']}|${r['knowledge_point']}';
      if (seen.add(key)) {
        tuples.add(PracticeKpTuple(
          subjectName: Subject.values[subjIdx].displayName,
          grade: (r['grade'] as int?) ?? 0,
          chapter: (r['chapter'] as String?) ?? '',
          knowledgePoint: r['knowledge_point'] as String?,
        ));
      }
    }
    final items = await plan.pendingItemsMatching(tuples);
    if (!mounted) return;
    setState(() {
      _records = recs;
      _matchingItems = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final acc = (s.accuracy * 100).round();
    return Scaffold(
      appBar: AppBar(title: const Text('练习详情')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fmtTime(s.startedAt),
                            style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text('${s.correctCount}/${s.count} 对 · 正确率 $acc%',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        if (s.chapters.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('范围：${s.chapters.join('、')}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700)),
                        ],
                      ],
                    ),
                  ),
                ),
                _planPanel(),
                const SizedBox(height: 8),
                const Text('  逐题记录',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ..._records.map(_recordTile),
              ],
            ),
    );
  }

  Widget _planPanel() {
    if (_matchingItems.isEmpty) {
      return Card(
        color: Colors.grey.shade50,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Text('📋 本次练习未匹配到待完成的计划任务\n'
              '（可能任务已完成，或章节/知识点名称与题库不一致）',
              style: TextStyle(fontSize: 13)),
        ),
      );
    }
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📋 本次练习相关的待完成任务',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            ..._matchingItems.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.subjectEmoji} ${item.chapterName}'
                        '${item.knowledgePoint != null ? ' / ${item.knowledgePoint}' : ''}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await context
                            .read<PlanService>()
                            .markItemComplete(item.id as int);
                        await _load();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已标记完成 ✅')),
                          );
                        }
                      },
                      child: const Text('标记完成'),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _recordTile(Map<String, Object?> r) {
    final correct = ((r['is_correct'] as int?) ?? 0) == 1;
    final partial = (r['partial_score'] as num?)?.toDouble();
    final ans = (r['user_answer'] as String?) ?? '';
    final ts = (r['time_spent'] as int?) ?? 0;
    final qid = r['question_id'] as int?;
    final partialNote = (!correct && partial != null && partial > 0)
        ? '（部分 ${(partial * 100).round()}%）'
        : '';
    return Card(
      color: correct ? Colors.green.shade50 : Colors.red.shade50,
      child: ListTile(
        dense: true,
        leading: Icon(correct ? Icons.check_circle : Icons.cancel,
            color: correct ? Colors.green : Colors.red),
        title: MathText(_clip((r['content'] as String?) ?? '', 70),
            style: const TextStyle(fontSize: 13)),
        subtitle: Text('你答：${ans.isEmpty ? '（空）' : _clip(ans, 40)}'
            '$partialNote · ${ts}s'),
        trailing: const Icon(Icons.history, size: 18),
        onTap: qid == null
            ? null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => QuestionHistoryScreen(
                          questionId: qid,
                          contentSnippet: _clip(
                              (r['content'] as String?) ?? '', 60))),
                ),
      ),
    );
  }
}

// ── 单题历次作答 ───────────────────────────────────────────
class QuestionHistoryScreen extends StatefulWidget {
  final int questionId;
  final String contentSnippet;
  const QuestionHistoryScreen(
      {super.key, required this.questionId, required this.contentSnippet});
  @override
  State<QuestionHistoryScreen> createState() => _QuestionHistoryScreenState();
}

class _QuestionHistoryScreenState extends State<QuestionHistoryScreen> {
  final _dao = QuestionDao();
  late Future<List<Map<String, Object?>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _dao.getAttemptsForQuestion(widget.questionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('这道题的历次作答')),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snap.data!;
          final correctN =
              rows.where((r) => ((r['is_correct'] as int?) ?? 0) == 1).length;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MathText(widget.contentSnippet,
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('做过 ${rows.length} 次 · 对 $correctN 次'
                          '${correctN >= 3 ? ' · 已掌握 ✅' : ''}',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...rows.map((r) {
                final correct = ((r['is_correct'] as int?) ?? 0) == 1;
                final at = DateTime.tryParse(
                    (r['practiced_at'] as String?) ?? '');
                final ans = (r['user_answer'] as String?) ?? '';
                return ListTile(
                  dense: true,
                  leading: Icon(correct ? Icons.check : Icons.close,
                      color: correct ? Colors.green : Colors.red, size: 20),
                  title: Text('你答：${ans.isEmpty ? '（空）' : _clip(ans, 50)}'),
                  subtitle: Text(at != null ? _fmtTime(at) : ''),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
