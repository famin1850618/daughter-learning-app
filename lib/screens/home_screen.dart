import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../models/subject.dart';
import '../services/plan_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanService>().loadDate(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('学习小助手'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GreetingCard(),
            const SizedBox(height: 16),
            _TodayPlanCard(),
            const SizedBox(height: 16),
            _SubjectGrid(),
          ],
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? '早上好' : hour < 18 ? '下午好' : '晚上好';
    return Card(
      color: AppTheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('🌟', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting，加油！',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('今天也要认真学习哦~',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayPlanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final plans = context.watch<PlanService>().plansForDate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('今日计划', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (plans.isEmpty)
              const Text('今天还没有计划，去添加一个吧！', style: TextStyle(color: Colors.grey))
            else
              ...plans.take(3).map((p) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(p.subject.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(p.title),
                trailing: Icon(
                  p.status.index == 2 ? Icons.check_circle : Icons.circle_outlined,
                  color: p.status.index == 2 ? AppTheme.success : Colors.grey,
                ),
              )),
          ],
        ),
      ),
    );
  }
}

class _SubjectGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const grade = 6;
    final subjects = Subject.values.where((s) => s.isAvailableForGrade(grade)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('科目', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: subjects.map((s) => Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {},
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 4),
                  Text(s.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}
