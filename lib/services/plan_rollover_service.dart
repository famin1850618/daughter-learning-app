import 'package:flutter/foundation.dart';

import '../database/plan_item_dao.dart';
import '../utils/plan_date_utils.dart';
import 'plan_service.dart';

class PlanRolloverSummary {
  final DateTime asOf;
  final List<PlanItemSchedule> items;

  const PlanRolloverSummary({
    required this.asOf,
    required this.items,
  });

  int get count => items.length;

  DateTime get earliestDate => items.first.scheduledDate;

  DateTime get latestDate => items.last.scheduledDate;

  String get dateRangeLabel {
    final start = earliestDate;
    final end = latestDate;
    if (PlanDateUtils.isSameDay(start, end)) {
      return '${start.month}月${start.day}日';
    }
    return '${start.month}月${start.day}日-${end.month}月${end.day}日';
  }
}

class PlanRolloverService extends ChangeNotifier {
  final PlanService _planService;

  PlanRolloverService(this._planService);

  PlanRolloverSummary? _summary;
  bool _checking = false;
  bool _rolling = false;

  PlanRolloverSummary? get summary => _summary;
  bool get checking => _checking;
  bool get rolling => _rolling;
  bool get hasOverdue => (_summary?.count ?? 0) > 0;

  Future<PlanRolloverSummary?> check({DateTime? asOf}) async {
    if (_checking) return _summary;
    _checking = true;
    notifyListeners();
    try {
      final today = PlanDateUtils.dateOnly(asOf ?? DateTime.now());
      final items = await _planService.overduePendingItems(asOf: today);
      _summary =
          items.isEmpty ? null : PlanRolloverSummary(asOf: today, items: items);
      return _summary;
    } finally {
      _checking = false;
      notifyListeners();
    }
  }

  Future<int> rollToToday() async {
    if (_rolling) return 0;
    _rolling = true;
    notifyListeners();
    try {
      final today = PlanDateUtils.dateOnly(DateTime.now());
      final current = _summary?.items ??
          await _planService.overduePendingItems(asOf: today);
      final moved = await _planService.rolloverItemsTo(
        current.map((entry) => entry.item).toList(),
        today,
      );
      await check(asOf: today);
      return moved;
    } finally {
      _rolling = false;
      notifyListeners();
    }
  }
}
