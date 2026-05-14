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
  // V3.23: 删"总复习"章，并入"综合练习"（orderIndex 99，见末尾）

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
  // 语文（人教版部编版）—— V3.11：删除老 6 单元体系，统一走 KP-category（见下方）
  // ══════════════════════════════════════════

  // ══════════════════════════════════════════
  // 英语（剑桥体系）—— V3.11：删除老外研社 6 章体系，统一走剑桥 4 模块（见下方）
  // ══════════════════════════════════════════
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
  // V3.21 综合练习 chapter：跨章节组合题与不属任一教材章的真题归此
  // 数学 g6 / g9，物理 g8 / g9，化学 g9 各一。chapter 名统一 `综合练习`，
  // 对应 KP 也是一级单段字符串 `综合练习`（fullPath 无斜杠）。
  // V3.10 旧 `小升初综合` `中考综合` chapter 删除（DB v27 migration 中迁移）。
  // ══════════════════════════════════════════
  Chapter(subject: '数学', grade: 6, orderIndex: 99, chapterName: '综合练习'),
  Chapter(subject: '数学', grade: 9, orderIndex: 99, chapterName: '综合练习'),

  // V3.22 简化（Famin 2026-05-13 决策）：语文 chapter 收敛到 7 个
  // V3.14: 删旧"句式与标点/修辞"→ 句子和语法 / 旧"现代文阅读/课文与名著"→ 阅读理解
  // V3.22: 删"综合性学习"章；加"综合练习"章（orderIndex 99，与数理化对齐）
  // 写作 chapter 保留但实际题应转 _subj_held（100% 主观题不入抽题池）
  Chapter(subject: '语文', grade: 6, orderIndex: 21, chapterName: '字词'),
  Chapter(subject: '语文', grade: 6, orderIndex: 22, chapterName: '句子和语法'),
  Chapter(subject: '语文', grade: 6, orderIndex: 23, chapterName: '阅读理解'),
  Chapter(subject: '语文', grade: 6, orderIndex: 24, chapterName: '古诗文'),
  Chapter(subject: '语文', grade: 6, orderIndex: 25, chapterName: '文学常识'),
  Chapter(subject: '语文', grade: 6, orderIndex: 27, chapterName: '写作'),
  Chapter(subject: '语文', grade: 6, orderIndex: 99, chapterName: '综合练习'),
  Chapter(subject: '语文', grade: 7, orderIndex: 21, chapterName: '字词'),
  Chapter(subject: '语文', grade: 7, orderIndex: 22, chapterName: '句子和语法'),
  Chapter(subject: '语文', grade: 7, orderIndex: 23, chapterName: '阅读理解'),
  Chapter(subject: '语文', grade: 7, orderIndex: 24, chapterName: '古诗文'),
  Chapter(subject: '语文', grade: 7, orderIndex: 25, chapterName: '文学常识'),
  Chapter(subject: '语文', grade: 7, orderIndex: 27, chapterName: '写作'),
  Chapter(subject: '语文', grade: 7, orderIndex: 99, chapterName: '综合练习'),
  Chapter(subject: '语文', grade: 8, orderIndex: 21, chapterName: '字词'),
  Chapter(subject: '语文', grade: 8, orderIndex: 22, chapterName: '句子和语法'),
  Chapter(subject: '语文', grade: 8, orderIndex: 23, chapterName: '阅读理解'),
  Chapter(subject: '语文', grade: 8, orderIndex: 24, chapterName: '古诗文'),
  Chapter(subject: '语文', grade: 8, orderIndex: 25, chapterName: '文学常识'),
  Chapter(subject: '语文', grade: 8, orderIndex: 27, chapterName: '写作'),
  Chapter(subject: '语文', grade: 8, orderIndex: 99, chapterName: '综合练习'),
  Chapter(subject: '语文', grade: 9, orderIndex: 21, chapterName: '字词'),
  Chapter(subject: '语文', grade: 9, orderIndex: 22, chapterName: '句子和语法'),
  Chapter(subject: '语文', grade: 9, orderIndex: 23, chapterName: '阅读理解'),
  Chapter(subject: '语文', grade: 9, orderIndex: 24, chapterName: '古诗文'),
  Chapter(subject: '语文', grade: 9, orderIndex: 25, chapterName: '文学常识'),
  Chapter(subject: '语文', grade: 9, orderIndex: 27, chapterName: '写作'),
  Chapter(subject: '语文', grade: 9, orderIndex: 99, chapterName: '综合练习'),
  Chapter(subject: '物理', grade: 8, orderIndex: 99, chapterName: '综合练习'),
  Chapter(subject: '物理', grade: 9, orderIndex: 99, chapterName: '综合练习'),
  Chapter(subject: '化学', grade: 9, orderIndex: 99, chapterName: '综合练习'),

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
