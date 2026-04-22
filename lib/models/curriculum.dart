class Chapter {
  final int? id;
  final String subject;
  final int grade; // 6=六年级, 7=初一, 8=初二, 9=初三
  final String chapterName;
  final int orderIndex;

  const Chapter({
    this.id,
    required this.subject,
    required this.grade,
    required this.chapterName,
    required this.orderIndex,
  });

  String get gradeLabel {
    const map = {6: '六年级', 7: '初一', 8: '初二', 9: '初三'};
    return map[grade] ?? '$grade年级';
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'subject': subject,
    'grade': grade,
    'chapter_name': chapterName,
    'order_index': orderIndex,
  };

  factory Chapter.fromMap(Map<String, dynamic> m) => Chapter(
    id: m['id'] as int?,
    subject: m['subject'] as String,
    grade: m['grade'] as int,
    chapterName: m['chapter_name'] as String,
    orderIndex: m['order_index'] as int,
  );
}
