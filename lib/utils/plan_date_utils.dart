class PlanDateUtils {
  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isSameWeek(DateTime a, DateTime b) =>
      isSameDay(weekStart(a), weekStart(b));

  /// 周一
  static DateTime weekStart(DateTime date) {
    final d = dateOnly(date);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// 周日
  static DateTime weekEnd(DateTime date) {
    final d = dateOnly(date);
    final daysToSunday = d.weekday == 7 ? 0 : 7 - d.weekday;
    return d.add(Duration(days: daysToSunday));
  }

  /// 月计划终止日：start+30天后的第一个周日
  static DateTime monthPlanEnd(DateTime start) {
    final minEnd = dateOnly(start).add(const Duration(days: 30));
    final daysToSunday = minEnd.weekday == 7 ? 0 : 7 - minEnd.weekday;
    return minEnd.add(Duration(days: daysToSunday));
  }

  /// 将日期范围切分为自然周列表 [(周一, 周日), ...]
  static List<(DateTime, DateTime)> splitIntoWeeks(DateTime start, DateTime end) {
    final weeks = <(DateTime, DateTime)>[];
    var ws = dateOnly(start);
    final endDate = dateOnly(end);
    while (!ws.isAfter(endDate)) {
      final we = weekEnd(ws).isAfter(endDate) ? endDate : weekEnd(ws);
      weeks.add((ws, we));
      ws = we.add(const Duration(days: 1));
    }
    return weeks;
  }

  /// 日期范围内所有天
  static List<DateTime> daysInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var d = dateOnly(start);
    final endDate = dateOnly(end);
    while (!d.isAfter(endDate)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }
    return days;
  }

  /// 将 items 均匀分配到 slotCount 个槽，循环分配
  static List<List<T>> autoDistribute<T>(List<T> items, int slotCount) {
    if (slotCount == 0 || items.isEmpty) return List.generate(slotCount, (_) => []);
    final result = List.generate(slotCount, (_) => <T>[]);
    for (var i = 0; i < items.length; i++) {
      result[i % slotCount].add(items[i]);
    }
    return result;
  }

  static bool dateInRange(DateTime date, DateTime start, DateTime end) {
    final d = dateOnly(date);
    return !d.isBefore(dateOnly(start)) && !d.isAfter(dateOnly(end));
  }

  static String weekLabel(DateTime start, DateTime end) {
    if (start.month == end.month) {
      return '${start.month}月${start.day}日－${end.day}日';
    }
    return '${start.month}月${start.day}日－${end.month}月${end.day}日';
  }

  static const weekdayLabels = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
}
