import '../models/plan_group.dart';
import '../utils/plan_date_utils.dart';
import 'database_helper.dart';

class PlanItemSchedule {
  final PlanItem item;
  final DateTime scheduledDate;

  const PlanItemSchedule({
    required this.item,
    required this.scheduledDate,
  });
}

class PlanItemDao {
  final _db = DatabaseHelper();

  Future<void> insertBatch(List<PlanItem> items) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert('plan_items', item.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> markComplete(int id) async {
    final db = await _db.database;
    await db.update(
        'plan_items',
        {
          'status': PlanItemStatus.completed.index,
          'completed_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  Future<void> markPending(int id) async {
    final db = await _db.database;
    await db.update(
        'plan_items',
        {
          'status': PlanItemStatus.pending.index,
          'completed_at': null,
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  /// V3.28: 所有 pending plan items（任意日期）。用于练习自动完成——
  /// 计划允许提前完成，故不应只看今天（Famin 2026-06-18）。
  Future<List<PlanItem>> getAllPending() async {
    final db = await _db.database;
    final rows = await db.query('plan_items',
        where: 'status = ?',
        whereArgs: [PlanItemStatus.pending.index],
        orderBy: 'id ASC');
    return rows.map(PlanItem.fromMap).toList();
  }

  /// Pending items whose scheduled day is before [date].
  Future<List<PlanItemSchedule>> getPendingBeforeDate(DateTime date) async {
    final db = await _db.database;
    final dateStr =
        PlanDateUtils.dateOnly(date).toIso8601String().substring(0, 10);
    final rows = await db.rawQuery('''
      SELECT pi.*, pg.start_date AS scheduled_date
      FROM plan_items pi
      JOIN plan_groups pg ON pg.id = pi.day_plan_id
      WHERE pi.status = ?
        AND pg.type = ?
        AND pg.start_date < ?
      ORDER BY pg.start_date ASC, pi.id ASC
    ''', [PlanItemStatus.pending.index, PlanGroupType.day.index, dateStr]);
    return rows
        .map((row) => PlanItemSchedule(
              item: PlanItem.fromMap(row),
              scheduledDate: DateTime.parse(row['scheduled_date'] as String),
            ))
        .toList();
  }

  Future<List<PlanItem>> getByDayPlanId(int dayPlanId) async {
    final db = await _db.database;
    final rows = await db.query('plan_items',
        where: 'day_plan_id = ?', whereArgs: [dayPlanId], orderBy: 'id ASC');
    return rows.map(PlanItem.fromMap).toList();
  }

  /// 批量获取多个日计划的 items
  Future<Map<int, List<PlanItem>>> getByDayPlanIds(List<int> ids) async {
    if (ids.isEmpty) return {};
    final db = await _db.database;
    final placeholders = ids.map((_) => '?').join(',');
    final rows = await db.rawQuery(
        'SELECT * FROM plan_items WHERE day_plan_id IN ($placeholders) ORDER BY id ASC',
        ids);
    final map = <int, List<PlanItem>>{};
    for (final row in rows) {
      final item = PlanItem.fromMap(row);
      map.putIfAbsent(item.dayPlanId, () => []).add(item);
    }
    return map;
  }

  /// 某月/周计划下所有 items（通过 origin 字段）
  Future<List<PlanItem>> getByOriginMonthPlan(int monthPlanId) async {
    final db = await _db.database;
    final rows = await db.query('plan_items',
        where: 'origin_month_plan_id = ?', whereArgs: [monthPlanId]);
    return rows.map(PlanItem.fromMap).toList();
  }

  Future<List<PlanItem>> getByOriginWeekPlan(int weekPlanId) async {
    final db = await _db.database;
    final rows = await db.query('plan_items',
        where: 'origin_week_plan_id = ?', whereArgs: [weekPlanId]);
    return rows.map(PlanItem.fromMap).toList();
  }

  /// 日期范围内所有 plan_items（fallback：当 origin 字段未挂时用日期）
  Future<List<PlanItem>> getInDateRange(DateTime start, DateTime end) async {
    final db = await _db.database;
    final s = start.toIso8601String().substring(0, 10);
    final e = end.toIso8601String().substring(0, 10);
    final rows = await db.rawQuery('''
      SELECT pi.* FROM plan_items pi
      JOIN plan_groups pg ON pg.id = pi.day_plan_id
      WHERE pg.type = 0 AND pg.start_date >= ? AND pg.start_date <= ?
    ''', [s, e]);
    return rows.map(PlanItem.fromMap).toList();
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('plan_items', where: 'id = ?', whereArgs: [id]);
  }

  /// 批量更新所属日计划（用于任务移转）
  Future<void> moveToDayPlan(List<int> itemIds, int newDayPlanId) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final id in itemIds) {
      batch.update('plan_items', {'day_plan_id': newDayPlanId},
          where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  /// Move items into a new plan container and rewrite their origin metadata.
  Future<void> moveToContainer(
    List<int> itemIds,
    int newDayPlanId, {
    int? originWeekPlanId,
    int? originMonthPlanId,
  }) async {
    if (itemIds.isEmpty) return;
    final db = await _db.database;
    final batch = db.batch();
    for (final id in itemIds) {
      batch.update(
          'plan_items',
          {
            'day_plan_id': newDayPlanId,
            'origin_week_plan_id': originWeekPlanId,
            'origin_month_plan_id': originMonthPlanId,
          },
          where: 'id = ?',
          whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  /// 章节在哪些月/周/日计划中（首页展示用）
  Future<List<PlanItem>> getByChapterId(int chapterId) async {
    final db = await _db.database;
    final rows = await db
        .query('plan_items', where: 'chapter_id = ?', whereArgs: [chapterId]);
    return rows.map(PlanItem.fromMap).toList();
  }
}
