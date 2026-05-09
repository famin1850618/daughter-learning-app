import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/initial_sync_screen.dart';
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
import 'services/review_request_service.dart';
import 'services/data_reset_service.dart';
import 'services/diagnostic_service.dart';
import 'database/question_dao.dart';
import 'models/question.dart';
import 'models/subject.dart';
import 'database/curriculum_dao.dart';
import 'database/curriculum_seed.dart';
import 'database/knowledge_point_dao.dart';
import 'database/knowledge_points_seed.dart';
import 'database/cambridge_english_kp_seed.dart';

// V3.12.11 起：题库不再 bundled，由 InitialSyncScreen / 后台 silent sync 从 CDN 拉。
// V3.12.21（2026-05-09 晚）：Famin 决定全清旧库重新基于深圳真题源（217 docx）扫起。
// lib/data/bundled_batches.dart 已删除（V3.12.11 已废弃 + 本轮全清孤儿）。

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  await _seedDatabase();
  // V3.12.11 CDN-first：题库 0 题（首次装 / 强制刷新后）→ 走 InitialSyncScreen
  // 阻塞拉云端最新；失败显示重试。否则正常进 LearningApp（后台 silent sync）。
  final qCount = await QuestionDao().count();
  // 注册回调让 InitialSyncScreen 完成后切到 LearningApp
  launchMainAppCallback = () => runApp(const LearningApp());
  runApp(qCount == 0 ? const InitialSyncApp() : const LearningApp());
}

Future<void> _seedDatabase() async {
  // 1. 课程章节（V3.10：fresh install 走 batch insert；老用户走增量 insertIfMissing 补 22 chapter）
  final curriculumDao = CurriculumDao();
  if (await curriculumDao.isEmpty()) {
    await curriculumDao.insertBatch(curriculumChapters);
  } else {
    await curriculumDao.insertIfMissing(curriculumChapters);
  }

  // 2. KP 清单（六下三科种子 + V3.9 Cambridge 英语；幂等）
  await KnowledgePointDao().insertIfMissing(knowledgePointsSeed);
  await KnowledgePointDao().insertIfMissing(cambridgeEnglishKpSeed);

  // 3. V3.12.11 起：题库不再 bundled，由 InitialSyncApp / 后台 silent sync 从 CDN 拉
  // 删除 bundled 内置后 APK 体积更小，避免 V3.10-V3.12.10 双数据源逻辑混乱。

  // 4. V3.11：清理过期归档（>7 天）
  final resetService = DataResetService();
  await resetService.gcExpiredArchives();

  // 5. V3.11 升级首次启动自动清零（试题期间累积数据 → 归档 + 清空）
  // 一次性触发，标记位 'v311_auto_reset_done'。已触发过的设备不再清零。
  // 用户后续可在设置页主动重置；归档 7 天内可回滚。
  final prefs = await SharedPreferences.getInstance();
  if (!(prefs.getBool('v311_auto_reset_done') ?? false)) {
    final batchId = await resetService.resetAllProgress(
      reason: 'V3.11 升级自动清零（试题期间累积数据）',
    );
    if (batchId != null) {
      debugPrint('V3.11 auto-reset succeeded: $batchId');
    }
    await prefs.setBool('v311_auto_reset_done', true);
  }

  // 6. V3.12.9_fix: 启动 self-check（diagnostic service）
  // 检查 DB version / 题数 by subject / source 状态 / 关键字段健康
  // 错误存到 ErrorLog（设置页诊断面板可查 + 可导出）
  try {
    await DiagnosticService().runStartupSelfCheck();
  } catch (e, stack) {
    await DiagnosticService().logError(
      level: 'error', context: 'startup_self_check',
      error: e, stack: stack,
    );
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
  late final ReviewRequestService _reviewService;
  late final PracticeService _practiceService;
  late final AssessmentService _assessmentService;
  final _planService = PlanService();
  final _syncService = LearningSyncService();
  final _difficultySettings = DifficultySettingsService();
  final _questionDao = QuestionDao();

  bool _wasPracticeActive = false;
  int _lastSessionScore = 0;
  int _lastSessionTotal = 0;
  List<Question> _lastSessionQuestions = const [];

  @override
  void initState() {
    super.initState();
    _rewardService = RewardService()..refresh();
    _reviewService = ReviewRequestService(_rewardService)..refresh();
    // V3.8.3: 审核通过后副作用编排（重判 session 通过 + 重打钩计划 + 测评刷新）
    _reviewService.onApproved = _handleReviewApproved;
    // 立即创建 PracticeService，触发 session 恢复（V3.8 注入 DifficultySettings、V3.8.3 注入 ReviewService）
    _practiceService = PracticeService(_rewardService, _difficultySettings, _reviewService);
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

  /// V3.8.3: 审核通过后副作用编排
  /// - 重判 session 通过状态 → 补发通过/满分加成
  /// - 重新触发计划自动完成
  /// - 测评刷新 + 学情同步
  Future<void> _handleReviewApproved(ApproveContext ctx) async {
    final sessionId = ctx.sessionId;
    if (sessionId != null) {
      // 1) session 加成补发（如果之前没发过）
      final hasBonus = await _rewardService.hasBonusForSession(sessionId);
      if (!hasBonus) {
        final ss = await _questionDao.getSessionScore(sessionId);
        if (ss.total > 0) {
          SessionKind kind;
          if (sessionId.startsWith('weeklyTest:')) {
            kind = SessionKind.weeklyTest;
          } else if (sessionId.startsWith('monthlyTest:')) {
            kind = SessionKind.monthlyTest;
          } else {
            kind = SessionKind.normal;
          }
          await _rewardService.recordBonusOnly(
            kind: kind,
            score: ss.score,
            total: ss.total,
            sessionId: sessionId,
          );
        }
      }

      // 2) 计划自动完成 / 测评刷新
      final tuples = await _questionDao.getSessionKpTuples(sessionId);
      if (tuples.isNotEmpty) {
        final ss = await _questionDao.getSessionScore(sessionId);
        final coveredTuples = tuples.map((row) {
          final subjIdx = row['subject'] as int;
          return PracticeKpTuple(
            subjectName: Subject.values[subjIdx].displayName,
            grade: row['grade'] as int,
            chapter: row['chapter'] as String,
            knowledgePoint: row['knowledge_point'] as String?,
          );
        }).toList();
        final marked = await _planService.autoCompleteFromPractice(
          score: ss.score,
          total: ss.total,
          coveredTuples: coveredTuples,
        );
        if (marked > 0) {
          await _assessmentService.refresh();
        }
      }
    }

    // 3) 学情同步
    await _syncService.syncIfDue();
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
        ChangeNotifierProvider.value(value: DiagnosticService()),
        ChangeNotifierProvider.value(value: _reviewService),
        ChangeNotifierProvider<DataResetService>.value(value: DataResetService()),
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
