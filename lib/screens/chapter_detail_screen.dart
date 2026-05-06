import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../models/subject.dart';
import '../models/curriculum.dart';
import '../database/curriculum_dao.dart';
import '../database/plan_item_dao.dart';
import '../models/plan_group.dart';
import '../services/practice_service.dart';
import '../services/navigation_service.dart';

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

  static const _gradeLabels = {6: '六年级', 7: '初一', 8: '初二', 9: '初三'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final chapters = await _dao.getChapters(widget.subject.name, widget.grade);
    if (!mounted) return;
    setState(() => _chapters = chapters);
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
              ),
            ),
    );
  }
}

class _ChapterTile extends StatefulWidget {
  final Chapter chapter;
  final Subject subject;
  const _ChapterTile({required this.chapter, required this.subject});

  @override
  State<_ChapterTile> createState() => _ChapterTileState();
}

class _ChapterTileState extends State<_ChapterTile> {
  final _itemDao = PlanItemDao();
  List<PlanItem> _planItems = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPlanItems();
  }

  Future<void> _loadPlanItems() async {
    final items = await _itemDao.getByChapterId(widget.chapter.id!);
    if (!mounted) return;
    setState(() {
      _planItems = items;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasPlan = _planItems.isNotEmpty;
    final doneCount = _planItems.where((i) => i.status == PlanItemStatus.completed).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '${widget.chapter.orderIndex}',
                style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.chapter.chapterName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  if (_loaded && hasPlan)
                    Text(
                      '📅 计划中 ($doneCount/${_planItems.length} 完成)',
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    )
                  else if (_loaded)
                    Text(
                      '暂未加入计划',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 12),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_circle_outline,
                  color: AppTheme.primary),
              tooltip: '开始练习',
              onPressed: () => _startPractice(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startPractice(BuildContext context) async {
    await context.read<PracticeService>().startSession(
      subject: widget.subject,
      grade: widget.chapter.grade,
      chapter: widget.chapter.chapterName,
      count: 10,
    );
    if (!context.mounted) return;
    final qs = context.read<PracticeService>().currentQuestions;
    if (qs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该章节暂无题，等新题包')),
      );
      return;
    }
    context.read<NavigationService>().goTo(2);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }
}
