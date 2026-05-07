import 'package:flutter/material.dart';
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
