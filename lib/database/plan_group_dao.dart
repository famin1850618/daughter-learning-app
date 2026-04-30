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

  Future<PlanGroup?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query('plan_groups', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : PlanGroup.fromMap(rows.first);
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
    final rows = await db.rawQuery(
      'SELECT DISTINCT pg.start_date FROM plan_groups pg '
      'INNER JOIN plan_items pi ON pi.day_plan_id = pg.id '
      'WHERE pg.type = ?',
      [PlanGroupType.day.index]);
    return rows.map((r) => r['start_date'] as String).toSet();
  }

  /// 某日的独立日计划（parentId IS NULL）
  Future<PlanGroup?> getStandaloneDayPlan(DateTime date) async {
    final db = await _db.database;
    final dateStr = PlanDateUtils.dateOnly(date).toIso8601String().substring(0, 10);
    final rows = await db.rawQuery(
        'SELECT * FROM plan_groups WHERE type = ? AND start_date = ? AND parent_id IS NULL',
        [PlanGroupType.day.index, dateStr]);
    return rows.isEmpty ? null : PlanGroup.fromMap(rows.first);
  }

  /// 某父计划下某天的子日计划
  Future<PlanGroup?> getChildDayPlan(int parentId, DateTime date) async {
    final db = await _db.database;
    final dateStr = PlanDateUtils.dateOnly(date).toIso8601String().substring(0, 10);
    final rows = await db.query('plan_groups',
        where: 'type = ? AND parent_id = ? AND start_date = ?',
        whereArgs: [PlanGroupType.day.index, parentId, dateStr]);
    return rows.isEmpty ? null : PlanGroup.fromMap(rows.first);
  }

  /// 月计划下包含某天的周计划
  Future<PlanGroup?> getChildWeekForDate(int monthId, DateTime date) async {
    final db = await _db.database;
    final dateStr = PlanDateUtils.dateOnly(date).toIso8601String().substring(0, 10);
    final rows = await db.query('plan_groups',
        where: 'type = ? AND parent_id = ? AND start_date <= ? AND end_date >= ?',
        whereArgs: [PlanGroupType.week.index, monthId, dateStr, dateStr]);
    return rows.isEmpty ? null : PlanGroup.fromMap(rows.first);
  }

  /// 检查周计划范围是否与已有周计划重叠
  Future<bool> hasOverlappingWeekPlan(DateTime start, DateTime end) async {
    final db = await _db.database;
    final s = PlanDateUtils.dateOnly(start).toIso8601String().substring(0, 10);
    final e = PlanDateUtils.dateOnly(end).toIso8601String().substring(0, 10);
    final rows = await db.query('plan_groups',
        where: 'type = ? AND start_date <= ? AND end_date >= ?',
        whereArgs: [PlanGroupType.week.index, e, s]);
    return rows.isNotEmpty;
  }

  /// 检查月计划范围是否与已有月计划重叠
  Future<bool> hasOverlappingMonthPlan(DateTime start, DateTime end) async {
    final db = await _db.database;
    final s = PlanDateUtils.dateOnly(start).toIso8601String().substring(0, 10);
    final e = PlanDateUtils.dateOnly(end).toIso8601String().substring(0, 10);
    final rows = await db.query('plan_groups',
        where: 'type = ? AND start_date <= ? AND end_date >= ?',
        whereArgs: [PlanGroupType.month.index, e, s]);
    return rows.isNotEmpty;
  }
}
