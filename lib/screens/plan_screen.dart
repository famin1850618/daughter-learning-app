import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../utils/plan_date_utils.dart';
import '../models/plan_group.dart';
import '../models/subject.dart';
import '../services/plan_service.dart';
import '../services/plan_settings_service.dart';
import '../services/navigation_service.dart';
import '../services/practice_service.dart';
import '../models/plan_settings.dart';
import 'chapter_picker_screen.dart';
import 'plan_adjustment_screen.dart';
import 'plan_settings_screen.dart';

// Helper: navigate to practice tab for a given plan item
void _startPractice(BuildContext context, PlanItem item) {
  Subject? subject;
  try {
    subject = Subject.values.firstWhere((s) => s.name == item.subjectName);
  } catch (_) {}
  if (subject == null) return;
  context.read<PracticeService>().startSession(
    subject: subject,
    grade: item.grade,
    chapter: item.chapterName,
    count: 10,
  );
  context.read<NavigationService>().goTo(2);
  Navigator.of(context).popUntil((r) => r.isFirst);
}

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('学习计划'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: '分配设置',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PlanSettingsScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2026, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) {
              final key = PlanDateUtils.dateOnly(day).toIso8601String().substring(0, 10);
              return svc.markedDates.contains(key) ? [true] : [];
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(children: [
              Text(
                DateFormat('M月d日 (EEEE)', 'zh_CN').format(_selectedDay),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              _CompactStats(svc: svc),
            ]),
          ),
          Expanded(child: _PlanBody(svc: svc)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        tooltip: svc.selectedDateHasPlans ? '调整计划' : '新建计划',
        onPressed: () => _openManage(context, svc),
        child: Icon(svc.selectedDateHasPlans ? Icons.tune : Icons.add, color: Colors.white),
      ),
    );
  }

  void _openManage(BuildContext context, PlanService svc) {
    final route = svc.selectedDateHasPlans
        ? MaterialPageRoute(builder: (_) => PlanAdjustmentScreen(initialDate: _selectedDay))
        : MaterialPageRoute(
            builder: (_) => _CreatePlanFlow(initialDate: _selectedDay),
            fullscreenDialog: true);
    Navigator.push(context, route)
        .then((_) => context.read<PlanService>().loadDate(_selectedDay));
  }
}

// ── Stats ──────────────────────────────────────
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
          color: done == items.length ? AppTheme.success : Colors.grey, fontSize: 13),
    );
  }
}

// ── Plan body: day → week → month ─────────────
class _PlanBody extends StatelessWidget {
  final PlanService svc;
  const _PlanBody({required this.svc});

  @override
  Widget build(BuildContext context) {
    final dayPlans = svc.dayPlans;
    final weekPlans = svc.weekPlans;
    final monthPlans = svc.monthPlans;

    if (dayPlans.isEmpty && weekPlans.isEmpty && monthPlans.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.event_note, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          const Text('这天没有计划', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 4),
          Text('点击右下角 + 创建计划',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ]),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
      children: [
        for (final dg in dayPlans) ...[
          _DayGroupCard(group: dg),
          const SizedBox(height: 8),
        ],
        for (final wg in weekPlans) ...[
          const SizedBox(height: 8),
          _WeekPlanCard(group: wg),
        ],
        for (final mg in monthPlans) ...[
          const SizedBox(height: 8),
          _MonthPlanCard(group: mg),
        ],
      ],
    );
  }
}

// ── Day group card ─────────────────────────────
class _DayGroupCard extends StatelessWidget {
  final PlanGroup group;
  const _DayGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final done =
        group.items.where((i) => i.status == PlanItemStatus.completed).length;
    return Card(
      elevation: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(children: [
              const Icon(Icons.today, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                group.parentId == null ? '独立日计划' : '来自${group.typeLabel}计划',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary),
              ),
              const Spacer(),
              Text('$done/${group.items.length}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          ...group.items.map((item) => _ItemTile(item: item)),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final PlanItem item;
  const _ItemTile({required this.item});

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
            color: done ? Colors.grey : null),
      ),
      subtitle: Text('${item.gradeLabel} · ${item.subjectName}',
          style: const TextStyle(fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline, size: 20),
            color: AppTheme.primary.withOpacity(0.7),
            visualDensity: VisualDensity.compact,
            onPressed: () => _startPractice(context, item),
          ),
          Checkbox(
            value: done,
            activeColor: AppTheme.success,
            onChanged: (_) {
              final svc = context.read<PlanService>();
              done ? svc.markItemPending(item.id!) : svc.markItemComplete(item.id!);
            },
          ),
        ],
      ),
    );
  }
}

// ── Week plan card (days with content only) ───
class _WeekPlanCard extends StatelessWidget {
  final PlanGroup group;
  const _WeekPlanCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final allItems = group.allItems;
    final done = allItems.where((i) => i.status == PlanItemStatus.completed).length;
    final dayMap = {
      for (final c in group.children)
        c.startDate.toIso8601String().substring(0, 10): c
    };
    final days = PlanDateUtils.daysInRange(group.startDate, group.endDate);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(children: [
              const Icon(Icons.view_week, size: 16, color: AppTheme.secondary),
              const SizedBox(width: 6),
              Text(
                '周计划  ${PlanDateUtils.weekLabel(group.startDate, group.endDate)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary),
              ),
              const Spacer(),
              Text('$done/${allItems.length}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: LinearProgressIndicator(
              value: allItems.isEmpty ? 0 : done / allItems.length,
              backgroundColor: Colors.grey.shade200,
              color: AppTheme.secondary,
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          // Only show days that have items
          ...days.map((day) {
            final key = day.toIso8601String().substring(0, 10);
            final dayPlan = dayMap[key];
            if (dayPlan == null || dayPlan.items.isEmpty) return const SizedBox.shrink();
            final label = PlanDateUtils.weekdayLabels[day.weekday];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
                  child: Text(
                    '$label  ${day.month}/${day.day}',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                ),
                ...dayPlan.items.map((item) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _ItemTile(item: item),
                    )),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Month plan card (per-week, tap week → popup)
class _MonthPlanCard extends StatelessWidget {
  final PlanGroup group;
  const _MonthPlanCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final allItems = group.allItems;
    final done = allItems.where((i) => i.status == PlanItemStatus.completed).length;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(children: [
              const Icon(Icons.calendar_view_month, size: 16, color: Colors.deepPurple),
              const SizedBox(width: 6),
              Text(
                '月计划  ${DateFormat('M/d').format(group.startDate)} – ${DateFormat('M/d').format(group.endDate)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              const Spacer(),
              Text('$done/${allItems.length}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: LinearProgressIndicator(
              value: allItems.isEmpty ? 0 : done / allItems.length,
              backgroundColor: Colors.grey.shade200,
              color: Colors.deepPurple,
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          ...group.children.map((wg) => _MonthWeekRow(weekGroup: wg)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _MonthWeekRow extends StatelessWidget {
  final PlanGroup weekGroup;
  const _MonthWeekRow({required this.weekGroup});

  @override
  Widget build(BuildContext context) {
    final wItems = weekGroup.allItems;
    final wDone = wItems.where((i) => i.status == PlanItemStatus.completed).length;
    return InkWell(
      onTap: () => _showWeekPopup(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Row(children: [
          const Icon(Icons.calendar_view_week, size: 14, color: Colors.deepPurple),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              PlanDateUtils.weekLabel(weekGroup.startDate, weekGroup.endDate),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text('$wDone/${wItems.length}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 6),
          SizedBox(
            width: 60,
            child: LinearProgressIndicator(
              value: wItems.isEmpty ? 0 : wDone / wItems.length,
              backgroundColor: Colors.grey.shade200,
              color: Colors.deepPurple.withOpacity(0.5),
              minHeight: 4,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
        ]),
      ),
    );
  }

  void _showWeekPopup(BuildContext context) {
    final allItems = weekGroup.allItems;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.deepPurple,
              width: double.infinity,
              child: Text(
                PlanDateUtils.weekLabel(weekGroup.startDate, weekGroup.endDate),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Expanded(
              child: allItems.isEmpty
                  ? const Center(child: Text('本周暂无内容'))
                  : ListView(
                      controller: ctrl,
                      children: allItems.map((item) => ListTile(
                            leading: Text(item.subjectEmoji,
                                style: const TextStyle(fontSize: 22)),
                            title: Text(item.displayTitle),
                            subtitle: Text('${item.gradeLabel} · ${item.subjectName}',
                                style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.play_circle_outline,
                                color: Colors.deepPurple),
                            onTap: () {
                              Navigator.pop(context);
                              _startPractice(context, item);
                            },
                          )).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Creation flow (when no plans on selected day)
// ═══════════════════════════════════════════════

class _CreatePlanFlow extends StatefulWidget {
  final DateTime initialDate;
  const _CreatePlanFlow({required this.initialDate});

  @override
  State<_CreatePlanFlow> createState() => _CreatePlanFlowState();
}

class _CreatePlanFlowState extends State<_CreatePlanFlow> {
  PlanGroupType _type = PlanGroupType.day;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  String get _rangeLabel {
    switch (_type) {
      case PlanGroupType.day:
        return DateFormat('M月d日 (EEEE)', 'zh_CN').format(_date);
      case PlanGroupType.week:
        final we = PlanDateUtils.weekEnd(_date);
        return '${DateFormat('M月d日').format(_date)} – ${DateFormat('M月d日').format(we)}（到本周日）';
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
            onPressed: _pickContent,
            child: const Text('选择内容', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('计划类型',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: PlanGroupType.values.map((t) {
              final selected = _type == t;
              const labels = ['日计划', '周计划', '月计划'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(labels[t.index]),
                    selected: selected,
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                        color: selected ? Colors.white : null,
                        fontWeight: FontWeight.w600),
                    onSelected: (_) => setState(() => _type = t),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('起始日期',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: AppTheme.primary),
              title: Text(_rangeLabel),
              subtitle: _type != PlanGroupType.day
                  ? Text('计划覆盖上方所示日期范围',
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

  Future<void> _pickContent() async {
    final drafts = await Navigator.push<List<PlanItemDraft>>(
        context, MaterialPageRoute(builder: (_) => const ChapterPickerScreen()));
    if (drafts == null || drafts.isEmpty || !mounted) return;
    await _showPreviewAndConfirm(drafts);
  }

  Future<void> _showPreviewAndConfirm(List<PlanItemDraft> drafts) async {
    final settings = context.read<PlanSettingsService>().settings;
    final preview = _buildPreview(drafts, settings);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _PreviewSheet(
          type: _type, startDate: _date, drafts: drafts, preview: preview),
    );
    if (confirmed != true || !mounted) return;

    final svc = context.read<PlanService>();
    String? err;
    switch (_type) {
      case PlanGroupType.day:
        await svc.createDayPlan(_date, drafts);
      case PlanGroupType.week:
        if (await svc.checkWeekOverlap(_date)) {
          err = '周计划重叠：该日期范围已有周计划';
        } else {
          await svc.createWeekPlan(_date, drafts, settings: settings);
        }
      case PlanGroupType.month:
        if (await svc.checkMonthOverlap(_date)) {
          err = '月份重叠：该日期范围已有月计划';
        } else {
          await svc.createMonthPlan(_date, drafts, settings: settings);
        }
    }

    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red));
    } else {
      Navigator.of(context).pop();
    }
  }

  Map<String, List<PlanItemDraft>> _buildPreview(
      List<PlanItemDraft> drafts, PlanSettings settings) {
    final result = <String, List<PlanItemDraft>>{};
    final ordered = settings.sortDrafts(drafts);
    switch (_type) {
      case PlanGroupType.day:
        result[DateFormat('M月d日 (EEEE)', 'zh_CN').format(_date)] = drafts.toList();
      case PlanGroupType.week:
        final allDays = PlanDateUtils.daysInRange(
            PlanDateUtils.dateOnly(_date), PlanDateUtils.weekEnd(_date));
        final activeDays = settings.filterDays(allDays);
        final byDay = PlanDateUtils.autoDistribute(ordered, activeDays.length);
        for (var i = 0; i < activeDays.length; i++) {
          if (byDay[i].isNotEmpty) {
            result[DateFormat('M月d日 (EEEE)', 'zh_CN').format(activeDays[i])] =
                byDay[i].cast<PlanItemDraft>();
          }
        }
      case PlanGroupType.month:
        final ms = PlanDateUtils.dateOnly(_date);
        final me = PlanDateUtils.monthPlanEnd(_date);
        final weeks = PlanDateUtils.splitIntoWeeks(ms, me);
        final byWeek = PlanDateUtils.autoDistribute(ordered, weeks.length);
        for (var wi = 0; wi < weeks.length; wi++) {
          if (byWeek[wi].isEmpty) continue;
          final (ws, we) = weeks[wi];
          final allDays = PlanDateUtils.daysInRange(ws, we);
          final activeDays = settings.filterDays(allDays);
          final byDay = PlanDateUtils.autoDistribute(byWeek[wi], activeDays.length);
          for (var di = 0; di < activeDays.length; di++) {
            if (byDay[di].isNotEmpty) {
              result[DateFormat('M月d日 (EEEE)', 'zh_CN').format(activeDays[di])] =
                  byDay[di].cast<PlanItemDraft>();
            }
          }
        }
    }
    return result;
  }
}

// ── Preview sheet ──────────────────────────────
class _PreviewSheet extends StatelessWidget {
  final PlanGroupType type;
  final DateTime startDate;
  final List<PlanItemDraft> drafts;
  final Map<String, List<PlanItemDraft>> preview;

  const _PreviewSheet({
    required this.type,
    required this.startDate,
    required this.drafts,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['日计划', '周计划', '月计划'];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primary,
            width: double.infinity,
            child: Row(children: [
              const Icon(Icons.event_note, color: Colors.white),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(labels[type.index],
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('共 ${drafts.length} 项，分配到 ${preview.length} 天',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: AppTheme.primary),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确认创建'),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.all(12),
              children: [
                for (final entry in preview.entries) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(entry.key,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ),
                  ...entry.value.map((d) => ListTile(
                        dense: true,
                        leading: Text(d.subjectEmoji, style: const TextStyle(fontSize: 20)),
                        title: Text(d.displayTitle, style: const TextStyle(fontSize: 14)),
                        subtitle: Text(d.subjectName, style: const TextStyle(fontSize: 11)),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
