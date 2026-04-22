import '../models/study_plan.dart';
import 'database_helper.dart';

class PlanDao {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> insert(StudyPlan plan) async {
    final db = await _db.database;
    return db.insert('study_plans', plan.toMap());
  }

  Future<int> update(StudyPlan plan) async {
    final db = await _db.database;
    return db.update('study_plans', plan.toMap(), where: 'id = ?', whereArgs: [plan.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('study_plans', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<StudyPlan>> getByDate(DateTime date) async {
    final db = await _db.database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final maps = await db.query(
      'study_plans',
      where: "due_date LIKE ?",
      whereArgs: ['$dateStr%'],
      orderBy: 'due_date ASC',
    );
    return maps.map(StudyPlan.fromMap).toList();
  }

  Future<List<StudyPlan>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _db.database;
    final maps = await db.query(
      'study_plans',
      where: 'due_date >= ? AND due_date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'due_date ASC',
    );
    return maps.map(StudyPlan.fromMap).toList();
  }

  Future<List<StudyPlan>> getOverdue() async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'study_plans',
      where: 'due_date < ? AND status = ?',
      whereArgs: [now, PlanStatus.pending.index],
    );
    return maps.map(StudyPlan.fromMap).toList();
  }

  Future<int> updateStatus(int id, PlanStatus status) async {
    final db = await _db.database;
    return db.update(
      'study_plans',
      {'status': status.index},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<StudyPlan>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('study_plans', orderBy: 'due_date DESC');
    return maps.map(StudyPlan.fromMap).toList();
  }
}
