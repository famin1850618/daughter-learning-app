import '../models/review_request.dart';
import 'database_helper.dart';

/// V3.8.3 申诉 / 主观题评分共用 DAO
class ReviewRequestDao {
  final DatabaseHelper _helper = DatabaseHelper();

  Future<int> insert(ReviewRequest req) async {
    final db = await _helper.database;
    return db.insert('review_requests', req.toMap());
  }

  Future<ReviewRequest?> findById(int id) async {
    final db = await _helper.database;
    final rows = await db.query(
      'review_requests',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ReviewRequest.fromMap(rows.first);
  }

  /// 同一条 practice_record 一旦申诉过就不能再发起（pending/approved/rejected 任一状态都拦）
  /// V3.14: 清孤儿 review_requests（关联的 question_id 已被删）
  /// 修 bug: "已删的题如果提起过申诉会留在申诉页面去不掉"
  /// 老 v22 升级到 v23 前 INSERT 的 review_requests 没 ON DELETE CASCADE，
  /// 导致 question 被删后 review_request 残留。每次 refresh 头部调用清理。
  Future<int> cleanupOrphans() async {
    final db = await _helper.database;
    return await db.rawDelete('''
      DELETE FROM review_requests
      WHERE question_id NOT IN (SELECT id FROM questions)
    ''');
  }

  Future<ReviewRequest?> findByPracticeRecordId(int recordId) async {
    final db = await _helper.database;
    final rows = await db.query(
      'review_requests',
      where: 'practice_record_id = ?',
      whereArgs: [recordId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ReviewRequest.fromMap(rows.first);
  }

  /// V3.13 修正：用于 aiDispute 去重（同 question_id + type 已存在则跳）
  Future<ReviewRequest?> findExistingByQuestionAndType(
      int questionId, ReviewRequestType type) async {
    final db = await _helper.database;
    final rows = await db.query(
      'review_requests',
      where: 'question_id = ? AND request_type = ?',
      whereArgs: [questionId, type.key],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ReviewRequest.fromMap(rows.first);
  }

  Future<List<ReviewRequest>> listByStatus(
    ReviewRequestStatus status, {
    ReviewRequestType? type,
  }) async {
    final db = await _helper.database;
    final where = <String>['status = ?'];
    final args = <Object?>[status.key];
    if (type != null) {
      where.add('request_type = ?');
      args.add(type.key);
    }
    final rows = await db.query(
      'review_requests',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return rows.map(ReviewRequest.fromMap).toList();
  }

  Future<int> countByStatus(ReviewRequestStatus status, {ReviewRequestType? type}) async {
    final db = await _helper.database;
    String sql = "SELECT COUNT(*) AS c FROM review_requests WHERE status = '${status.key}'";
    if (type != null) {
      sql += " AND request_type = '${type.key}'";
    }
    final rows = await db.rawQuery(sql);
    if (rows.isEmpty) return 0;
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<void> updateStatus({
    required int id,
    required ReviewRequestStatus status,
    String? parentNote,
    SubjectiveScore? parentScore,
    ReviewIssueType? issueType,
    required DateTime reviewedAt,
  }) async {
    final db = await _helper.database;
    final values = <String, Object?>{
      'status': status.key,
      'reviewed_at': reviewedAt.toIso8601String(),
    };
    if (parentNote != null) values['parent_note'] = parentNote;
    if (parentScore != null) values['parent_score'] = parentScore.key;
    if (issueType != null) values['issue_type'] = issueType.key;
    await db.update(
      'review_requests',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 学情导出用：返回所有非 pending 的请求（含 approved/rejected）
  Future<List<ReviewRequest>> listReviewedForExport() async {
    final db = await _helper.database;
    final rows = await db.query(
      'review_requests',
      where: "status != 'pending'",
      orderBy: 'reviewed_at DESC',
    );
    return rows.map(ReviewRequest.fromMap).toList();
  }
}
