import 'subject.dart';

enum QuestionType { multipleChoice, fillBlank, calculation }
enum Difficulty { easy, medium, hard }

extension QuestionTypeExt on QuestionType {
  String get label {
    switch (this) {
      case QuestionType.multipleChoice: return '选择题';
      case QuestionType.fillBlank:      return '填空题';
      case QuestionType.calculation:    return '计算题';
    }
  }
  String get key {
    switch (this) {
      case QuestionType.multipleChoice: return 'choice';
      case QuestionType.fillBlank:      return 'fill';
      case QuestionType.calculation:    return 'calculation';
    }
  }
  static QuestionType fromKey(String key) {
    switch (key) {
      case 'choice':      return QuestionType.multipleChoice;
      case 'fill':        return QuestionType.fillBlank;
      case 'calculation': return QuestionType.calculation;
      default:            return QuestionType.fillBlank;
    }
  }
}

extension DifficultyExt on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.easy:   return '简单';
      case Difficulty.medium: return '中等';
      case Difficulty.hard:   return '困难';
    }
  }
}

class Question {
  final int? id;
  final Subject subject;
  final int grade;
  final String chapter;
  final String? knowledgePoint;
  final String content;
  final QuestionType type;
  final Difficulty difficulty;
  final List<String>? options;
  final String answer;
  final String? explanation;
  final String source;

  const Question({
    this.id,
    required this.subject,
    required this.grade,
    required this.chapter,
    this.knowledgePoint,
    required this.content,
    required this.type,
    required this.difficulty,
    this.options,
    required this.answer,
    this.explanation,
    this.source = 'pregenerated',
  });

  /// 用户可见的"正确答案"（answer 字段可用 ||| 分隔多种等价写法供判定，
  /// 这里仅取第一种用于 UI 显示）
  String get displayAnswer => answer.split('|||').first;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'subject': subject.index,
      'grade': grade,
      'chapter': chapter,
      'knowledge_point': knowledgePoint,
      'content': content,
      'type': type.index,
      'difficulty': difficulty.index,
      'options': options?.join('||'),
      'answer': answer,
      'explanation': explanation,
      'source': source,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    final optionsRaw = map['options'] as String?;
    return Question(
      id: map['id'] as int?,
      subject: Subject.values[map['subject'] as int],
      grade: map['grade'] as int,
      chapter: map['chapter'] as String,
      knowledgePoint: map['knowledge_point'] as String?,
      content: map['content'] as String,
      type: QuestionType.values[map['type'] as int],
      difficulty: Difficulty.values[map['difficulty'] as int],
      options: optionsRaw?.split('||'),
      answer: map['answer'] as String,
      explanation: map['explanation'] as String?,
      source: (map['source'] as String?) ?? 'pregenerated',
    );
  }
}

class PracticeRecord {
  final int? id;
  final int questionId;
  final String userAnswer;
  final bool isCorrect;
  final DateTime practicedAt;
  final int timeSpent;
  final bool usedHint;

  const PracticeRecord({
    this.id,
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
    required this.practicedAt,
    this.timeSpent = 0,
    this.usedHint = false,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'question_id': questionId,
    'user_answer': userAnswer,
    'is_correct': isCorrect ? 1 : 0,
    'practiced_at': practicedAt.toIso8601String(),
    'time_spent': timeSpent,
    'used_hint': usedHint ? 1 : 0,
  };

  factory PracticeRecord.fromMap(Map<String, dynamic> map) => PracticeRecord(
    id: map['id'] as int?,
    questionId: map['question_id'] as int,
    userAnswer: map['user_answer'] as String,
    isCorrect: (map['is_correct'] as int) == 1,
    practicedAt: DateTime.parse(map['practiced_at'] as String),
    timeSpent: (map['time_spent'] as int?) ?? 0,
    usedHint: ((map['used_hint'] as int?) ?? 0) == 1,
  );
}
