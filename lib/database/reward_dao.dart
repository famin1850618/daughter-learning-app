import 'database_helper.dart';
import '../models/reward.dart';

class RewardDao {
  Future<int> insert(Reward r) async {
    final db = await DatabaseHelper().database;
    return db.insert('rewards', r.toMap());
  }

  Future<double> getTotalStars() async {
    final db = await DatabaseHelper().database;
    final res = await db
        .rawQuery('SELECT COALESCE(SUM(stars), 0) AS total FROM rewards');
    return ((res.first['total'] as num?) ?? 0).toDouble();
  }

  Future<Map<String, double>> getStarsBySource() async {
    final db = await DatabaseHelper().database;
    final res = await db.rawQuery(
        'SELECT source, COALESCE(SUM(stars), 0) AS s FROM rewards GROUP BY source');
    final out = <String, double>{};
    for (final row in res) {
      out[row['source'] as String] = ((row['s'] as num?) ?? 0).toDouble();
    }
    return out;
  }

  Future<List<Reward>> getRecent({int limit = 30}) async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('rewards',
        orderBy: 'earned_at DESC', limit: limit);
    return rows.map(Reward.fromMap).toList();
  }

  Future<List<Reward>> getAll() async {
    final db = await DatabaseHelper().database;
    final rows =
        await db.query('rewards', orderBy: 'earned_at DESC');
    return rows.map(Reward.fromMap).toList();
  }

  Future<void> deleteAll() async {
    final db = await DatabaseHelper().database;
    await db.delete('rewards');
  }

  /// V3.8.3: 查 session 已发的所有奖励行（用于审核通过后判断是否需补发通过加成）
  Future<List<Reward>> getBySessionId(String sessionId) async {
    final db = await DatabaseHelper().database;
    final rows = await db.query(
      'rewards',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'earned_at ASC',
    );
    return rows.map(Reward.fromMap).toList();
  }
}
