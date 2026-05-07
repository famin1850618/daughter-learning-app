import 'package:flutter/foundation.dart';
import '../models/plan_group.dart';
import '../models/plan_settings.dart';
import '../database/plan_group_dao.dart';
import '../database/plan_item_dao.dart';
import '../utils/plan_date_utils.dart';

/// V3.7.9：练习触发的计划自动完成时，传入的"涵盖知识点"元组
class PracticeKpTuple {
  final String subjectName;  // 中文名（与 PlanItem.subjectName 一致）
  final int grade;
  final String chapter;
  final String? knowledgePoint;

  const PracticeKpTuple({
    required this.subjectName,
    required this.grade,
    required this.chapter,
    this.knowledgePoint,
  });
}

// ── Snapshot used by the plan adjustment screen ──────────────────────────────
class AdjustmentSnapshot {
  final DateTime date;
  final List<PlanItem> todayItems; // all items scheduled for this date
  final PlanGroup? weekPlan;       // full week plan (all children loaded)
  final PlanGroup? monthPlan;      // full month plan (all children loaded)

  const AdjustmentSnapshot({
    required this.date,
    required this.todayItems,
    this.weekPlan,
    this.monthPlan,
  });

  bool get hasAnyPlan =>
      todayItems.isNotEmpty || weekPlan != null || monthPlan != null;
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
  List<PlanItem> get todayItems => _dayPlans.expand((g) => g.items).toList();
  bool get selectedDateHasPlans =>
      _dayPlans.isNotEmpty || _weekPlans.isNotEmpty || _monthPlans.isNotEmpty;

  PlanService() {
    _init();
  }

  Future<void> _init() async {
    _markedDates = await _groupDao.getDatesWithPlans();
    await loadDate(DateTime.now());
  }

  // ── Main screen data loading ─────────────────

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

  // ── Adjustment screen data loading ──────────

  Future<AdjustmentSnapshot> getAdjustmentSnapshot(DateTime date) async {
    final d = PlanDateUtils.dateOnly(date);
    final todayStr = d.toIso8601String().substring(0, 10);
    final todayItems = <PlanItem>[];

    // Standalone day plan
    final standalonePlan = await _groupDao.getStandaloneDayPlan(d);
    if (standalonePlan != null) {
      final items = await _itemDao.getByDayPlanId(standalonePlan.id!);
      standalonePlan.items = items;
      todayItems.addAll(items);
    }

    // Full week plan
    PlanGroup? weekPlan;
    final weekPlans = await _groupDao.getWeekPlansForDate(d);
    if (weekPlans.isNotEmpty) {
      weekPlan = weekPlans.first;
      final children = await _groupDao.getChildren(weekPlan.id!);
      for (final child in children) {
        final items = await _itemDao.getByDayPlanId(child.id!);
        child.items = items;
        if (child.startDate.toIso8601String().substring(0, 10) == todayStr) {
          todayItems.addAll(items);
        }
      }
      weekPlan.children = children;
    }

    // Full month plan
    PlanGroup? monthPlan;
    final monthPlans = await _groupDao.getMonthPlansForDate(d);
    if (monthPlans.isNotEmpty) {
      monthPlan = monthPlans.first;
      final weeks = await _groupDao.getChildren(monthPlan.id!);
      for (final week in weeks) {
        final days = await _groupDao.getChildren(week.id!);
        for (final day in days) {
          final items = await _itemDao.getByDayPlanId(day.id!);
          day.items = items;
          if (day.startDate.toIso8601String().substring(0, 10) == todayStr) {
            todayItems.addAll(items);
          }
        }
        week.children = days;
      }
      monthPlan.children = weeks;
    }

    return AdjustmentSnapshot(
      date: d,
      todayItems: todayItems,
      weekPlan: weekPlan,
      monthPlan: monthPlan,
    );
  }

  // ── Creation ────────────────────────────────

  Future<void> createDayPlan(DateTime date, List<PlanItemDraft> drafts) async {
    final now = DateTime.now();
    final d = PlanDateUtils.dateOnly(date);
    final dayId = await _groupDao.insert(PlanGroup(
      type: PlanGroupType.day, startDate: d, endDate: d, createdAt: now,
    ));
    await _itemDao.insertBatch(
        drafts.map((dr) => _draftToItem(dr, dayPlanId: dayId)).toList());
    _markedDates.add(d.toIso8601String().substring(0, 10));
    await loadDate(_selectedDate);
  }

  Future<void> createWeekPlan(DateTime startDate, List<PlanItemDraft> drafts,
      {PlanSettings settings = const PlanSettings()}) async {
    final now = DateTime.now();
    final ws = PlanDateUtils.dateOnly(startDate);
    final we = PlanDateUtils.weekEnd(startDate);

    final weekId = await _groupDao.insert(PlanGroup(
      type: PlanGroupType.week, startDate: ws, endDate: we, createdAt: now,
    ));

    final allDays = PlanDateUtils.daysInRange(ws, we);
    final activeDays = settings.filterDays(allDays);
    final ordered = settings.sortDrafts(drafts);
    final distributed = _distributeWithMax(ordered, activeDays.length, settings.maxPerDay);

    for (var i = 0; i < activeDays.length; i++) {
      if (distributed[i].isEmpty) continue;
      final dayId = await _groupDao.insert(PlanGroup(
        type: PlanGroupType.day, parentId: weekId,
        startDate: activeDays[i], endDate: activeDays[i], createdAt: now,
      ));
      await _itemDao.insertBatch(distributed[i]
          .map((d) => _draftToItem(d, dayPlanId: dayId, weekId: weekId))
          .toList());
      _markedDates.add(activeDays[i].toIso8601String().substring(0, 10));
    }
    await loadDate(_selectedDate);
  }

  Future<void> createMonthPlan(DateTime startDate, List<PlanItemDraft> drafts,
      {PlanSettings settings = const PlanSettings()}) async {
    final now = DateTime.now();
    final ms = PlanDateUtils.dateOnly(startDate);
    final me = PlanDateUtils.monthPlanEnd(startDate);

    final monthId = await _groupDao.insert(PlanGroup(
      type: PlanGroupType.month, startDate: ms, endDate: me, createdAt: now,
    ));

    final weeks = PlanDateUtils.splitIntoWeeks(ms, me);
    final ordered = settings.sortDrafts(drafts);
    final byWeek = PlanDateUtils.autoDistribute(ordered, weeks.length);

    for (var wi = 0; wi < weeks.length; wi++) {
      if (byWeek[wi].isEmpty) continue;
      final (ws, we) = weeks[wi];
      final weekId = await _groupDao.insert(PlanGroup(
        type: PlanGroupType.week, parentId: monthId,
        startDate: ws, endDate: we, createdAt: now,
      ));

      final allDays = PlanDateUtils.daysInRange(ws, we);
      final activeDays = settings.filterDays(allDays);
      final weekOrdered = settings.sortDrafts(byWeek[wi]);
      final byDay = _distributeWithMax(weekOrdered, activeDays.length, settings.maxPerDay);

      for (var di = 0; di < activeDays.length; di++) {
        if (byDay[di].isEmpty) continue;
        final dayId = await _groupDao.insert(PlanGroup(
          type: PlanGroupType.day, parentId: weekId,
          startDate: activeDays[di], endDate: activeDays[di], createdAt: now,
        ));
        await _itemDao.insertBatch(byDay[di]
            .map((d) => _draftToItem(d, dayPlanId: dayId, weekId: weekId, monthId: monthId))
            .toList());
        _markedDates.add(activeDays[di].toIso8601String().substring(0, 10));
      }
    }
    await loadDate(_selectedDate);
  }

  // ── Completion ───────────────────────────────

  Future<void> markItemComplete(int itemId) async {
    await _itemDao.markComplete(itemId);
    await loadDate(_selectedDate);
  }

  /// V3.7.9：练习自动判定计划完成
  ///
  /// 当一组练习正确率 ≥ 80% 时，扫描今日所有 pending PlanItem：
  /// - 有 knowledgePoint 的 PlanItem：要求 (subjectName, grade, chapter, kp) 全匹配
  /// - 无 knowledgePoint 的 PlanItem：仅 (subjectName, grade, chapter) 匹配即可
  ///
  /// 返回标记完成的 item 数。
  Future<int> autoCompleteFromPractice({
    required int score,
    required int total,
    required List<PracticeKpTuple> coveredTuples,
  }) async {
    if (total == 0) return 0;
    if (score / total < 0.8) return 0;
    if (coveredTuples.isEmpty) return 0;

    final today = PlanDateUtils.dateOnly(DateTime.now());
    final dayGroups = await _groupDao.getDayPlansForDate(today);
    if (dayGroups.isEmpty) return 0;
    final ids = dayGroups.map((g) => g.id!).toList();
    final itemMap = await _itemDao.getByDayPlanIds(ids);
    final allItems = itemMap.values.expand((x) => x).toList();

    int marked = 0;
    for (final item in allItems) {
      if (item.status == PlanItemStatus.completed) continue;
      final hasKp = item.knowledgePoint != null && item.knowledgePoint!.isNotEmpty;
      final matched = coveredTuples.any((t) {
        if (t.subjectName != item.subjectName) return false;
        if (t.grade != item.grade) return false;
        if (t.chapter != item.chapterName) return false;
        if (hasKp) return t.knowledgePoint == item.knowledgePoint;
        return true; // PlanItem 无 KP 时章节匹配即可
      });
      if (matched) {
        await _itemDao.markComplete(item.id!);
        marked++;
      }
    }

    if (marked > 0) {
      await loadDate(_selectedDate);
    }
    return marked;
  }

  Future<void> markItemPending(int itemId) async {
    await _itemDao.markPending(itemId);
    await loadDate(_selectedDate);
  }

  // ── Item-level adjustment ────────────────────

  Future<void> deleteItem(int itemId) async {
    await _itemDao.delete(itemId);
    _markedDates = await _groupDao.getDatesWithPlans();
    await loadDate(_selectedDate);
  }

  /// Add drafts to the best-fit container for the given date.
  /// Month container takes priority, then week, then standalone day.
  Future<String?> addToDay(DateTime date, List<PlanItemDraft> drafts) async {
    final d = PlanDateUtils.dateOnly(date);
    final monthPlans = await _groupDao.getMonthPlansForDate(d);
    if (monthPlans.isNotEmpty) return addToLevel(date, PlanGroupType.month, drafts);
    final weekPlans = await _groupDao.getWeekPlansForDate(d);
    if (weekPlans.isNotEmpty) return addToLevel(date, PlanGroupType.week, drafts);
    return addToLevel(date, PlanGroupType.day, drafts);
  }

  /// Add drafts to a specific plan level on a given date.
  /// Creates the plan hierarchy if needed.
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
            type: PlanGroupType.day, startDate: d, endDate: d, createdAt: now,
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
            type: PlanGroupType.week, startDate: ws, endDate: we, createdAt: now,
          ));
        }
        PlanGroup? weekDay = await _groupDao.getChildDayPlan(weekId, d);
        int dayId;
        if (weekDay != null) {
          dayId = weekDay.id!;
        } else {
          dayId = await _groupDao.insert(PlanGroup(
            type: PlanGroupType.day, parentId: weekId,
            startDate: d, endDate: d, createdAt: now,
          ));
          _markedDates.add(d.toIso8601String().substring(0, 10));
        }
        await _itemDao.insertBatch(
            drafts.map((dr) => _draftToItem(dr, dayPlanId: dayId, weekId: weekId)).toList());

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
            type: PlanGroupType.month, startDate: ms, endDate: me, createdAt: now,
          ));
        }
        PlanGroup? mWeek = await _groupDao.getChildWeekForDate(monthId, d);
        int weekId;
        if (mWeek != null) {
          weekId = mWeek.id!;
        } else {
          weekId = await _groupDao.insert(PlanGroup(
            type: PlanGroupType.week, parentId: monthId,
            startDate: PlanDateUtils.weekStart(d),
            endDate: PlanDateUtils.weekEnd(d),
            createdAt: now,
          ));
        }
        PlanGroup? mDay = await _groupDao.getChildDayPlan(weekId, d);
        int dayId;
        if (mDay != null) {
          dayId = mDay.id!;
        } else {
          dayId = await _groupDao.insert(PlanGroup(
            type: PlanGroupType.day, parentId: weekId,
            startDate: d, endDate: d, createdAt: now,
          ));
          _markedDates.add(d.toIso8601String().substring(0, 10));
        }
        await _itemDao.insertBatch(
            drafts.map((dr) => _draftToItem(dr, dayPlanId: dayId, weekId: weekId, monthId: monthId)).toList());
    }

    await loadDate(_selectedDate);
    return null;
  }

  /// Move items to another date's day plan within the same container context.
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
          type: PlanGroupType.week, parentId: monthId,
          startDate: PlanDateUtils.weekStart(d), endDate: PlanDateUtils.weekEnd(d),
          createdAt: now,
        ));
      }
      PlanGroup? dg = await _groupDao.getChildDayPlan(weekId, d);
      targetDayPlanId = dg?.id ?? await _groupDao.insert(PlanGroup(
        type: PlanGroupType.day, parentId: weekId,
        startDate: d, endDate: d, createdAt: now,
      ));
    } else if (first.originWeekPlanId != null) {
      final weekId = first.originWeekPlanId!;
      PlanGroup? dg = await _groupDao.getChildDayPlan(weekId, d);
      targetDayPlanId = dg?.id ?? await _groupDao.insert(PlanGroup(
        type: PlanGroupType.day, parentId: weekId,
        startDate: d, endDate: d, createdAt: now,
      ));
    } else {
      PlanGroup? dg = await _groupDao.getStandaloneDayPlan(d);
      targetDayPlanId = dg?.id ?? await _groupDao.insert(PlanGroup(
        type: PlanGroupType.day, startDate: d, endDate: d, createdAt: now,
      ));
    }

    _markedDates.add(d.toIso8601String().substring(0, 10));
    await _itemDao.moveToDayPlan(items.map((i) => i.id!).toList(), targetDayPlanId);
    await loadDate(_selectedDate);
  }

  // ── Week-level adjustment ────────────────────

  /// Move all items from sourceWeek into targetWeek, redistributing across days.
  Future<void> moveWeekItems(int sourceWeekId, int targetWeekId,
      {PlanSettings settings = const PlanSettings()}) async {
    final now = DateTime.now();

    // Collect source items as drafts
    final sourceDays = await _groupDao.getChildren(sourceWeekId);
    final sourceDrafts = <PlanItemDraft>[];
    for (final day in sourceDays) {
      final items = await _itemDao.getByDayPlanId(day.id!);
      sourceDrafts.addAll(items.map(_itemToDraft));
    }

    // Collect target items as drafts
    final targetDays = await _groupDao.getChildren(targetWeekId);
    final targetDrafts = <PlanItemDraft>[];
    for (final day in targetDays) {
      final items = await _itemDao.getByDayPlanId(day.id!);
      targetDrafts.addAll(items.map(_itemToDraft));
    }

    final allDrafts = [...sourceDrafts, ...targetDrafts];

    // Delete source week group (cascade deletes its day plans + items)
    await _groupDao.delete(sourceWeekId);

    // Delete target week's existing day plans (will rebuild)
    for (final day in targetDays) {
      await _groupDao.delete(day.id!);
    }

    if (allDrafts.isEmpty) {
      _markedDates = await _groupDao.getDatesWithPlans();
      await loadDate(_selectedDate);
      return;
    }

    // Get target week's date range
    final targetWeek = await _groupDao.getById(targetWeekId);
    if (targetWeek == null) {
      _markedDates = await _groupDao.getDatesWithPlans();
      await loadDate(_selectedDate);
      return;
    }
    final monthId = targetWeek.parentId;

    // Redistribute
    final allDays = PlanDateUtils.daysInRange(targetWeek.startDate, targetWeek.endDate);
    final activeDays = settings.filterDays(allDays);
    final ordered = settings.sortDrafts(allDrafts);
    final distributed = _distributeWithMax(ordered, activeDays.length, settings.maxPerDay);

    for (var i = 0; i < activeDays.length; i++) {
      if (distributed[i].isEmpty) continue;
      final dayId = await _groupDao.insert(PlanGroup(
        type: PlanGroupType.day, parentId: targetWeekId,
        startDate: activeDays[i], endDate: activeDays[i], createdAt: now,
      ));
      await _itemDao.insertBatch(distributed[i]
          .map((d) => _draftToItem(d, dayPlanId: dayId, weekId: targetWeekId, monthId: monthId))
          .toList());
    }

    _markedDates = await _groupDao.getDatesWithPlans();
    await loadDate(_selectedDate);
  }

  /// Delete an entire week group and all its items.
  Future<void> deleteWeekGroup(int weekId) async {
    await _groupDao.delete(weekId);
    _markedDates = await _groupDao.getDatesWithPlans();
    await loadDate(_selectedDate);
  }

  /// Delete an entire month group and all its children (weeks + days + items).
  Future<void> deleteMonthGroup(int monthId) async {
    await _groupDao.delete(monthId);
    _markedDates = await _groupDao.getDatesWithPlans();
    await loadDate(_selectedDate);
  }

  // ── Overlap checks ───────────────────────────

  Future<bool> checkWeekOverlap(DateTime startDate) async {
    return _groupDao.hasOverlappingWeekPlan(
        PlanDateUtils.dateOnly(startDate), PlanDateUtils.weekEnd(startDate));
  }

  Future<bool> checkMonthOverlap(DateTime startDate) async {
    return _groupDao.hasOverlappingMonthPlan(
        PlanDateUtils.dateOnly(startDate), PlanDateUtils.monthPlanEnd(startDate));
  }

  // ── Internal helpers ─────────────────────────

  List<List<T>> _distributeWithMax<T>(List<T> items, int slots, int maxPerDay) {
    if (slots == 0 || items.isEmpty) return List.generate(slots, (_) => []);
    final result = List.generate(slots, (_) => <T>[]);
    final effective = maxPerDay > 0 ? maxPerDay : items.length;
    var idx = 0;
    for (final item in items) {
      // Find next slot with capacity
      var tries = 0;
      while (result[idx].length >= effective && tries < slots) {
        idx = (idx + 1) % slots;
        tries++;
      }
      result[idx].add(item);
      idx = (idx + 1) % slots;
    }
    return result;
  }

  PlanItemDraft _itemToDraft(PlanItem item) => PlanItemDraft(
        chapterId: item.chapterId,
        chapterName: item.chapterName,
        subjectName: item.subjectName,
        subjectEmoji: item.subjectEmoji,
        grade: item.grade,
        knowledgePoint: item.knowledgePoint,
      );

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
