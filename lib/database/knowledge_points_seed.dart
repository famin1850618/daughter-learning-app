import '../models/knowledge_point.dart';

/// V3.6 首批：六下语数英二级 KP 清单
///
/// 命名风格：subject + category + name → fullPath = "category/name"
/// 同一 fullPath 跨年级用同名（如"修辞/比喻"在六七八九都有效）。
/// AI 科目待独立设计（不走选择填空模板），不在此清单中。
List<KnowledgePoint> get knowledgePointsSeed => [

  // ════════════════════════════════════
  // 数学（北师大版六下）— 27 个
  // ════════════════════════════════════

  // 圆柱与圆锥
  KnowledgePoint(subject: '数学', category: '圆柱与圆锥', name: '圆柱的认识', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '圆柱与圆锥', name: '圆柱的表面积', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '圆柱与圆锥', name: '圆柱的体积', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '圆柱与圆锥', name: '圆锥的认识', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '圆柱与圆锥', name: '圆锥的体积', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '圆柱与圆锥', name: '圆柱圆锥综合应用', introducedGrade: 6),

  // 比和比例
  KnowledgePoint(subject: '数学', category: '比和比例', name: '比的意义', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '比和比例', name: '求比值', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '比和比例', name: '化简比', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '比和比例', name: '比例的意义', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '比和比例', name: '比例的基本性质', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '比和比例', name: '解比例', introducedGrade: 6),

  // 图形的运动
  KnowledgePoint(subject: '数学', category: '图形的运动', name: '平移', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '图形的运动', name: '旋转', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '图形的运动', name: '轴对称', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '图形的运动', name: '图形放大缩小', introducedGrade: 6),

  // 正反比例
  KnowledgePoint(subject: '数学', category: '正反比例', name: '正比例的意义', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '正反比例', name: '反比例的意义', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '正反比例', name: '正反比例的判断', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '正反比例', name: '正反比例图象', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '正反比例', name: '比例尺', introducedGrade: 6),

  // 数学综合
  KnowledgePoint(subject: '数学', category: '数学综合', name: '生活中的数学', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '数学综合', name: '神奇的几何变换', introducedGrade: 6),

  // 总复习（小学整体回顾）
  KnowledgePoint(subject: '数学', category: '总复习', name: '数与代数综合', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '总复习', name: '图形与几何综合', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '总复习', name: '统计与可能性', introducedGrade: 6),
  KnowledgePoint(subject: '数学', category: '总复习', name: '解决问题策略', introducedGrade: 6),

  // ════════════════════════════════════
  // 语文（人教部编六下，KP 跨单元按考点维度）— 38 个
  // ════════════════════════════════════

  // 字词
  KnowledgePoint(subject: '语文', category: '字词', name: '字音', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '字词', name: '字形', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '字词', name: '字义', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '字词', name: '词语理解', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '字词', name: '近义词反义词', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '字词', name: '词语搭配', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '字词', name: '成语运用', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '字词', name: '词语感情色彩', introducedGrade: 6),

  // 修辞
  KnowledgePoint(subject: '语文', category: '修辞', name: '比喻', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '修辞', name: '拟人', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '修辞', name: '排比', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '修辞', name: '夸张', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '修辞', name: '反问', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '修辞', name: '设问', introducedGrade: 6),

  // 句式与标点
  KnowledgePoint(subject: '语文', category: '句式与标点', name: '病句修改', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '句式与标点', name: '句式转换', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '句式与标点', name: '关联词运用', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '句式与标点', name: '句子衔接', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '句式与标点', name: '标点符号', introducedGrade: 6),

  // 阅读理解（不细分，单一 KP）
  KnowledgePoint(subject: '语文', category: '阅读理解', name: '阅读理解', introducedGrade: 6),

  // 文学常识
  KnowledgePoint(subject: '语文', category: '文学常识', name: '中国古代作家作品', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '文学常识', name: '中国现代作家作品', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '文学常识', name: '外国作家作品', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '文学常识', name: '文体常识', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '文学常识', name: '文化常识', introducedGrade: 6),

  // 古诗文
  KnowledgePoint(subject: '语文', category: '古诗文', name: '古诗词背诵默写', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '古诗文', name: '古诗词意境理解', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '古诗文', name: '古诗词作者风格', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '古诗文', name: '文言实词', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '古诗文', name: '文言句子翻译', introducedGrade: 6),

  // 写作
  KnowledgePoint(subject: '语文', category: '写作', name: '审题立意', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '写作', name: '文章结构', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '写作', name: '表达手法', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '写作', name: '人物描写', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '写作', name: '景物描写', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '写作', name: '修改作文', introducedGrade: 6),

  // 课文与名著
  KnowledgePoint(subject: '语文', category: '课文与名著', name: '课文内容理解', introducedGrade: 6),
  KnowledgePoint(subject: '语文', category: '课文与名著', name: '名著情节人物', introducedGrade: 6),

  // ════════════════════════════════════
  // 英语（外研社六下，KP 跨章节）— 23 个
  // ════════════════════════════════════

  // 词汇
  KnowledgePoint(subject: '英语', category: '词汇', name: '学习用品', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '词汇', name: '家庭与人物', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '词汇', name: '日常生活', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '词汇', name: '食物饮料', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '词汇', name: '动物植物', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '词汇', name: '交通与场所', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '词汇', name: '数字日期星期', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '词汇', name: '颜色与形状', introducedGrade: 6),

  // 语法时态
  KnowledgePoint(subject: '英语', category: '语法时态', name: '一般现在时-be动词', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '语法时态', name: '一般现在时-实义动词', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '语法时态', name: '现在进行时', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '语法时态', name: '一般过去时-be动词', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '语法时态', name: '一般过去时-实义动词', introducedGrade: 6),

  // 句型
  KnowledgePoint(subject: '英语', category: '句型', name: '陈述句', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '句型', name: '一般疑问句', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '句型', name: '特殊疑问句', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '句型', name: '否定句转换', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '句型', name: 'there be 句型', introducedGrade: 6),

  // 日常交际
  KnowledgePoint(subject: '英语', category: '日常交际', name: '问候与告别', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '日常交际', name: '介绍与询问', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '日常交际', name: '请求与帮助', introducedGrade: 6),
  KnowledgePoint(subject: '英语', category: '日常交际', name: '表达喜好', introducedGrade: 6),

  // 阅读理解（单一 KP）
  KnowledgePoint(subject: '英语', category: '阅读理解', name: '阅读理解', introducedGrade: 6),
];
