import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/subject.dart';
import '../models/curriculum.dart';
import '../models/plan_group.dart';
import '../database/curriculum_dao.dart';

/// Pushes a screen that lets the user multi-select chapters.
/// Returns List<PlanItemDraft> via Navigator.pop.
class ChapterPickerScreen extends StatefulWidget {
  const ChapterPickerScreen({super.key});

  @override
  State<ChapterPickerScreen> createState() => _ChapterPickerScreenState();
}

class _ChapterPickerScreenState extends State<ChapterPickerScreen>
    with SingleTickerProviderStateMixin {
  final _dao = CurriculumDao();
  late TabController _tabCtrl;
  final _selected = <PlanItemDraft>[];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: Subject.values.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
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
            onPressed: _selected.isEmpty ? null : _done,
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
            .map((s) => _SubjectPane(
                  subject: s,
                  dao: _dao,
                  selected: _selected,
                  onToggle: (draft) => setState(() {
                    final idx = _selected.indexWhere(
                        (d) => d.chapterId == draft.chapterId);
                    if (idx >= 0) {
                      _selected.removeAt(idx);
                    } else {
                      _selected.add(draft);
                    }
                  }),
                ))
            .toList(),
      ),
    );
  }

  void _done() {
    Navigator.pop(context, List<PlanItemDraft>.unmodifiable(_selected));
  }
}

class _SubjectPane extends StatefulWidget {
  final Subject subject;
  final CurriculumDao dao;
  final List<PlanItemDraft> selected;
  final void Function(PlanItemDraft) onToggle;

  const _SubjectPane({
    required this.subject,
    required this.dao,
    required this.selected,
    required this.onToggle,
  });

  @override
  State<_SubjectPane> createState() => _SubjectPaneState();
}

class _SubjectPaneState extends State<_SubjectPane>
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
    if (grades.isNotEmpty) _expandGrade(grades.first);
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

  bool _isSelected(Chapter c) =>
      widget.selected.any((d) => d.chapterId == c.id);

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
              onTap: () => isOpen
                  ? setState(() => _expandedGrade = null)
                  : _expandGrade(grade),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primary,
                      child: Text(
                        (_gradeLabels[grade] ?? '$grade').substring(0, 1),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_gradeLabels[grade]} ${widget.subject.displayName}',
                      style:
                          const TextStyle(fontWeight: FontWeight.w600),
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
                    title: Text(c.chapterName,
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                        '${_gradeLabels[grade]} · 第${c.orderIndex}章',
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
