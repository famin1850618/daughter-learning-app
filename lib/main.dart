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
import 'services/learning_sync_service.dart';
import 'services/difficulty_settings_service.dart';
import 'models/question.dart';
import 'models/subject.dart';
import 'database/curriculum_dao.dart';
import 'database/curriculum_seed.dart';
import 'database/knowledge_point_dao.dart';
import 'database/knowledge_points_seed.dart';

/// 内置题包路径（assets 首装兜底）—— 历版累积，cron 扩题后追加
const _bundledBatchAssets = [
  'assets/data/batches/batch_2026_05_06_g6_math.json',
  'assets/data/batches/batch_2026_05_06_g6_chinese.json',
  'assets/data/batches/batch_2026_05_06_g6_english.json',
  'assets/data/batches/batch_2026_05_07_g6_math_r2.json',
  'assets/data/batches/batch_2026_05_07_g6_chinese_r2.json',
  'assets/data/batches/batch_2026_05_07_g6_english_r2.json',
  'assets/data/batches/batch_2026_05_07_g6_math_r3.json',
  'assets/data/batches/batch_2026_05_07_g6_chinese_r3.json',
  'assets/data/batches/batch_2026_05_07_g6_english_r3.json',
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
  final _planService = PlanService();
  final _syncService = LearningSyncService();
  final _difficultySettings = DifficultySettingsService();

  bool _wasPracticeActive = false;
  int _lastSessionScore = 0;
  int _lastSessionTotal = 0;
  List<Question> _lastSessionQuestions = const [];

  @override
  void initState() {
    super.initState();
    _rewardService = RewardService()..refresh();
    // 立即创建 PracticeService，触发 session 恢复（V3.8 注入 DifficultySettings）
    _practiceService = PracticeService(_rewardService, _difficultySettings);
    _assessmentService = AssessmentService()..refresh();

    // session 状态变化监听：snapshot 当前数据 + 完成时触发自动完成 + 学情同步
    _practiceService.addListener(_onPracticeChanged);

    // 启动后异步触发一次更新检查 + 学情同步（不阻塞 UI；离线静默失败）
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_updateService.autoCheck) {
        await _updateService.checkAndImport(silent: true);
      }
      await _syncService.syncIfDue();
    });
  }

  void _onPracticeChanged() {
    // 持续 snapshot 当前 session 状态：当 active=false 时这些值是"刚结束的会话"
    if (_practiceService.sessionActive) {
      _lastSessionScore = _practiceService.score;
      _lastSessionTotal = _practiceService.currentQuestions.length;
      _lastSessionQuestions = List.of(_practiceService.currentQuestions);
    }
    final nowActive = _practiceService.sessionActive;
    if (_wasPracticeActive && !nowActive) {
      // 用快照里的最终值（endSession 后这些被清空）
      final score = _lastSessionScore;
      final total = _lastSessionTotal;
      final questions = _lastSessionQuestions;
      // 1. 计划自动完成（≥80% 通过）
      if (total > 0 && score / total >= 0.8 && questions.isNotEmpty) {
        final tuples = questions
            .map((q) => PracticeKpTuple(
                  subjectName: q.subject.displayName,
                  grade: q.grade,
                  chapter: q.chapter,
                  knowledgePoint: q.knowledgePoint,
                ))
            .toList();
        _planService.autoCompleteFromPractice(
          score: score,
          total: total,
          coveredTuples: tuples,
        ).then((marked) {
          if (marked > 0) {
            // 计划状态变更后立即重算测评解锁
            _assessmentService.refresh();
          }
        });
      }
      // 2. 学情同步
      _syncService.syncIfDue();
    }
    _wasPracticeActive = nowActive;
  }

  @override
  void dispose() {
    _practiceService.removeListener(_onPracticeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationService()),
        ChangeNotifierProvider(create: (_) => PlanSettingsService()),
        ChangeNotifierProvider.value(value: _planService),
        ChangeNotifierProvider.value(value: _rewardService),
        ChangeNotifierProvider.value(value: _practiceService),
        ChangeNotifierProvider.value(value: _assessmentService),
        ChangeNotifierProvider.value(value: _updateService),
        ChangeNotifierProvider.value(value: _syncService),
        ChangeNotifierProvider.value(value: _difficultySettings),
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
