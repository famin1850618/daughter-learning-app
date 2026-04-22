import '../models/curriculum.dart';

/// 完整课程体系种子数据
/// 数学：北师大版 | 英语：外研社/剑桥对齐 | 其余：人教版
List<Chapter> get curriculumChapters => [

  // ══════════════════════════════════════════
  // 数学（北师大版）六年级下 ～ 初三
  // ══════════════════════════════════════════
  Chapter(subject: '数学', grade: 6, orderIndex: 1,  chapterName: '分数除法'),
  Chapter(subject: '数学', grade: 6, orderIndex: 2,  chapterName: '比和比例'),
  Chapter(subject: '数学', grade: 6, orderIndex: 3,  chapterName: '圆'),
  Chapter(subject: '数学', grade: 6, orderIndex: 4,  chapterName: '确定与不确定'),
  Chapter(subject: '数学', grade: 6, orderIndex: 5,  chapterName: '数据的处理'),
  Chapter(subject: '数学', grade: 6, orderIndex: 6,  chapterName: '总复习'),

  Chapter(subject: '数学', grade: 7, orderIndex: 1,  chapterName: '丰富的图形世界'),
  Chapter(subject: '数学', grade: 7, orderIndex: 2,  chapterName: '有理数及其运算'),
  Chapter(subject: '数学', grade: 7, orderIndex: 3,  chapterName: '字母表示数'),
  Chapter(subject: '数学', grade: 7, orderIndex: 4,  chapterName: '基本平面图形'),
  Chapter(subject: '数学', grade: 7, orderIndex: 5,  chapterName: '一元一次方程'),
  Chapter(subject: '数学', grade: 7, orderIndex: 6,  chapterName: '整式的加减'),
  Chapter(subject: '数学', grade: 7, orderIndex: 7,  chapterName: '平行线与相交线'),
  Chapter(subject: '数学', grade: 7, orderIndex: 8,  chapterName: '数据的收集与整理'),
  Chapter(subject: '数学', grade: 7, orderIndex: 9,  chapterName: '三角形'),
  Chapter(subject: '数学', grade: 7, orderIndex: 10, chapterName: '概率初步'),

  Chapter(subject: '数学', grade: 8, orderIndex: 1,  chapterName: '勾股定理'),
  Chapter(subject: '数学', grade: 8, orderIndex: 2,  chapterName: '实数'),
  Chapter(subject: '数学', grade: 8, orderIndex: 3,  chapterName: '整式的乘法'),
  Chapter(subject: '数学', grade: 8, orderIndex: 4,  chapterName: '因式分解'),
  Chapter(subject: '数学', grade: 8, orderIndex: 5,  chapterName: '分式'),
  Chapter(subject: '数学', grade: 8, orderIndex: 6,  chapterName: '平行四边形'),
  Chapter(subject: '数学', grade: 8, orderIndex: 7,  chapterName: '一次函数'),
  Chapter(subject: '数学', grade: 8, orderIndex: 8,  chapterName: '数据的分析'),
  Chapter(subject: '数学', grade: 8, orderIndex: 9,  chapterName: '图形的平移与旋转'),

  Chapter(subject: '数学', grade: 9, orderIndex: 1,  chapterName: '一元二次方程'),
  Chapter(subject: '数学', grade: 9, orderIndex: 2,  chapterName: '二次函数'),
  Chapter(subject: '数学', grade: 9, orderIndex: 3,  chapterName: '反比例函数'),
  Chapter(subject: '数学', grade: 9, orderIndex: 4,  chapterName: '圆'),
  Chapter(subject: '数学', grade: 9, orderIndex: 5,  chapterName: '图形的相似'),
  Chapter(subject: '数学', grade: 9, orderIndex: 6,  chapterName: '锐角三角函数'),
  Chapter(subject: '数学', grade: 9, orderIndex: 7,  chapterName: '统计与概率'),

  // ══════════════════════════════════════════
  // 语文（人教版）六年级下 ～ 初三
  // ══════════════════════════════════════════
  Chapter(subject: '语文', grade: 6, orderIndex: 1,  chapterName: '字词与成语'),
  Chapter(subject: '语文', grade: 6, orderIndex: 2,  chapterName: '古诗词背诵'),
  Chapter(subject: '语文', grade: 6, orderIndex: 3,  chapterName: '文言文阅读'),
  Chapter(subject: '语文', grade: 6, orderIndex: 4,  chapterName: '现代文阅读'),
  Chapter(subject: '语文', grade: 6, orderIndex: 5,  chapterName: '习作与写作'),
  Chapter(subject: '语文', grade: 6, orderIndex: 6,  chapterName: '口语交际'),

  Chapter(subject: '语文', grade: 7, orderIndex: 1,  chapterName: '字词积累与运用'),
  Chapter(subject: '语文', grade: 7, orderIndex: 2,  chapterName: '古代诗歌鉴赏'),
  Chapter(subject: '语文', grade: 7, orderIndex: 3,  chapterName: '文言文（《论语》《世说新语》等）'),
  Chapter(subject: '语文', grade: 7, orderIndex: 4,  chapterName: '写景状物散文'),
  Chapter(subject: '语文', grade: 7, orderIndex: 5,  chapterName: '叙事性作品阅读'),
  Chapter(subject: '语文', grade: 7, orderIndex: 6,  chapterName: '说明文阅读'),
  Chapter(subject: '语文', grade: 7, orderIndex: 7,  chapterName: '写作：记叙文'),

  Chapter(subject: '语文', grade: 8, orderIndex: 1,  chapterName: '字词与语法'),
  Chapter(subject: '语文', grade: 8, orderIndex: 2,  chapterName: '古诗词（八年级篇目）'),
  Chapter(subject: '语文', grade: 8, orderIndex: 3,  chapterName: '文言文（《三峡》《桃花源记》等）'),
  Chapter(subject: '语文', grade: 8, orderIndex: 4,  chapterName: '回忆性散文'),
  Chapter(subject: '语文', grade: 8, orderIndex: 5,  chapterName: '说明文（事物与事理）'),
  Chapter(subject: '语文', grade: 8, orderIndex: 6,  chapterName: '新闻与非连续性文本'),
  Chapter(subject: '语文', grade: 8, orderIndex: 7,  chapterName: '写作：说明文与议论文'),

  Chapter(subject: '语文', grade: 9, orderIndex: 1,  chapterName: '字词与语言运用'),
  Chapter(subject: '语文', grade: 9, orderIndex: 2,  chapterName: '古诗词（九年级篇目）'),
  Chapter(subject: '语文', grade: 9, orderIndex: 3,  chapterName: '文言文（《岳阳楼记》《醉翁亭记》等）'),
  Chapter(subject: '语文', grade: 9, orderIndex: 4,  chapterName: '小说阅读（现代）'),
  Chapter(subject: '语文', grade: 9, orderIndex: 5,  chapterName: '议论文阅读'),
  Chapter(subject: '语文', grade: 9, orderIndex: 6,  chapterName: '中外经典名著导读'),
  Chapter(subject: '语文', grade: 9, orderIndex: 7,  chapterName: '写作：综合写作与应试'),

  // ══════════════════════════════════════════
  // 英语（外研社/剑桥对齐国际通用体系）六年级下 ～ 初三
  // ══════════════════════════════════════════
  Chapter(subject: '英语', grade: 6, orderIndex: 1,  chapterName: '词汇积累（小学核心1500词）'),
  Chapter(subject: '英语', grade: 6, orderIndex: 2,  chapterName: '一般现在时与现在进行时'),
  Chapter(subject: '英语', grade: 6, orderIndex: 3,  chapterName: '一般过去时'),
  Chapter(subject: '英语', grade: 6, orderIndex: 4,  chapterName: '简单句与句型转换'),
  Chapter(subject: '英语', grade: 6, orderIndex: 5,  chapterName: '日常交际用语'),
  Chapter(subject: '英语', grade: 6, orderIndex: 6,  chapterName: '基础阅读理解'),

  Chapter(subject: '英语', grade: 7, orderIndex: 1,  chapterName: '词汇扩展（初中核心词2000词）'),
  Chapter(subject: '英语', grade: 7, orderIndex: 2,  chapterName: '一般将来时与情态动词'),
  Chapter(subject: '英语', grade: 7, orderIndex: 3,  chapterName: '比较级与最高级'),
  Chapter(subject: '英语', grade: 7, orderIndex: 4,  chapterName: 'there be 句型与介词'),
  Chapter(subject: '英语', grade: 7, orderIndex: 5,  chapterName: '阅读理解：记叙文'),
  Chapter(subject: '英语', grade: 7, orderIndex: 6,  chapterName: '写作：简单段落'),

  Chapter(subject: '英语', grade: 8, orderIndex: 1,  chapterName: '词汇扩展（3000词）'),
  Chapter(subject: '英语', grade: 8, orderIndex: 2,  chapterName: '现在完成时'),
  Chapter(subject: '英语', grade: 8, orderIndex: 3,  chapterName: '被动语态'),
  Chapter(subject: '英语', grade: 8, orderIndex: 4,  chapterName: '宾语从句'),
  Chapter(subject: '英语', grade: 8, orderIndex: 5,  chapterName: '阅读理解：说明文与议论文'),
  Chapter(subject: '英语', grade: 8, orderIndex: 6,  chapterName: '写作：应用文（书信/邮件）'),

  Chapter(subject: '英语', grade: 9, orderIndex: 1,  chapterName: '词汇扩展（4000词）'),
  Chapter(subject: '英语', grade: 9, orderIndex: 2,  chapterName: '定语从句'),
  Chapter(subject: '英语', grade: 9, orderIndex: 3,  chapterName: '各类从句综合'),
  Chapter(subject: '英语', grade: 9, orderIndex: 4,  chapterName: '阅读理解：综合题型'),
  Chapter(subject: '英语', grade: 9, orderIndex: 5,  chapterName: '写作：议论文与说明文'),
  Chapter(subject: '英语', grade: 9, orderIndex: 6,  chapterName: '听力与口语表达'),

  // ══════════════════════════════════════════
  // 物理（人教版）初二 ～ 初三
  // ══════════════════════════════════════════
  Chapter(subject: '物理', grade: 8, orderIndex: 1,  chapterName: '机械运动'),
  Chapter(subject: '物理', grade: 8, orderIndex: 2,  chapterName: '声现象'),
  Chapter(subject: '物理', grade: 8, orderIndex: 3,  chapterName: '光现象'),
  Chapter(subject: '物理', grade: 8, orderIndex: 4,  chapterName: '透镜及其应用'),
  Chapter(subject: '物理', grade: 8, orderIndex: 5,  chapterName: '物态变化'),
  Chapter(subject: '物理', grade: 8, orderIndex: 6,  chapterName: '质量与密度'),

  Chapter(subject: '物理', grade: 9, orderIndex: 1,  chapterName: '力与运动'),
  Chapter(subject: '物理', grade: 9, orderIndex: 2,  chapterName: '压强'),
  Chapter(subject: '物理', grade: 9, orderIndex: 3,  chapterName: '浮力'),
  Chapter(subject: '物理', grade: 9, orderIndex: 4,  chapterName: '功与机械能'),
  Chapter(subject: '物理', grade: 9, orderIndex: 5,  chapterName: '电流与电路'),
  Chapter(subject: '物理', grade: 9, orderIndex: 6,  chapterName: '欧姆定律'),
  Chapter(subject: '物理', grade: 9, orderIndex: 7,  chapterName: '电功率'),
  Chapter(subject: '物理', grade: 9, orderIndex: 8,  chapterName: '电磁现象'),

  // ══════════════════════════════════════════
  // 化学（人教版）初三
  // ══════════════════════════════════════════
  Chapter(subject: '化学', grade: 9, orderIndex: 1,  chapterName: '走进化学世界'),
  Chapter(subject: '化学', grade: 9, orderIndex: 2,  chapterName: '我们周围的空气'),
  Chapter(subject: '化学', grade: 9, orderIndex: 3,  chapterName: '物质构成的奥秘'),
  Chapter(subject: '化学', grade: 9, orderIndex: 4,  chapterName: '自然界的水'),
  Chapter(subject: '化学', grade: 9, orderIndex: 5,  chapterName: '化学方程式'),
  Chapter(subject: '化学', grade: 9, orderIndex: 6,  chapterName: '碳和碳的氧化物'),
  Chapter(subject: '化学', grade: 9, orderIndex: 7,  chapterName: '燃料及其利用'),
  Chapter(subject: '化学', grade: 9, orderIndex: 8,  chapterName: '金属和金属材料'),
  Chapter(subject: '化学', grade: 9, orderIndex: 9,  chapterName: '溶液'),
  Chapter(subject: '化学', grade: 9, orderIndex: 10, chapterName: '酸和碱'),
  Chapter(subject: '化学', grade: 9, orderIndex: 11, chapterName: '盐与化肥'),

  // ══════════════════════════════════════════
  // AI（自定义体系）六年级 ～ 初三
  // ══════════════════════════════════════════
  Chapter(subject: 'AI', grade: 6, orderIndex: 1,  chapterName: 'Scratch编程基础'),
  Chapter(subject: 'AI', grade: 6, orderIndex: 2,  chapterName: '条件判断与循环'),
  Chapter(subject: 'AI', grade: 6, orderIndex: 3,  chapterName: 'Scratch动画与游戏制作'),
  Chapter(subject: 'AI', grade: 6, orderIndex: 4,  chapterName: '什么是人工智能'),

  Chapter(subject: 'AI', grade: 7, orderIndex: 1,  chapterName: 'Python入门与环境搭建'),
  Chapter(subject: 'AI', grade: 7, orderIndex: 2,  chapterName: 'Python变量与数据类型'),
  Chapter(subject: 'AI', grade: 7, orderIndex: 3,  chapterName: 'Python条件与循环'),
  Chapter(subject: 'AI', grade: 7, orderIndex: 4,  chapterName: 'Python函数与模块'),
  Chapter(subject: 'AI', grade: 7, orderIndex: 5,  chapterName: 'AI应用体验：图像识别与语音'),

  Chapter(subject: 'AI', grade: 8, orderIndex: 1,  chapterName: 'Python列表与字典'),
  Chapter(subject: 'AI', grade: 8, orderIndex: 2,  chapterName: '数据处理与可视化（matplotlib）'),
  Chapter(subject: 'AI', grade: 8, orderIndex: 3,  chapterName: '机器学习基本概念'),
  Chapter(subject: 'AI', grade: 8, orderIndex: 4,  chapterName: '分类与预测：决策树入门'),
  Chapter(subject: 'AI', grade: 8, orderIndex: 5,  chapterName: 'AI伦理与数据隐私'),

  Chapter(subject: 'AI', grade: 9, orderIndex: 1,  chapterName: '神经网络基础概念'),
  Chapter(subject: 'AI', grade: 9, orderIndex: 2,  chapterName: '自然语言处理入门'),
  Chapter(subject: 'AI', grade: 9, orderIndex: 3,  chapterName: '计算机视觉基础'),
  Chapter(subject: 'AI', grade: 9, orderIndex: 4,  chapterName: 'AI项目实战：制作智能小程序'),
  Chapter(subject: 'AI', grade: 9, orderIndex: 5,  chapterName: 'AI与未来社会'),
];
