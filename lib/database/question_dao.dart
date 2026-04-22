import '../models/question.dart';
import '../models/subject.dart';
import 'database_helper.dart';

class QuestionDao {
  final DatabaseHelper _db = DatabaseHelper();

  Future<void> insertBatch(List<Question> questions) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final q in questions) {
      batch.insert('questions', q.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<Question>> getRandom({
    required Subject subject,
    required int grade,
    String? chapter,
    Difficulty? difficulty,
    int limit = 10,
  }) async {
    final db = await _db.database;
    String where = 'subject = ? AND grade = ?';
    List<dynamic> args = [subject.index, grade];
    if (chapter != null) {
      where += ' AND chapter = ?';
      args.add(chapter);
    }
    if (difficulty != null) {
      where += ' AND difficulty = ?';
      args.add(difficulty.index);
    }
    final maps = await db.query(
      'questions',
      where: where,
      whereArgs: args,
      orderBy: 'RANDOM()',
      limit: limit,
    );
    return maps.map(Question.fromMap).toList();
  }

  Future<List<Question>> getWrongQuestions(int limit) async {
    final db = await _db.database;
    // 取最近答错且未答对过的题
    final maps = await db.rawQuery('''
      SELECT q.* FROM questions q
      INNER JOIN practice_records r ON q.id = r.question_id
      WHERE r.is_correct = 0
        AND q.id NOT IN (
          SELECT question_id FROM practice_records WHERE is_correct = 1
        )
      GROUP BY q.id
      ORDER BY MAX(r.practiced_at) DESC
      LIMIT ?
    ''', [limit]);
    return maps.map(Question.fromMap).toList();
  }

  Future<int> insertRecord(PracticeRecord record) async {
    final db = await _db.database;
    return db.insert('practice_records', record.toMap());
  }

  Future<Map<String, int>> getStats(Subject subject, int grade) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as total,
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
}
