import '../models/curriculum.dart';

/// 完整课程体系种子数据
/// 数学：北师大版 | 语文：人教版部编版（按单元主题）| 英语：外研社版（按技能分类）| 物理/化学：人教版
List<Chapter> get curriculumChapters => [

  // ══════════════════════════════════════════
  // 数学（北师大版）六年级下 ～ 初三
  // ══════════════════════════════════════════
  Chapter(subject: '数学', grade: 6, orderIndex: 1,  chapterName: '圆柱与圆锥'),
  Chapter(subject: '数学', grade: 6, orderIndex: 2,  chapterName: '比例'),
  Chapter(subject: '数学', grade: 6, orderIndex: 3,  chapterName: '图形的运动'),
  Chapter(subject: '数学', grade: 6, orderIndex: 4,  chapterName: '正比例和反比例'),
  Chapter(subject: '数学', grade: 6, orderIndex: 5,  chapterName: '数学好玩'),
  Chapter(subject: '数学', grade: 6, orderIndex: 6,  chapterName: '总复习'),

  Chapter(subject: '数学', grade: 7, orderIndex: 1,  chapterName: '丰富的图形世界'),
  Chapter(subject: '数学', grade: 7, orderIndex: 2,  chapterName: '有理数及其运算'),
  Chapter(subject: '数学', grade: 7, orderIndex: 3,  chapterName: '整式及其加减'),
  Chapter(subject: '数学', grade: 7, orderIndex: 4,  chapterName: '基本平面图形'),
  Chapter(subject: '数学', grade: 7, orderIndex: 5,  chapterName: '一元一次方程'),
  Chapter(subject: '数学', grade: 7, orderIndex: 6,  chapterName: '数据的收集与整理'),
  Chapter(subject: '数学', grade: 7, orderIndex: 7,  chapterName: '整式的乘除'),
  Chapter(subject: '数学', grade: 7, orderIndex: 8,  chapterName: '相交线与平行线'),
  Chapter(subject: '数学', grade: 7, orderIndex: 9,  chapterName: '变量间的关系'),
  Chapter(subject: '数学', grade: 7, orderIndex: 10, chapterName: '三角形'),
  Chapter(subject: '数学', grade: 7, orderIndex: 11, chapterName: '生活中的轴对称'),
  Chapter(subject: '数学', grade: 7, orderIndex: 12, chapterName: '概率初步'),

  Chapter(subject: '数学', grade: 8, orderIndex: 1,  chapterName: '勾股定理'),
  Chapter(subject: '数学', grade: 8, orderIndex: 2,  chapterName: '实数'),
  Chapter(subject: '数学', grade: 8, orderIndex: 3,  chapterName: '位置与坐标'),
  Chapter(subject: '数学', grade: 8, orderIndex: 4,  chapterName: '一次函数'),
  Chapter(subject: '数学', grade: 8, orderIndex: 5,  chapterName: '二元一次方程组'),
  Chapter(subject: '数学', grade: 8, orderIndex: 6,  chapterName: '数据的分析'),
  Chapter(subject: '数学', grade: 8, orderIndex: 7,  chapterName: '平行线的证明'),
  Chapter(subject: '数学', grade: 8, orderIndex: 8,  chapterName: '三角形的证明'),
  Chapter(subject: '数学', grade: 8, orderIndex: 9,  chapterName: '一元一次不等式与不等式组'),
  Chapter(subject: '数学', grade: 8, orderIndex: 10, chapterName: '图形的平移与旋转'),
  Chapter(subject: '数学', grade: 8, orderIndex: 11, chapterName: '因式分解'),
  Chapter(subject: '数学', grade: 8, orderIndex: 12, chapterName: '分式与分式方程'),
  Chapter(subject: '数学', grade: 8, orderIndex: 13, chapterName: '平行四边形'),

  Chapter(subject: '数学', grade: 9, orderIndex: 1,  chapterName: '特殊平行四边形'),
  Chapter(subject: '数学', grade: 9, orderIndex: 2,  chapterName: '一元二次方程'),
  Chapter(subject: '数学', grade: 9, orderIndex: 3,  chapterName: '概率的进一步认识'),
  Chapter(subject: '数学', grade: 9, orderIndex: 4,  chapterName: '图形的相似'),
  Chapter(subject: '数学', grade: 9, orderIndex: 5,  chapterName: '投影与视图'),
  Chapter(subject: '数学', grade: 9, orderIndex: 6,  chapterName: '反比例函数'),
  Chapter(subject: '数学', grade: 9, orderIndex: 7,  chapterName: '直角三角形的边角关系'),
  Chapter(subject: '数学', grade: 9, orderIndex: 8,  chapterName: '二次函数'),
  Chapter(subject: '数学', grade: 9, orderIndex: 9,  chapterName: '圆'),

  // ══════════════════════════════════════════
  // 语文（人教版部编版）六年级下 ～ 初三，按单元主题
  // ══════════════════════════════════════════
  Chapter(subject: '语文', grade: 6, orderIndex: 1,  chapterName: '第一单元：民风民俗'),
  Chapter(subject: '语文', grade: 6, orderIndex: 2,  chapterName: '第二单元：外国名著'),
  Chapter(subject: '语文', grade: 6, orderIndex: 3,  chapterName: '第三单元：真情流露'),
  Chapter(subject: '语文', grade: 6, orderIndex: 4,  chapterName: '第四单元：革命精神'),
  Chapter(subject: '语文', grade: 6, orderIndex: 5,  chapterName: '第五单元：科学精神'),
  Chapter(subject: '语文', grade: 6, orderIndex: 6,  chapterName: '第六单元：难忘小学生活'),

  Chapter(subject: '语文', grade: 7, orderIndex: 1,  chapterName: '七上·第一单元：四季美景'),
  Chapter(subject: '语文', grade: 7, orderIndex: 2,  chapterName: '七上·第二单元：至爱亲情'),
  Chapter(subject: '语文', grade: 7, orderIndex: 3,  chapterName: '七上·第三单元：学习生活'),
  Chapter(subject: '语文', grade: 7, orderIndex: 4,  chapterName: '七上·第四单元：人生之舟'),
  Chapter(subject: '语文', grade: 7, orderIndex: 5,  chapterName: '七上·第五单元：动物与人'),
  Chapter(subject: '语文', grade: 7, orderIndex: 6,  chapterName: '七上·第六单元：想象之翼'),
  Chapter(subject: '语文', grade: 7, orderIndex: 7,  chapterName: '七下·第一单元：群星闪耀'),
  Chapter(subject: '语文', grade: 7, orderIndex: 8,  chapterName: '七下·第二单元：家国情怀'),
  Chapter(subject: '语文', grade: 7, orderIndex: 9,  chapterName: '七下·第三单元：凡人小事'),
  Chapter(subject: '语文', grade: 7, orderIndex: 10, chapterName: '七下·第四单元：修身正己'),
  Chapter(subject: '语文', grade: 7, orderIndex: 11, chapterName: '七下·第五单元：哲思与志趣'),
  Chapter(subject: '语文', grade: 7, orderIndex: 12, chapterName: '七下·第六单元：探险与科学'),

  Chapter(subject: '语文', grade: 8, orderIndex: 1,  chapterName: '八上·第一单元：新闻阅读'),
  Chapter(subject: '语文', grade: 8, orderIndex: 2,  chapterName: '八上·第二单元：回忆往事'),
  Chapter(subject: '语文', grade: 8, orderIndex: 3,  chapterName: '八上·第三单元：山川美景'),
  Chapter(subject: '语文', grade: 8, orderIndex: 4,  chapterName: '八上·第四单元：情感哲思'),
  Chapter(subject: '语文', grade: 8, orderIndex: 5,  chapterName: '八上·第五单元：文明的印迹'),
  Chapter(subject: '语文', grade: 8, orderIndex: 6,  chapterName: '八上·第六单元：情操与志趣'),
  Chapter(subject: '语文', grade: 8, orderIndex: 7,  chapterName: '八下·第一单元：民俗风情'),
  Chapter(subject: '语文', grade: 8, orderIndex: 8,  chapterName: '八下·第二单元：自然科学'),
  Chapter(subject: '语文', grade: 8, orderIndex: 9,  chapterName: '八下·第三单元：古代山水'),
  Chapter(subject: '语文', grade: 8, orderIndex: 10, chapterName: '八下·第四单元：演讲口语'),
  Chapter(subject: '语文', grade: 8, orderIndex: 11, chapterName: '八下·第五单元：山水游记'),
  Chapter(subject: '语文', grade: 8, orderIndex: 12, chapterName: '八下·第六单元：古代哲思'),

  Chapter(subject: '语文', grade: 9, orderIndex: 1,  chapterName: '九上·第一单元：诗歌鉴赏'),
  Chapter(subject: '语文', grade: 9, orderIndex: 2,  chapterName: '九上·第二单元：议论文·思辨'),
  Chapter(subject: '语文', grade: 9, orderIndex: 3,  chapterName: '九上·第三单元：山水古文'),
  Chapter(subject: '语文', grade: 9, orderIndex: 4,  chapterName: '九上·第四单元：小说阅读'),
  Chapter(subject: '语文', grade: 9, orderIndex: 5,  chapterName: '九上·第五单元：议论文·创新'),
  Chapter(subject: '语文', grade: 9, orderIndex: 6,  chapterName: '九上·第六单元：古典小说'),
  Chapter(subject: '语文', grade: 9, orderIndex: 7,  chapterName: '九下·第一单元：现代诗歌'),
  Chapter(subject: '语文', grade: 9, orderIndex: 8,  chapterName: '九下·第二单元：小说人物'),
  Chapter(subject: '语文', grade: 9, orderIndex: 9,  chapterName: '九下·第三单元：先秦诸子'),
  Chapter(subject: '语文', grade: 9, orderIndex: 10, chapterName: '九下·第四单元：文艺理论'),
  Chapter(subject: '语文', grade: 9, orderIndex: 11, chapterName: '九下·第五单元：戏剧阅读'),
  Chapter(subject: '语文', grade: 9, orderIndex: 12, chapterName: '九下·第六单元：古代史传'),

  // ══════════════════════════════════════════
  // 英语（外研社版）六年级下 ～ 初三，按技能分类
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
  Chapter(subject: '物理', grade: 8, orderIndex: 3,  chapterName: '物态变化'),
  Chapter(subject: '物理', grade: 8, orderIndex: 4,  chapterName: '光现象'),
  Chapter(subject: '物理', grade: 8, orderIndex: 5,  chapterName: '透镜及其应用'),
  Chapter(subject: '物理', grade: 8, orderIndex: 6,  chapterName: '质量与密度'),
  Chapter(subject: '物理', grade: 8, orderIndex: 7,  chapterName: '力'),
  Chapter(subject: '物理', grade: 8, orderIndex: 8,  chapterName: '运动和力'),
  Chapter(subject: '物理', grade: 8, orderIndex: 9,  chapterName: '压强'),
  Chapter(subject: '物理', grade: 8, orderIndex: 10, chapterName: '浮力'),
  Chapter(subject: '物理', grade: 8, orderIndex: 11, chapterName: '功和机械能'),
  Chapter(subject: '物理', grade: 8, orderIndex: 12, chapterName: '简单机械'),

  Chapter(subject: '物理', grade: 9, orderIndex: 1,  chapterName: '内能'),
  Chapter(subject: '物理', grade: 9, orderIndex: 2,  chapterName: '热机'),
  Chapter(subject: '物理', grade: 9, orderIndex: 3,  chapterName: '电流和电路'),
  Chapter(subject: '物理', grade: 9, orderIndex: 4,  chapterName: '电压和电阻'),
  Chapter(subject: '物理', grade: 9, orderIndex: 5,  chapterName: '欧姆定律'),
  Chapter(subject: '物理', grade: 9, orderIndex: 6,  chapterName: '电功和电热'),
  Chapter(subject: '物理', grade: 9, orderIndex: 7,  chapterName: '安全用电'),
  Chapter(subject: '物理', grade: 9, orderIndex: 8,  chapterName: '电与磁'),
  Chapter(subject: '物理', grade: 9, orderIndex: 9,  chapterName: '信息的传输'),
  Chapter(subject: '物理', grade: 9, orderIndex: 10, chapterName: '能源'),

  // ══════════════════════════════════════════
  // 化学（人教版2024版）初三
  // ══════════════════════════════════════════
  Chapter(subject: '化学', grade: 9, orderIndex: 1,  chapterName: '走进化学世界'),
  Chapter(subject: '化学', grade: 9, orderIndex: 2,  chapterName: '空气和氧气'),
  Chapter(subject: '化学', grade: 9, orderIndex: 3,  chapterName: '物质构成的奥秘'),
  Chapter(subject: '化学', grade: 9, orderIndex: 4,  chapterName: '自然界的水'),
  Chapter(subject: '化学', grade: 9, orderIndex: 5,  chapterName: '化学反应的定量关系'),
  Chapter(subject: '化学', grade: 9, orderIndex: 6,  chapterName: '碳和碳的氧化物'),
  Chapter(subject: '化学', grade: 9, orderIndex: 7,  chapterName: '能源的合理利用与开发'),
  Chapter(subject: '化学', grade: 9, orderIndex: 8,  chapterName: '金属和金属材料'),
  Chapter(subject: '化学', grade: 9, orderIndex: 9,  chapterName: '溶液'),
  Chapter(subject: '化学', grade: 9, orderIndex: 10, chapterName: '酸、碱、盐'),
  Chapter(subject: '化学', grade: 9, orderIndex: 11, chapterName: '化学与社会发展'),

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

  // ══════════════════════════════════════════
  // V3.10 新增：真题综合 chapter（小升初/中考）
  // 数理化语：教材章节体系下补"综合卷"chapter，收纳跨多 chapter 的小升初/中考真题
  // ══════════════════════════════════════════
  Chapter(subject: '数学', grade: 6, orderIndex: 99, chapterName: '小升初综合'),
  Chapter(subject: '数学', grade: 9, orderIndex: 99, chapterName: '中考综合'),
  Chapter(subject: '语文', grade: 6, orderIndex: 99, chapterName: '小升初综合'),
  Chapter(subject: '语文', grade: 9, orderIndex: 99, chapterName: '中考综合'),
  Chapter(subject: '物理', grade: 9, orderIndex: 99, chapterName: '中考综合'),
  Chapter(subject: '化学', grade: 9, orderIndex: 99, chapterName: '中考综合'),

  // ══════════════════════════════════════════
  // V3.10 新增：英语 Cambridge 体系 chapter（按 KP 一级 category 4 类）
  // V3.8.4 之前用 "PET" / "FCE Part 1" 等考试 part 编号 chapter，改为"学习模块"风格。
  // 4 类 × 4 grade = 16 chapter。orderIndex 200+ 区别原外研社英语 chapter。
  // ══════════════════════════════════════════
  Chapter(subject: '英语', grade: 6, orderIndex: 200, chapterName: 'Vocabulary'),
  Chapter(subject: '英语', grade: 6, orderIndex: 201, chapterName: 'Grammar'),
  Chapter(subject: '英语', grade: 6, orderIndex: 202, chapterName: 'Reading'),
  Chapter(subject: '英语', grade: 6, orderIndex: 203, chapterName: 'Listening'),
  Chapter(subject: '英语', grade: 7, orderIndex: 200, chapterName: 'Vocabulary'),
  Chapter(subject: '英语', grade: 7, orderIndex: 201, chapterName: 'Grammar'),
  Chapter(subject: '英语', grade: 7, orderIndex: 202, chapterName: 'Reading'),
  Chapter(subject: '英语', grade: 7, orderIndex: 203, chapterName: 'Listening'),
  Chapter(subject: '英语', grade: 8, orderIndex: 200, chapterName: 'Vocabulary'),
  Chapter(subject: '英语', grade: 8, orderIndex: 201, chapterName: 'Grammar'),
  Chapter(subject: '英语', grade: 8, orderIndex: 202, chapterName: 'Reading'),
  Chapter(subject: '英语', grade: 8, orderIndex: 203, chapterName: 'Listening'),
  Chapter(subject: '英语', grade: 9, orderIndex: 200, chapterName: 'Vocabulary'),
  Chapter(subject: '英语', grade: 9, orderIndex: 201, chapterName: 'Grammar'),
  Chapter(subject: '英语', grade: 9, orderIndex: 202, chapterName: 'Reading'),
  Chapter(subject: '英语', grade: 9, orderIndex: 203, chapterName: 'Listening'),
];
