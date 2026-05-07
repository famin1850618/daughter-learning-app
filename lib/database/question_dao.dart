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
  final int subjectIndex;      // Subject 枚举 index（V3.7.8：成效页按科目一级分类）

  const ReviewKpSummary({
    required this.fullPath,
    required this.category,
    required this.name,
    required this.totalErrors,
    required this.lastWrongAt,
    required this.subjectIndex,
  });

  Subject get subject => Subject.values[subjectIndex];
}

/// 错题历史记录（详情页用）
class WrongQuestionRecord {
  /// V3.8.3：申诉副作用要 UPDATE 这条 record 的 is_correct
  final int practiceRecordId;
  final Question question;
  final String userAnswer;
  final DateTime practicedAt;
  /// V3.8.3：来源 session id（错题集详情页显示"来自哪天的练习"）
  final String? sessionId;

  const WrongQuestionRecord({
    required this.practiceRecordId,
    required this.question,
    required this.userAnswer,
    required this.practicedAt,
    this.sessionId,
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

  /// V3.8 新增：按 round 限制抽题（精确单档 / 多档混合）
  ///
  /// [rounds]：null = 不限（含 round=NULL 的历史题），[N] = 限定单档，
  ///   [a,b,c,d]+[weights] 配合 = 模糊按比例混合（weights 不传则等权重）
  ///
  /// V3.8.2：自动排除"已答对 ≥3 次"的题；含 group_id 的题抽到时自动展开同 group
  Future<List<Question>> getRandomByRound({
    required Subject subject,
    required int grade,
    String? chapter,
    List<int>? rounds,
    List<int>? weights,
    int limit = 10,
  }) async {
    final db = await _db.database;
    String baseWhere = 'subject = ? AND grade = ?';
    List<dynamic> baseArgs = [subject.index, grade];
    if (chapter != null) { baseWhere += ' AND chapter = ?'; baseArgs.add(chapter); }
    // V3.8.2: 排除累计答对 ≥3 次的题
    baseWhere += ' AND id NOT IN ($_masteredSubquery)';

    List<Question> picks;

    // 不限 round：直接返回（含 NULL）
    if (rounds == null || rounds.isEmpty) {
      final maps = await db.query('questions',
          where: baseWhere, whereArgs: baseArgs, orderBy: 'RANDOM()', limit: limit);
      picks = maps.map(Question.fromMap).toList();
    } else if (rounds.length == 1) {
      // 单档 precise：直接限定
      final maps = await db.query('questions',
          where: '$baseWhere AND round = ?',
          whereArgs: [...baseArgs, rounds.first],
          orderBy: 'RANDOM()',
          limit: limit);
      picks = maps.map(Question.fromMap).toList();
    } else {
      // 多档 fuzzy：按 weights 分配 limit
      final w = weights ?? List.filled(rounds.length, 1);
      final wSum = w.fold(0, (a, b) => a + b);
      picks = <Question>[];
      int remaining = limit;
      for (int i = 0; i < rounds.length; i++) {
        final share = i == rounds.length - 1
            ? remaining
            : (limit * w[i] / wSum).round();
        if (share <= 0) continue;
        final maps = await db.query('questions',
            where: '$baseWhere AND round = ?',
            whereArgs: [...baseArgs, rounds[i]],
            orderBy: 'RANDOM()',
            limit: share);
        picks.addAll(maps.map(Question.fromMap));
        remaining -= maps.length;
      }
      // 不足补：从不限 round 池抽剩下的
      if (picks.length < limit) {
        final got = picks.map((q) => q.id).whereType<int>().toList();
        final placeholders = got.isEmpty ? '0' : List.filled(got.length, '?').join(',');
        final fill = await db.query('questions',
            where: '$baseWhere AND id NOT IN ($placeholders)',
            whereArgs: [...baseArgs, ...got],
            orderBy: 'RANDOM()',
            limit: limit - picks.length);
        picks.addAll(fill.map(Question.fromMap));
      }
      picks.shuffle();
    }

    return await _expandGroups(picks);
  }

  /// V3.8.2 子句：累计答对 ≥3 次的题 id（NOT IN 排除用）
  static const _masteredSubquery =
      'SELECT question_id FROM practice_records WHERE is_correct = 1 GROUP BY question_id HAVING COUNT(*) >= 3';

  /// V3.8.2: 展开 group 系列题
  /// 抽中含 group_id 的题 → 把同 group_id 全部题拉出来 + 按 group_order 排序 + 替换原位置
  Future<List<Question>> _expandGroups(List<Question> seed) async {
    final groupIds = seed
        .where((q) => q.groupId != null && q.groupId!.isNotEmpty)
        .map((q) => q.groupId!)
        .toSet();
    if (groupIds.isEmpty) return seed;

    final db = await _db.database;
    final placeholders = List.filled(groupIds.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT * FROM questions WHERE group_id IN ($placeholders) ORDER BY group_id, group_order',
      groupIds.toList(),
    );
    final byGroup = <String, List<Question>>{};
    for (final m in rows) {
      final q = Question.fromMap(m);
      byGroup.putIfAbsent(q.groupId!, () => []).add(q);
    }

    // 按 seed 的顺序重组：第一次遇到某 group 时插入完整 group，后续遇到同 group 跳过
    final result = <Question>[];
    final addedGroups = <String>{};
    for (final q in seed) {
      if (q.groupId != null && q.groupId!.isNotEmpty) {
        if (!addedGroups.contains(q.groupId!)) {
          result.addAll(byGroup[q.groupId!] ?? [q]);
          addedGroups.add(q.groupId!);
        }
      } else {
        result.add(q);
      }
    }
    return result;
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
        SELECT q.knowledge_point AS kp, q.subject AS subject, MAX(r.practiced_at) AS t
        FROM practice_records r
        JOIN questions q ON q.id = r.question_id
        WHERE r.is_correct = 0 AND q.knowledge_point IS NOT NULL
        GROUP BY q.knowledge_point, q.subject
      ),
      progress AS (
        SELECT lw.kp, lw.subject,
               lw.t AS last_wrong_at,
               COUNT(DISTINCT CASE WHEN r2.is_correct = 1 AND r2.practiced_at > lw.t
                                   THEN r2.question_id END) AS correct_after_last
        FROM last_wrong lw
        JOIN questions q2 ON q2.knowledge_point = lw.kp AND q2.subject = lw.subject
        LEFT JOIN practice_records r2 ON r2.question_id = q2.id
        GROUP BY lw.kp, lw.subject, lw.t
      ),
      total_err AS (
        SELECT q.knowledge_point AS kp, q.subject AS subject, COUNT(*) AS total_errors
        FROM practice_records r
        JOIN questions q ON q.id = r.question_id
        WHERE r.is_correct = 0 AND q.knowledge_point IS NOT NULL
        GROUP BY q.knowledge_point, q.subject
      )
      SELECT p.kp, p.subject, p.last_wrong_at, te.total_errors
      FROM progress p
      JOIN total_err te ON te.kp = p.kp AND te.subject = p.subject
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
        subjectIndex: (row['subject'] as int?) ?? 0,
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
      SELECT q.*, r.id AS r_id,
             r.user_answer AS r_user_answer,
             r.practiced_at AS r_practiced_at,
             r.session_id AS r_session_id
      FROM practice_records r
      JOIN questions q ON q.id = r.question_id
      WHERE r.is_correct = 0 AND q.knowledge_point = ?
      ORDER BY r.practiced_at DESC
    ''', [kpPath]);

    return rows.map((row) {
      final q = Question.fromMap(row);
      return WrongQuestionRecord(
        practiceRecordId: row['r_id'] as int,
        question: q,
        userAnswer: row['r_user_answer'] as String,
        practicedAt: DateTime.parse(row['r_practiced_at'] as String),
        sessionId: row['r_session_id'] as String?,
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
    int? minRound, // V3.8.2: 周/月测仅从 round ≥ minRound 抽
  }) async {
    if (limit <= 0) return [];
    final db = await _db.database;
    final excludeClause = excludeIds.isEmpty
        ? ''
        : ' AND id NOT IN (${List.filled(excludeIds.length, '?').join(',')})';
    // V3.8.2: 排除已掌握题（≥3 次答对）
    final masteredClause = ' AND id NOT IN ($_masteredSubquery)';
    final roundClause = minRound == null ? '' : ' AND (round IS NULL OR round >= $minRound)';

    Future<List<Question>> q1(String where, List<dynamic> args, int n) async {
      final maps = await db.query(
        'questions',
        where: where + excludeClause + masteredClause + roundClause,
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
          where: where + excludeClauseNow + masteredClause + roundClause,
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
          where: where + excludeClauseNow + masteredClause + roundClause,
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

  /// V3.8：按 round 限制的 KP 抽题（替代 getQuestionsForKpExcludingWrong 在难度设置开启时使用）
  /// 排除原错题；先取未做过的，再按权重补
  Future<List<Question>> getQuestionsForKpByRound({
    required String kpPath,
    List<int>? rounds,
    List<int>? weights,
    required int limit,
  }) async {
    if (limit <= 0) return [];
    final db = await _db.database;
    String roundFilter = '';
    List<dynamic> roundArgs = [];
    if (rounds != null && rounds.length == 1) {
      roundFilter = ' AND round = ?';
      roundArgs = [rounds.first];
    } else if (rounds != null && rounds.length > 1) {
      final ph = List.filled(rounds.length, '?').join(',');
      roundFilter = ' AND round IN ($ph)';
      roundArgs = [...rounds];
    }

    // Tier 1: 同 KP + round 匹配 + 未做过 + 未掌握 (V3.8.2)
    final fresh = await db.rawQuery('''
      SELECT * FROM questions
      WHERE knowledge_point = ?$roundFilter
        AND id NOT IN (SELECT DISTINCT question_id FROM practice_records)
        AND id NOT IN ($_masteredSubquery)
      ORDER BY RANDOM()
      LIMIT ?
    ''', [kpPath, ...roundArgs, limit]);
    if (fresh.length >= limit) {
      return await _expandGroups(fresh.map(Question.fromMap).toList());
    }

    // Tier 2: 做过但从未答错过 + 最久未练 + 未掌握
    final remaining = limit - fresh.length;
    final pickedIds = fresh.map((m) => m['id']).toList();
    final ph2 = pickedIds.isEmpty ? '0' : List.filled(pickedIds.length, '?').join(',');
    final stale = await db.rawQuery('''
      SELECT q.*
      FROM questions q
      LEFT JOIN (
        SELECT question_id, MAX(practiced_at) AS last_practiced
        FROM practice_records
        GROUP BY question_id
      ) lr ON lr.question_id = q.id
      WHERE q.knowledge_point = ?$roundFilter
        AND q.id NOT IN ($ph2)
        AND q.id NOT IN (
          SELECT DISTINCT question_id FROM practice_records WHERE is_correct = 0
        )
        AND q.id NOT IN ($_masteredSubquery)
      ORDER BY lr.last_practiced ASC
      LIMIT ?
    ''', [kpPath, ...roundArgs, ...pickedIds, remaining]);

    final combined = [
      ...fresh.map(Question.fromMap),
      ...stale.map(Question.fromMap),
    ];
    return await _expandGroups(combined);
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

  /// V3.8：根据 KP path 反查所属科目（中文名，与 displayName 一致）
  /// 用法：薄弱点练习时取该 KP 的科目，进而读取该科目的难度 profile
  Future<String?> getSubjectForKp(String kpPath) async {
    final db = await _db.database;
    final r = await db.rawQuery(
        'SELECT subject FROM questions WHERE knowledge_point = ? LIMIT 1', [kpPath]);
    if (r.isEmpty) return null;
    final idx = r.first['subject'] as int?;
    if (idx == null) return null;
    return Subject.values[idx].displayName;
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

  // ── V3.8.3: 申诉/主观题评分相关 ───────────────────────

  Future<Question?> findById(int questionId) async {
    final db = await _db.database;
    final rows = await db.query(
      'questions',
      where: 'id = ?',
      whereArgs: [questionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Question.fromMap(rows.first);
  }

  Future<PracticeRecord?> findPracticeRecord(int recordId) async {
    final db = await _db.database;
    final rows = await db.query(
      'practice_records',
      where: 'id = ?',
      whereArgs: [recordId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PracticeRecord.fromMap(rows.first);
  }

  Future<void> updatePracticeRecordIsCorrect(int recordId, bool isCorrect) async {
    final db = await _db.database;
    await db.update(
      'practice_records',
      {'is_correct': isCorrect ? 1 : 0},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  /// 算 session 当前 (score, total)，用于审核通过后重判 session 是否新进入"通过"区间
  Future<({int score, int total})> getSessionScore(String sessionId) async {
    final db = await _db.database;
    final r = await db.rawQuery('''
      SELECT COUNT(*) as total,
             SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct
      FROM practice_records
      WHERE session_id = ?
    ''', [sessionId]);
    final row = r.first;
    return (
      score: (row['correct'] as int?) ?? 0,
      total: (row['total'] as int?) ?? 0,
    );
  }

  /// 找出 session 内所有题目的 (subject, grade, chapter, kp)，用于审核通过后
  /// 重新触发 PlanService.autoCompleteFromPractice
  Future<List<Map<String, Object?>>> getSessionKpTuples(String sessionId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT q.subject, q.grade, q.chapter, q.knowledge_point
      FROM practice_records r
      JOIN questions q ON q.id = r.question_id
      WHERE r.session_id = ?
    ''', [sessionId]);
    return rows;
  }

  /// 判断一道题在小孩做过的所有记录中累计出现了多少次（替代选项随机：用次数标提醒"做过 N 次"）
  Future<int> getAttemptCountForQuestion(int questionId) async {
    final db = await _db.database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) as c FROM practice_records WHERE question_id = ?',
      [questionId],
    );
    return (r.first['c'] as int?) ?? 0;
  }
}
