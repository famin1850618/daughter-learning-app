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
}
