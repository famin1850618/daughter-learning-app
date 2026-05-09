import 'dart:convert';
import 'subject.dart';
import 'speaker_profile.dart';

/// V3.8.3：新增 subjective（主观题）—— 答完不立即判定，自动入家长审核队列由家长打分。
/// 用于作文、阅读理解开放问答、Cambridge Writing 等无标准答案的题型。
/// V3.10：新增 judgment（判断题）—— 二选一 对/错 按钮 UI，answer = "对" 或 "错"。
enum QuestionType { multipleChoice, fillBlank, calculation, subjective, judgment }
enum Difficulty { easy, medium, hard }

extension QuestionTypeExt on QuestionType {
  String get label {
    switch (this) {
      case QuestionType.multipleChoice: return '选择题';
      case QuestionType.fillBlank:      return '填空题';
      case QuestionType.calculation:    return '计算题';
      case QuestionType.subjective:     return '主观题';
      case QuestionType.judgment:       return '判断题';
    }
  }
  String get key {
    switch (this) {
      case QuestionType.multipleChoice: return 'choice';
      case QuestionType.fillBlank:      return 'fill';
      case QuestionType.calculation:    return 'calculation';
      case QuestionType.subjective:     return 'subjective';
      case QuestionType.judgment:       return 'judgment';
    }
  }
  static QuestionType fromKey(String key) {
    switch (key) {
      case 'choice':      return QuestionType.multipleChoice;
      case 'fill':        return QuestionType.fillBlank;
      case 'calculation': return QuestionType.calculation;
      case 'subjective':  return QuestionType.subjective;
      case 'judgment':    return QuestionType.judgment;
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
  /// 题目附图：SVG 字符串（以 `<svg` 开头）或 data URL（如 `data:image/png;base64,...`）。null 表示无图。
  final String? imageData;
  /// 听力题朗读原文（设备 TTS 朗读，仅英语题用）。null 表示无听力。
  /// 多角色对话格式：每行一个 turn，`角色名:` 开头，与 [speakers] map 的 key 对齐。
  final String? audioText;
  /// V3.12: 多角色 TTS 元数据。key 是 audioText 中的角色名，value 是 SpeakerProfile。
  /// audioText 是单角色独白时此字段可省略，TTS 端用 SpeakerProfile.defaultProfile。
  final Map<String, SpeakerProfile>? speakers;
  /// 难度档（V3.8）：1=基础 / 2=中等 / 3=较难 / 4=竞赛
  /// null 表示历史题包未标 round（V3.6/V3.7.6 之前），后续 Agent 回填。
  final int? round;
  /// 系列题分组 ID（V3.8.2）：同 groupId 的题一起抽 + 按 groupOrder 排序展示
  final String? groupId;
  final int? groupOrder;
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
    this.imageData,
    this.audioText,
    this.speakers,
    this.round,
    this.groupId,
    this.groupOrder,
    this.source = 'pregenerated',
  });

  /// 用户可见的"正确答案"（answer 字段可用 ||| 分隔多种等价写法供判定，
  /// 这里仅取第一种用于 UI 显示）
  String get displayAnswer => answer.split('|||').first;

  /// V3.12.14: 多选题判定（隐式：answer 含 ≥ 2 个字母 A/B/C/D/Z）
  /// 例 answer='AC' / 'A,C' / 'A、C' / 'ABD' → 多选；'A' / 'B' → 单选
  /// 仅 multipleChoice 题型有意义；其他类型返回 false
  bool get isMultiSelect {
    if (type != QuestionType.multipleChoice) return false;
    final firstSeg = displayAnswer.toUpperCase();
    final letters = RegExp(r'[A-DZ]').allMatches(firstSeg);
    return letters.length >= 2;
  }

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
      'image_data': imageData,
      'audio_text': audioText,
      'speakers_json': speakers == null
          ? null
          : jsonEncode(speakers!.map((k, v) => MapEntry(k, v.toMap()))),
      'round': round,
      'group_id': groupId,
      'group_order': groupOrder,
      'source': source,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    final optionsRaw = map['options'] as String?;
    final speakersRaw = map['speakers_json'] as String?;
    Map<String, SpeakerProfile>? speakersMap;
    if (speakersRaw != null && speakersRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(speakersRaw) as Map<String, dynamic>;
        speakersMap = decoded.map(
          (k, v) => MapEntry(k, SpeakerProfile.fromMap((v as Map).cast<String, dynamic>())),
        );
      } catch (_) {/* 损坏的 JSON 忽略，TTS 走 default */}
    }
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
      imageData: map['image_data'] as String?,
      audioText: map['audio_text'] as String?,
      speakers: speakersMap,
      round: map['round'] as int?,
      groupId: map['group_id'] as String?,
      groupOrder: map['group_order'] as int?,
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
  /// V3.8.3：写入时绑定的 session id；普通练习/章节练习/KP review/测评都生成 ID。
  /// 申诉/主观题评分批改后用于反查 session 重判通过状态。
  final String? sessionId;

  const PracticeRecord({
    this.id,
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
    required this.practicedAt,
    this.timeSpent = 0,
    this.usedHint = false,
    this.sessionId,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'question_id': questionId,
    'user_answer': userAnswer,
    'is_correct': isCorrect ? 1 : 0,
    'practiced_at': practicedAt.toIso8601String(),
    'time_spent': timeSpent,
    'used_hint': usedHint ? 1 : 0,
    'session_id': sessionId,
  };

  factory PracticeRecord.fromMap(Map<String, dynamic> map) => PracticeRecord(
    id: map['id'] as int?,
    questionId: map['question_id'] as int,
    userAnswer: map['user_answer'] as String,
    isCorrect: (map['is_correct'] as int) == 1,
    practicedAt: DateTime.parse(map['practiced_at'] as String),
    timeSpent: (map['time_spent'] as int?) ?? 0,
    usedHint: ((map['used_hint'] as int?) ?? 0) == 1,
    sessionId: map['session_id'] as String?,
  );
}
