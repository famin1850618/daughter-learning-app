import '../models/plan_group.dart';
import '../utils/plan_date_utils.dart';
import 'database_helper.dart';

class PlanGroupDao {
  final _db = DatabaseHelper();

  Future<int> insert(PlanGroup g) async {
    final db = await _db.database;
    return db.insert('plan_groups', g.toMap());
  }

  Future<void> insertBatch(List<PlanGroup> groups) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final g in groups) {
      batch.insert('plan_groups', g.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateStatus(int id, PlanGroupStatus status) async {
    final db = await _db.database;
    await db.update('plan_groups', {'status': status.index},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('plan_groups', where: 'id = ?', whereArgs: [id]);
  }

  /// 找某天所属的日计划列表
  Future<List<PlanGroup>> getDayPlansForDate(DateTime date) async {
    final db = await _db.database;
    final dateStr = PlanDateUtils.dateOnly(date).toIso8601String().substring(0, 10);
    final rows = await db.query('plan_groups',
        where: 'type = ? AND start_date = ?',
        whereArgs: [PlanGroupType.day.index, dateStr],
        orderBy: 'created_at ASC');
    return rows.map(PlanGroup.fromMap).toList();
  }

  /// 找包含某天的周计划
  Future<List<PlanGroup>> getWeekPlansForDate(DateTime date) async {
    final db = await _db.database;
    final dateStr = PlanDateUtils.dateOnly(date).toIso8601String().substring(0, 10);
    final rows = await db.query('plan_groups',
        where: 'type = ? AND start_date <= ? AND end_date >= ?',
        whereArgs: [PlanGroupType.week.index, dateStr, dateStr]);
    return rows.map(PlanGroup.fromMap).toList();
  }

  /// 找包含某天的月计划
  Future<List<PlanGroup>> getMonthPlansForDate(DateTime date) async {
    final db = await _db.database;
    final dateStr = PlanDateUtils.dateOnly(date).toIso8601String().substring(0, 10);
    final rows = await db.query('plan_groups',
        where: 'type = ? AND start_date <= ? AND end_date >= ?',
        whereArgs: [PlanGroupType.month.index, dateStr, dateStr]);
    return rows.map(PlanGroup.fromMap).toList();
  }

  /// 某 parent_id 下的所有子计划
  Future<List<PlanGroup>> getChildren(int parentId) async {
    final db = await _db.database;
    final rows = await db.query('plan_groups',
        where: 'parent_id = ?',
        whereArgs: [parentId],
        orderBy: 'start_date ASC');
    return rows.map(PlanGroup.fromMap).toList();
  }

  /// 获取所有有计划的日期（用于日历标记）
  Future<Set<String>> getDatesWithPlans() async {
    final db = await _db.database;
    final rows = await db.query('plan_groups',
        columns: ['start_date'],
        where: 'type = ?',
        whereArgs: [PlanGroupType.day.index]);
    return rows.map((r) => r['start_date'] as String).toSet();
  }
}
