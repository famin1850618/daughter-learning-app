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
                Text('${plans.length} 个计划',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: plans.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('这天还没有计划', style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('在首页选择科目和章节来添加计划',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: plans.length,
                    itemBuilder: (ctx, i) => _PlanTile(plan: plans[i]),
                  ),
          ),
        ],
      ),
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
        title: Text(
          plan.displayTitle,
          style: TextStyle(decoration: done ? TextDecoration.lineThrough : null),
        ),
        subtitle: Text('${plan.gradeLabel} · 预计 ${plan.estimatedMinutes} 分钟'),
        trailing: Checkbox(
          value: done,
          activeColor: AppTheme.success,
          onChanged: done ? null : (_) => context.read<PlanService>().markComplete(plan),
        ),
        onLongPress: () => _confirmDelete(context),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除计划'),
        content: Text('确认删除「${plan.displayTitle}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              context.read<PlanService>().deletePlan(plan);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
