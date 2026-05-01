import 'package:flutter/material.dart';
import '../database/curriculum_dao.dart';
import '../models/curriculum.dart';
import '../models/subject.dart';
import '../utils/app_theme.dart';

class CurriculumChapterEditScreen extends StatefulWidget {
  final Subject subject;
  const CurriculumChapterEditScreen({super.key, required this.subject});

  @override
  State<CurriculumChapterEditScreen> createState() =>
      _CurriculumChapterEditScreenState();
}

class _CurriculumChapterEditScreenState
    extends State<CurriculumChapterEditScreen>
    with SingleTickerProviderStateMixin {
  final _dao = CurriculumDao();
  late final List<int> _grades;
  late final TabController _tabController;
  final Map<int, List<Chapter>> _chapters = {};
  bool _loading = true;

  static const _gradeLabels = {
    6: '六年级',
    7: '初一',
    8: '初二',
    9: '初三',
  };

  @override
  void initState() {
    super.initState();
    _grades = List.generate(
      10 - widget.subject.startGrade,
      (i) => widget.subject.startGrade + i,
    );
    _tabController = TabController(length: _grades.length, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    for (final g in _grades) {
      _chapters[g] = await _dao.getChapters(widget.subject.name, g);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _reload(int grade) async {
    final list = await _dao.getChapters(widget.subject.name, grade);
    if (mounted) setState(() => _chapters[grade] = list);
  }

  Future<void> _addChapter(int grade) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _AddChapterDialog(),
    );
    if (name == null || name.trim().isEmpty) return;
    await _dao.insertChapter(widget.subject.name, grade, name.trim());
    await _reload(grade);
  }

  Future<void> _deleteChapter(Chapter chapter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除章节'),
        content: Text('确认删除「${chapter.chapterName}」？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('删除', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _dao.deleteChapter(chapter.id!);
    await _reload(chapter.grade);
  }

  Future<void> _resetToDefault(int grade) async {
    final label = _gradeLabels[grade]!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重置为默认'),
        content: Text(
            '将恢复 $label ${widget.subject.displayName} 的官方章节，自定义修改将丢失。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('重置')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _dao.resetToDefault(widget.subject.name, grade);
    await _reload(grade);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已重置为默认章节')));
    }
  }

  Future<void> _onReorder(int grade, int oldIndex, int newIndex) async {
    final list = List<Chapter>.from(_chapters[grade]!);
    if (newIndex > oldIndex) newIndex--;
    list.insert(newIndex, list.removeAt(oldIndex));
    setState(() => _chapters[grade] = list);
    await _dao.updateOrder(list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject.emoji} ${widget.subject.displayName}'),
        bottom: _grades.length > 1
            ? TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: _grades
                    .map((g) => Tab(text: _gradeLabels[g]))
                    .toList(),
              )
            : null,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert),
            tooltip: '重置为默认',
            itemBuilder: (_) => _grades
                .map((g) => PopupMenuItem(
                      value: g,
                      child: Text('重置 ${_gradeLabels[g]} 为默认'),
                    ))
                .toList(),
            onSelected: _resetToDefault,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _grades.length > 1
              ? TabBarView(
                  controller: _tabController,
                  children:
                      _grades.map((g) => _buildGradeTab(g)).toList(),
                )
              : _buildGradeTab(_grades.first),
    );
  }

  Widget _buildGradeTab(int grade) {
    final chapters = _chapters[grade] ?? [];
    return Column(
      children: [
        Expanded(
          child: chapters.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_outlined,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('暂无章节',
                          style:
                              TextStyle(color: Colors.grey.shade400)),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding:
                      const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: chapters.length,
                  onReorder: (o, n) => _onReorder(grade, o, n),
                  itemBuilder: (context, index) {
                    final chapter = chapters[index];
                    return ListTile(
                      key: ValueKey(chapter.id),
                      leading: CircleAvatar(
                        backgroundColor:
                            AppTheme.primary.withOpacity(0.1),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Text(chapter.chapterName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            tooltip: '删除',
                            onPressed: () =>
                                _deleteChapter(chapter),
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.drag_handle,
                                  color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _addChapter(grade),
              icon: const Icon(Icons.add),
              label: const Text('添加章节'),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddChapterDialog extends StatefulWidget {
  const _AddChapterDialog();

  @override
  State<_AddChapterDialog> createState() => _AddChapterDialogState();
}

class _AddChapterDialogState extends State<_AddChapterDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加章节'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration:
            const InputDecoration(hintText: '输入章节名称', border: OutlineInputBorder()),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消')),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('添加'),
        ),
      ],
    );
  }
}
