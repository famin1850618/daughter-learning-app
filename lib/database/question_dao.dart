import '../models/question.dart';
import '../models/subject.dart';
import 'database_helper.dart';

/// 待掌握 KP 摘要（错题集卡片用）
class ReviewKpSummary {
  final String fullPath;       // "category/name"
  final String category;
  final String name;
  final int totalErrors;       // 历史累计错次（颜色梯度用）
  final DateTime lastWrongAt;  // 最近一次错的时间

  const ReviewKpSummary({
    required this.fullPath,
    required this.category,
    required this.name,
    required this.totalErrors,
    required this.lastWrongAt,
  });
}

/// 错题历史记录（详情页用）
class WrongQuestionRecord {
  final Question question;
  final String userAnswer;
  final DateTime practicedAt;

  const WrongQuestionRecord({
    required this.question,
    required this.userAnswer,
    required this.practicedAt,
  });
}

class QuestionDao {
  final DatabaseHelper _db = DatabaseHelper();

  // ── 题目导入与查询 ─────────────────────────────────

  Future<void> insertBatch(List<Question> questions) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final q in questions) {
      batch.insert('questions', q.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// 按 source 幂等导入：source 已存在就跳过，避免重复入库
  Future<bool> insertBatchIfMissing(String source, List<Question> questions) async {
    final db = await _db.database;
    final exists = await db.rawQuery(
        'SELECT 1 FROM questions WHERE source = ? LIMIT 1', [source]);
    if (exists.isNotEmpty) return false;
    final batch = db.batch();
    for (final q in questions) {
      final m = q.toMap();
      m['source'] = source;
      batch.insert('questions', m);
    }
    await batch.commit(noResult: true);
    return true;
  }

  Future<int> count() async {
    final db = await _db.database;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM questions');
    return (r.first['c'] as int?) ?? 0;
  }

  Future<List<Question>> getRandom({
    required Subject subject,
    required int grade,
    String? chapter,
    QuestionType? type,
    Difficulty? difficulty,
    int limit = 10,
  }) async {
    final db = await _db.database;
    String where = 'subject = ? AND grade = ?';
    List<dynamic> args = [subject.index, grade];
    if (chapter != null) { where += ' AND chapter = ?'; args.add(chapter); }
    if (type != null) { where += ' AND type = ?'; args.add(type.index); }
    if (difficulty != null) { where += ' AND difficulty = ?'; args.add(difficulty.index); }
    final maps = await db.query('questions',
        where: where, whereArgs: args, orderBy: 'RANDOM()', limit: limit);
    return maps.map(Question.fromMap).toList();
  }

  // ── 答题记录 ────────────────────────────────────────

  Future<int> insertRecord(PracticeRecord record) async {
    final db = await _db.database;
    return db.insert('practice_records', record.toMap());
  }

  // ── 错题集（KP 维度 / 举一反三）─────────────────────

  /// 待掌握 KP 列表：以"最近一次错"为锚点，之后答对的不同题数 < 2 即视为待掌握。
  /// 一旦该 KP 再错，锚点更新到最新时间，自动重新进入待掌握。
  Future<List<ReviewKpSummary>> getReviewKnowledgePoints() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      WITH last_wrong AS (
        SELECT q.knowledge_point AS kp, MAX(r.practiced_at) AS t
        FROM practice_records r
        JOIN questions q ON q.id = r.question_id
        WHERE r.is_correct = 0 AND q.knowledge_point IS NOT NULL
        GROUP BY q.knowledge_point
      ),
      progress AS (
        SELECT lw.kp,
               lw.t AS last_wrong_at,
               COUNT(DISTINCT CASE WHEN r2.is_correct = 1 AND r2.practiced_at > lw.t
                                   THEN r2.question_id END) AS correct_after_last
        FROM last_wrong lw
        JOIN questions q2 ON q2.knowledge_point = lw.kp
        LEFT JOIN practice_records r2 ON r2.question_id = q2.id
        GROUP BY lw.kp, lw.t
      ),
      total_err AS (
        SELECT q.knowledge_point AS kp, COUNT(*) AS total_errors
        FROM practice_records r
        JOIN questions q ON q.id = r.question_id
        WHERE r.is_correct = 0 AND q.knowledge_point IS NOT NULL
        GROUP BY q.knowledge_point
      )
      SELECT p.kp, p.last_wrong_at, te.total_errors
      FROM progress p
      JOIN total_err te ON te.kp = p.kp
      WHERE p.correct_after_last < 2
      ORDER BY te.total_errors DESC, p.last_wrong_at DESC
    ''');

    return rows.map((row) {
      final kp = row['kp'] as String;
      final parts = kp.split('/');
      return ReviewKpSummary(
        fullPath: kp,
        category: parts.isNotEmpty ? parts.first : kp,
        name: parts.length > 1 ? parts.sublist(1).join('/') : kp,
        totalErrors: (row['total_errors'] as int?) ?? 0,
        lastWrongAt: DateTime.parse(row['last_wrong_at'] as String),
      );
    }).toList();
  }

  /// 用于首页摘要：累计错次 Top N 的待掌握 KP
  Future<List<ReviewKpSummary>> getTopWeakKnowledgePoints(int n) async {
    final all = await getReviewKnowledgePoints();
    return all.take(n).toList();
  }

  /// 某 KP 是否已掌握（错过 + 之后答对 ≥2 道不同 question_id 的题）
  Future<bool> isKnowledgePointMastered(String kpPath) async {
    final list = await getReviewKnowledgePoints();
    return !list.any((r) => r.fullPath == kpPath);
  }

  /// 某 KP 的错题历史（每条 = 一次错答事件，按时间倒序）
  Future<List<WrongQuestionRecord>> getWrongHistoryForKnowledgePoint(String kpPath) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT q.*, r.user_answer AS r_user_answer, r.practiced_at AS r_practiced_at
      FROM practice_records r
      JOIN questions q ON q.id = r.question_id
      WHERE r.is_correct = 0 AND q.knowledge_point = ?
      ORDER BY r.practiced_at DESC
    ''', [kpPath]);

    return rows.map((row) {
      final q = Question.fromMap(row);
      return WrongQuestionRecord(
        question: q,
        userAnswer: row['r_user_answer'] as String,
        practicedAt: DateTime.parse(row['r_practiced_at'] as String),
      );
    }).toList();
  }

  /// 举一反三抽题：同 KP 同难度未做过优先；回退到做过但最久未练的；都用尽返回空。
  Future<List<Question>> getQuestionsForKnowledgePoint({
    required String kpPath,
    required Difficulty difficulty,
    int limit = 5,
  }) async {
    final db = await _db.database;

    // Step 1: 同 KP + 同难度 + 未做过
    final fresh = await db.rawQuery('''
      SELECT * FROM questions
      WHERE knowledge_point = ?
        AND difficulty = ?
        AND id NOT IN (SELECT DISTINCT question_id FROM practice_records)
      ORDER BY RANDOM()
      LIMIT ?
    ''', [kpPath, difficulty.index, limit]);
    if (fresh.length >= limit) {
      return fresh.map(Question.fromMap).toList();
    }

    // Step 2: 不足则补：同 KP + 同难度 + 做过但最久未练
    final remaining = limit - fresh.length;
    final pickedIds = fresh.map((m) => m['id']).toList();
    final placeholders = pickedIds.isEmpty
        ? '0'
        : List.filled(pickedIds.length, '?').join(',');
    final stale = await db.rawQuery('''
      SELECT q.*
      FROM questions q
      LEFT JOIN (
        SELECT question_id, MAX(practiced_at) AS last_practiced
        FROM practice_records
        GROUP BY question_id
      ) lr ON lr.question_id = q.id
      WHERE q.knowledge_point = ?
        AND q.difficulty = ?
        AND q.id NOT IN ($placeholders)
      ORDER BY lr.last_practiced ASC
      LIMIT ?
    ''', [kpPath, difficulty.index, ...pickedIds, remaining]);

    return [
      ...fresh.map(Question.fromMap),
      ...stale.map(Question.fromMap),
    ];
  }

  /// 测评抽题：按 unit (chapter ± KP) + difficulty 抽题，可排除指定 id 列表（"原错题"）
  /// 不足时降级：先放宽难度，再放宽 KP（保留 chapter）
  Future<List<Question>> getQuestionsForAssessmentUnit({
    required String subjectName,
    required int grade,
    required String chapterName,
    String? knowledgePoint,
    Difficulty? difficulty,
    required List<int> excludeIds,
    required int limit,
  }) async {
    if (limit <= 0) return [];
    final db = await _db.database;
    final excludeClause = excludeIds.isEmpty
        ? ''
        : ' AND id NOT IN (${List.filled(excludeIds.length, '?').join(',')})';

    // subject 是 INTEGER，需要转 index：通过 subject_name 查询时回退用 chapter 唯一性
    // 这里直接按 chapter + grade 查（chapter 名在某 grade 下唯一性已假定）
    Future<List<Question>> q1(String where, List<dynamic> args, int n) async {
      final maps = await db.query(
        'questions',
        where: where + excludeClause,
        whereArgs: [...args, ...excludeIds],
        orderBy: 'RANDOM()',
        limit: n,
      );
      return maps.map(Question.fromMap).toList();
    }

    final got = <Question>[];
    final seen = <int>{...excludeIds};

    // Tier 1: chapter + grade + KP + difficulty
    if (knowledgePoint != null) {
      String where = 'chapter = ? AND grade = ? AND knowledge_point = ?';
      List<dynamic> a = [chapterName, grade, knowledgePoint];
      if (difficulty != null) {
        where += ' AND difficulty = ?';
        a.add(difficulty.index);
      }
      final qs = await q1(where, a, limit - got.length);
      for (final q in qs) {
        if (q.id != null && !seen.contains(q.id)) {
          got.add(q);
          seen.add(q.id!);
        }
      }
    }

    // Tier 2: chapter + grade（放宽 KP，只要 chapter）+ difficulty
    if (got.length < limit) {
      String where = 'chapter = ? AND grade = ?';
      List<dynamic> a = [chapterName, grade];
      if (difficulty != null) {
        where += ' AND difficulty = ?';
        a.add(difficulty.index);
      }
      final excludeNow = seen.toList();
      final excludeClauseNow = excludeNow.isEmpty
          ? ''
          : ' AND id NOT IN (${List.filled(excludeNow.length, '?').join(',')})';
      final maps = await db.query('questions',
          where: where + excludeClauseNow,
          whereArgs: [...a, ...excludeNow],
          orderBy: 'RANDOM()',
          limit: limit - got.length);
      for (final m in maps) {
        final q = Question.fromMap(m);
        if (q.id != null && !seen.contains(q.id)) {
          got.add(q);
          seen.add(q.id!);
        }
      }
    }

    // Tier 3: chapter + grade（放弃难度限制）
    if (got.length < limit) {
      String where = 'chapter = ? AND grade = ?';
      List<dynamic> a = [chapterName, grade];
      final excludeNow = seen.toList();
      final excludeClauseNow = excludeNow.isEmpty
          ? ''
          : ' AND id NOT IN (${List.filled(excludeNow.length, '?').join(',')})';
      final maps = await db.query('questions',
          where: where + excludeClauseNow,
          whereArgs: [...a, ...excludeNow],
          orderBy: 'RANDOM()',
          limit: limit - got.length);
      for (final m in maps) {
        final q = Question.fromMap(m);
        if (q.id != null && !seen.contains(q.id)) {
          got.add(q);
          seen.add(q.id!);
        }
      }
    }

    return got;
  }

  /// 一段时间内对某 chapter（可选 KP）做错的 question_id 集合
  Future<List<int>> getWrongQuestionIdsInRange({
    required DateTime start,
    required DateTime end,
    required String chapterName,
    String? knowledgePoint,
  }) async {
    final db = await _db.database;
    final s = start.toIso8601String();
    final e = end.toIso8601String();
    String where = 'r.is_correct = 0 AND q.chapter = ? AND r.practiced_at >= ? AND r.practiced_at <= ?';
    final args = <dynamic>[chapterName, s, e];
    if (knowledgePoint != null) {
      where += ' AND q.knowledge_point = ?';
      args.add(knowledgePoint);
    }
    final rows = await db.rawQuery('''
      SELECT DISTINCT q.id AS qid
      FROM practice_records r
      JOIN questions q ON q.id = r.question_id
      WHERE $where
    ''', args);
    return rows.map((r) => r['qid'] as int).toList();
  }

  /// 一段时间内 unit 维度的累计错次（用于错题加权）
  Future<int> countWrongInRange({
    required DateTime start,
    required DateTime end,
    required String chapterName,
    String? knowledgePoint,
  }) async {
    final db = await _db.database;
    final s = start.toIso8601String();
    final e = end.toIso8601String();
    String where = 'r.is_correct = 0 AND q.chapter = ? AND r.practiced_at >= ? AND r.practiced_at <= ?';
    final args = <dynamic>[chapterName, s, e];
    if (knowledgePoint != null) {
      where += ' AND q.knowledge_point = ?';
      args.add(knowledgePoint);
    }
    final rows = await db.rawQuery('''
      SELECT COUNT(*) AS c
      FROM practice_records r
      JOIN questions q ON q.id = r.question_id
      WHERE $where
    ''', args);
    return (rows.first['c'] as int?) ?? 0;
  }

  /// 薄弱点练习抽题：排除曾做错过的"原题"，仅取未做过 + 答对过最久未练的题
  /// 用于 startAggregatedReviewSession，避免重复出现用户做错过的同一道题
  Future<List<Question>> getQuestionsForKpExcludingWrong({
    required String kpPath,
    required Difficulty difficulty,
    required int limit,
  }) async {
    if (limit <= 0) return [];
    final db = await _db.database;

    // Tier 1: 同 KP + 同难度 + 完全未做过
    final fresh = await db.rawQuery('''
      SELECT * FROM questions
      WHERE knowledge_point = ?
        AND difficulty = ?
        AND id NOT IN (SELECT DISTINCT question_id FROM practice_records)
      ORDER BY RANDOM()
      LIMIT ?
    ''', [kpPath, difficulty.index, limit]);
    if (fresh.length >= limit) {
      return fresh.map(Question.fromMap).toList();
    }

    // Tier 2: 同 KP + 同难度 + 做过但**从未答错过** + 最久未练
    final remaining = limit - fresh.length;
    final pickedIds = fresh.map((m) => m['id']).toList();
    final placeholders = pickedIds.isEmpty
        ? '0'
        : List.filled(pickedIds.length, '?').join(',');
    final stale = await db.rawQuery('''
      SELECT q.*
      FROM questions q
      LEFT JOIN (
        SELECT question_id, MAX(practiced_at) AS last_practiced
        FROM practice_records
        GROUP BY question_id
      ) lr ON lr.question_id = q.id
      WHERE q.knowledge_point = ?
        AND q.difficulty = ?
        AND q.id NOT IN ($placeholders)
        AND q.id NOT IN (
          SELECT DISTINCT question_id FROM practice_records WHERE is_correct = 0
        )
      ORDER BY lr.last_practiced ASC
      LIMIT ?
    ''', [kpPath, difficulty.index, ...pickedIds, remaining]);

    return [
      ...fresh.map(Question.fromMap),
      ...stale.map(Question.fromMap),
    ];
  }

  /// 找出某 KP 最近一次错过题的难度（举一反三抽题时用作"同难度"基准）
  Future<Difficulty?> getMostRecentErrorDifficulty(String kpPath) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT q.difficulty
      FROM practice_records r
      JOIN questions q ON q.id = r.question_id
      WHERE r.is_correct = 0 AND q.knowledge_point = ?
      ORDER BY r.practiced_at DESC
      LIMIT 1
    ''', [kpPath]);
    if (rows.isEmpty) return null;
    return Difficulty.values[rows.first['difficulty'] as int];
  }

  // ── 学情统计（学情导出用）──────────────────────────

  /// 错误率超阈值的知识点（用于学情报告里的"重点补题信号"）
  Future<List<Map<String, dynamic>>> getWeakKnowledgePoints({
    double errorThreshold = 0.6,
    int minAttempts = 3,
  }) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT q.subject, q.grade, q.chapter, q.knowledge_point,
             COUNT(*) as attempts,
             SUM(CASE WHEN r.is_correct = 0 THEN 1 ELSE 0 END) as errors,
             ROUND(1.0 * SUM(CASE WHEN r.is_correct = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) as error_rate
      FROM practice_records r
      JOIN questions q ON r.question_id = q.id
      WHERE q.knowledge_point IS NOT NULL
      GROUP BY q.subject, q.grade, q.knowledge_point
      HAVING attempts >= ? AND error_rate >= ?
      ORDER BY error_rate DESC
    ''', [minAttempts, errorThreshold]);
  }

  /// 最近 N 道错题原文（学情报告的补题输入）
  Future<List<Map<String, dynamic>>> getRecentWrongQuestions({int limit = 50}) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT q.subject, q.grade, q.chapter, q.knowledge_point, q.content,
             q.answer AS correct_answer,
             r.user_answer, r.practiced_at
      FROM practice_records r
      JOIN questions q ON r.question_id = q.id
      WHERE r.is_correct = 0
      ORDER BY r.practiced_at DESC
      LIMIT ?
    ''', [limit]);
  }

  Future<Map<String, int>> getStats(Subject subject, int grade) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as total,
             SUM(CASE WHEN r.is_correct = 1 THEN 1 ELSE 0 END) as correct
      FROM practice_records r
      INNER JOIN questions q ON r.question_id = q.id
      WHERE q.subject = ? AND q.grade = ?
    ''', [subject.index, grade]);
    final row = result.first;
    return {
      'total': (row['total'] as int?) ?? 0,
      'correct': (row['correct'] as int?) ?? 0,
    };
  }

  Future<Map<String, int>> getOverallStats() async {
    final db = await _db.database;
    final r = await db.rawQuery('''
      SELECT COUNT(*) as total,
             SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct
      FROM practice_records
    ''');
    return {
      'total': (r.first['total'] as int?) ?? 0,
      'correct': (r.first['correct'] as int?) ?? 0,
    };
  }
}
