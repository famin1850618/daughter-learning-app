import 'package:sqflite/sqflite.dart';
import '../models/curriculum.dart';
import 'curriculum_seed.dart';
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

  /// V3.10：增量插入缺失 chapter（老用户升级时把新加的 22 个 V3.10 chapter 补上）
  /// 按 (subject, grade, chapterName) 去重，已存在的跳过。
  Future<void> insertIfMissing(List<Chapter> chapters) async {
    final db = await _db.database;
    for (final c in chapters) {
      final existing = await db.rawQuery(
        'SELECT id FROM curriculum WHERE subject=? AND grade=? AND chapter_name=? LIMIT 1',
        [c.subject, c.grade, c.chapterName],
      );
      if (existing.isEmpty) {
        await db.insert('curriculum', c.toMap());
      }
    }
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

  Future<int> insertChapter(String subject, int grade, String chapterName) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT MAX(order_index) AS m FROM curriculum WHERE subject = ? AND grade = ?',
      [subject, grade],
    );
    final maxIdx = Sqflite.firstIntValue(result) ?? 0;
    return db.insert('curriculum', {
      'subject': subject,
      'grade': grade,
      'chapter_name': chapterName,
      'order_index': maxIdx + 1,
    });
  }

  Future<void> deleteChapter(int id) async {
    final db = await _db.database;
    await db.delete('curriculum', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateOrder(List<Chapter> chapters) async {
    final db = await _db.database;
    final batch = db.batch();
    for (int i = 0; i < chapters.length; i++) {
      batch.update('curriculum', {'order_index': i + 1},
          where: 'id = ?', whereArgs: [chapters[i].id]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> resetToDefault(String subject, int grade) async {
    final db = await _db.database;
    await db.delete('curriculum',
        where: 'subject = ? AND grade = ?', whereArgs: [subject, grade]);
    final defaults = curriculumChapters
        .where((c) => c.subject == subject && c.grade == grade)
        .toList();
    final batch = db.batch();
    for (final c in defaults) {
      batch.insert('curriculum', c.toMap());
    }
    await batch.commit(noResult: true);
  }
}
