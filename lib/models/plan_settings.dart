import 'plan_group.dart';

class PlanSettings {
  /// Weekdays to schedule on: 1=Mon…7=Sun. Empty = every day.
  final Set<int> targetWeekdays;
  /// Max items per day during auto-distribution. 0 = unlimited.
  final int maxPerDay;
  /// true = group same subject together; false = interleave subjects.
  final bool concentrated;

  const PlanSettings({
    this.targetWeekdays = const {},
    this.maxPerDay = 0,
    this.concentrated = false,
  });

  List<DateTime> filterDays(List<DateTime> days) {
    if (targetWeekdays.isEmpty) return days;
    final filtered =
        days.where((d) => targetWeekdays.contains(d.weekday)).toList();
    return filtered.isEmpty ? days : filtered;
  }

  /// Re-order drafts according to the subject distribution preference.
  List<PlanItemDraft> sortDrafts(List<PlanItemDraft> drafts) {
    if (drafts.length <= 1) return drafts;
    final grouped = <String, List<PlanItemDraft>>{};
    for (final d in drafts) {
      grouped.putIfAbsent(d.subjectName, () => []).add(d);
    }
    if (grouped.length == 1) return drafts;

    if (concentrated) {
      // All items of same subject together: A A A B B C
      return grouped.values.expand((v) => v).toList();
    } else {
      // Interleave subjects: A B C A B C …
      final subjects = grouped.keys.toList();
      final result = <PlanItemDraft>[];
      int maxLen = 0;
      for (final l in grouped.values) {
        if (l.length > maxLen) maxLen = l.length;
      }
      for (var i = 0; i < maxLen; i++) {
        for (final s in subjects) {
          if (i < (grouped[s]?.length ?? 0)) result.add(grouped[s]![i]);
        }
      }
      return result;
    }
  }

  PlanSettings copyWith({
    Set<int>? targetWeekdays,
    int? maxPerDay,
    bool? concentrated,
  }) =>
      PlanSettings(
        targetWeekdays: targetWeekdays ?? this.targetWeekdays,
        maxPerDay: maxPerDay ?? this.maxPerDay,
        concentrated: concentrated ?? this.concentrated,
      );

  Map<String, dynamic> toJson() => {
        'targetWeekdays': targetWeekdays.toList(),
        'maxPerDay': maxPerDay,
        'concentrated': concentrated,
      };

  factory PlanSettings.fromJson(Map<String, dynamic> j) => PlanSettings(
        targetWeekdays:
            Set<int>.from((j['targetWeekdays'] as List? ?? []).cast<int>()),
        maxPerDay: j['maxPerDay'] as int? ?? 0,
        concentrated: j['concentrated'] as bool? ?? false,
      );
}
