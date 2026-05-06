import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../models/reward.dart';
import '../services/reward_service.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RewardService>().refresh();
    });
  }

  String _fmt(double s) =>
      s == s.toInt() ? s.toInt().toString() : s.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<RewardService>();
    final total = svc.totalStars;
    final bySource = svc.bySource;
    final recent = svc.recent;
    return Scaffold(
      appBar: AppBar(title: const Text('奖励中心')),
      body: RefreshIndicator(
        onRefresh: () => svc.refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 总星数大卡
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade400, Colors.orange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('🌟', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(_fmt(total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                      )),
                  const Text('累计星星',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 来源分布
            const Text('来源分布',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            if (bySource.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('还没攒到星星，去练几道题吧！',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ..._sortedSources(bySource).map((e) => _SourceTile(
                    source: e.key,
                    stars: e.value,
                    formatter: _fmt,
                  )),
            const SizedBox(height: 20),

            // 最近获奖记录
            const Text('最近获奖',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('暂无记录', style: TextStyle(color: Colors.grey)),
              )
            else
              ...recent.map((r) => _RewardTile(reward: r, formatter: _fmt)),
          ],
        ),
      ),
    );
  }

  List<MapEntry<String, double>> _sortedSources(Map<String, double> m) {
    final entries = m.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}

class _SourceTile extends StatelessWidget {
  final String source;
  final double stars;
  final String Function(double) formatter;
  const _SourceTile({
    required this.source,
    required this.stars,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: Icon(_iconFor(source), color: AppTheme.primary),
        title: Text(rewardSourceLabel(source),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: Text('${formatter(stars)} ⭐',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  IconData _iconFor(String source) {
    switch (source) {
      case 'practice':
        return Icons.edit_note;
      case 'weekly_test':
        return Icons.calendar_view_week;
      case 'monthly_test':
        return Icons.calendar_month;
      case 'bonus':
        return Icons.workspace_premium;
      default:
        return Icons.star_border;
    }
  }
}

class _RewardTile extends StatelessWidget {
  final Reward reward;
  final String Function(double) formatter;
  const _RewardTile({required this.reward, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('M月d日 HH:mm').format(reward.earnedAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        title: Text(rewardSourceLabel(reward.source),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${reward.note ?? ''}  ·  $timeStr',
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text('+${formatter(reward.stars)} ⭐',
            style: const TextStyle(
                fontSize: 13,
                color: Colors.orange,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
