import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../models/study_plan.dart';
import '../models/subject.dart';
import '../services/plan_service.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  DateTime _selectedDay = DateTime.now();
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
    final plans = context.watch<PlanService>().plansForDate;

    return Scaffold(
      appBar: AppBar(title: const Text('学习计划')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2026, 1, 1),
            lastDay: DateTime(2029, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
              context.read<PlanService>().loadDate(selected);
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: AppTheme.primary, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.3), shape: BoxShape.circle),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('M月d日').format(_selectedDay),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${plans.length} 个计划', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: plans.isEmpty
                ? const Center(child: Text('这天还没有计划', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: plans.length,
                    itemBuilder: (ctx, i) => _PlanTile(plan: plans[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddPlanDialog(context),
      ),
    );
  }

  void _showAddPlanDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AddPlanSheet(selectedDate: _selectedDay),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final StudyPlan plan;
  const _PlanTile({required this.plan});

  @override
  Widget build(BuildContext context) {
    final done = plan.status == PlanStatus.completed;
    return Card(
      child: ListTile(
        leading: Text(plan.subject.emoji, style: const TextStyle(fontSize: 28)),
        title: Text(plan.title,
            style: TextStyle(decoration: done ? TextDecoration.lineThrough : null)),
        subtitle: Text('预计 ${plan.estimatedMinutes} 分钟'),
        trailing: Checkbox(
          value: done,
          activeColor: AppTheme.success,
          onChanged: done ? null : (_) => context.read<PlanService>().markComplete(plan),
        ),
      ),
    );
  }
}

class _AddPlanSheet extends StatefulWidget {
  final DateTime selectedDate;
  const _AddPlanSheet({required this.selectedDate});

  @override
  State<_AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<_AddPlanSheet> {
  Subject _subject = Subject.math;
  final _titleCtrl = TextEditingController();
  int _minutes = 30;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('添加计划', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<Subject>(
            value: _subject,
            decoration: const InputDecoration(labelText: '科目', border: OutlineInputBorder()),
            items: Subject.values
                .where((s) => s.isAvailableForGrade(6))
                .map((s) => DropdownMenuItem(value: s, child: Text('${s.emoji} ${s.displayName}')))
                .toList(),
            onChanged: (v) => setState(() => _subject = v!),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: '计划内容', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('预计时间：'),
              Expanded(
                child: Slider(
                  value: _minutes.toDouble(),
                  min: 10, max: 120, divisions: 11,
                  label: '$_minutes 分钟',
                  activeColor: AppTheme.primary,
                  onChanged: (v) => setState(() => _minutes = v.round()),
                ),
              ),
              Text('$_minutes 分钟'),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleCtrl.text.isEmpty) return;
              context.read<PlanService>().addPlan(StudyPlan(
                subject: _subject,
                title: _titleCtrl.text,
                dueDate: widget.selectedDate,
                type: PlanType.daily,
                estimatedMinutes: _minutes,
                createdAt: DateTime.now(),
              ));
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
