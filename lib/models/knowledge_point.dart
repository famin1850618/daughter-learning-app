/// 知识点模型（两层结构：category 一级 / name 二级）
///
/// fullPath 格式：`一级类目/二级具体名`，如 `比和比例/化简比`、`修辞/比喻`。
/// 用作题目 [Question.knowledgePoint] 的引用值；同一 fullPath 跨年级表示同一概念。
class KnowledgePoint {
  final int? id;
  final String subject;
  final String category;
  final String name;
  final int? introducedGrade;

  const KnowledgePoint({
    this.id,
    required this.subject,
    required this.category,
    required this.name,
    this.introducedGrade,
  });

  /// V3.21: name 为空时输出单段 fullPath（如数理化 `综合练习` 一级 KP，无斜杠）。
  String get fullPath => name.isEmpty ? category : '$category/$name';

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'subject': subject,
    'category': category,
    'name': name,
    'full_path': fullPath,
    if (introducedGrade != null) 'introduced_grade': introducedGrade,
  };

  factory KnowledgePoint.fromMap(Map<String, dynamic> m) => KnowledgePoint(
    id: m['id'] as int?,
    subject: m['subject'] as String,
    category: m['category'] as String,
    name: m['name'] as String,
    introducedGrade: m['introduced_grade'] as int?,
  );
}
