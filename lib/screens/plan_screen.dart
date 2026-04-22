import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../utils/plan_date_utils.dart';
import '../models/plan_group.dart';
import '../models/subject.dart';
import '../models/curriculum.dart';
import '../services/plan_service.dart';
import '../database/curriculum_dao.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  DateTime _selectedDay = PlanDateUtils.dateOnly(DateTime.now());
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanService>().loadDate(_selectedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<PlanService>();
    final markedDates = svc.markedDates;

    return Scaffold(
      appBar: AppBar(title: const Text('学习计划')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2026, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) {
              final key = PlanDateUtils.dateOnly(day).toIso8601String().substring(0, 10);
              return markedDates.contains(key) ? [true] : [];
            },
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = PlanDateUtils.dateOnly(selected);
                _focusedDay = focused;
              });
              context.read<PlanService>().loadDate(selected);
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                  color: AppTheme.primary, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.3), shape: BoxShape.circle),
              markerDecoration: const BoxDecoration(
                  color: AppTheme.secondary, shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(formatButtonVisible: false),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  DateFormat('M月d日 (EEEE)', 'zh_CN').format(_selectedDay),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                _CompactStats(svc: svc),
              ],
            ),
          ),
          Expanded(
            child: _DayPlanBody(svc: svc, selectedDay: _selectedDay),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _openCreateFlow(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _openCreateFlow(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreatePlanStep1(initialDate: _selectedDay),
        fullscreenDialog: true,
      ),
    );
  }
}

// ── 当日统计摘要 ──────────────────────────────
class _CompactStats extends StatelessWidget {
  final PlanService svc;
  const _CompactStats({required this.svc});

  @override
  Widget build(BuildContext context) {
    final items = svc.dayPlans.expand((g) => g.items).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final done = items.where((i) => i.status == PlanItemStatus.completed).length;
    return Text(
      '$done / ${items.length} 已完成',
      style: TextStyle(
        color: done == items.length ? AppTheme.success : Colors.grey,
        fontSize: 13,
      ),
    );
  }
}

// ── 当日计划主体 ──────────────────────────────
class _DayPlanBody extends StatelessWidget {
  final PlanService svc;
  final DateTime selectedDay;
  const _DayPlanBody({required this.svc, required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    final dayPlans = svc.dayPlans;
    final weekPlans = svc.weekPlans;
    final monthPlans = svc.monthPlans;

    if (dayPlans.isEmpty && weekPlans.isEmpty && monthPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_note, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('这天没有计划', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              '点击右下角 + 创建计划',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
      children: [
        // 月计划卡片（摘要）
        for (final mg in monthPlans) _MonthPlanCard(group: mg),

        // 周计划卡片（摘要）
        for (final wg in weekPlans) _WeekPlanCard(group: wg),

        // 日计划（展开到任务）
        for (final dg in dayPlans) _DayGroupCard(group: dg),
      ],
    );
  }
}

// ── 月计划摘要卡 ──────────────────────────────
class _MonthPlanCard extends StatelessWidget {
  final PlanGroup group;
  const _MonthPlanCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final rate = group.completionRate;
    final allItems = group.allItems;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.calendar_view_month, size: 18, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                '月计划  ${DateFormat('M/d').format(group.startDate)} – ${DateFormat('M/d').format(group.endDate)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${allItems.where((i) => i.status == PlanItemStatus.completed).length}/${allItems.length}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: rate,
              backgroundColor: Colors.grey.shade200,
              color: AppTheme.success,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 周计划摘要卡 ──────────────────────────────
class _WeekPlanCard extends StatelessWidget {
  final PlanGroup group;
  const _WeekPlanCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final rate = group.completionRate;
    final allItems = group.allItems;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.view_week, size: 18, color: AppTheme.secondary),
              const SizedBox(width: 6),
              Text(
                '周计划  ${PlanDateUtils.weekLabel(group.startDate, group.endDate)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${allItems.where((i) => i.status == PlanItemStatus.completed).length}/${allItems.length}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: rate,
              backgroundColor: Colors.grey.shade200,
              color: AppTheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 日计划任务列表 ────────────────────────────
class _DayGroupCard extends StatelessWidget {
  final PlanGroup group;
  const _DayGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                const Icon(Icons.today, size: 16, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  group.originLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '${group.items.where((i) => i.status == PlanItemStatus.completed).length}/${group.items.length}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          ...group.items.map((item) => _PlanItemTile(item: item)),
        ],
      ),
    );
  }
}

extension _PlanGroupLabel on PlanGroup {
  String get originLabel {
    if (parentId == null) return '独立日计划';
    return '来自${typeLabel}计划';
  }
}

class _PlanItemTile extends StatelessWidget {
  final PlanItem item;
  const _PlanItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final done = item.status == PlanItemStatus.completed;
    return ListTile(
      dense: true,
      leading: Text(item.subjectEmoji, style: const TextStyle(fontSize: 22)),
      title: Text(
        item.displayTitle,
        style: TextStyle(
          decoration: done ? TextDecoration.lineThrough : null,
          color: done ? Colors.grey : null,
        ),
      ),
      subtitle: Text(
        '${item.gradeLabel} · ${item.subjectName}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Checkbox(
        value: done,
        activeColor: AppTheme.success,
        onChanged: (_) {
          final svc = context.read<PlanService>();
          if (done) {
            svc.markItemPending(item.id!);
          } else {
            svc.markItemComplete(item.id!);
          }
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  计划创建流程
// ═══════════════════════════════════════════════

// Step 1: 选择计划类型 + 起始日期
class _CreatePlanStep1 extends StatefulWidget {
  final DateTime initialDate;
  const _CreatePlanStep1({required this.initialDate});

  @override
  State<_CreatePlanStep1> createState() => _CreatePlanStep1State();
}

class _CreatePlanStep1State extends State<_CreatePlanStep1> {
  PlanGroupType _type = PlanGroupType.day;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  String get _typeLabel => ['日', '周', '月'][_type.index];

  String get _dateRangeHint {
    switch (_type) {
      case PlanGroupType.day:
        return DateFormat('M月d日 (EEEE)', 'zh_CN').format(_date);
      case PlanGroupType.week:
        final ws = PlanDateUtils.weekStart(_date);
        final we = PlanDateUtils.weekEnd(_date);
        return PlanDateUtils.weekLabel(ws, we);
      case PlanGroupType.month:
        final me = PlanDateUtils.monthPlanEnd(_date);
        return '${DateFormat('M月d日').format(_date)} – ${DateFormat('M月d日').format(me)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新建计划'),
        actions: [
          TextButton(
            onPressed: _next,
            child: const Text('下一步', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('计划类型', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: PlanGroupType.values.map((t) {
              final selected = _type == t;
              final labels = ['日计划', '周计划', '月计划'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(labels[t.index]),
                    selected: selected,
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _type = t),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('起始日期', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: AppTheme.primary),
              title: Text(_dateRangeHint),
              subtitle: _type != PlanGroupType.day
                  ? Text('计划将覆盖上方所示日期范围',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12))
                  : null,
              trailing: const Icon(Icons.edit, size: 16),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2026, 1, 1),
                  lastDate: DateTime(2030, 12, 31),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _next() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreatePlanStep2(type: _type, startDate: _date),
      ),
    );
  }
}

// Step 2: 选择章节（多选）
class _CreatePlanStep2 extends StatefulWidget {
  final PlanGroupType type;
  final DateTime startDate;
  const _CreatePlanStep2({required this.type, required this.startDate});

  @override
  State<_CreatePlanStep2> createState() => _CreatePlanStep2State();
}

class _CreatePlanStep2State extends State<_CreatePlanStep2>
    with SingleTickerProviderStateMixin {
  final _dao = CurriculumDao();
  late TabController _tabCtrl;
  final _selected = <PlanItemDraft>[];
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: Subject.values.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() => _tabIndex = _tabCtrl.index);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择学习内容'),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: Subject.values
              .map((s) => Tab(text: '${s.emoji} ${s.displayName}'))
              .toList(),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '已选 ${_selected.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          TextButton(
            onPressed: _selected.isEmpty ? null : _next,
            child: Text(
              '完成',
              style: TextStyle(
                color: _selected.isEmpty ? Colors.white38 : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: Subject.values
            .map((s) => _SubjectChapterPicker(
                  subject: s,
                  dao: _dao,
                  selected: _selected,
                  onToggle: _toggleDraft,
                ))
            .toList(),
      ),
    );
  }

  void _toggleDraft(PlanItemDraft draft) {
    setState(() {
      final existing = _selected.indexWhere((d) =>
          d.chapterId == draft.chapterId &&
          d.knowledgePoint == draft.knowledgePoint);
      if (existing >= 0) {
        _selected.removeAt(existing);
      } else {
        _selected.add(draft);
      }
    });
  }

  void _next() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreatePlanStep3(
          type: widget.type,
          startDate: widget.startDate,
          drafts: List.unmodifiable(_selected),
        ),
      ),
    );
  }
}

class _SubjectChapterPicker extends StatefulWidget {
  final Subject subject;
  final CurriculumDao dao;
  final List<PlanItemDraft> selected;
  final void Function(PlanItemDraft) onToggle;

  const _SubjectChapterPicker({
    required this.subject,
    required this.dao,
    required this.selected,
    required this.onToggle,
  });

  @override
  State<_SubjectChapterPicker> createState() => _SubjectChapterPickerState();
}

class _SubjectChapterPickerState extends State<_SubjectChapterPicker>
    with AutomaticKeepAliveClientMixin {
  List<int> _grades = [];
  final Map<int, List<Chapter>> _chapters = {};
  int? _expandedGrade;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    final grades = await widget.dao.getGradesForSubject(widget.subject.name);
    if (!mounted) return;
    setState(() => _grades = grades);
    if (grades.isNotEmpty) {
      _expandGrade(grades.first);
    }
  }

  Future<void> _expandGrade(int grade) async {
    if (!_chapters.containsKey(grade)) {
      final chapters =
          await widget.dao.getChapters(widget.subject.name, grade);
      if (!mounted) return;
      setState(() => _chapters[grade] = chapters);
    }
    setState(() => _expandedGrade = grade);
  }

  static const _gradeLabels = {6: '六年级', 7: '初一', 8: '初二', 9: '初三'};

  bool _isSelected(Chapter c) => widget.selected.any((d) => d.chapterId == c.id);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_grades.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      children: _grades.map((grade) {
        final isOpen = _expandedGrade == grade;
        final chapters = _chapters[grade] ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => isOpen ? setState(() => _expandedGrade = null) : _expandGrade(grade),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primary,
                      child: Text(
                        (_gradeLabels[grade] ?? '$grade').substring(0, 1),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_gradeLabels[grade]} ${widget.subject.displayName}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Icon(isOpen ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey),
                  ],
                ),
              ),
            ),
            if (isOpen)
              ...chapters.map((c) => CheckboxListTile(
                    dense: true,
                    value: _isSelected(c),
                    activeColor: AppTheme.primary,
                    title: Text(c.chapterName, style: const TextStyle(fontSize: 14)),
                    subtitle: Text('${_gradeLabels[grade]} · 第${c.orderIndex}章',
                        style: const TextStyle(fontSize: 11)),
                    onChanged: (_) => widget.onToggle(PlanItemDraft(
                      chapterId: c.id!,
                      chapterName: c.chapterName,
                      subjectName: widget.subject.name,
                      subjectEmoji: widget.subject.emoji,
                      grade: c.grade,
                    )),
                  )),
            const Divider(height: 1),
          ],
        );
      }).toList(),
    );
  }
}

// Step 3: 预览分配 + 确认
class _CreatePlanStep3 extends StatelessWidget {
  final PlanGroupType type;
  final DateTime startDate;
  final List<PlanItemDraft> drafts;

  const _CreatePlanStep3({
    required this.type,
    required this.startDate,
    required this.drafts,
  });

  @override
  Widget build(BuildContext context) {
    final preview = _buildPreview();
    return Scaffold(
      appBar: AppBar(
        title: const Text('确认计划'),
        actions: [
          TextButton(
            onPressed: () => _confirm(context),
            child: const Text('确认创建', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          _SummaryHeader(type: type, startDate: startDate, totalItems: drafts.length),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final entry in preview.entries) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                  ...entry.value.map((d) => _PreviewItemTile(draft: d)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<PlanItemDraft>> _buildPreview() {
    final result = <String, List<PlanItemDraft>>{};
    switch (type) {
      case PlanGroupType.day:
        result[DateFormat('M月d日 (EEEE)', 'zh_CN').format(startDate)] = drafts.toList();
      case PlanGroupType.week:
        final ws = PlanDateUtils.weekStart(startDate);
        final we = PlanDateUtils.weekEnd(startDate);
        final days = PlanDateUtils.daysInRange(ws, we);
        final byDay = PlanDateUtils.autoDistribute(drafts, days.length);
        for (var i = 0; i < days.length; i++) {
          if (byDay[i].isNotEmpty) {
            result[DateFormat('M月d日 (EEEE)', 'zh_CN').format(days[i])] = byDay[i];
          }
        }
      case PlanGroupType.month:
        final ms = PlanDateUtils.dateOnly(startDate);
        final me = PlanDateUtils.monthPlanEnd(startDate);
        final weeks = PlanDateUtils.splitIntoWeeks(ms, me);
        final byWeek = PlanDateUtils.autoDistribute(drafts, weeks.length);
        for (var wi = 0; wi < weeks.length; wi++) {
          if (byWeek[wi].isEmpty) continue;
          final (ws, we) = weeks[wi];
          final days = PlanDateUtils.daysInRange(ws, we);
          final byDay = PlanDateUtils.autoDistribute(byWeek[wi], days.length);
          for (var di = 0; di < days.length; di++) {
            if (byDay[di].isNotEmpty) {
              result[DateFormat('M月d日 (EEEE)', 'zh_CN').format(days[di])] = byDay[di];
            }
          }
        }
    }
    return result;
  }

  Future<void> _confirm(BuildContext context) async {
    final svc = context.read<PlanService>();
    switch (type) {
      case PlanGroupType.day:
        await svc.createDayPlan(startDate, drafts.toList());
      case PlanGroupType.week:
        await svc.createWeekPlan(startDate, drafts.toList());
      case PlanGroupType.month:
        await svc.createMonthPlan(startDate, drafts.toList());
    }
    if (context.mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }
}

class _SummaryHeader extends StatelessWidget {
  final PlanGroupType type;
  final DateTime startDate;
  final int totalItems;
  const _SummaryHeader(
      {required this.type, required this.startDate, required this.totalItems});

  @override
  Widget build(BuildContext context) {
    final labels = ['日计划', '周计划', '月计划'];
    String range;
    switch (type) {
      case PlanGroupType.day:
        range = DateFormat('M月d日').format(startDate);
      case PlanGroupType.week:
        final ws = PlanDateUtils.weekStart(startDate);
        final we = PlanDateUtils.weekEnd(startDate);
        range = PlanDateUtils.weekLabel(ws, we);
      case PlanGroupType.month:
        final me = PlanDateUtils.monthPlanEnd(startDate);
        range = '${DateFormat('M月d日').format(startDate)} – ${DateFormat('M月d日').format(me)}';
    }

    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        const Icon(Icons.event_note, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(labels[type.index],
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text('$range · 共 $totalItems 项',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
      ]),
    );
  }
}

class _PreviewItemTile extends StatelessWidget {
  final PlanItemDraft draft;
  const _PreviewItemTile({required this.draft});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Text(draft.subjectEmoji, style: const TextStyle(fontSize: 20)),
      title: Text(draft.displayTitle, style: const TextStyle(fontSize: 14)),
      subtitle: Text(draft.subjectName, style: const TextStyle(fontSize: 11)),
    );
  }
}
