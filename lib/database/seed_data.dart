import '../models/question.dart';
import '../models/subject.dart';

/// 六年级下学期内置题库（第一批，每科10题）
List<Question> get grade6SeedQuestions => [
  // ── 数学：分数除法 ──
  Question(
    subject: Subject.math, grade: 6, chapter: '分数除法',
    content: '3/4 ÷ 3/8 = ?',
    type: QuestionType.multipleChoice, difficulty: Difficulty.easy,
    options: ['A. 1/2', 'B. 2', 'C. 9/32', 'D. 2/1'],
    answer: 'B',
    explanation: '除以一个分数等于乘以它的倒数：3/4 × 8/3 = 2',
  ),
  Question(
    subject: Subject.math, grade: 6, chapter: '分数除法',
    content: '一块布长5/6米，剪成每段1/12米，能剪几段？',
    type: QuestionType.fillBlank, difficulty: Difficulty.medium,
    answer: '10',
    explanation: '5/6 ÷ 1/12 = 5/6 × 12 = 10段',
  ),
  Question(
    subject: Subject.math, grade: 6, chapter: '比和比例',
    content: '比例 2:x = 6:9 中，x = ?',
    type: QuestionType.fillBlank, difficulty: Difficulty.easy,
    answer: '3',
    explanation: '2×9 = 6×x，18 = 6x，x = 3',
  ),
  Question(
    subject: Subject.math, grade: 6, chapter: '比和比例',
    content: '下列哪个不是比例？',
    type: QuestionType.multipleChoice, difficulty: Difficulty.easy,
    options: ['A. 1:2 = 3:6', 'B. 2:3 = 4:5', 'C. 6:4 = 9:6', 'D. 5:10 = 1:2'],
    answer: 'B',
    explanation: '2×5 = 10，3×4 = 12，10≠12，所以B不是比例',
  ),
  Question(
    subject: Subject.math, grade: 6, chapter: '圆',
    content: '一个圆的半径是5cm，其周长是多少？（π取3.14）',
    type: QuestionType.fillBlank, difficulty: Difficulty.easy,
    answer: '31.4cm',
    explanation: 'C = 2πr = 2 × 3.14 × 5 = 31.4cm',
  ),

  // ── 语文：文学常识 ──
  Question(
    subject: Subject.chinese, grade: 6, chapter: '古诗词',
    content: '"春蚕到死丝方尽，蜡炬成灰泪始干"出自哪位诗人？',
    type: QuestionType.multipleChoice, difficulty: Difficulty.easy,
    options: ['A. 杜甫', 'B. 白居易', 'C. 李商隐', 'D. 李白'],
    answer: 'C',
    explanation: '出自唐代诗人李商隐的《无题》',
  ),
  Question(
    subject: Subject.chinese, grade: 6, chapter: '字词',
    content: '"截然不同"中"截"的正确读音是？',
    type: QuestionType.multipleChoice, difficulty: Difficulty.easy,
    options: ['A. jié', 'B. jiē', 'C. zhé', 'D. zhē'],
    answer: 'A',
    explanation: '"截"读 jié，截然不同意为完全不同',
  ),
  Question(
    subject: Subject.chinese, grade: 6, chapter: '阅读理解',
    content: '说明文的三种说明顺序是：时间顺序、空间顺序和？',
    type: QuestionType.fillBlank, difficulty: Difficulty.medium,
    answer: '逻辑顺序',
  ),

  // ── 英语：时态 ──
  Question(
    subject: Subject.english, grade: 6, chapter: '现在完成时',
    content: 'She ___ (visit) the Great Wall three times.',
    type: QuestionType.fillBlank, difficulty: Difficulty.easy,
    answer: 'has visited',
    explanation: '现在完成时：have/has + 过去分词，表示过去动作对现在的影响',
  ),
  Question(
    subject: Subject.english, grade: 6, chapter: '词汇',
    content: '"图书馆"的正确英文是？',
    type: QuestionType.multipleChoice, difficulty: Difficulty.easy,
    options: ['A. laboratory', 'B. library', 'C. bookstore', 'D. canteen'],
    answer: 'B',
    explanation: 'library = 图书馆，laboratory = 实验室',
  ),

  // ── AI：基础概念 ──
  Question(
    subject: Subject.ai, grade: 6, chapter: 'AI基础',
    content: 'Scratch是一种什么类型的编程语言？',
    type: QuestionType.multipleChoice, difficulty: Difficulty.easy,
    options: ['A. 文本编程语言', 'B. 图形化积木编程', 'C. 机器学习框架', 'D. 数据库语言'],
    answer: 'B',
    explanation: 'Scratch是麻省理工学院开发的图形化积木编程工具，适合初学者',
  ),
];
