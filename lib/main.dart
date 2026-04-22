import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'utils/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/review_screen.dart';
import 'screens/reward_screen.dart';
import 'services/plan_service.dart';
import 'services/practice_service.dart';
import 'database/question_dao.dart';
import 'database/curriculum_dao.dart';
import 'database/seed_data.dart';
import 'database/curriculum_seed.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  await _seedDatabase();
  runApp(const LearningApp());
}

Future<void> _seedDatabase() async {
  // 课程体系种子数据
  final curriculumDao = CurriculumDao();
  if (await curriculumDao.isEmpty()) {
    await curriculumDao.insertBatch(curriculumChapters);
  }

  // 题库种子数据
  final questionDao = QuestionDao();
  final existing = await questionDao.getRandom(
    subject: grade6SeedQuestions.first.subject,
    grade: 6,
    limit: 1,
  );
  if (existing.isEmpty) {
    await questionDao.insertBatch(grade6SeedQuestions);
  }
}

class LearningApp extends StatelessWidget {
  const LearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlanService()),
        ChangeNotifierProvider(create: (_) => PracticeService()),
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

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    PlanScreen(),
    PracticeScreen(),
    ReviewScreen(),
    RewardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
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
