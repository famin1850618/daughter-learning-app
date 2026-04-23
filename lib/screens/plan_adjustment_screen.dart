import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../utils/plan_date_utils.dart';
import '../models/plan_group.dart';
import '../models/subject.dart';
import '../services/plan_service.dart';
import '../services/plan_settings_service.dart';
import '../services/navigation_service.dart';
import '../services/practice_service.dart';
import 'chapter_picker_screen.dart';

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

class PlanAdjustmentScreen extends StatefulWidget {
  final DateTime initialDate;
  const PlanAdjustmentScreen({super.key, required this.initialDate});

  @override
  State<PlanAdjustmentScreen> createState() => _PlanAdjustmentScreenState();
}

class _PlanAdjustmentScreenState extends State<PlanAdjustmentScreen> {
  late DateTime _date;
  AdjustmentSnapshot? _snap;
  bool _loading = false;

  // Multi-select state (for 今日任务 and 本周排布)
  final Set<int> _selectedIds = {};
  bool _selecting = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _loading = true; _selectedIds.clear(); _selecting = false; });
    final svc = context.read<PlanService>();
    final snap = await svc.getAdjustmentSnapshot(_date);
    if (!mounted) return;
    setState(() { _snap = snap; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('计划管理')),
      body: Column(
        children: [
          _DateBar(date: _date, onChanged: _changeDate),
          Expanded(
            child: _loading || _snap == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    children: [
                      _TodaySection(
                        snap: _snap!,
                        selecting: _selecting,
                        selectedIds: _selectedIds,
                        onLongPress: _startSelect,
                        onTap: _toggleSelect,
                        onAdd: _addToday,
                      ),
                      if (_snap!.weekPlan != null) ...[
                        const SizedBox(height: 16),
                        _WeekSection(
                          snap: _snap!,
                          selecting: _selecting,
                          selectedIds: _selectedIds,
                          onLongPress: _startSelect,
                          onTap: _toggleSelect,
                        ),
                      ],
                      if (_snap!.monthPlan != null) ...[
                        const SizedBox(height: 16),
                        _MonthSection(snap: _snap!, onMoved: _load, onDeleted: _load),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _selecting
          ? _ActionBar(
              count: _selectedIds.length,
              onDelete: _deleteSelected,
              onMove: _moveSelected,
              onCancel: () => setState(() {
                _selecting = false;
                _selectedIds.clear();
              }),
            )
          : null,
    );
  }

  void _changeDate(DateTime d) {
    setState(() { _date = d; _snap = null; });
    _load();
  }

  void _startSelect(int id) {
    setState(() {
      _selecting = true;
      _selectedIds.clear();
      _selectedIds.add(id);
    });
  }

  void _toggleSelect(int id) {
    if (!_selecting) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) { _selecting = false; }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _addToday() async {
    final drafts = await Navigator.push<List<PlanItemDraft>>(
        context, MaterialPageRoute(builder: (_) => const ChapterPickerScreen()));
    if (drafts == null || drafts.isEmpty || !mounted) return;
    final err = await context.read<PlanService>().addToDay(_date, drafts);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red));
    }
    await _load();
  }

  Future<void> _deleteSelected() async {
    final svc = context.read<PlanService>();
    for (final id in _selectedIds.toList()) await svc.deleteItem(id);
    await _load();
  }

  Future<void> _moveSelected() async {
    final s = _snap!;
    DateTime firstDate = DateTime(2026, 1, 1);
    DateTime lastDate = DateTime(2030, 12, 31);

    // Determine context from selected items
    final allItems = [...s.todayItems];
    if (s.weekPlan != null) {
      allItems.addAll(s.weekPlan!.children.expand((c) => c.items));
    }
    final sel = allItems.where((i) => _selectedIds.contains(i.id)).toList();
    if (sel.isNotEmpty) {
      final first = sel.first;
      if (first.originMonthPlanId != null && s.monthPlan != null) {
        firstDate = s.monthPlan!.startDate;
        lastDate = s.monthPlan!.endDate;
      } else if (first.originWeekPlanId != null && s.weekPlan != null) {
        firstDate = s.weekPlan!.startDate;
        lastDate = s.weekPlan!.endDate;
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(firstDate) ? firstDate : _date,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '移动到哪天？',
    );
    if (picked == null || !mounted) return;

    await context.read<PlanService>().moveItems(sel, picked);
    await _load();
  }
}

// ── Date bar ──────────────────────────────────
class _DateBar extends StatelessWidget {
  final DateTime date;
  final void Function(DateTime) onChanged;
  const _DateBar({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary.withOpacity(0.08),
      child: InkWell(
        onTap: () async {
          final p = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2026, 1, 1),
            lastDate: DateTime(2030, 12, 31),
          );
          if (p != null) onChanged(PlanDateUtils.dateOnly(p));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            const Icon(Icons.calendar_today, size: 16, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              DateFormat('yyyy年M月d日 (EEEE)', 'zh_CN').format(date),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
            const Spacer(),
            const Icon(Icons.edit, size: 14, color: AppTheme.primary),
          ]),
        ),
      ),
    );
  }
}

// ── 今日任务 section ───────────────────────────
class _TodaySection extends StatelessWidget {
  final AdjustmentSnapshot snap;
  final bool selecting;
  final Set<int> selectedIds;
  final void Function(int) onLongPress;
  final void Function(int) onTap;
  final VoidCallback onAdd;

  const _TodaySection({
    required this.snap,
    required this.selecting,
    required this.selectedIds,
    required this.onLongPress,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final items = snap.todayItems;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(children: [
              const Icon(Icons.today, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              const Text('今日任务',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 15)),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 28)),
                icon: const Icon(Icons.add, size: 14, color: AppTheme.primary),
                label: const Text('添加', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                onPressed: onAdd,
              ),
            ]),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Text('今日暂无任务', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            )
          else
            ...items.map((item) => _SelectableTile(
              item: item,
              selecting: selecting,
              isSelected: selectedIds.contains(item.id),
              color: AppTheme.primary,
              onLongPress: () => onLongPress(item.id!),
              onTap: () => selecting ? onTap(item.id!) : _startPractice(context, item),
            )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── 本周排布 section ───────────────────────────
class _WeekSection extends StatelessWidget {
  final AdjustmentSnapshot snap;
  final bool selecting;
  final Set<int> selectedIds;
  final void Function(int) onLongPress;
  final void Function(int) onTap;

  const _WeekSection({
    required this.snap,
    required this.selecting,
    required this.selectedIds,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final wg = snap.weekPlan!;
    final allItems = wg.children.expand((c) => c.items).toList();
    final pending = allItems.where((i) => i.status == PlanItemStatus.pending).toList();
    final dayMap = {
      for (final c in wg.children)
        c.startDate.toIso8601String().substring(0, 10): c
    };
    final days = PlanDateUtils.daysInRange(wg.startDate, wg.endDate);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(children: [
              const Icon(Icons.view_week, size: 16, color: AppTheme.secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '本周排布  ${PlanDateUtils.weekLabel(wg.startDate, wg.endDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary, fontSize: 15),
                ),
              ),
              Text('${pending.length} 未完成', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          ...days.map((day) {
            final key = day.toIso8601String().substring(0, 10);
            final dayPlan = dayMap[key];
            final label = PlanDateUtils.weekdayLabels[day.weekday];
            final dayItems = (dayPlan?.items ?? [])
                .where((i) => i.status == PlanItemStatus.pending)
                .toList();
            if (dayItems.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
                  child: Text('$label  ${day.month}/${day.day}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                ),
                ...dayItems.map((item) => _SelectableTile(
                  item: item,
                  selecting: selecting,
                  isSelected: selectedIds.contains(item.id),
                  color: AppTheme.secondary,
                  onLongPress: () => onLongPress(item.id!),
                  onTap: () => selecting ? onTap(item.id!) : _startPractice(context, item),
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

// ── 月计划总览 section ─────────────────────────
class _MonthSection extends StatelessWidget {
  final AdjustmentSnapshot snap;
  final VoidCallback onMoved;
  final VoidCallback onDeleted;

  const _MonthSection({required this.snap, required this.onMoved, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final mg = snap.monthPlan!;
    final allItems = mg.allItems;
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
              Expanded(
                child: Text(
                  '月计划总览  ${DateFormat('M/d').format(mg.startDate)} – ${DateFormat('M/d').format(mg.endDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 15),
                ),
              ),
              Text('$done/${allItems.length}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
          ...mg.children.map((wg) => _WeekRow(
            monthGroup: mg,
            weekGroup: wg,
            onMove: () => _pickMoveTarget(context, mg, wg),
            onDelete: () => _confirmDeleteWeek(context, wg),
          )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Future<void> _pickMoveTarget(BuildContext context, PlanGroup mg, PlanGroup sourceWg) async {
    final otherWeeks = mg.children.where((w) => w.id != sourceWg.id).toList();
    if (otherWeeks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('月计划中没有其他周可以移动到')));
      return;
    }

    final target = await showDialog<PlanGroup>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('移动到哪一周？'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: otherWeeks.map((wg) => ListTile(
            title: Text(PlanDateUtils.weekLabel(wg.startDate, wg.endDate)),
            subtitle: Text('${wg.allItems.length} 项内容'),
            onTap: () => Navigator.pop(context, wg),
          )).toList(),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消'))],
      ),
    );
    if (target == null || !context.mounted) return;

    final settings = context.read<PlanSettingsService>().settings;
    await context.read<PlanService>().moveWeekItems(sourceWg.id!, target.id!, settings: settings);
    onMoved();
  }

  Future<void> _confirmDeleteWeek(BuildContext context, PlanGroup wg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除整周内容'),
        content: Text('确认删除「${PlanDateUtils.weekLabel(wg.startDate, wg.endDate)}」的所有任务？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<PlanService>().deleteWeekGroup(wg.id!);
    onDeleted();
  }
}

class _WeekRow extends StatelessWidget {
  final PlanGroup monthGroup;
  final PlanGroup weekGroup;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  const _WeekRow({
    required this.monthGroup,
    required this.weekGroup,
    required this.onMove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final items = weekGroup.allItems;
    final done = items.where((i) => i.status == PlanItemStatus.completed).length;
    final rate = items.isEmpty ? 0.0 : done / items.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                PlanDateUtils.weekLabel(weekGroup.startDate, weekGroup.endDate),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Text('$done/${items.length}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.drive_file_move_outline, size: 18),
              color: Colors.deepPurple,
              tooltip: '移动本周内容',
              onPressed: onMove,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.red,
              tooltip: '删除本周',
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ]),
          LinearProgressIndicator(
            value: rate,
            backgroundColor: Colors.grey.shade200,
            color: Colors.deepPurple.withOpacity(0.5),
            minHeight: 4,
          ),
        ],
      ),
    );
  }
}

// ── Selectable item tile ──────────────────────
class _SelectableTile extends StatelessWidget {
  final PlanItem item;
  final bool selecting;
  final bool isSelected;
  final Color color;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const _SelectableTile({
    required this.item,
    required this.selecting,
    required this.isSelected,
    required this.color,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = item.status == PlanItemStatus.completed;
    return InkWell(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Container(
        color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        child: ListTile(
          dense: true,
          leading: selecting
              ? Checkbox(value: isSelected, activeColor: color, onChanged: (_) => onTap())
              : Text(item.subjectEmoji, style: const TextStyle(fontSize: 20)),
          title: Text(
            item.displayTitle,
            style: TextStyle(
              fontSize: 14,
              decoration: done ? TextDecoration.lineThrough : null,
              color: done ? Colors.grey : null,
            ),
          ),
          subtitle: Text('${item.gradeLabel} · ${item.subjectName}',
              style: const TextStyle(fontSize: 11)),
          trailing: selecting
              ? null
              : Icon(Icons.play_circle_outline, size: 18, color: color.withOpacity(0.6)),
        ),
      ),
    );
  }
}

// ── Action bar ────────────────────────────────
class _ActionBar extends StatelessWidget {
  final int count;
  final VoidCallback onDelete;
  final VoidCallback onMove;
  final VoidCallback onCancel;

  const _ActionBar({required this.count, required this.onDelete, required this.onMove, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Row(children: [
          Text('已选 $count 项', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
            label: const Text('删除', style: TextStyle(color: Colors.red)),
            onPressed: onDelete,
          ),
          TextButton.icon(
            icon: const Icon(Icons.drive_file_move_outline, color: AppTheme.primary, size: 18),
            label: const Text('移动', style: TextStyle(color: AppTheme.primary)),
            onPressed: onMove,
          ),
          TextButton(onPressed: onCancel, child: const Text('取消', style: TextStyle(color: Colors.grey))),
        ]),
      ),
    );
  }
}
