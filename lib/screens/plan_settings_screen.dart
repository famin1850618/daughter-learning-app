import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../models/plan_settings.dart';
import '../services/plan_settings_service.dart';
import '../services/question_update_service.dart';
import '../services/learning_export_service.dart';
import '../services/learning_sync_service.dart';
import '../services/data_backup_service.dart';
import '../services/difficulty_settings_service.dart';
import '../services/review_request_service.dart';
import '../services/data_reset_service.dart';
import '../services/diagnostic_service.dart';
import '../services/practice_service.dart';
import '../services/reward_service.dart';
import '../services/assessment_service.dart';
import '../services/plan_service.dart';
import 'curriculum_management_screen.dart';
import 'parent_review_screen.dart';

class PlanSettingsScreen extends StatefulWidget {
  const PlanSettingsScreen({super.key});

  @override
  State<PlanSettingsScreen> createState() => _PlanSettingsScreenState();
}

class _PlanSettingsScreenState extends State<PlanSettingsScreen> {
  late PlanSettings _settings;

  static const _weekdayLabels = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  void initState() {
    super.initState();
    _settings = context.read<PlanSettingsService>().settings;
  }

  void _save() {
    context.read<PlanSettingsService>().save(_settings);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── 家长审核（V3.8.3）──────────────────
          const _ParentReviewEntry(),
          const SizedBox(height: 16),

          // ── 课程知识库 ────────────────────────
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book, color: AppTheme.primary),
              title: const Text('课程知识库'),
              subtitle: const Text('管理各科目章节，支持增删和排序'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CurriculumManagementScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 题库更新 ──────────────────────────
          _SectionHeader(
            title: '题库更新',
            subtitle: '从云端拉取新题包，按知识点增量同步。',
          ),
          const _UpdateSection(),
          const SizedBox(height: 16),

          // ── 难度设置（V3.8）──────────────────
          _SectionHeader(
            title: '练习难度',
            subtitle: '设置抽题的难度档（基础/中等/较难/竞赛）。普通练习强制应用；薄弱点练习可选。',
          ),
          const _DifficultySection(),
          const SizedBox(height: 16),

          // ── 学情自动同步（V3.7.7）────────────
          _SectionHeader(
            title: '学情自动同步',
            subtitle: '完成练习后自动把错题/弱 KP 推送到私有 GitHub repo，第二阶段错题反馈出题用。',
          ),
          const _SyncSection(),
          const SizedBox(height: 16),

          // ── V3.24 家长审核反馈 audit log ────────────
          _SectionHeader(
            title: '家长审核反馈',
            subtitle: '审核通过时选了"题目有误/答案有误/半主观题"的条目会累积在这里，复制 prompt 给 Claude 派 agent 修题库。',
          ),
          const _AuditFeedbackSection(),
          const SizedBox(height: 16),

          // ── 数据导出与备份 ────────────────────
          _SectionHeader(
            title: '数据导出与备份',
            subtitle: '导出学情供后续题目生成参考；备份后即使重装也不丢数据。',
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.assessment, color: AppTheme.primary),
                  title: const Text('导出学情数据'),
                  subtitle: const Text('生成 JSON：弱知识点 + 最近错题'),
                  trailing: const Icon(Icons.share, size: 18),
                  onTap: () async {
                    try {
                      await LearningExportService().exportAndShare();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('导出失败：$e')));
                    }
                  },
                ),
                const Divider(height: 1, indent: 16),
                ListTile(
                  leading: const Icon(Icons.backup, color: AppTheme.primary),
                  title: const Text('备份所有数据'),
                  subtitle: const Text('题目/练习/错题/奖励/计划全部打包'),
                  trailing: const Icon(Icons.share, size: 18),
                  onTap: () async {
                    try {
                      await DataBackupService().exportAndShare();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('备份失败：$e')));
                    }
                  },
                ),
                const Divider(height: 1, indent: 16),
                ListTile(
                  leading: const Icon(Icons.restore, color: Colors.orange),
                  title: const Text('从备份恢复'),
                  subtitle: const Text('选 JSON 文件覆盖本地（不可撤销）'),
                  trailing: const Icon(Icons.upload_file, size: 18),
                  onTap: () => _confirmRestore(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 重置全部学习数据（V3.11）──────────
          _SectionHeader(
            title: '重置学习进度',
            subtitle: '一键清空错题、奖励、测评、练习记录、计划完成度。归档保留 7 天，可回滚。',
          ),
          const _DataResetSection(),
          const SizedBox(height: 16),

          // ── 诊断面板（V3.12.9_fix）─────────────
          _SectionHeader(
            title: '诊断',
            subtitle: '题库 self-check + 错误日志。任何 bug 反复出现先看这里。',
          ),
          const _DiagnosticSection(),
          const SizedBox(height: 16),

          // ── 分配到哪几天 ──────────────────────
          _SectionHeader(
            title: '分配天数',
            subtitle: '自动分配周/月计划时，只安排在勾选的星期。全部不勾选表示每天都分配。',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: List.generate(7, (i) {
                  final day = i + 1; // 1=Mon...7=Sun
                  final selected = _settings.targetWeekdays.contains(day);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FilterChip(
                      label: Text(_weekdayLabels[day]),
                      selected: selected,
                      selectedColor: AppTheme.primary.withOpacity(0.2),
                      checkmarkColor: AppTheme.primary,
                      onSelected: (v) {
                        final days = Set<int>.from(_settings.targetWeekdays);
                        v ? days.add(day) : days.remove(day);
                        setState(() => _settings = _settings.copyWith(targetWeekdays: days));
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
            child: Text(
              _settings.targetWeekdays.isEmpty
                  ? '当前：每天都可分配'
                  : '当前：只在 ${_settings.targetWeekdays.map((d) => _weekdayLabels[d]).join('、')} 分配',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),

          // ── 每日最多任务数 ────────────────────
          _SectionHeader(
            title: '每日最多任务',
            subtitle: '超出此数量的任务会顺延到下一天，0 表示不限制。',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _settings.maxPerDay == 0
                        ? '不限制（当前）'
                        : '每天最多 ${_settings.maxPerDay} 项（当前）',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: _settings.maxPerDay.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _settings.maxPerDay == 0 ? '不限' : '${_settings.maxPerDay}项',
                    activeColor: AppTheme.primary,
                    onChanged: (v) => setState(
                        () => _settings = _settings.copyWith(maxPerDay: v.round())),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 科目分配方式 ──────────────────────
          _SectionHeader(
            title: '科目分配方式',
            subtitle: '决定同一天内多个任务是来自不同科目还是集中在同一科目。',
          ),
          Card(
            child: Column(
              children: [
                RadioListTile<bool>(
                  title: const Text('均匀分配（推荐）'),
                  subtitle: const Text('每天安排不同科目，交叉轮换'),
                  value: false,
                  groupValue: _settings.concentrated,
                  activeColor: AppTheme.primary,
                  onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(concentrated: v)),
                ),
                const Divider(height: 1, indent: 16),
                RadioListTile<bool>(
                  title: const Text('集中分配'),
                  subtitle: const Text('同一科目的内容优先安排在连续的天'),
                  value: true,
                  groupValue: _settings.concentrated,
                  activeColor: AppTheme.primary,
                  onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(concentrated: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 说明 ──────────────────────────────
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 6),
                    Text('说明', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    '这些设置影响新建周/月计划时的自动分配，以及月计划内周与周之间的内容移动。\n\n'
                    '已有计划不受影响，只有新创建的计划或执行"移动本周内容"时才会应用新设置。',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmRestore(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('从备份恢复？'),
      content: const Text('将用备份文件覆盖现有数据。\n\n现有的题目、练习记录、错题、奖励、计划将被替换。\n\n确定继续吗？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('确认覆盖'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final (ok, msg) = await DataBackupService().pickAndRestore();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  if (ok) {
    // 数据已变化，强制重启 app 让 provider 重读
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('恢复完成'),
        content: const Text('请重启 app 让所有页面看到最新数据。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('好')),
        ],
      ),
    );
  }
}

class _UpdateSection extends StatelessWidget {
  const _UpdateSection();

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<QuestionUpdateService>();
    final lastSyncStr = svc.lastSync == null
        ? '从未同步'
        : DateFormat('M月d日 HH:mm').format(svc.lastSync!);
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_sync, color: AppTheme.primary),
            title: const Text('同步题库（云端 → 本地）'),
            subtitle: Text(svc.syncing
                ? svc.status
                : '上次：$lastSyncStr · ${svc.status}\n本地与云端 1:1 镜像；新增/调整/去除自动同步'),
            isThreeLine: !svc.syncing,
            trailing: svc.syncing
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh, size: 18),
            onTap: svc.syncing ? null : () async {
              try {
                final result = await svc.checkAndImport();
                if (!context.mounted) return;
                final msg = result.errors.isEmpty
                    ? '同步完成 (+${result.added} ~${result.updated} -${result.removed})'
                    : '同步完成 (+${result.added} ~${result.updated} -${result.removed}; ${result.errors.length} 错，详见诊断面板)';
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              } on SyncException catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('同步失败 [${e.phase}]: ${e.message}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 6),
                  ),
                );
              }
            },
          ),
          const Divider(height: 1, indent: 16),
          ListTile(
            leading: const Icon(Icons.refresh_outlined, color: Colors.orange),
            title: const Text('强制全量刷新'),
            subtitle: const Text('清空 questions 表 + 重新从云端拉全部 batch（同步异常时用）'),
            trailing: svc.syncing
                ? null
                : const Icon(Icons.warning_amber, size: 18, color: Colors.orange),
            onTap: svc.syncing ? null : () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('强制全量刷新？'),
                  content: const Text(
                    '会清空本地 questions 表 + 从云端重新拉全部 batch。\n'
                    '不影响错题记录、奖励、计划等学情数据。\n\n'
                    '需要联网。失败可重试。',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('强制刷新'),
                    ),
                  ],
                ),
              );
              if (ok != true || !context.mounted) return;
              try {
                final result = await svc.refreshAll();
                if (!context.mounted) return;
                final msg = result.errors.isEmpty
                    ? '已清空 + 拉全部：${result.added} 卷'
                    : '已清空 + 拉 ${result.added} 卷；${result.errors.length} 错（详见诊断面板）';
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              } on SyncException catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('刷新失败 [${e.phase}]: ${e.message}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 6),
                  ),
                );
              }
            },
          ),
          const Divider(height: 1, indent: 16),
          SwitchListTile(
            secondary: const Icon(Icons.autorenew, color: AppTheme.primary),
            title: const Text('启动时自动检查'),
            subtitle: const Text('打开 app 时静默 sync（题库已存在；首次装强制阻塞 sync）'),
            value: svc.autoCheck,
            activeColor: AppTheme.primary,
            onChanged: (v) => svc.setAutoCheck(v),
          ),
        ],
      ),
    );
  }
}

class _SyncSection extends StatefulWidget {
  const _SyncSection();
  @override
  State<_SyncSection> createState() => _SyncSectionState();
}

class _SyncSectionState extends State<_SyncSection> {
  late TextEditingController _patCtrl;
  late TextEditingController _ownerCtrl;
  late TextEditingController _repoCtrl;
  late TextEditingController _deviceCtrl;
  bool _patVisible = false;

  @override
  void initState() {
    super.initState();
    final svc = context.read<LearningSyncService>();
    _patCtrl = TextEditingController(text: svc.pat);
    _ownerCtrl = TextEditingController(text: svc.repoOwner);
    _repoCtrl = TextEditingController(text: svc.repoName);
    _deviceCtrl = TextEditingController(text: svc.deviceName);
  }

  @override
  void dispose() {
    _patCtrl.dispose();
    _ownerCtrl.dispose();
    _repoCtrl.dispose();
    _deviceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<LearningSyncService>();
    final lastSyncStr = svc.lastAt == null
        ? '从未'
        : DateFormat('M月d日 HH:mm').format(svc.lastAt!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('启用学情同步'),
              subtitle: Text('上次：$lastSyncStr · ${svc.status}'),
              value: svc.enabled,
              activeColor: AppTheme.primary,
              onChanged: (v) => svc.setEnabled(v),
            ),
            if (svc.enabled) ...[
              const SizedBox(height: 4),
              TextField(
                controller: _patCtrl,
                obscureText: !_patVisible,
                decoration: InputDecoration(
                  labelText: 'GitHub PAT (fine-grained)',
                  hintText: 'github_pat_xxxxxx',
                  helperText: 'fine-grained PAT；仅 Contents: read & write',
                  helperMaxLines: 2,
                  suffixIcon: IconButton(
                    icon: Icon(_patVisible
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(() => _patVisible = !_patVisible),
                  ),
                ),
                onSubmitted: (v) => svc.setPat(v),
                onEditingComplete: () => svc.setPat(_patCtrl.text),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ownerCtrl,
                      decoration: const InputDecoration(labelText: 'Owner'),
                      onEditingComplete: () => svc.setRepoOwner(_ownerCtrl.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('/'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _repoCtrl,
                      decoration: const InputDecoration(labelText: 'Repo'),
                      onEditingComplete: () => svc.setRepoName(_repoCtrl.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _deviceCtrl,
                decoration: const InputDecoration(
                  labelText: '设备昵称',
                  helperText: '用于云端按设备分目录（如 daughter-phone）',
                ),
                onEditingComplete: () => svc.setDeviceName(_deviceCtrl.text),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: svc.syncing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cloud_upload, size: 18),
                      label: Text(svc.syncing ? '同步中' : '立即同步'),
                      onPressed: svc.syncing
                          ? null
                          : () async {
                              // 提交所有输入
                              await svc.setPat(_patCtrl.text);
                              await svc.setRepoOwner(_ownerCtrl.text);
                              await svc.setRepoName(_repoCtrl.text);
                              await svc.setDeviceName(_deviceCtrl.text);
                              final result = await svc.syncNow();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result)));
                            },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// V3.24 家长审核反馈 audit log section
class _AuditFeedbackSection extends StatefulWidget {
  const _AuditFeedbackSection();

  @override
  State<_AuditFeedbackSection> createState() => _AuditFeedbackSectionState();
}

class _AuditFeedbackSectionState extends State<_AuditFeedbackSection> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final svc = context.read<ReviewRequestService>();
    final c = await svc.auditFeedbackPendingCount();
    if (mounted) setState(() => _count = c);
  }

  Future<void> _showProcessDialog() async {
    final svc = context.read<ReviewRequestService>();
    final log = await svc.exportAuditFeedbackLog();
    if (!mounted) return;
    if (log.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无待处理审核反馈')),
      );
      return;
    }
    // 构造 prompt
    final prompt = '''你是 daughter_learning_app 的 audit-feedback-processor agent。

请按 audit feedback log 分类处理三类问题（题目有误/答案有误/半主观题），完整流程见 ~/.claude/skills/audit-feedback-processor/SKILL.md。

【Audit Feedback Log（${log.split('\n').length} 条）】
$log

【处理方针】
- 能直接修题库的（半主观题打标记、答案明确错的）→ patch batch JSON + commit
- 不能确认的（题目有误需查原 docx 但无可读源 / 答案有误但争议大）→ 写 ~/AI_Workspace/Planning/audit_pending_famin.md 等 Famin 决策
- 完成后报告 done/pending 分布

工作 repo: /home/faminwsl/daughter_learning_app''';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('处理审核反馈'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('1. 复制下方 prompt'),
              const Text('2. 粘贴到 Claude Code 主对话'),
              const Text('3. Claude 派 agent 处理并报告'),
              const Text('4. 确认无误后回来点"清空已处理"'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SelectableText(
                  prompt,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: prompt));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Prompt 已复制到剪贴板')),
                );
              }
            },
            child: const Text('复制 Prompt'),
          ),
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: ctx,
                builder: (c) => AlertDialog(
                  title: const Text('清空已处理？'),
                  content: const Text('确认 agent 已处理完毕？清空后无法恢复。'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
                    TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('清空')),
                  ],
                ),
              );
              if (confirm == true) {
                await svc.clearAuditFeedbackLog();
                if (ctx.mounted) Navigator.pop(ctx);
                await _refresh();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('audit log 已清空')),
                  );
                }
              }
            },
            child: const Text('清空已处理'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Stack(
          children: [
            const Icon(Icons.fact_check, color: AppTheme.primary),
            if (_count > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    '$_count',
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: const Text('现在处理审核反馈'),
        subtitle: Text(_count == 0 ? '暂无待处理' : '$_count 条等候 agent 处理'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: _showProcessDialog,
      ),
    );
  }
}

/// 难度设置区块（V3.8）
class _DifficultySection extends StatelessWidget {
  const _DifficultySection();

  static const _subjects = ['数学', '语文', '英语', '物理', '化学', 'AI'];

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DifficultySettingsService>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 全局 / 分科
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Text('应用范围：'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SegmentedButton<DifficultyMode>(
                      segments: const [
                        ButtonSegment(
                            value: DifficultyMode.global,
                            label: Text('全局', style: TextStyle(fontSize: 13))),
                        ButtonSegment(
                            value: DifficultyMode.perSubject,
                            label: Text('分科', style: TextStyle(fontSize: 13))),
                      ],
                      selected: {svc.mode},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => svc.setMode(s.first),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),

            if (svc.mode == DifficultyMode.global)
              _ProfileEditor(profileKey: 'global', label: '所有科目')
            else
              ..._subjects.map((s) => ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                    childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    title: Text(s, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(_summarize(svc.profileFor(s)),
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    children: [_ProfileEditor(profileKey: s, label: s)],
                  )),

            const Divider(height: 16),
            // 应用范围开关
            SwitchListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: const Text('首页薄弱知识点应用难度', style: TextStyle(fontSize: 13)),
              subtitle: const Text('关掉则按"最近错过的难度"匹配（旧逻辑）',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              value: svc.applyToWeakKp,
              activeColor: AppTheme.primary,
              onChanged: (v) => svc.setApplyToWeakKp(v),
            ),
            SwitchListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: const Text('错题集"练相似题"应用难度', style: TextStyle(fontSize: 13)),
              subtitle: const Text('关掉则按错题原题难度匹配',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              value: svc.applyToReviewSimilar,
              activeColor: AppTheme.primary,
              onChanged: (v) => svc.setApplyToReviewSimilar(v),
            ),
          ],
        ),
      ),
    );
  }

  static String _summarize(DifficultyProfile p) {
    if (p.type == DifficultyType.precise) {
      if (p.preciseRound == null) return '不限难度';
      const names = {1: '基础', 2: '中等', 3: '较难', 4: '竞赛'};
      return '精确：${names[p.preciseRound]}';
    }
    return '模糊：${p.fuzzyWeights.join('/')}';
  }
}

class _ProfileEditor extends StatelessWidget {
  final String profileKey;
  final String label;
  const _ProfileEditor({required this.profileKey, required this.label});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DifficultySettingsService>();
    final profile = svc.profileFor(profileKey == 'global' ? '' : profileKey);
    final p = profileKey == 'global' ? svc.globalProfile : profile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 类型切换
          Row(
            children: [
              const Text('类型：', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: SegmentedButton<DifficultyType>(
                  segments: const [
                    ButtonSegment(
                        value: DifficultyType.precise,
                        label: Text('精确（单档）', style: TextStyle(fontSize: 12))),
                    ButtonSegment(
                        value: DifficultyType.fuzzy,
                        label: Text('模糊（混合）', style: TextStyle(fontSize: 12))),
                  ],
                  selected: {p.type},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) {
                    final newType = s.first;
                    if (newType == DifficultyType.precise) {
                      svc.setPrecise(profileKey, p.preciseRound);
                    } else {
                      svc.setProfile(profileKey,
                          p.copyWith(type: DifficultyType.fuzzy));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (p.type == DifficultyType.precise) ...[
            const Text('选择档位：', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                _ChoiceChip(
                  label: '不限',
                  selected: p.preciseRound == null,
                  onTap: () => svc.setPrecise(profileKey, null),
                ),
                _ChoiceChip(
                  label: '基础',
                  selected: p.preciseRound == 1,
                  onTap: () => svc.setPrecise(profileKey, 1),
                ),
                _ChoiceChip(
                  label: '中等',
                  selected: p.preciseRound == 2,
                  onTap: () => svc.setPrecise(profileKey, 2),
                ),
                _ChoiceChip(
                  label: '较难',
                  selected: p.preciseRound == 3,
                  onTap: () => svc.setPrecise(profileKey, 3),
                ),
                _ChoiceChip(
                  label: '竞赛',
                  selected: p.preciseRound == 4,
                  onTap: () => svc.setPrecise(profileKey, 4),
                ),
              ],
            ),
          ] else ...[
            const Text('选择预设：', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: DifficultyPreset.values.map((preset) {
                final isCurrent = _listEquals(p.fuzzyWeights, preset.weights);
                return _ChoiceChip(
                  label: '${preset.label} (${preset.weights.join('/')})',
                  selected: isCurrent,
                  onTap: () => svc.applyPreset(profileKey, preset),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            Text('当前：基础${p.fuzzyWeights[0]} / 中等${p.fuzzyWeights[1]} / 较难${p.fuzzyWeights[2]} / 竞赛${p.fuzzyWeights[3]}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontSize: 12,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// V3.8.3 设置页家长审核入口（pending 数 badge）
class _ParentReviewEntry extends StatelessWidget {
  const _ParentReviewEntry();

  @override
  Widget build(BuildContext context) {
    final review = context.watch<ReviewRequestService>();
    final pending = review.pendingCount;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.fact_check, color: Colors.deepPurple),
        title: const Text('家长审核'),
        subtitle: Text(pending > 0
            ? '$pending 条待审核（小孩申诉判错 / 主观题待批改）'
            : '小孩申诉判错 / 主观题待批改 都在这里处理'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pending > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$pending',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ParentReviewScreen()),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }
}

class _DataResetSection extends StatefulWidget {
  const _DataResetSection();

  @override
  State<_DataResetSection> createState() => _DataResetSectionState();
}

class _DataResetSectionState extends State<_DataResetSection> {
  List<DataResetArchive> _archives = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refreshArchives();
  }

  Future<void> _refreshArchives() async {
    setState(() => _loading = true);
    final list = await DataResetService().listArchives();
    if (!mounted) return;
    setState(() {
      _archives = list;
      _loading = false;
    });
  }

  /// 三段确认重置流程：警告弹窗 → 输入"重置"二字 → 最终确认
  ///
  /// [wipePlans] 决定是否一并清空 plan_groups + plan_items（V3.12 新增）
  Future<void> _confirmReset({required bool wipePlans}) async {
    // Step 1: 警告
    final clearedItems = StringBuffer()
      ..writeln('• 所有错题记录')
      ..writeln('• 所有奖励星星')
      ..writeln('• 所有测评成绩')
      ..writeln('• 所有练习记录与进行中的会话')
      ..writeln('• 所有家长审核记录');
    if (wipePlans) {
      clearedItems.writeln('• 所有月/周/日计划及其完成度（整张计划清空）');
    } else {
      clearedItems.writeln('• 所有计划完成度（计划本身保留）');
    }

    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              wipePlans ? Icons.delete_forever : Icons.warning_amber,
              color: wipePlans ? Colors.red : Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(wipePlans ? '重置全部（含计划）' : '重置学习进度'),
          ],
        ),
        content: Text(
          '此操作会清空：\n\n'
          '$clearedItems\n'
          '题目本身不删。归档保留 7 天，期间可回滚。',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '继续',
              style: TextStyle(color: wipePlans ? Colors.red : Colors.orange),
            ),
          ),
        ],
      ),
    );
    if (step1 != true || !mounted) return;

    // Step 2: 输入"重置"
    final controller = TextEditingController();
    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认操作'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请输入"重置"两字以继续：', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '重置',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim() == '重置'),
            child: const Text('确认', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (step2 != true || !mounted) return;

    // Step 3: 最终确认
    final step3 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('最终确认'),
        content: const Text(
          '将立即归档并清空全部学习进度数据。\n\n'
          '7 天内可在本页面回滚。\n\n'
          '是否继续？',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('再想想')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('立即重置', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (step3 != true || !mounted) return;

    // 执行重置
    final timestamp = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final reason = wipePlans ? '手动重置（含计划）$timestamp' : '手动重置 $timestamp';
    final batchId = await DataResetService().resetAllProgress(
      reason: reason,
      wipePlans: wipePlans,
    );

    if (!mounted) return;
    if (batchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('重置失败，请重试'), backgroundColor: Colors.red),
      );
      return;
    }

    // 刷新所有相关 service
    await _refreshAllServices();
    await _refreshArchives();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已重置，归档 7 天内可回滚（$batchId）')),
    );
  }

  Future<void> _confirmRollback(DataResetArchive archive) async {
    final detail = archive.includesPlans
        ? '这会把 ${archive.totalRowsArchived} 行进度数据 + '
            '${archive.stats['plan_groups'] ?? 0} 个计划组 + '
            '${archive.stats['plan_items'] ?? 0} 个计划项整体恢复。'
        : '这会把 ${archive.totalRowsArchived} 行进度数据恢复回主表，'
            '同时回滚 ${archive.stats['plan_items_completion'] ?? 0} 项计划完成度。';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('回滚归档？'),
        content: Text(
          '$detail\n\n回滚后该归档会被删除，无法再次回滚。',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('回滚'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final success = await DataResetService().rollbackArchive(archive.batchId);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('回滚失败（可能已过期或归档不存在）')),
      );
      return;
    }
    await _refreshAllServices();
    await _refreshArchives();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已回滚')),
    );
  }

  /// 重置/回滚后刷新所有依赖学情数据的 service
  Future<void> _refreshAllServices() async {
    if (!mounted) return;
    try {
      context.read<RewardService>().refresh();
    } catch (_) {}
    try {
      context.read<AssessmentService>().refresh();
    } catch (_) {}
    try {
      context.read<ReviewRequestService>().refresh();
    } catch (_) {}
    try {
      context.read<PracticeService>().endSession();
    } catch (_) {}
    // wipePlans 时 plan_groups/plan_items 整表变更，PlanService 必须重读
    try {
      await context.read<PlanService>().reload();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.orange),
            title: const Text('重置学习数据'),
            subtitle: const Text('清空错题/奖励/测评/练习记录/计划完成度（计划本身保留）'),
            trailing: TextButton(
              onPressed: () => _confirmReset(wipePlans: false),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('重置'),
            ),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('重置全部（含计划）'),
            subtitle: const Text('上面那项 + 整张月/周/日计划全部清空'),
            trailing: TextButton(
              onPressed: () => _confirmReset(wipePlans: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('全部重置'),
            ),
          ),
          // V3.12.11：原"重建题库"按钮已并入"题库"区的"强制全量刷新"（CDN 拉云端）
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_archives.isNotEmpty) ...[
            const Divider(height: 1, indent: 16),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('可回滚的归档（7 天内）',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
            ..._archives.map((a) => _buildArchiveTile(a)),
          ],
        ],
      ),
    );
  }

  Widget _buildArchiveTile(DataResetArchive a) {
    final timeStr = DateFormat('MM-dd HH:mm').format(a.createdAt);
    final tag = a.includesPlans ? ' · 含计划' : '';
    return ListTile(
      dense: true,
      leading: Icon(
        a.includesPlans ? Icons.delete_forever : Icons.history,
        color: a.includesPlans ? Colors.red : Colors.grey,
        size: 20,
      ),
      title: Text(
        '$timeStr · ${a.totalRowsArchived} 行$tag',
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        '${a.reason}\n剩余可回滚：${a.daysUntilExpiry} 天',
        style: const TextStyle(fontSize: 11),
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _confirmRollback(a),
            child: const Text('回滚'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: '删除归档（不回滚）',
            onPressed: () => _confirmDeleteArchive(a),
          ),
        ],
      ),
    );
  }

  // V3.12.11: 原 _confirmRebuild 已删除，功能并入题库 section 的"强制全量刷新"
  // (走 QuestionUpdateService.refreshAll() → 清表 + 拉 CDN 全量)

  /// V3.12.9: 删除归档（不回滚）
  Future<void> _confirmDeleteArchive(DataResetArchive a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除归档？'),
        content: Text(
          '删除后无法回滚。\n\n${a.reason}\n${a.totalRowsArchived} 行进度数据将永久丢失。',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final success = await DataResetService().deleteArchive(a.batchId);
    if (!mounted) return;
    if (success) {
      await _refreshArchives();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('归档已删除')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除失败'), backgroundColor: Colors.red),
      );
    }
  }
}

// ── 诊断面板（V3.12.9_fix）──────────────────────────────
// feedback_bug_diagnosis_discipline.md 的 app 端实施
class _DiagnosticSection extends StatelessWidget {
  const _DiagnosticSection();

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DiagnosticService>();
    return Card(
      child: Column(
        children: [
          // self-check 报告
          ExpansionTile(
            leading: Icon(
              svc.startupReport.every((e) => e.ok) ? Icons.check_circle : Icons.warning,
              color: svc.startupReport.every((e) => e.ok) ? Colors.green : Colors.orange,
            ),
            title: const Text('启动 self-check 报告'),
            subtitle: Text('${svc.startupReport.where((e) => e.ok).length} / ${svc.startupReport.length} 项通过'),
            children: svc.startupReport.map((e) => ListTile(
              dense: true,
              leading: Icon(
                e.ok ? Icons.check : Icons.error,
                color: e.ok ? Colors.green : Colors.red,
                size: 18,
              ),
              title: Text(e.key, style: const TextStyle(fontSize: 13)),
              subtitle: e.hint != null
                  ? Text(e.hint!, style: const TextStyle(fontSize: 11, color: Colors.red))
                  : null,
              trailing: Text(e.value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            )).toList(),
          ),
          const Divider(height: 1, indent: 56),
          // 错误日志
          ExpansionTile(
            leading: Icon(
              svc.errorCount > 0 ? Icons.error : Icons.info_outline,
              color: svc.errorCount > 0 ? Colors.red : Colors.grey,
            ),
            title: Text('错误日志（${svc.errorLogs.length} 条）'),
            subtitle: svc.errorCount > 0
                ? Text('${svc.errorCount} 条错误', style: const TextStyle(color: Colors.red))
                : const Text('无错误'),
            trailing: svc.errorLogs.isNotEmpty
                ? Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: '复制全部日志',
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: svc.exportErrorLogs()));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('日志已复制到剪贴板')),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep, size: 18),
                        tooltip: '清空日志',
                        onPressed: () async => svc.clearErrorLogs(),
                      ),
                    ],
                  )
                : null,
            children: svc.errorLogs.take(20).map((l) => ListTile(
              dense: true,
              leading: Icon(
                l.level == 'error' ? Icons.error :
                l.level == 'warn' ? Icons.warning : Icons.info,
                color: l.level == 'error' ? Colors.red :
                       l.level == 'warn' ? Colors.orange : Colors.blue,
                size: 18,
              ),
              title: Text('${l.context} | ${l.message}',
                  style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                  DateFormat('MM-dd HH:mm:ss').format(l.timestamp),
                  style: const TextStyle(fontSize: 10)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
