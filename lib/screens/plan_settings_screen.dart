import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../models/plan_settings.dart';
import '../services/plan_settings_service.dart';
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
