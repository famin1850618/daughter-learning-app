import 'subject.dart';

enum QuestionType { multipleChoice, fillBlank, shortAnswer }
enum Difficulty { easy, medium, hard }

class Question {
  final int? id;
  final Subject subject;
  final int grade;        // 6=六年级, 7=初一, 8=初二, 9=初三
  final String chapter;
  final String content;
  final QuestionType type;
  final Difficulty difficulty;
  final List<String>? options;   // 选择题选项 A/B/C/D
  final String answer;
  final String? explanation;

  const Question({
    this.id,
    required this.subject,
    required this.grade,
    required this.chapter,
    required this.content,
    required this.type,
    required this.difficulty,
    this.options,
    required this.answer,
    this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'subject': subject.index,
      'grade': grade,
      'chapter': chapter,
      'content': content,
      'type': type.index,
      'difficulty': difficulty.index,
      'options': options?.join('||'),
      'answer': answer,
      'explanation': explanation,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    final optionsRaw = map['options'] as String?;
    return Question(
      id: map['id'] as int?,
      subject: Subject.values[map['subject'] as int],
      grade: map['grade'] as int,
      chapter: map['chapter'] as String,
      content: map['content'] as String,
      type: QuestionType.values[map['type'] as int],
      difficulty: Difficulty.values[map['difficulty'] as int],
      options: optionsRaw?.split('||'),
      answer: map['answer'] as String,
      explanation: map['explanation'] as String?,
    );
  }
}

class PracticeRecord {
  final int? id;
  final int questionId;
  final String userAnswer;
  final bool isCorrect;
  final DateTime practicedAt;

  const PracticeRecord({
    this.id,
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
    required this.practicedAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'question_id': questionId,
    'user_answer': userAnswer,
    'is_correct': isCorrect ? 1 : 0,
    'practiced_at': practicedAt.toIso8601String(),
  };

  factory PracticeRecord.fromMap(Map<String, dynamic> map) => PracticeRecord(
    id: map['id'] as int?,
    questionId: map['question_id'] as int,
    userAnswer: map['user_answer'] as String,
    isCorrect: (map['is_correct'] as int) == 1,
    practicedAt: DateTime.parse(map['practiced_at'] as String),
  );
}
