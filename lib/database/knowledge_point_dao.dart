import '../models/knowledge_point.dart';
import 'database_helper.dart';

class KnowledgePointDao {
  final DatabaseHelper _db = DatabaseHelper();

  Future<bool> isEmpty() async {
    final db = await _db.database;
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM knowledge_points');
    return ((r.first['c'] as int?) ?? 0) == 0;
  }

  /// 幂等插入（按 subject+full_path UNIQUE）。已存在则跳过。
  Future<void> insertIfMissing(List<KnowledgePoint> kps) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final kp in kps) {
      batch.rawInsert(
        'INSERT OR IGNORE INTO knowledge_points '
        '(subject, category, name, full_path, introduced_grade) '
        'VALUES (?, ?, ?, ?, ?)',
        [kp.subject, kp.category, kp.name, kp.fullPath, kp.introducedGrade],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<KnowledgePoint>> getBySubject(String subject) async {
    final db = await _db.database;
    final maps = await db.query(
      'knowledge_points',
      where: 'subject = ?',
      whereArgs: [subject],
      orderBy: 'category ASC, name ASC',
    );
    return maps.map(KnowledgePoint.fromMap).toList();
  }

  Future<KnowledgePoint?> findByPath(String subject, String fullPath) async {
    final db = await _db.database;
    final maps = await db.query(
      'knowledge_points',
      where: 'subject = ? AND full_path = ?',
      whereArgs: [subject, fullPath],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return KnowledgePoint.fromMap(maps.first);
  }
}
