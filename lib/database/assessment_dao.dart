import '../models/assessment.dart';
import 'database_helper.dart';

class AssessmentDao {
  Future<int> upsert(Assessment a) async {
    final db = await DatabaseHelper().database;
    return db.insert('assessments', a.toMap());
  }

  Future<Assessment?> getLatest(AssessmentType type, String periodKey) async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('assessments',
        where: 'type = ? AND period_key = ?',
        whereArgs: [type.index, periodKey],
        orderBy: 'id DESC',
        limit: 1);
    return rows.isEmpty ? null : Assessment.fromMap(rows.first);
  }

  Future<List<Assessment>> getAll() async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('assessments', orderBy: 'id DESC');
    return rows.map(Assessment.fromMap).toList();
  }

  Future<void> deleteAll() async {
    final db = await DatabaseHelper().database;
    await db.delete('assessments');
  }
}
