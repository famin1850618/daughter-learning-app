import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../utils/math_text.dart';
import '../models/question.dart';
import '../models/review_request.dart';
import '../services/review_request_service.dart';

/// V3.8.3 家长审核屏：判错申诉 + 主观题评分混合处理
///
/// 三 tab：
///   1. 待审核（pending）—— 主操作页：通过/驳回 + 主观题评分
///   2. 已通过（approved）—— 历史
///   3. 已驳回（rejected）—— 历史
///
/// 不加 PIN（公开监督；UI 文案明确"家长操作"）。
class ParentReviewScreen extends StatefulWidget {
  const ParentReviewScreen({super.key});

  @override
  State<ParentReviewScreen> createState() => _ParentReviewScreenState();
}

class _ParentReviewScreenState extends State<ParentReviewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    // 进入屏幕时刷新一次
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewRequestService>().refresh();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final review = context.watch<ReviewRequestService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('家长审核'),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: '待审核 ${review.pendingCount > 0 ? "(${review.pendingCount})" : ""}'),
            const Tab(text: '已通过'),
            const Tab(text: '已驳回'),
          ],
        ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: TabBarView(
          controller: _tab,
          children: const [
            _RequestList(status: ReviewRequestStatus.pending),
            _RequestList(status: ReviewRequestStatus.approved),
            _RequestList(status: ReviewRequestStatus.rejected),
          ],
        ),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  final ReviewRequestStatus status;
  const _RequestList({required this.status});

  Future<List<ReviewRequest>> _load(ReviewRequestService svc) {
    switch (status) {
      case ReviewRequestStatus.pending:
        return svc.listPending();
      case ReviewRequestStatus.approved:
        return svc.listApproved();
      case ReviewRequestStatus.rejected:
        return svc.listRejected();
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ReviewRequestService>();
    return FutureBuilder<List<ReviewRequest>>(
      future: _load(svc),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(_emptyHint(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ),
          );
        }
        // V3.13 修正（Famin 反馈）: 待审核 tab 内分两区"小孩的 / AI 的"
        if (status == ReviewRequestStatus.pending) {
          final fromChild = list.where((r) =>
              r.requestType == ReviewRequestType.appeal ||
              r.requestType == ReviewRequestType.subjectiveGrading).toList();
          final fromAi = list.where((r) =>
              r.requestType == ReviewRequestType.aiDispute).toList();
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _SectionHeader(title: '小孩的（${fromChild.length}）',
                  subtitle: '判错申诉 / 主观题待批',
                  color: Colors.orange.shade100,
                  textColor: Colors.orange.shade900),
              if (fromChild.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('暂无',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                )
              else
                ...fromChild.map((r) => _ReviewCard(request: r)),
              const SizedBox(height: 16),
              _SectionHeader(title: 'AI 的（${fromAi.length}）',
                  subtitle: 'AI 标注题面/答案有疑问，待你定夺',
                  color: Colors.amber.shade100,
                  textColor: Colors.amber.shade900),
              if (fromAi.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('暂无',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                )
              else
                ...fromAi.map((r) => _ReviewCard(request: r)),
            ],
          );
        }
        // approved / rejected：原列表
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (_, i) => _ReviewCard(request: list[i]),
        );
      },
    );
  }

  String _emptyHint() {
    switch (status) {
      case ReviewRequestStatus.pending:
        return '没有待审核的项目 👍';
      case ReviewRequestStatus.approved:
        return '暂无已通过记录';
      case ReviewRequestStatus.rejected:
        return '暂无已驳回记录';
    }
  }
}

/// V3.13 修正：分组标题（"小孩的"/"AI 的"）
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Color textColor;
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.75))),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final ReviewRequest request;
  const _ReviewCard({required this.request});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  Question? _question;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = context.read<ReviewRequestService>();
    try {
      final detail = await svc.loadDetail(widget.request.id!);
      if (!mounted) return;
      setState(() {
        _question = detail.q;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final dateStr = DateFormat('M月d日 HH:mm').format(req.createdAt);
    final isAppeal = req.requestType == ReviewRequestType.appeal;
    final isAiDispute = req.requestType == ReviewRequestType.aiDispute;
    final isAppealLike = isAppeal || isAiDispute; // V3.13: AI 争议 UI 与申诉同（approve/reject 双按钮）

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 类型标签 + 时间
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isAppeal
                      ? Colors.orange.withOpacity(0.15)
                      : isAiDispute
                          ? Colors.amber.withOpacity(0.20)
                          : Colors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(req.requestType.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isAppeal
                          ? Colors.orange.shade800
                          : isAiDispute
                              ? Colors.amber.shade900
                              : Colors.purple,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              const Spacer(),
              Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ]),
            const SizedBox(height: 8),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
              )
            else if (_question == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('题目已删除（无法审核）', style: TextStyle(color: Colors.grey)),
              )
            else
              _detailContent(_question!),
          ],
        ),
      ),
    );
  }

  Widget _detailContent(Question q) {
    final req = widget.request;
    final isAppeal = req.requestType == ReviewRequestType.appeal;
    final isAiDispute = req.requestType == ReviewRequestType.aiDispute;
    final isAppealLike = isAppeal || isAiDispute; // V3.13: AI 争议 UI 与申诉同（approve/reject 双按钮）
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 题目
        Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: MathText(q.content,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        // 选择题选项
        if (q.type == QuestionType.multipleChoice && q.options != null) ...[
          const SizedBox(height: 8),
          ...q.options!.map((opt) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: MathText(opt, style: const TextStyle(fontSize: 13)),
              )),
        ],
        const SizedBox(height: 10),
        _kvRow('小孩答的：', req.userAnswer, Colors.blue.shade700),
        if (isAppealLike && req.standardAnswer != null)
          _kvRow('当前答案：', req.standardAnswer!.split('|||').first,
              Colors.green.shade700),
        if (q.explanation != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: MathText('💡 ${q.explanation}',
                style: const TextStyle(fontSize: 12.5, height: 1.5)),
          ),
        ],
        if ((req.childNote ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('小孩说：${req.childNote}',
                style: TextStyle(fontSize: 12.5, color: Colors.blue.shade900)),
          ),
        ],
        if (req.parentNote != null && req.parentNote!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('家长备注：${req.parentNote}',
                style: TextStyle(fontSize: 12.5, color: Colors.green.shade900)),
          ),
        ],
        if (req.parentScore != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _scoreColor(req.parentScore!).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('评分：${req.parentScore!.label} (${req.parentScore!.stars}⭐)',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _scoreColor(req.parentScore!))),
          ),
        ],
        const SizedBox(height: 12),
        // 操作区域（仅 pending 时显示）
        if (req.status == ReviewRequestStatus.pending) ...[
          if (isAppealLike)
            _appealActions(context, req)
          else
            _subjectiveActions(context, req),
        ],
      ],
    );
  }

  Widget _appealActions(BuildContext context, ReviewRequest req) {
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
          label: const Text('驳回', style: TextStyle(color: Colors.red)),
          onPressed: () => _confirm(context, req, approve: false),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check_circle, size: 18),
          label: const Text('通过 +0.5⭐'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success, foregroundColor: Colors.white),
          onPressed: () => _confirm(context, req, approve: true),
        ),
      ),
    ]);
  }

  Widget _subjectiveActions(BuildContext context, ReviewRequest req) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('请给主观题评分：',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.5,
          children: SubjectiveScore.values.map((s) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _scoreColor(s).withOpacity(0.15),
                foregroundColor: _scoreColor(s),
                elevation: 0,
                padding: EdgeInsets.zero,
              ),
              onPressed: () => _gradeSubjective(context, req, s),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${s.stars}⭐', style: const TextStyle(fontSize: 11)),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => _confirm(context, req, approve: false),
          child: const Text('驳回（不打分）',
              style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Future<void> _confirm(BuildContext context, ReviewRequest req,
      {required bool approve}) async {
    final ctrl = TextEditingController();
    ReviewIssueType selectedIssue = ReviewIssueType.none;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(approve ? '审核通过？' : '驳回申诉？'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(approve
                    ? '通过后，小孩的这道题改为对的，并补 0.5⭐。'
                    : '驳回后，错题状态保持，小孩看到驳回结果。'),
                if (approve) ...[
                  const SizedBox(height: 14),
                  const Text('问题类型（V3.24）：',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<ReviewIssueType>(
                    value: selectedIssue,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: ReviewIssueType.none, child: Text('无问题（仅判错申诉通过）')),
                      DropdownMenuItem(value: ReviewIssueType.questionWrong, child: Text('题目有误（题面缺信息/印刷错）')),
                      DropdownMenuItem(value: ReviewIssueType.answerWrong, child: Text('答案有误（标准答案错）')),
                      DropdownMenuItem(value: ReviewIssueType.semiSubjective, child: Text('半主观题（答案表述灵活）')),
                    ],
                    onChanged: (v) => setSt(() => selectedIssue = v ?? ReviewIssueType.none),
                  ),
                  if (selectedIssue != ReviewIssueType.none) ...[
                    const SizedBox(height: 6),
                    Text(
                      '→ 选择后将写入 audit feedback，下次"现在处理审核反馈"时 agent 会${selectedIssue == ReviewIssueType.semiSubjective ? "给本题打半主观题标记" : "查原 docx 修题库"}',
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '备注（可空，会展示给小孩看）',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认')),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final note = ctrl.text.trim().isEmpty ? null : ctrl.text.trim();
    final svc = context.read<ReviewRequestService>();
    if (approve) {
      await svc.approve(
          requestId: req.id!, parentNote: note, issueType: selectedIssue);
    } else {
      await svc.reject(requestId: req.id!, parentNote: note);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? '已通过' : '已驳回')),
      );
    }
  }

  Future<void> _gradeSubjective(
      BuildContext context, ReviewRequest req, SubjectiveScore s) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('评分：${s.label} (${s.stars}⭐)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s == SubjectiveScore.fail
                ? '不合格 → 算错题（进错题集，不可再申诉）'
                : '通过 → 这道题算对，并补 ${s.stars}⭐'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '点评（可空，会展示给小孩看）',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final note = ctrl.text.trim().isEmpty ? null : ctrl.text.trim();
    final svc = context.read<ReviewRequestService>();
    await svc.approve(requestId: req.id!, parentNote: note, score: s);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已评分：${s.label}')),
      );
    }
  }

  Color _scoreColor(SubjectiveScore s) {
    switch (s) {
      case SubjectiveScore.perfect: return Colors.green;
      case SubjectiveScore.good:    return Colors.blue;
      case SubjectiveScore.pass:    return Colors.orange;
      case SubjectiveScore.fail:    return Colors.red;
    }
  }

  Widget _kvRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Expanded(
            child: Text(
              value.isEmpty ? '（空）' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
