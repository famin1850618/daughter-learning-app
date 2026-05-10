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
      KnowledgePoint(
          subject: '数学', category: '圆柱与圆锥', name: '圆柱的认识', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '圆柱与圆锥', name: '圆柱的表面积', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '圆柱与圆锥', name: '圆柱的体积', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '圆柱与圆锥', name: '圆锥的认识', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '圆柱与圆锥', name: '圆锥的体积', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学',
          category: '圆柱与圆锥',
          name: '圆柱圆锥综合应用',
          introducedGrade: 6),

      // 比和比例
      KnowledgePoint(
          subject: '数学', category: '比和比例', name: '比的意义', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '比和比例', name: '求比值', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '比和比例', name: '化简比', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '比和比例', name: '比例的意义', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '比和比例', name: '比例的基本性质', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '比和比例', name: '解比例', introducedGrade: 6),

      // 图形的运动
      KnowledgePoint(
          subject: '数学', category: '图形的运动', name: '平移', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '图形的运动', name: '旋转', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '图形的运动', name: '轴对称', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '图形的运动', name: '图形放大缩小', introducedGrade: 6),

      // 正反比例
      KnowledgePoint(
          subject: '数学', category: '正反比例', name: '正比例的意义', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '正反比例', name: '反比例的意义', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '正反比例', name: '正反比例的判断', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '正反比例', name: '正反比例图象', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '正反比例', name: '比例尺', introducedGrade: 6),

      // 数学综合
      KnowledgePoint(
          subject: '数学', category: '数学综合', name: '生活中的数学', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '数学综合', name: '神奇的几何变换', introducedGrade: 6),

      // 总复习（小学整体回顾）
      KnowledgePoint(
          subject: '数学', category: '总复习', name: '数与代数综合', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '总复习', name: '图形与几何综合', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '总复习', name: '统计与可能性', introducedGrade: 6),
      KnowledgePoint(
          subject: '数学', category: '总复习', name: '解决问题策略', introducedGrade: 6),

      // ════════════════════════════════════
      // 语文（V3.14 Famin 简化 7 chapter，2026-05-10）
      // 字词 / 句子和语法 / 阅读理解 / 古诗文 / 文学常识 / 综合性学习 / 写作
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
      KnowledgePoint(subject: '语文', category: '字词', name: '多音字辨析', introducedGrade: 6),

      // 句子和语法（合并旧 句式与标点 + 修辞）
      KnowledgePoint(subject: '语文', category: '句子和语法', name: '病句修改', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '句子和语法', name: '句式转换', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '句子和语法', name: '关联词运用', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '句子和语法', name: '句子衔接', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '句子和语法', name: '标点符号', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '句子和语法', name: '比喻', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '句子和语法', name: '拟人', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '句子和语法', name: '排比', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '句子和语法', name: '夸张', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '句子和语法', name: '反问', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '句子和语法', name: '设问', introducedGrade: 6),

      // 阅读理解（合并旧 现代文阅读 + 课文与名著课文部分）
      KnowledgePoint(subject: '语文', category: '阅读理解', name: '阅读理解', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '阅读理解', name: '材料阅读', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '阅读理解', name: '标题概括', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '阅读理解', name: '说明方法', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '阅读理解', name: '段意概括', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '阅读理解', name: '人物形象分析', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '阅读理解', name: '主旨理解', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '阅读理解', name: '词句赏析', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '阅读理解', name: '课文内容理解', introducedGrade: 6),

      // 古诗文
      KnowledgePoint(subject: '语文', category: '古诗文', name: '古诗词背诵默写', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '古诗文', name: '古诗词意境理解', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '古诗文', name: '古诗词作者风格', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '古诗文', name: '文言实词', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '古诗文', name: '文言虚词', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '古诗文', name: '文言句子翻译', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '古诗文', name: '文言文阅读', introducedGrade: 6),

      // 文学常识（合并旧 课文与名著名著部分 + 古诗文文学常识）
      KnowledgePoint(subject: '语文', category: '文学常识', name: '中国古代作家作品', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '文学常识', name: '中国现代作家作品', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '文学常识', name: '外国作家作品', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '文学常识', name: '文体常识', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '文学常识', name: '文化常识', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '文学常识', name: '名著阅读', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '文学常识', name: '名著情节人物', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '文学常识', name: '古代文学常识', introducedGrade: 6),

      // 综合性学习
      KnowledgePoint(subject: '语文', category: '综合性学习', name: '生活常识', introducedGrade: 6),

      // 写作（V3.14 Famin 决策：100% 主观题，应转 _subj_held 不入主抽题池）
      // KP 保留供未来 AI 评分接入后启用
      KnowledgePoint(subject: '语文', category: '写作', name: '记叙文写作', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '写作', name: '说明文写作', introducedGrade: 6),
      KnowledgePoint(subject: '语文', category: '写作', name: '应用文写作', introducedGrade: 6),

      // ════════════════════════════════════
      // 英语（外研社六下，KP 跨章节）— 23 个
      // ════════════════════════════════════

      // 词汇
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '学习用品', introducedGrade: 6),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '家庭与人物', introducedGrade: 6),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '日常生活', introducedGrade: 6),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '食物饮料', introducedGrade: 6),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '动物植物', introducedGrade: 6),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '交通与场所', introducedGrade: 6),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '数字日期星期', introducedGrade: 6),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '颜色与形状', introducedGrade: 6),

      // 语法时态
      KnowledgePoint(
          subject: '英语',
          category: '语法时态',
          name: '一般现在时-be动词',
          introducedGrade: 6),
      KnowledgePoint(
          subject: '英语',
          category: '语法时态',
          name: '一般现在时-实义动词',
          introducedGrade: 6),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '现在进行时', introducedGrade: 6),
      KnowledgePoint(
          subject: '英语',
          category: '语法时态',
          name: '一般过去时-be动词',
          introducedGrade: 6),
      KnowledgePoint(
          subject: '英语',
          category: '语法时态',
          name: '一般过去时-实义动词',
          introducedGrade: 6),

      // 句型
      KnowledgePoint(
          subject: '英语', category: '句型', name: '陈述句', introducedGrade: 6),
      KnowledgePoint(
          subject: '英语', category: '句型', name: '一般疑问句', introducedGrade: 6),
      KnowledgePoint(
          subject: '英语', category: '句型', name: '特殊疑问句', introducedGrade: 6),
      KnowledgePoint(
          subject: '英语', category: '句型', name: '否定句转换', introducedGrade: 6),
      KnowledgePoint(
          subject: '英语',
          category: '句型',
          name: 'there be 句型',
          introducedGrade: 6),

      // 日常交际
      KnowledgePoint(
          subject: '英语', category: '日常交际', name: '问候与告别', introducedGrade: 6),
      KnowledgePoint(
          subject: '英语', category: '日常交际', name: '介绍与询问', introducedGrade: 6),
      KnowledgePoint(
          subject: '英语', category: '日常交际', name: '请求与帮助', introducedGrade: 6),
      KnowledgePoint(
          subject: '英语', category: '日常交际', name: '表达喜好', introducedGrade: 6),

      // 阅读理解（单一 KP）
      KnowledgePoint(
          subject: '英语', category: '阅读理解', name: '阅读理解', introducedGrade: 6),

      // ════════════════════════════════════
      // === 七年级数学（北师大）===
      // ════════════════════════════════════

      // 有理数
      KnowledgePoint(
          subject: '数学', category: '有理数', name: '正数与负数', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '有理数', name: '数轴', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '有理数', name: '相反数', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '有理数', name: '绝对值', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '有理数', name: '有理数加减', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '有理数', name: '有理数乘除', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '有理数', name: '有理数乘方', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '有理数', name: '科学记数法', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '有理数', name: '近似数', introducedGrade: 7),

      // 整式
      KnowledgePoint(
          subject: '数学', category: '整式', name: '用字母表示数', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '整式', name: '代数式求值', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '整式', name: '单项式与多项式', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '整式', name: '合并同类项', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '整式', name: '去括号', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '整式', name: '整式加减', introducedGrade: 7),

      // 一元一次方程
      KnowledgePoint(
          subject: '数学', category: '一元一次方程', name: '方程的概念', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '一元一次方程', name: '等式性质', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学',
          category: '一元一次方程',
          name: '解一元一次方程',
          introducedGrade: 7),
      KnowledgePoint(
          subject: '数学',
          category: '一元一次方程',
          name: '应用题-行程',
          introducedGrade: 7),
      KnowledgePoint(
          subject: '数学',
          category: '一元一次方程',
          name: '应用题-工程',
          introducedGrade: 7),
      KnowledgePoint(
          subject: '数学',
          category: '一元一次方程',
          name: '应用题-销售',
          introducedGrade: 7),

      // 几何图形初步
      KnowledgePoint(
          subject: '数学', category: '几何图形初步', name: '立体图形', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学',
          category: '几何图形初步',
          name: '直线射线线段',
          introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '几何图形初步', name: '角的度量', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '几何图形初步', name: '角的比较', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '几何图形初步', name: '余角与补角', introducedGrade: 7),

      // 相交线与平行线
      KnowledgePoint(
          subject: '数学', category: '相交线与平行线', name: '对顶角', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '相交线与平行线', name: '垂线', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学',
          category: '相交线与平行线',
          name: '平行线判定',
          introducedGrade: 7),
      KnowledgePoint(
          subject: '数学',
          category: '相交线与平行线',
          name: '平行线性质',
          introducedGrade: 7),

      // 三角形
      KnowledgePoint(
          subject: '数学', category: '三角形', name: '三角形分类', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '三角形', name: '三角形内角和', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '三角形', name: '三角形三边关系', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学', category: '三角形', name: '全等三角形', introducedGrade: 7),

      // 数据收集与处理
      KnowledgePoint(
          subject: '数学', category: '数据收集与处理', name: '统计调查', introducedGrade: 7),
      KnowledgePoint(
          subject: '数学',
          category: '数据收集与处理',
          name: '频数与频率',
          introducedGrade: 7),
      KnowledgePoint(
          subject: '数学',
          category: '数据收集与处理',
          name: '统计图选择',
          introducedGrade: 7),
      KnowledgePoint(
          subject: '数学',
          category: '数据收集与处理',
          name: '可能性大小',
          introducedGrade: 7),

      // ════════════════════════════════════
      // === 八年级数学（北师大）===
      // ════════════════════════════════════

      // 实数
      KnowledgePoint(
          subject: '数学', category: '实数', name: '平方根', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '实数', name: '立方根', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '实数', name: '无理数', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '实数', name: '实数运算', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '实数', name: '实数大小比较', introducedGrade: 8),

      // 二次根式
      KnowledgePoint(
          subject: '数学', category: '二次根式', name: '二次根式的概念', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '二次根式', name: '二次根式化简', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '二次根式', name: '二次根式运算', introducedGrade: 8),

      // 一次函数
      KnowledgePoint(
          subject: '数学', category: '一次函数', name: '函数的概念', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '一次函数', name: '一次函数图象', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '一次函数', name: '一次函数性质', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学',
          category: '一次函数',
          name: '求一次函数解析式',
          introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '一次函数', name: '一次函数应用', introducedGrade: 8),

      // 二元一次方程组
      KnowledgePoint(
          subject: '数学',
          category: '二元一次方程组',
          name: '代入消元法',
          introducedGrade: 8),
      KnowledgePoint(
          subject: '数学',
          category: '二元一次方程组',
          name: '加减消元法',
          introducedGrade: 8),
      KnowledgePoint(
          subject: '数学',
          category: '二元一次方程组',
          name: '方程组应用题',
          introducedGrade: 8),
      KnowledgePoint(
          subject: '数学',
          category: '二元一次方程组',
          name: '三元一次方程组',
          introducedGrade: 8),

      // 一元一次不等式
      KnowledgePoint(
          subject: '数学',
          category: '一元一次不等式',
          name: '不等式性质',
          introducedGrade: 8),
      KnowledgePoint(
          subject: '数学',
          category: '一元一次不等式',
          name: '解一元一次不等式',
          introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '一元一次不等式', name: '不等式组', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学',
          category: '一元一次不等式',
          name: '不等式应用题',
          introducedGrade: 8),

      // 三角形进阶
      KnowledgePoint(
          subject: '数学', category: '三角形进阶', name: '勾股定理', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学',
          category: '三角形进阶',
          name: '勾股定理逆定理',
          introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '三角形进阶', name: '等腰三角形', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '三角形进阶', name: '等边三角形', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '三角形进阶', name: '直角三角形', introducedGrade: 8),

      // 平行四边形
      KnowledgePoint(
          subject: '数学',
          category: '平行四边形',
          name: '平行四边形性质',
          introducedGrade: 8),
      KnowledgePoint(
          subject: '数学',
          category: '平行四边形',
          name: '平行四边形判定',
          introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '平行四边形', name: '矩形', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '平行四边形', name: '菱形', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '平行四边形', name: '正方形', introducedGrade: 8),

      // 数据分析
      KnowledgePoint(
          subject: '数学', category: '数据分析', name: '平均数', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '数据分析', name: '中位数', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '数据分析', name: '众数', introducedGrade: 8),
      KnowledgePoint(
          subject: '数学', category: '数据分析', name: '方差', introducedGrade: 8),

      // ════════════════════════════════════
      // === 九年级数学（北师大）===
      // ════════════════════════════════════

      // 一元二次方程
      KnowledgePoint(
          subject: '数学',
          category: '一元二次方程',
          name: '一元二次方程概念',
          introducedGrade: 9),
      KnowledgePoint(
          subject: '数学',
          category: '一元二次方程',
          name: '直接开平方法',
          introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '一元二次方程', name: '配方法', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '一元二次方程', name: '公式法', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '一元二次方程', name: '因式分解法', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '一元二次方程', name: '根的判别式', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学',
          category: '一元二次方程',
          name: '根与系数关系',
          introducedGrade: 9),
      KnowledgePoint(
          subject: '数学',
          category: '一元二次方程',
          name: '一元二次方程应用',
          introducedGrade: 9),

      // 二次函数
      KnowledgePoint(
          subject: '数学', category: '二次函数', name: '二次函数定义', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '二次函数', name: '二次函数图象', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '二次函数', name: '顶点与对称轴', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学',
          category: '二次函数',
          name: '求二次函数解析式',
          introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '二次函数', name: '二次函数最值', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '二次函数', name: '二次函数应用', introducedGrade: 9),

      // 反比例函数
      KnowledgePoint(
          subject: '数学',
          category: '反比例函数',
          name: '反比例函数定义',
          introducedGrade: 9),
      KnowledgePoint(
          subject: '数学',
          category: '反比例函数',
          name: '反比例函数图象',
          introducedGrade: 9),
      KnowledgePoint(
          subject: '数学',
          category: '反比例函数',
          name: '反比例函数应用',
          introducedGrade: 9),

      // 圆
      KnowledgePoint(
          subject: '数学', category: '圆', name: '圆的基本性质', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '圆', name: '垂径定理', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '圆', name: '圆心角圆周角', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '圆', name: '点与圆位置关系', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '圆', name: '直线与圆位置关系', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '圆', name: '切线性质判定', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '圆', name: '弧长与扇形面积', introducedGrade: 9),

      // 相似
      KnowledgePoint(
          subject: '数学', category: '相似', name: '比例性质', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '相似', name: '相似三角形判定', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '相似', name: '相似三角形性质', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '相似', name: '位似图形', introducedGrade: 9),

      // 锐角三角函数
      KnowledgePoint(
          subject: '数学',
          category: '锐角三角函数',
          name: '正弦余弦正切',
          introducedGrade: 9),
      KnowledgePoint(
          subject: '数学',
          category: '锐角三角函数',
          name: '特殊角三角函数值',
          introducedGrade: 9),
      KnowledgePoint(
          subject: '数学',
          category: '锐角三角函数',
          name: '解直角三角形',
          introducedGrade: 9),
      KnowledgePoint(
          subject: '数学',
          category: '锐角三角函数',
          name: '三角函数实际应用',
          introducedGrade: 9),

      // 概率统计
      KnowledgePoint(
          subject: '数学', category: '概率统计', name: '随机事件', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '概率统计', name: '用列举法求概率', introducedGrade: 9),
      KnowledgePoint(
          subject: '数学', category: '概率统计', name: '频率估计概率', introducedGrade: 9),

      // ════════════════════════════════════
      // === 七年级语文（人教）===
      // ════════════════════════════════════

      // 字词
      KnowledgePoint(
          subject: '语文', category: '字词', name: '多音字辨析', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '字词', name: '形近字辨析', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '字词', name: '词语含义理解', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '字词', name: '成语辨析', introducedGrade: 7),

      // 语法
      KnowledgePoint(
          subject: '语文', category: '语法', name: '词性判断', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '语法', name: '短语类型', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '语法', name: '句子成分', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '语法', name: '复句关系', introducedGrade: 7),

      // 修辞
      KnowledgePoint(
          subject: '语文', category: '修辞', name: '对偶', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '修辞', name: '反复', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '修辞', name: '借代', introducedGrade: 7),

      // 古诗文
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '论语十二章', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '诫子书', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '世说新语二则', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '陋室铭', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '爱莲说', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '河中石兽', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '文言虚词', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '古今异义', introducedGrade: 7),

      // 现代文阅读
      KnowledgePoint(
          subject: '语文', category: '现代文阅读', name: '记叙文阅读', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '现代文阅读', name: '散文阅读', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '现代文阅读', name: '说明文阅读', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '现代文阅读', name: '词句赏析', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '现代文阅读', name: '段落作用', introducedGrade: 7),

      // 文学常识
      KnowledgePoint(
          subject: '语文', category: '文学常识', name: '鲁迅作品', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '文学常识', name: '朱自清作品', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '文学常识', name: '老舍作品', introducedGrade: 7),

      // 名著
      KnowledgePoint(
          subject: '语文', category: '名著阅读', name: '朝花夕拾', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '名著阅读', name: '西游记', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '名著阅读', name: '骆驼祥子', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '名著阅读', name: '海底两万里', introducedGrade: 7),

      // 写作
      KnowledgePoint(
          subject: '语文', category: '写作', name: '写人记事', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '写作', name: '景物描写技巧', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '写作', name: '抒情议论', introducedGrade: 7),
      KnowledgePoint(
          subject: '语文', category: '写作', name: '细节描写', introducedGrade: 7),

      // ════════════════════════════════════
      // === 八年级语文（人教）===
      // ════════════════════════════════════

      // 字词
      KnowledgePoint(
          subject: '语文', category: '字词', name: '生僻字注音', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '字词', name: '词语感情色彩辨析', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '字词', name: '成语使用得当', introducedGrade: 8),

      // 语法与句式
      KnowledgePoint(
          subject: '语文', category: '语法与句式', name: '句子主干', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '语法与句式', name: '常见病句类型', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '语法与句式', name: '长句变短句', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '语法与句式', name: '语序调整', introducedGrade: 8),

      // 古诗文
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '桃花源记', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '小石潭记', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '岳阳楼记', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '醉翁亭记', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '爱莲说赏析', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '生于忧患死于安乐', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '富贵不能淫', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '愚公移山', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '词类活用', introducedGrade: 8),

      // 现代文阅读
      KnowledgePoint(
          subject: '语文', category: '现代文阅读', name: '新闻文体阅读', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '现代文阅读', name: '传记类阅读', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '现代文阅读', name: '议论文初步', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '现代文阅读', name: '说明方法判断', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '现代文阅读', name: '说明顺序', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '现代文阅读', name: '环境描写作用', introducedGrade: 8),

      // 名著
      KnowledgePoint(
          subject: '语文', category: '名著阅读', name: '红星照耀中国', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '名著阅读', name: '昆虫记', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文',
          category: '名著阅读',
          name: '钢铁是怎样炼成的',
          introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '名著阅读', name: '傅雷家书', introducedGrade: 8),

      // 文学常识
      KnowledgePoint(
          subject: '语文', category: '文学常识', name: '唐宋八大家', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '文学常识', name: '诗经楚辞', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '文学常识', name: '现代散文家', introducedGrade: 8),

      // 写作
      KnowledgePoint(
          subject: '语文', category: '写作', name: '游记写作', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '写作', name: '说明文写作', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '写作', name: '议论文论证', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '写作', name: '应用文格式', introducedGrade: 8),

      // 综合性学习
      KnowledgePoint(
          subject: '语文', category: '综合性学习', name: '材料概括', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '综合性学习', name: '图表分析', introducedGrade: 8),
      KnowledgePoint(
          subject: '语文', category: '综合性学习', name: '口语交际', introducedGrade: 8),

      // ════════════════════════════════════
      // === 九年级语文（人教）===
      // ════════════════════════════════════

      // 字词
      KnowledgePoint(
          subject: '语文', category: '字词', name: '中考易错字音', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '字词', name: '中考易错字形', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '字词', name: '中考成语高频', introducedGrade: 9),

      // 古诗文
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '岳阳楼记重点', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '醉翁亭记重点', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '送东阳马生序', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '出师表', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '曹刿论战', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '邹忌讽齐王纳谏', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '鱼我所欲也', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '中考诗词默写', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '诗词鉴赏', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '古诗文', name: '文言文比较阅读', introducedGrade: 9),

      // 现代文阅读
      KnowledgePoint(
          subject: '语文',
          category: '现代文阅读',
          name: '议论文论点论据',
          introducedGrade: 9),
      KnowledgePoint(
          subject: '语文',
          category: '现代文阅读',
          name: '议论文论证方法',
          introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '现代文阅读', name: '小说三要素', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '现代文阅读', name: '小说人物形象', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '现代文阅读', name: '小说情节作用', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '现代文阅读', name: '主旨概括', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '现代文阅读', name: '标题含义', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '现代文阅读', name: '开放性表达', introducedGrade: 9),

      // 名著
      KnowledgePoint(
          subject: '语文', category: '名著阅读', name: '水浒传', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '名著阅读', name: '艾青诗选', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '名著阅读', name: '简爱', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '名著阅读', name: '儒林外史', introducedGrade: 9),

      // 文学常识
      KnowledgePoint(
          subject: '语文', category: '文学常识', name: '中考文化常识', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '文学常识', name: '诗歌流派', introducedGrade: 9),

      // 写作
      KnowledgePoint(
          subject: '语文', category: '写作', name: '中考命题作文', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '写作', name: '中考材料作文', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '写作', name: '中考半命题作文', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '写作', name: '议论文写作', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '写作', name: '记叙文升格', introducedGrade: 9),

      // 综合性学习
      KnowledgePoint(
          subject: '语文', category: '综合性学习', name: '材料探究', introducedGrade: 9),
      KnowledgePoint(
          subject: '语文', category: '综合性学习', name: '语言得体', introducedGrade: 9),

      // ════════════════════════════════════
      // === 七年级英语（外研社）===
      // ════════════════════════════════════

      // 词汇
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '学校生活', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '兴趣爱好', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '季节天气', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '城市国家', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '节日庆典', introducedGrade: 7),

      // 语法时态
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '名词单复数', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '可数不可数名词', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '人称代词', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '物主代词', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '指示代词', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '冠词用法', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '基数词序数词', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '介词常用搭配', introducedGrade: 7),

      // 句型
      KnowledgePoint(
          subject: '英语',
          category: '句型',
          name: 'How many/much',
          introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '句型', name: '祈使句', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '句型', name: 'can表能力', introducedGrade: 7),

      // 日常交际
      KnowledgePoint(
          subject: '英语', category: '日常交际', name: '问路指路', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '日常交际', name: '购物对话', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '日常交际', name: '电话交流', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '日常交际', name: '邀请与回应', introducedGrade: 7),

      // 写作
      KnowledgePoint(
          subject: '英语', category: '写作', name: '自我介绍', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '写作', name: '描写朋友', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '写作', name: '日常活动', introducedGrade: 7),

      // 听力
      KnowledgePoint(
          subject: '英语', category: '听力', name: '听单词拼写', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '听力', name: '听对话答问题', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '听力', name: '听句子辨意', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '听力', name: '听短文判断正误', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '听力', name: '听数字与时间', introducedGrade: 7),

      // 阅读
      KnowledgePoint(
          subject: '英语', category: '阅读理解', name: '细节理解题', introducedGrade: 7),
      KnowledgePoint(
          subject: '英语', category: '阅读理解', name: '主旨大意题', introducedGrade: 7),

      // ════════════════════════════════════
      // === 八年级英语（外研社）===
      // ════════════════════════════════════

      // 词汇
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '体育运动', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '健康饮食', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '科技发明', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '环境保护', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '影视书籍', introducedGrade: 8),

      // 语法时态
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '一般将来时', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '过去进行时', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '现在完成时', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '形容词比较级', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '形容词最高级', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '副词用法', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '情态动词', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '动词不定式', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '动名词', introducedGrade: 8),

      // 句型
      KnowledgePoint(
          subject: '英语', category: '句型', name: '宾语从句', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '句型', name: '感叹句', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语',
          category: '句型',
          name: 'so that 句型',
          introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '句型', name: 'too to 句型', introducedGrade: 8),

      // 日常交际
      KnowledgePoint(
          subject: '英语', category: '日常交际', name: '看病就医', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '日常交际', name: '建议与劝告', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '日常交际', name: '同意与反对', introducedGrade: 8),

      // 写作
      KnowledgePoint(
          subject: '英语', category: '写作', name: '看图作文', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '写作', name: '电子邮件', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '写作', name: '观点表达', introducedGrade: 8),

      // 听力
      KnowledgePoint(
          subject: '英语', category: '听力', name: '听对话选图片', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '听力', name: '听长对话', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '听力', name: '听短文填空', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '听力', name: '听新闻报道', introducedGrade: 8),

      // 阅读
      KnowledgePoint(
          subject: '英语', category: '阅读理解', name: '推理判断题', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '阅读理解', name: '词义猜测题', introducedGrade: 8),
      KnowledgePoint(
          subject: '英语', category: '阅读理解', name: '任务型阅读', introducedGrade: 8),

      // ════════════════════════════════════
      // === 九年级英语（外研社）===
      // ════════════════════════════════════

      // 词汇
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '社会热点', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '历史文化', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '职业理想', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '词汇', name: '中考高频词', introducedGrade: 9),

      // 语法时态
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '过去完成时', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '被动语态', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '虚拟语气初步', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语',
          category: '语法时态',
          name: '直接引语间接引语',
          introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '语法时态', name: '反义疑问句', introducedGrade: 9),

      // 句型
      KnowledgePoint(
          subject: '英语', category: '句型', name: '定语从句', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '句型', name: '状语从句', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '句型', name: '主语从句', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '句型', name: '强调句型', introducedGrade: 9),

      // 日常交际
      KnowledgePoint(
          subject: '英语', category: '日常交际', name: '表达感谢道歉', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '日常交际', name: '讨论计划', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '日常交际', name: '请求许可', introducedGrade: 9),

      // 写作
      KnowledgePoint(
          subject: '英语', category: '写作', name: '中考话题作文', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '写作', name: '议论文写作', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '写作', name: '书信格式', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '写作', name: '通知与海报', introducedGrade: 9),

      // 听力
      KnowledgePoint(
          subject: '英语', category: '听力', name: '听独白回答', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '听力', name: '听采访', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '听力', name: '听材料补全表格', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '听力', name: '听辨态度观点', introducedGrade: 9),

      // 阅读
      KnowledgePoint(
          subject: '英语', category: '阅读理解', name: '七选五', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '阅读理解', name: '完形填空', introducedGrade: 9),
      KnowledgePoint(
          subject: '英语', category: '阅读理解', name: '中考长难句', introducedGrade: 9),

      // ════════════════════════════════════
      // === 八年级物理（人教）===
      // ════════════════════════════════════

      // 声学
      KnowledgePoint(
          subject: '物理', category: '声学', name: '声音的产生', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '声学', name: '声音的传播', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '声学', name: '声音的特性', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '声学', name: '噪声的危害与控制', introducedGrade: 8),

      // 光学
      KnowledgePoint(
          subject: '物理', category: '光学', name: '光的直线传播', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '光学', name: '光的反射', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '光学', name: '平面镜成像', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '光学', name: '光的折射', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '光学', name: '透镜成像规律', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '光学', name: '眼睛与眼镜', introducedGrade: 8),

      // 热学
      KnowledgePoint(
          subject: '物理', category: '热学', name: '温度与温度计', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '热学', name: '熔化与凝固', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '热学', name: '汽化与液化', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '热学', name: '升华与凝华', introducedGrade: 8),

      // 运动
      KnowledgePoint(
          subject: '物理', category: '运动', name: '长度与时间测量', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '运动', name: '机械运动', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '运动', name: '速度', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '运动', name: '匀速直线运动', introducedGrade: 8),

      // 力学
      KnowledgePoint(
          subject: '物理', category: '力学', name: '质量与密度', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '力学', name: '密度测量', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '力学', name: '力的作用', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '力学', name: '弹力与弹簧测力计', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '力学', name: '重力', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '力学', name: '摩擦力', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '力学', name: '牛顿第一定律', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '力学', name: '二力平衡', introducedGrade: 8),

      // 压强浮力
      KnowledgePoint(
          subject: '物理', category: '压强浮力', name: '压强', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '压强浮力', name: '液体压强', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '压强浮力', name: '大气压强', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '压强浮力', name: '浮力', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '压强浮力', name: '阿基米德原理', introducedGrade: 8),
      KnowledgePoint(
          subject: '物理', category: '压强浮力', name: '物体浮沉条件', introducedGrade: 8),

      // ════════════════════════════════════
      // === 九年级物理（人教）===
      // ════════════════════════════════════

      // 能量
      KnowledgePoint(
          subject: '物理', category: '能量', name: '功', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '能量', name: '功率', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '能量', name: '动能与势能', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '能量', name: '机械能转化', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '能量', name: '简单机械-杠杆', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '能量', name: '简单机械-滑轮', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '能量', name: '机械效率', introducedGrade: 9),

      // 热学
      KnowledgePoint(
          subject: '物理', category: '热学', name: '分子热运动', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '热学', name: '内能', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '热学', name: '比热容', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '热学', name: '热机与效率', introducedGrade: 9),

      // 电学
      KnowledgePoint(
          subject: '物理', category: '电学', name: '电荷与摩擦起电', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '电学', name: '电流与电路', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '电学', name: '串联与并联', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '电学', name: '电压', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '电学', name: '电阻', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '电学', name: '欧姆定律', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '电学', name: '电功与电功率', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '电学', name: '焦耳定律', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '电学', name: '家庭电路', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '电学', name: '安全用电', introducedGrade: 9),

      // 电磁
      KnowledgePoint(
          subject: '物理', category: '电磁', name: '磁现象与磁场', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '电磁', name: '电生磁', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '电磁', name: '电磁铁', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '电磁', name: '电动机原理', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '电磁', name: '电磁感应', introducedGrade: 9),

      // 信息能源
      KnowledgePoint(
          subject: '物理', category: '信息能源', name: '电磁波', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '信息能源', name: '能源利用', introducedGrade: 9),
      KnowledgePoint(
          subject: '物理', category: '信息能源', name: '核能', introducedGrade: 9),

      // ════════════════════════════════════
      // === 九年级化学（人教）===
      // ════════════════════════════════════

      // 物质构成
      KnowledgePoint(
          subject: '化学', category: '物质构成', name: '分子与原子', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '物质构成', name: '原子结构', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '物质构成', name: '元素', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '物质构成', name: '元素周期表', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '物质构成', name: '离子', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '物质构成', name: '化学式与化合价', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '物质构成', name: '相对原子质量', introducedGrade: 9),

      // 化学反应
      KnowledgePoint(
          subject: '化学',
          category: '化学反应',
          name: '物理变化与化学变化',
          introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '化学反应', name: '化学方程式书写', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '化学反应', name: '质量守恒定律', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '化学反应', name: '化学方程式计算', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '化学反应', name: '化学反应类型', introducedGrade: 9),

      // 空气与氧气
      KnowledgePoint(
          subject: '化学', category: '空气与氧气', name: '空气的成分', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '空气与氧气', name: '氧气的性质', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '空气与氧气', name: '氧气的制取', introducedGrade: 9),

      // 燃烧氧化
      KnowledgePoint(
          subject: '化学', category: '燃烧氧化', name: '燃烧条件', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '燃烧氧化', name: '灭火原理', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '燃烧氧化', name: '化石燃料', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '燃烧氧化', name: '碳和碳的氧化物', introducedGrade: 9),

      // 水
      KnowledgePoint(
          subject: '化学', category: '水', name: '水的组成', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '水', name: '水的净化', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '水', name: '硬水与软水', introducedGrade: 9),

      // 溶液
      KnowledgePoint(
          subject: '化学', category: '溶液', name: '溶液的形成', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '溶液', name: '溶解度', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '溶液', name: '溶质质量分数', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '溶液', name: '溶液配制', introducedGrade: 9),

      // 金属
      KnowledgePoint(
          subject: '化学', category: '金属', name: '金属物理性质', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '金属', name: '金属化学性质', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '金属', name: '金属活动性顺序', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '金属', name: '金属冶炼', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '金属', name: '金属防护', introducedGrade: 9),

      // 酸碱盐
      KnowledgePoint(
          subject: '化学', category: '酸碱盐', name: '常见的酸', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '酸碱盐', name: '常见的碱', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '酸碱盐', name: '中和反应', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '酸碱盐', name: 'pH与酸碱度', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '酸碱盐', name: '常见的盐', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '酸碱盐', name: '复分解反应', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学', category: '酸碱盐', name: '化肥', introducedGrade: 9),

      // 化学与生活
      KnowledgePoint(
          subject: '化学', category: '化学与生活', name: '有机物', introducedGrade: 9),
      KnowledgePoint(
          subject: '化学',
          category: '化学与生活',
          name: '人类重要营养物质',
          introducedGrade: 9),
      KnowledgePoint(
          subject: '化学',
          category: '化学与生活',
          name: '化学元素与人体健康',
          introducedGrade: 9),
    ];
