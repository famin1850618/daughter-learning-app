import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../models/plan_settings.dart';
import '../services/plan_settings_service.dart';
import '../services/question_update_service.dart';
import '../services/learning_export_service.dart';
import '../services/data_backup_service.dart';
import 'curriculum_management_screen.dart';

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
            leading: const Icon(Icons.cloud_download, color: AppTheme.primary),
            title: const Text('立即检查更新'),
            subtitle: Text(svc.syncing ? svc.status : '上次：$lastSyncStr · ${svc.status}'),
            trailing: svc.syncing
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh, size: 18),
            onTap: svc.syncing ? null : () async {
              final result = await svc.checkAndImport();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result)));
            },
          ),
          const Divider(height: 1, indent: 16),
          SwitchListTile(
            secondary: const Icon(Icons.autorenew, color: AppTheme.primary),
            title: const Text('启动时自动检查'),
            subtitle: const Text('打开 app 时静默拉取新题包'),
            value: svc.autoCheck,
            activeColor: AppTheme.primary,
            onChanged: (v) => svc.setAutoCheck(v),
          ),
        ],
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
