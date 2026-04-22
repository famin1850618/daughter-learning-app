import 'package:flutter/foundation.dart';
import '../models/study_plan.dart';
import '../database/plan_dao.dart';

class PlanService extends ChangeNotifier {
  final PlanDao _dao = PlanDao();

  List<StudyPlan> _plansForDate = [];
  List<StudyPlan> get plansForDate => _plansForDate;

  Future<void> loadDate(DateTime date) async {
    _plansForDate = await _dao.getByDate(date);
    notifyListeners();
  }

  Future<void> addPlan(StudyPlan plan) async {
    await _dao.insert(plan);
    await loadDate(plan.dueDate);
  }

  Future<void> markComplete(StudyPlan plan) async {
    await _dao.updateStatus(plan.id!, PlanStatus.completed);
    await loadDate(plan.dueDate);
  }

  Future<void> deletePlan(StudyPlan plan) async {
    await _dao.delete(plan.id!);
    await loadDate(plan.dueDate);
  }

  Future<List<StudyPlan>> getWeekPlans(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return _dao.getByDateRange(weekStart, weekEnd);
  }

  Future<List<StudyPlan>> getOverdue() => _dao.getOverdue();
}
