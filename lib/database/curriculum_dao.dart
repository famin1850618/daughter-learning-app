import 'package:sqflite/sqflite.dart';
import '../models/curriculum.dart';
import 'database_helper.dart';

class CurriculumDao {
  final _db = DatabaseHelper();

  Future<void> insertBatch(List<Chapter> chapters) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final c in chapters) {
      batch.insert('curriculum', c.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<bool> isEmpty() async {
    final db = await _db.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM curriculum'),
    );
    return (count ?? 0) == 0;
  }

  /// 返回有内容的所有科目列表
  Future<List<String>> getSubjects() async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT subject FROM curriculum ORDER BY subject',
    );
    return rows.map((r) => r['subject'] as String).toList();
  }

  /// 某科目有哪些年级（返回 [6,7,8,9] 的子集）
  Future<List<int>> getGradesForSubject(String subject) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT grade FROM curriculum WHERE subject = ? ORDER BY grade',
      [subject],
    );
    return rows.map((r) => r['grade'] as int).toList();
  }

  /// 某年级有哪些科目
  Future<List<String>> getSubjectsForGrade(int grade) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT subject FROM curriculum WHERE grade = ? ORDER BY subject',
      [grade],
    );
    return rows.map((r) => r['subject'] as String).toList();
  }

  /// 某科目+年级的章节列表
  Future<List<Chapter>> getChapters(String subject, int grade) async {
    final db = await _db.database;
    final rows = await db.query(
      'curriculum',
      where: 'subject = ? AND grade = ?',
      whereArgs: [subject, grade],
      orderBy: 'order_index ASC',
    );
    return rows.map(Chapter.fromMap).toList();
  }

  Future<Chapter?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query('curriculum', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Chapter.fromMap(rows.first);
  }
}
