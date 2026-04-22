import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../models/subject.dart';
import '../models/curriculum.dart';
import '../models/study_plan.dart';
import '../database/curriculum_dao.dart';
import '../services/plan_service.dart';
import '../services/practice_service.dart';

class ChapterDetailScreen extends StatefulWidget {
  final Subject subject;
  final int grade;
  const ChapterDetailScreen({super.key, required this.subject, required this.grade});

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  final _dao = CurriculumDao();
  List<Chapter> _chapters = [];
  Set<int> _plannedChapterIds = {};

  static const _gradeLabels = {6: '六年级', 7: '初一', 8: '初二', 9: '初三'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final chapters = await _dao.getChapters(widget.subject.name, widget.grade);
    if (!mounted) return;
    final plans = context.read<PlanService>().allPlans;
    final planned = plans
        .where((p) => p.chapterId != null)
        .map((p) => p.chapterId!)
        .toSet();
    setState(() {
      _chapters = chapters;
      _plannedChapterIds = planned;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_gradeLabels[widget.grade]} ${widget.subject.displayName}'),
      ),
      body: _chapters.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _chapters.length,
              itemBuilder: (ctx, i) => _ChapterTile(
                chapter: _chapters[i],
                subject: widget.subject,
                isPlanned: _plannedChapterIds.contains(_chapters[i].id),
                onPlanAdded: _load,
              ),
            ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final Subject subject;
  final bool isPlanned;
  final VoidCallback onPlanAdded;

  const _ChapterTile({
    required this.chapter,
    required this.subject,
    required this.isPlanned,
    required this.onPlanAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // 序号
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text('${chapter.orderIndex}',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 10),
            // 章节名
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chapter.chapterName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  if (isPlanned)
                    const Text('📅 已在计划中',
                        style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ),
            // 操作按钮
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 练习按钮
                IconButton(
                  icon: const Icon(Icons.play_circle_outline, color: AppTheme.primary),
                  tooltip: '开始练习',
                  onPressed: () {
                    context.read<PracticeService>().startSession(
                      subject: subject,
                      grade: chapter.grade,
                      chapter: chapter.chapterName,
                      count: 10,
                    );
                    // 跳到练习tab (index 2)
                    DefaultTabController.of(
                      context.findAncestorWidgetOfExactType<DefaultTabController>() != null
                          ? context
                          : context,
                    );
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),
                // 添加计划按钮
                IconButton(
                  icon: Icon(
                    isPlanned ? Icons.event_available : Icons.add_task,
                    color: isPlanned ? Colors.green : AppTheme.secondary,
                  ),
                  tooltip: '加入计划',
                  onPressed: () => _showAddPlanSheet(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPlanSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AddPlanSheet(
        chapter: chapter,
        subject: subject,
        onSaved: onPlanAdded,
      ),
    );
  }
}

// ── 添加计划底部弹窗 ───────────────────────
class _AddPlanSheet extends StatefulWidget {
  final Chapter chapter;
  final Subject subject;
  final VoidCallback onSaved;
  const _AddPlanSheet({required this.chapter, required this.subject, required this.onSaved});

  @override
  State<_AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<_AddPlanSheet> {
  final _kpCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  int _minutes = 30;

  @override
  void dispose() {
    _kpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(children: [
            Text(widget.subject.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text(
              widget.chapter.chapterName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            )),
          ]),
          Text('${widget.chapter.gradeLabel} · ${widget.subject.displayName}',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),

          // 具体知识点（可选）
          TextField(
            controller: _kpCtrl,
            decoration: const InputDecoration(
              labelText: '具体知识点（可选）',
              hintText: '例：分数除法的计算方法',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // 日期选择
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, color: AppTheme.primary),
            title: Text(DateFormat('M月d日 (EEEE)', 'zh_CN').format(_date)),
            trailing: const Icon(Icons.edit, size: 16),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),

          // 时长
          Row(children: [
            const Icon(Icons.timer_outlined, color: AppTheme.primary),
            const SizedBox(width: 8),
            const Text('预计时长：'),
            Expanded(child: Slider(
              value: _minutes.toDouble(),
              min: 10, max: 120, divisions: 11,
              label: '$_minutes 分钟',
              activeColor: AppTheme.primary,
              onChanged: (v) => setState(() => _minutes = v.round()),
            )),
            Text('$_minutes 分钟'),
          ]),
          const SizedBox(height: 8),

          // 确认按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('加入计划'),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final plan = StudyPlan(
      subject: widget.subject,
      grade: widget.chapter.grade,
      chapterId: widget.chapter.id,
      chapterName: widget.chapter.chapterName,
      knowledgePoint: _kpCtrl.text.trim().isEmpty ? null : _kpCtrl.text.trim(),
      dueDate: _date,
      type: PlanType.daily,
      estimatedMinutes: _minutes,
      createdAt: DateTime.now(),
    );
    context.read<PlanService>().addPlan(plan);
    Navigator.pop(context);
    widget.onSaved();
  }
}
