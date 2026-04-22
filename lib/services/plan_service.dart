import 'package:flutter/foundation.dart';
import '../models/plan_group.dart';
import '../database/plan_group_dao.dart';
import '../database/plan_item_dao.dart';
import '../utils/plan_date_utils.dart';

// Snapshot of a single date's plan state across all three levels
class DayPlanSnapshot {
  final DateTime date;
  final PlanGroup? standaloneDayPlan; // independent day plan (parentId IS NULL)
  final PlanGroup? weekPlan;          // week plan covering date
  final PlanGroup? weekDayPlan;       // day plan under weekPlan for date
  final PlanGroup? monthPlan;         // month plan covering date
  final PlanGroup? monthWeekPlan;     // week plan under monthPlan covering date
  final PlanGroup? monthDayPlan;      // day plan under monthWeekPlan for date

  const DayPlanSnapshot({
    required this.date,
    this.standaloneDayPlan,
    this.weekPlan,
    this.weekDayPlan,
    this.monthPlan,
    this.monthWeekPlan,
    this.monthDayPlan,
  });

  bool get hasAnyPlan => standaloneDayPlan != null || weekPlan != null || monthPlan != null;
  bool get hasDayPlan => standaloneDayPlan != null;
  bool get hasWeekPlan => weekPlan != null;
  bool get hasMonthPlan => monthPlan != null;

  List<PlanItem> get dayItems => standaloneDayPlan?.items ?? [];
  List<PlanItem> get weekItems => weekDayPlan?.items ?? [];
  List<PlanItem> get monthItems => monthDayPlan?.items ?? [];
}

class PlanService extends ChangeNotifier {
  final _groupDao = PlanGroupDao();
  final _itemDao = PlanItemDao();

  DateTime _selectedDate = PlanDateUtils.dateOnly(DateTime.now());
  List<PlanGroup> _dayPlans = [];
  List<PlanGroup> _weekPlans = [];
  List<PlanGroup> _monthPlans = [];
  Set<String> _markedDates = {};

  List<PlanGroup> get dayPlans => _dayPlans;
  List<PlanGroup> get weekPlans => _weekPlans;
  List<PlanGroup> get monthPlans => _monthPlans;
  Set<String> get markedDates => _markedDates;

  List<PlanItem> get todayItems =>
      _dayPlans.expand((g) => g.items).toList();

  bool get selectedDateHasPlans =>
      _dayPlans.isNotEmpty || _weekPlans.isNotEmpty || _monthPlans.isNotEmpty;

  PlanService() {
    _init();
  }

  Future<void> _init() async {
    _markedDates = await _groupDao.getDatesWithPlans();
    await loadDate(DateTime.now());
  }

  Future<void> loadDate(DateTime date) async {
    _selectedDate = PlanDateUtils.dateOnly(date);

    final dayGroups = await _groupDao.getDayPlansForDate(date);
    final weekGroups = await _groupDao.getWeekPlansForDate(date);
    final monthGroups = await _groupDao.getMonthPlansForDate(date);

    if (dayGroups.isNotEmpty) {
      final ids = dayGroups.map((g) => g.id!).toList();
      final itemMap = await _itemDao.getByDayPlanIds(ids);
      for (final g in dayGroups) {
        g.items = itemMap[g.id] ?? [];
      }
    }

    for (final wg in weekGroups) {
      final children = await _groupDao.getChildren(wg.id!);
      if (children.isNotEmpty) {
        final childIds = children.map((c) => c.id!).toList();
        final itemMap = await _itemDao.getByDayPlanIds(childIds);
        for (final c in children) {
          c.items = itemMap[c.id] ?? [];
        }
      }
      wg.children = children;
    }

    for (final mg in monthGroups) {
      final weeks = await _groupDao.getChildren(mg.id!);
      for (final wg in weeks) {
        final days = await _groupDao.getChildren(wg.id!);
        if (days.isNotEmpty) {
          final dayIds = days.map((d) => d.id!).toList();
          final itemMap = await _itemDao.getByDayPlanIds(dayIds);
          for (final d in days) {
            d.items = itemMap[d.id] ?? [];
          }
        }
        wg.children = days;
      }
      mg.children = weeks;
    }

    _dayPlans = dayGroups;
    _weekPlans = weekGroups;
    _monthPlans = monthGroups;
    notifyListeners();
  }

  // ── Creation ─────────────────────────────────

  Future<void> createDayPlan(DateTime date, List<PlanItemDraft> drafts) async {
    final now = DateTime.now();
    final d = PlanDateUtils.dateOnly(date);
    final dayId = await _groupDao.insert(PlanGroup(
      type: PlanGroupType.day,
      startDate: d,
      endDate: d,
      createdAt: now,
    ));
    await _itemDao.insertBatch(
        drafts.map((dr) => _draftToItem(dr, dayPlanId: dayId)).toList());
    _markedDates.add(d.toIso8601String().substring(0, 10));
    await loadDate(_selectedDate);
  }

  /// Week plan starts from startDate (not from Monday — only future days)
  Future<void> createWeekPlan(DateTime startDate, List<PlanItemDraft> drafts) async {
    final now = DateTime.now();
    final ws = PlanDateUtils.dateOnly(startDate);
    final we = PlanDateUtils.weekEnd(startDate);

    final weekId = await _groupDao.insert(PlanGroup(
      type: PlanGroupType.week,
      startDate: ws,
      endDate: we,
      createdAt: now,
    ));

    final days = PlanDateUtils.daysInRange(ws, we);
    final distributed = PlanDateUtils.autoDistribute(drafts, days.length);

    for (var i = 0; i < days.length; i++) {
      if (distributed[i].isEmpty) continue;
      final dayId = await _groupDao.insert(PlanGroup(
        type: PlanGroupType.day,
        parentId: weekId,
        startDate: days[i],
        endDate: days[i],
        createdAt: now,
      ));
      await _itemDao.insertBatch(distributed[i]
          .map((d) => _draftToItem(d, dayPlanId: dayId, weekId: weekId))
          .toList());
      _markedDates.add(days[i].toIso8601String().substring(0, 10));
    }

    await loadDate(_selectedDate);
  }

  Future<void> createMonthPlan(DateTime startDate, List<PlanItemDraft> drafts) async {
    final now = DateTime.now();
    final ms = PlanDateUtils.dateOnly(startDate);
    final me = PlanDateUtils.monthPlanEnd(startDate);

    final monthId = await _groupDao.insert(PlanGroup(
      type: PlanGroupType.month,
      startDate: ms,
      endDate: me,
      createdAt: now,
    ));

    final weeks = PlanDateUtils.splitIntoWeeks(ms, me);
    final byWeek = PlanDateUtils.autoDistribute(drafts, weeks.length);

    for (var wi = 0; wi < weeks.length; wi++) {
      if (byWeek[wi].isEmpty) continue;
      final (ws, we) = weeks[wi];
      final weekId = await _groupDao.insert(PlanGroup(
        type: PlanGroupType.week,
        parentId: monthId,
        startDate: ws,
        endDate: we,
        createdAt: now,
      ));

      final days = PlanDateUtils.daysInRange(ws, we);
      final byDay = PlanDateUtils.autoDistribute(byWeek[wi], days.length);

      for (var di = 0; di < days.length; di++) {
        if (byDay[di].isEmpty) continue;
        final dayId = await _groupDao.insert(PlanGroup(
          type: PlanGroupType.day,
          parentId: weekId,
          startDate: days[di],
          endDate: days[di],
          createdAt: now,
        ));
        await _itemDao.insertBatch(byDay[di]
            .map((d) => _draftToItem(d,
                dayPlanId: dayId, weekId: weekId, monthId: monthId))
            .toList());
        _markedDates.add(days[di].toIso8601String().substring(0, 10));
      }
    }

    await loadDate(_selectedDate);
  }

  // ── Completion ────────────────────────────────

  Future<void> markItemComplete(int itemId) async {
    await _itemDao.markComplete(itemId);
    await loadDate(_selectedDate);
  }

  Future<void> markItemPending(int itemId) async {
    await _itemDao.markPending(itemId);
    await loadDate(_selectedDate);
  }

  // ── Adjustment ────────────────────────────────

  /// Returns a full snapshot of a date's plan state (for the adjustment screen).
  Future<DayPlanSnapshot> getSnapshot(DateTime date) async {
    final d = PlanDateUtils.dateOnly(date);

    PlanGroup? standaloneDayPlan = await _groupDao.getStandaloneDayPlan(d);
    if (standaloneDayPlan != null) {
      final m = await _itemDao.getByDayPlanIds([standaloneDayPlan.id!]);
      standaloneDayPlan.items = m[standaloneDayPlan.id] ?? [];
    }

    final weekPlans = await _groupDao.getWeekPlansForDate(d);
    PlanGroup? weekPlan = weekPlans.isNotEmpty ? weekPlans.first : null;
    PlanGroup? weekDayPlan;
    if (weekPlan != null) {
      weekDayPlan = await _groupDao.getChildDayPlan(weekPlan.id!, d);
      if (weekDayPlan != null) {
        final m = await _itemDao.getByDayPlanIds([weekDayPlan.id!]);
        weekDayPlan.items = m[weekDayPlan.id] ?? [];
      }
    }

    final monthPlans = await _groupDao.getMonthPlansForDate(d);
    PlanGroup? monthPlan = monthPlans.isNotEmpty ? monthPlans.first : null;
    PlanGroup? monthWeekPlan;
    PlanGroup? monthDayPlan;
    if (monthPlan != null) {
      monthWeekPlan = await _groupDao.getChildWeekForDate(monthPlan.id!, d);
      if (monthWeekPlan != null) {
        monthDayPlan = await _groupDao.getChildDayPlan(monthWeekPlan.id!, d);
        if (monthDayPlan != null) {
          final m = await _itemDao.getByDayPlanIds([monthDayPlan.id!]);
          monthDayPlan.items = m[monthDayPlan.id] ?? [];
        }
      }
    }

    return DayPlanSnapshot(
      date: d,
      standaloneDayPlan: standaloneDayPlan,
      weekPlan: weekPlan,
      weekDayPlan: weekDayPlan,
      monthPlan: monthPlan,
      monthWeekPlan: monthWeekPlan,
      monthDayPlan: monthDayPlan,
    );
  }

  /// Delete a single item (not mark complete).
  Future<void> deleteItem(int itemId) async {
    await _itemDao.delete(itemId);
    await loadDate(_selectedDate);
  }

  /// Add drafts to a given level on a given date.
  /// Creates the plan hierarchy if needed.
  /// Returns an error string on conflict, or null on success.
  Future<String?> addToLevel(
      DateTime date, PlanGroupType level, List<PlanItemDraft> drafts) async {
    if (drafts.isEmpty) return null;
    final d = PlanDateUtils.dateOnly(date);
    final now = DateTime.now();

    switch (level) {
      case PlanGroupType.day:
        PlanGroup? dayPlan = await _groupDao.getStandaloneDayPlan(d);
        int dayId;
        if (dayPlan != null) {
          dayId = dayPlan.id!;
        } else {
          dayId = await _groupDao.insert(PlanGroup(
            type: PlanGroupType.day,
            startDate: d,
            endDate: d,
            createdAt: now,
          ));
          _markedDates.add(d.toIso8601String().substring(0, 10));
        }
        await _itemDao.insertBatch(
            drafts.map((dr) => _draftToItem(dr, dayPlanId: dayId)).toList());

      case PlanGroupType.week:
        final weekPlans = await _groupDao.getWeekPlansForDate(d);
        int weekId;
        if (weekPlans.isNotEmpty) {
          weekId = weekPlans.first.id!;
        } else {
          final ws = d;
          final we = PlanDateUtils.weekEnd(d);
          if (await _groupDao.hasOverlappingWeekPlan(ws, we)) {
            return '周计划重叠：该日期已在其他周计划范围内';
          }
          weekId = await _groupDao.insert(PlanGroup(
            type: PlanGroupType.week,
            startDate: ws,
            endDate: we,
            createdAt: now,
          ));
        }
        PlanGroup? weekDayPlan = await _groupDao.getChildDayPlan(weekId, d);
        int dayId;
        if (weekDayPlan != null) {
          dayId = weekDayPlan.id!;
        } else {
          dayId = await _groupDao.insert(PlanGroup(
            type: PlanGroupType.day,
            parentId: weekId,
            startDate: d,
            endDate: d,
            createdAt: now,
          ));
          _markedDates.add(d.toIso8601String().substring(0, 10));
        }
        await _itemDao.insertBatch(drafts
            .map((dr) => _draftToItem(dr, dayPlanId: dayId, weekId: weekId))
            .toList());

      case PlanGroupType.month:
        final monthPlans = await _groupDao.getMonthPlansForDate(d);
        int monthId;
        if (monthPlans.isNotEmpty) {
          monthId = monthPlans.first.id!;
        } else {
          final ms = d;
          final me = PlanDateUtils.monthPlanEnd(d);
          if (await _groupDao.hasOverlappingMonthPlan(ms, me)) {
            return '月份重叠：该日期范围已有月计划存在';
          }
          monthId = await _groupDao.insert(PlanGroup(
            type: PlanGroupType.month,
            startDate: ms,
            endDate: me,
            createdAt: now,
          ));
        }
        PlanGroup? monthWeekPlan =
            await _groupDao.getChildWeekForDate(monthId, d);
        int weekId;
        if (monthWeekPlan != null) {
          weekId = monthWeekPlan.id!;
        } else {
          final ws = PlanDateUtils.weekStart(d);
          final we = PlanDateUtils.weekEnd(d);
          weekId = await _groupDao.insert(PlanGroup(
            type: PlanGroupType.week,
            parentId: monthId,
            startDate: ws,
            endDate: we,
            createdAt: now,
          ));
        }
        PlanGroup? monthDayPlan = await _groupDao.getChildDayPlan(weekId, d);
        int dayId;
        if (monthDayPlan != null) {
          dayId = monthDayPlan.id!;
        } else {
          dayId = await _groupDao.insert(PlanGroup(
            type: PlanGroupType.day,
            parentId: weekId,
            startDate: d,
            endDate: d,
            createdAt: now,
          ));
          _markedDates.add(d.toIso8601String().substring(0, 10));
        }
        await _itemDao.insertBatch(drafts
            .map((dr) =>
                _draftToItem(dr, dayPlanId: dayId, weekId: weekId, monthId: monthId))
            .toList());
    }

    await loadDate(_selectedDate);
    return null;
  }

  /// Move items to another date's day plan within the same plan context.
  Future<void> moveItems(List<PlanItem> items, DateTime targetDate) async {
    if (items.isEmpty) return;
    final d = PlanDateUtils.dateOnly(targetDate);
    final now = DateTime.now();
    final first = items.first;

    int targetDayPlanId;

    if (first.originMonthPlanId != null) {
      final monthId = first.originMonthPlanId!;
      PlanGroup? wg = await _groupDao.getChildWeekForDate(monthId, d);
      int weekId;
      if (wg != null) {
        weekId = wg.id!;
      } else {
        weekId = await _groupDao.insert(PlanGroup(
          type: PlanGroupType.week,
          parentId: monthId,
          startDate: PlanDateUtils.weekStart(d),
          endDate: PlanDateUtils.weekEnd(d),
          createdAt: now,
        ));
      }
      PlanGroup? dg = await _groupDao.getChildDayPlan(weekId, d);
      if (dg != null) {
        targetDayPlanId = dg.id!;
      } else {
        targetDayPlanId = await _groupDao.insert(PlanGroup(
          type: PlanGroupType.day,
          parentId: weekId,
          startDate: d,
          endDate: d,
          createdAt: now,
        ));
        _markedDates.add(d.toIso8601String().substring(0, 10));
      }
    } else if (first.originWeekPlanId != null) {
      final weekId = first.originWeekPlanId!;
      PlanGroup? dg = await _groupDao.getChildDayPlan(weekId, d);
      if (dg != null) {
        targetDayPlanId = dg.id!;
      } else {
        targetDayPlanId = await _groupDao.insert(PlanGroup(
          type: PlanGroupType.day,
          parentId: weekId,
          startDate: d,
          endDate: d,
          createdAt: now,
        ));
        _markedDates.add(d.toIso8601String().substring(0, 10));
      }
    } else {
      PlanGroup? dg = await _groupDao.getStandaloneDayPlan(d);
      if (dg != null) {
        targetDayPlanId = dg.id!;
      } else {
        targetDayPlanId = await _groupDao.insert(PlanGroup(
          type: PlanGroupType.day,
          startDate: d,
          endDate: d,
          createdAt: now,
        ));
        _markedDates.add(d.toIso8601String().substring(0, 10));
      }
    }

    await _itemDao.moveToDayPlan(
        items.map((i) => i.id!).toList(), targetDayPlanId);
    await loadDate(_selectedDate);
  }

  Future<bool> checkWeekOverlap(DateTime startDate) async {
    final ws = PlanDateUtils.dateOnly(startDate);
    final we = PlanDateUtils.weekEnd(startDate);
    return _groupDao.hasOverlappingWeekPlan(ws, we);
  }

  Future<bool> checkMonthOverlap(DateTime startDate) async {
    final ms = PlanDateUtils.dateOnly(startDate);
    final me = PlanDateUtils.monthPlanEnd(startDate);
    return _groupDao.hasOverlappingMonthPlan(ms, me);
  }

  // ── Internal ──────────────────────────────────

  PlanItem _draftToItem(PlanItemDraft d,
      {required int dayPlanId, int? weekId, int? monthId}) {
    return PlanItem(
      dayPlanId: dayPlanId,
      chapterId: d.chapterId,
      chapterName: d.chapterName,
      subjectName: d.subjectName,
      subjectEmoji: d.subjectEmoji,
      grade: d.grade,
      knowledgePoint: d.knowledgePoint,
      originWeekPlanId: weekId,
      originMonthPlanId: monthId,
    );
  }
}
