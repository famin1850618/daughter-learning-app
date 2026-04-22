import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../utils/plan_date_utils.dart';
import '../models/plan_group.dart';
import '../services/plan_service.dart';
import 'chapter_picker_screen.dart';

class PlanAdjustmentScreen extends StatefulWidget {
  final DateTime initialDate;
  const PlanAdjustmentScreen({super.key, required this.initialDate});

  @override
  State<PlanAdjustmentScreen> createState() => _PlanAdjustmentScreenState();
}

class _PlanAdjustmentScreenState extends State<PlanAdjustmentScreen> {
  late DateTime _date;
  DayPlanSnapshot? _snapshot;
  bool _loading = false;

  final Set<int> _selectedIds = {};
  bool _selecting = false;
  PlanGroupType? _selectingLevel;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSnapshot());
  }

  Future<void> _loadSnapshot() async {
    setState(() => _loading = true);
    final svc = context.read<PlanService>();
    final snap = await svc.getSnapshot(_date);
    if (!mounted) return;
    setState(() {
      _snapshot = snap;
      _loading = false;
      _selectedIds.clear();
      _selecting = false;
      _selectingLevel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('计划管理')),
      body: Column(
        children: [
          _DatePickerBar(
            date: _date,
            onChanged: (d) {
              setState(() {
                _date = d;
                _snapshot = null;
                _selectedIds.clear();
                _selecting = false;
                _selectingLevel = null;
              });
              _loadSnapshot();
            },
          ),
          Expanded(
            child: _loading || _snapshot == null
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(),
          ),
        ],
      ),
      bottomNavigationBar:
          _selecting ? _ActionBar(
            count: _selectedIds.length,
            onDelete: _deleteSelected,
            onMove: _moveSelected,
            onCancel: () => setState(() {
              _selecting = false;
              _selectedIds.clear();
              _selectingLevel = null;
            }),
          ) : null,
    );
  }

  Widget _buildBody() {
    final s = _snapshot!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        _LevelSection(
          title: '日计划',
          icon: Icons.today,
          color: AppTheme.primary,
          subtitle: null,
          hasplan: s.hasDayPlan,
          items: s.dayItems,
          selecting: _selecting && _selectingLevel == PlanGroupType.day,
          selectedIds: _selectedIds,
          onLongPress: (item) => _startSelect(PlanGroupType.day, item.id!),
          onTap: (item) => _toggleSelect(item.id!),
          onAddTap: () => _addToLevel(PlanGroupType.day),
          onCreateTap: s.hasDayPlan ? null : () => _addToLevel(PlanGroupType.day),
        ),
        const SizedBox(height: 16),
        _LevelSection(
          title: '周计划',
          icon: Icons.view_week,
          color: AppTheme.secondary,
          subtitle: s.weekPlan != null
              ? PlanDateUtils.weekLabel(
                  s.weekPlan!.startDate, s.weekPlan!.endDate)
              : null,
          hasplan: s.hasWeekPlan,
          items: s.weekItems,
          selecting: _selecting && _selectingLevel == PlanGroupType.week,
          selectedIds: _selectedIds,
          onLongPress: (item) => _startSelect(PlanGroupType.week, item.id!),
          onTap: (item) => _toggleSelect(item.id!),
          onAddTap: () => _addToLevel(PlanGroupType.week),
          onCreateTap: s.hasWeekPlan ? null : () => _addToLevel(PlanGroupType.week),
        ),
        const SizedBox(height: 16),
        _LevelSection(
          title: '月计划',
          icon: Icons.calendar_view_month,
          color: Colors.deepPurple,
          subtitle: s.monthPlan != null
              ? '${DateFormat('M/d').format(s.monthPlan!.startDate)} – ${DateFormat('M/d').format(s.monthPlan!.endDate)}'
              : null,
          hasplan: s.hasMonthPlan,
          items: s.monthItems,
          selecting: _selecting && _selectingLevel == PlanGroupType.month,
          selectedIds: _selectedIds,
          onLongPress: (item) => _startSelect(PlanGroupType.month, item.id!),
          onTap: (item) => _toggleSelect(item.id!),
          onAddTap: () => _addToLevel(PlanGroupType.month),
          onCreateTap: s.hasMonthPlan ? null : () => _addToLevel(PlanGroupType.month),
        ),
      ],
    );
  }

  void _startSelect(PlanGroupType level, int id) {
    setState(() {
      _selecting = true;
      _selectingLevel = level;
      _selectedIds.clear();
      _selectedIds.add(id);
    });
  }

  void _toggleSelect(int id) {
    if (!_selecting) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _selecting = false;
          _selectingLevel = null;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _addToLevel(PlanGroupType level) async {
    final drafts = await Navigator.push<List<PlanItemDraft>>(
      context,
      MaterialPageRoute(builder: (_) => const ChapterPickerScreen()),
    );
    if (drafts == null || drafts.isEmpty || !mounted) return;
    final svc = context.read<PlanService>();
    final err = await svc.addToLevel(_date, level, drafts);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
    }
    await _loadSnapshot();
  }

  Future<void> _deleteSelected() async {
    final svc = context.read<PlanService>();
    for (final id in _selectedIds.toList()) {
      await svc.deleteItem(id);
    }
    await _loadSnapshot();
  }

  Future<void> _moveSelected() async {
    final s = _snapshot!;
    DateTime firstDate = DateTime(2026, 1, 1);
    DateTime lastDate = DateTime(2030, 12, 31);
    switch (_selectingLevel!) {
      case PlanGroupType.week:
        if (s.weekPlan != null) {
          firstDate = s.weekPlan!.startDate;
          lastDate = s.weekPlan!.endDate;
        }
      case PlanGroupType.month:
        if (s.monthPlan != null) {
          firstDate = s.monthPlan!.startDate;
          lastDate = s.monthPlan!.endDate;
        }
      case PlanGroupType.day:
        break;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(firstDate) || _date.isAfter(lastDate)
          ? firstDate
          : _date,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '移动到哪天？',
    );
    if (picked == null || !mounted) return;

    final allItems = [
      ...s.dayItems,
      ...s.weekItems,
      ...s.monthItems,
    ].where((i) => _selectedIds.contains(i.id)).toList();

    final svc = context.read<PlanService>();
    await svc.moveItems(allItems, picked);
    await _loadSnapshot();
  }
}

// ── Date picker header bar ─────────────────────
class _DatePickerBar extends StatelessWidget {
  final DateTime date;
  final void Function(DateTime) onChanged;
  const _DatePickerBar({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary.withOpacity(0.08),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2026, 1, 1),
            lastDate: DateTime(2030, 12, 31),
            helpText: '选择日期',
          );
          if (picked != null) onChanged(PlanDateUtils.dateOnly(picked));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                DateFormat('yyyy年M月d日 (EEEE)', 'zh_CN').format(date),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const Spacer(),
              const Icon(Icons.edit, size: 14, color: AppTheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Plan level section ────────────────────────
class _LevelSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final bool hasplan;
  final List<PlanItem> items;
  final bool selecting;
  final Set<int> selectedIds;
  final void Function(PlanItem) onLongPress;
  final void Function(PlanItem) onTap;
  final VoidCallback onAddTap;
  final VoidCallback? onCreateTap; // null = not needed (hasplan)

  const _LevelSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.hasplan,
    required this.items,
    required this.selecting,
    required this.selectedIds,
    required this.onLongPress,
    required this.onTap,
    required this.onAddTap,
    required this.onCreateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 15)),
                if (subtitle != null) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Spacer(),
                if (hasplan)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 30)),
                    icon: Icon(Icons.add, size: 14, color: color),
                    label: Text('添加', style: TextStyle(color: color, fontSize: 12)),
                    onPressed: onAddTap,
                  )
                else
                  TextButton.icon(
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 30)),
                    icon: Icon(Icons.add_circle_outline, size: 14, color: color),
                    label: Text('新建', style: TextStyle(color: color, fontSize: 12)),
                    onPressed: onCreateTap,
                  ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          // Items
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Text(
                hasplan ? '本日无该计划内容' : '尚未建立${title}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            )
          else
            ...items.map((item) {
              final isSelected = selectedIds.contains(item.id);
              return InkWell(
                onLongPress: () => onLongPress(item),
                onTap: selecting ? () => onTap(item) : null,
                child: Container(
                  color: isSelected
                      ? color.withOpacity(0.1)
                      : Colors.transparent,
                  child: ListTile(
                    dense: true,
                    leading: selecting
                        ? Checkbox(
                            value: isSelected,
                            activeColor: color,
                            onChanged: (_) => onTap(item),
                          )
                        : Text(item.subjectEmoji,
                            style: const TextStyle(fontSize: 20)),
                    title: Text(item.displayTitle,
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                        '${item.gradeLabel} · ${item.subjectName}',
                        style: const TextStyle(fontSize: 11)),
                    trailing: selecting
                        ? null
                        : Icon(Icons.drag_handle,
                            color: Colors.grey.shade300, size: 18),
                  ),
                ),
              );
            }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Multi-select action bar ────────────────────
class _ActionBar extends StatelessWidget {
  final int count;
  final VoidCallback onDelete;
  final VoidCallback onMove;
  final VoidCallback onCancel;

  const _ActionBar({
    required this.count,
    required this.onDelete,
    required this.onMove,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Row(
          children: [
            Text('已选 $count 项',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              label: const Text('删除', style: TextStyle(color: Colors.red)),
              onPressed: onDelete,
            ),
            TextButton.icon(
              icon: const Icon(Icons.drive_file_move_outline,
                  color: AppTheme.primary, size: 18),
              label: const Text('移动', style: TextStyle(color: AppTheme.primary)),
              onPressed: onMove,
            ),
            TextButton(
              onPressed: onCancel,
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
