import 'package:flutter/foundation.dart';
import '../models/study_plan.dart';
import '../database/plan_dao.dart';

class PlanService extends ChangeNotifier {
  final PlanDao _dao = PlanDao();

  List<StudyPlan> _plansForDate = [];
  List<StudyPlan> _allPlans = [];

  List<StudyPlan> get plansForDate => _plansForDate;
  List<StudyPlan> get allPlans => _allPlans;

  PlanService() {
    _init();
  }

  Future<void> _init() async {
    await loadDate(DateTime.now());
    _allPlans = await _dao.getAll();
    notifyListeners();
  }

  Future<void> loadDate(DateTime date) async {
    _plansForDate = await _dao.getByDate(date);
    notifyListeners();
  }

  Future<void> addPlan(StudyPlan plan) async {
    await _dao.insert(plan);
    _allPlans = await _dao.getAll();
    await loadDate(plan.dueDate);
  }

  Future<void> markComplete(StudyPlan plan) async {
    await _dao.updateStatus(plan.id!, PlanStatus.completed);
    _allPlans = await _dao.getAll();
    await loadDate(plan.dueDate);
  }

  Future<void> deletePlan(StudyPlan plan) async {
    await _dao.delete(plan.id!);
    _allPlans = await _dao.getAll();
    await loadDate(plan.dueDate);
  }

  Future<List<StudyPlan>> getWeekPlans(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return _dao.getByDateRange(weekStart, weekEnd);
  }

  Future<List<StudyPlan>> getOverdue() => _dao.getOverdue();
}
