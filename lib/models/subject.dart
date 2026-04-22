enum Subject {
  chinese,
  math,
  english,
  physics,
  chemistry,
  ai,
}

extension SubjectExtension on Subject {
  String get displayName {
    switch (this) {
      case Subject.chinese:  return '语文';
      case Subject.math:     return '数学';
      case Subject.english:  return '英语';
      case Subject.physics:  return '物理';
      case Subject.chemistry: return '化学';
      case Subject.ai:       return 'AI';
    }
  }

  String get emoji {
    switch (this) {
      case Subject.chinese:  return '📖';
      case Subject.math:     return '🔢';
      case Subject.english:  return '🔤';
      case Subject.physics:  return '⚡';
      case Subject.chemistry: return '🧪';
      case Subject.ai:       return '🤖';
    }
  }

  // 起始年级：物理初二(8)，化学初三(9)，其余六年级(6)
  int get startGrade {
    switch (this) {
      case Subject.physics:  return 8;
      case Subject.chemistry: return 9;
      default:               return 6;
    }
  }

  bool isAvailableForGrade(int grade) => grade >= startGrade;

  /// 用于匹配 curriculum 表中的 subject 字段
  String get name {
    switch (this) {
      case Subject.chinese:   return '语文';
      case Subject.math:      return '数学';
      case Subject.english:   return '英语';
      case Subject.physics:   return '物理';
      case Subject.chemistry: return '化学';
      case Subject.ai:        return 'AI';
    }
  }

  String get gradeRangeLabel {
    switch (this) {
      case Subject.physics:   return '初二 ～ 初三';
      case Subject.chemistry: return '初三';
      default:                return '六年级 ～ 初三';
    }
  }
}
