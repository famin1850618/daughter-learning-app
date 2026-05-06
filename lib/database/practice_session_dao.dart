import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// 练习 session 持久化（单行表，id 固定 1，覆盖式）
class PracticeSessionDao {
  static const _id = 1;

  Future<void> save({
    required String questionsJson,
    required int currentIndex,
    required int score,
    required int kind,
    required bool sessionActive,
    String? sessionId,
    required bool hintShown,
    required bool rewardClaimed,
    String? lastRewardJson,
  }) async {
    final db = await DatabaseHelper().database;
    await db.insert(
      'practice_sessions',
      {
        'id': _id,
        'questions_json': questionsJson,
        'current_index': currentIndex,
        'score': score,
        'kind': kind,
        'session_active': sessionActive ? 1 : 0,
        'session_id': sessionId,
        'hint_shown': hintShown ? 1 : 0,
        'reward_claimed': rewardClaimed ? 1 : 0,
        'last_reward_json': lastRewardJson,
        'saved_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> load() async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('practice_sessions',
        where: 'id = ?', whereArgs: [_id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> clear() async {
    final db = await DatabaseHelper().database;
    await db.delete('practice_sessions', where: 'id = ?', whereArgs: [_id]);
  }
}
