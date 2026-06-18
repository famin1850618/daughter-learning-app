import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/question_dao.dart';
import '../services/plan_service.dart';
import '../models/subject.dart';
import '../utils/math_text.dart';

/// V3.28 学习留痕：练习历史（时间线 → session 详情 + 计划对账 → 单题历次作答）。
/// 数据全来自 practice_records（按 session_id 聚合），不改数据层。

String _fmtTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.month}/${t.day} ${two(t.hour)}:${two(t.minute)}';
}

String _fmtDate(DateTime t) => '${t.year}/${t.month}/${t.day}';

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
  bool _rangeMode = false; // false=按自然月分组, true=自定义日期区间
  DateTimeRange? _range;
  late Future<List<SessionSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<SessionSummary>> _load() {
    if (_rangeMode && _range != null) {
      final start = DateTime(
          _range!.start.year, _range!.start.month, _range!.start.day);
      final endExclusive = DateTime(
              _range!.end.year, _range!.end.month, _range!.end.day)
          .add(const Duration(days: 1));
      return _dao.getSessionSummaries(
          start: start, end: endExclusive, limit: 2000);
    }
    return _dao.getSessionSummaries();
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _range ??
          DateTimeRange(
              start: now.subtract(const Duration(days: 29)), end: now),
      helpText: '选择日期区间',
    );
    if (picked != null) {
      setState(() {
        _rangeMode = true;
        _range = picked;
        _future = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _filterBar(),
        Expanded(
          child: FutureBuilder<List<SessionSummary>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snap.data!;
              if (all.isEmpty) {
                return const Center(child: Text('该范围内没有练习记录'));
              }
              return _groupedList(all);
            },
          ),
        ),
      ],
    );
  }

  Widget _filterBar() {
    final rangeLabel = _range == null
        ? '选择区间'
        : '${_fmtDate(_range!.start)} – ${_fmtDate(_range!.end)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('按月'),
            selected: !_rangeMode,
            onSelected: (_) => setState(() {
              _rangeMode = false;
              _future = _load();
            }),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('自定义区间'),
            selected: _rangeMode,
            onSelected: (_) {
              if (_range == null) {
                _pickRange();
              } else {
                setState(() {
                  _rangeMode = true;
                  _future = _load();
                });
              }
            },
          ),
          const Spacer(),
          if (_rangeMode)
            TextButton.icon(
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(rangeLabel),
              onPressed: _pickRange,
            ),
        ],
      ),
    );
  }

  Widget _groupedList(List<SessionSummary> all) {
    // 按自然月分组（all 已按时间倒序）
    final groups = <String, List<SessionSummary>>{};
    for (final s in all) {
      final key =
          '${s.startedAt.year}-${s.startedAt.month.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => []).add(s);
    }
    final now = DateTime.now();
    final curKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final prev = DateTime(now.year, now.month - 1, 1);
    final prevKey = '${prev.year}-${prev.month.toString().padLeft(2, '0')}';
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 16),
      children: keys.map((k) {
        final list = groups[k]!;
        final q = list.fold<int>(0, (a, s) => a + s.count);
        final p = list.fold<double>(0, (a, s) => a + s.partialSum);
        final acc = q > 0 ? (p / q * 100).round() : 0;
        final parts = k.split('-');
        final title = '${parts[0]}年${int.parse(parts[1])}月';
        // 按月模式：默认展开本月+上月；区间模式：全展开
        final expanded = _rangeMode || k == curKey || k == prevKey;
        return Card(
          child: ExpansionTile(
            key: PageStorageKey(k),
            initiallyExpanded: expanded,
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('练习 ${list.length} 次 · 做题 $q 道 · 正确率 $acc%',
                style: const TextStyle(fontSize: 12)),
            childrenPadding: const EdgeInsets.only(bottom: 6),
            children: list.map((s) => _sessionCard(context, s)).toList(),
          ),
        );
      }).toList(),
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
    final pending = ((r['grading_pending'] as int?) ?? 0) == 1; // V3.35 证明题批改中
    final correct = ((r['is_correct'] as int?) ?? 0) == 1;
    final partial = (r['partial_score'] as num?)?.toDouble();
    final ans = (r['user_answer'] as String?) ?? '';
    final fb = (r['ai_feedback'] as String?) ?? '';
    final ts = (r['time_spent'] as int?) ?? 0;
    final qid = r['question_id'] as int?;
    final partialNote = (!correct && partial != null && partial > 0)
        ? '（部分 ${(partial * 100).round()}%）'
        : '';
    final cardColor = pending
        ? Colors.blue.shade50
        : (correct ? Colors.green.shade50 : Colors.red.shade50);
    return Card(
      color: cardColor,
      child: ListTile(
        dense: true,
        leading: Icon(
            pending
                ? Icons.hourglass_top
                : (correct ? Icons.check_circle : Icons.cancel),
            color: pending
                ? Colors.blue
                : (correct ? Colors.green : Colors.red)),
        title: MathText(_clip((r['content'] as String?) ?? '', 70),
            style: const TextStyle(fontSize: 13)),
        subtitle: Text(pending
            ? '✍️ 手写已交，AI 批改中…'
            : '你答：${ans.isEmpty ? '（空）' : _clip(ans, 40)}'
                '$partialNote · ${ts}s${fb.isNotEmpty ? '\n🤖 $fb' : ''}'),
        isThreeLine: !pending && fb.isNotEmpty,
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
