import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'utils/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/review_screen.dart';
import 'screens/reward_screen.dart';
import 'services/plan_service.dart';
import 'services/plan_settings_service.dart';
import 'services/navigation_service.dart';
import 'services/practice_service.dart';
import 'services/question_update_service.dart';
import 'services/reward_service.dart';
import 'services/assessment_service.dart';
import 'database/curriculum_dao.dart';
import 'database/curriculum_seed.dart';
import 'database/knowledge_point_dao.dart';
import 'database/knowledge_points_seed.dart';

/// V3.6 起内置题包路径（assets 首装兜底）
const _bundledBatchAssets = [
  'assets/data/batches/batch_2026_05_06_g6_math.json',
  'assets/data/batches/batch_2026_05_06_g6_chinese.json',
  'assets/data/batches/batch_2026_05_06_g6_english.json',
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  await _seedDatabase();
  runApp(const LearningApp());
}

Future<void> _seedDatabase() async {
  // 1. 课程章节（保持原逻辑）
  final curriculumDao = CurriculumDao();
  if (await curriculumDao.isEmpty()) {
    await curriculumDao.insertBatch(curriculumChapters);
  }

  // 2. KP 清单（六下三科种子；幂等）
  await KnowledgePointDao().insertIfMissing(knowledgePointsSeed);

  // 3. 题包（assets 首装兜底；按 source 幂等，已装则跳过）
  final updateService = QuestionUpdateService();
  for (final asset in _bundledBatchAssets) {
    try {
      final json = await rootBundle.loadString(asset);
      await updateService.importBatchJsonString(json);
    } catch (e) {
      debugPrint('Failed to load $asset: $e');
    }
  }
}

class LearningApp extends StatefulWidget {
  const LearningApp({super.key});

  @override
  State<LearningApp> createState() => _LearningAppState();
}

class _LearningAppState extends State<LearningApp> {
  final _updateService = QuestionUpdateService();
  late final RewardService _rewardService;
  late final PracticeService _practiceService;
  late final AssessmentService _assessmentService;

  @override
  void initState() {
    super.initState();
    _rewardService = RewardService()..refresh();
    // 立即创建 PracticeService，触发 session 恢复
    _practiceService = PracticeService(_rewardService);
    _assessmentService = AssessmentService()..refresh();

    // 启动后异步触发一次更新检查（不阻塞 UI；离线静默失败）
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_updateService.autoCheck) {
        await _updateService.checkAndImport(silent: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationService()),
        ChangeNotifierProvider(create: (_) => PlanSettingsService()),
        ChangeNotifierProvider(create: (_) => PlanService()),
        ChangeNotifierProvider.value(value: _rewardService),
        ChangeNotifierProvider.value(value: _practiceService),
        ChangeNotifierProvider.value(value: _assessmentService),
        ChangeNotifierProvider.value(value: _updateService),
      ],
      child: MaterialApp(
        title: '学习小助手',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        locale: const Locale('zh', 'CN'),
        home: const MainNavigation(),
      ),
    );
  }
}

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    PlanScreen(),
    PracticeScreen(),
    ReviewScreen(),
    RewardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationService>();
    return Scaffold(
      body: IndexedStack(index: nav.index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: nav.index,
        onTap: (i) {
          // 切到「成效」tab 时刷新测评解锁状态（计划完成后即时反映）
          if (i == 3) context.read<AssessmentService>().refresh();
          context.read<NavigationService>().goTo(i);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: '计划'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: '练习'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: '成效'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: '奖励'),
        ],
      ),
    );
  }
}
