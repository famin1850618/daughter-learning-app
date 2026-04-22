import 'package:flutter/foundation.dart';
import '../models/plan_group.dart';
import '../database/plan_group_dao.dart';
import '../database/plan_item_dao.dart';
import '../utils/plan_date_utils.dart';

class PlanService extends ChangeNotifier {
  final _groupDao = PlanGroupDao();
  final _itemDao = PlanItemDao();

  DateTime _selectedDate = DateTime.now();
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

  Future<void> createDayPlan(DateTime date, List<PlanItemDraft> drafts) async {
    final now = DateTime.now();
    final d = PlanDateUtils.dateOnly(date);
    final dayId = await _groupDao.insert(PlanGroup(
      type: PlanGroupType.day,
      startDate: d,
      endDate: d,
      createdAt: now,
    ));
    await _itemDao.insertBatch(drafts
        .map((draft) => _draftToItem(draft, dayPlanId: dayId))
        .toList());
    _markedDates.add(d.toIso8601String().substring(0, 10));
    await loadDate(_selectedDate);
  }

  Future<void> createWeekPlan(DateTime startDate, List<PlanItemDraft> drafts) async {
    final now = DateTime.now();
    final ws = PlanDateUtils.weekStart(startDate);
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

  Future<void> markItemComplete(int itemId) async {
    await _itemDao.markComplete(itemId);
    await loadDate(_selectedDate);
  }

  Future<void> markItemPending(int itemId) async {
    await _itemDao.markPending(itemId);
    await loadDate(_selectedDate);
  }

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
