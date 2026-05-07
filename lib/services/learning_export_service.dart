import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../database/question_dao.dart';
import '../database/review_request_dao.dart';
import '../models/review_request.dart';

/// 学情数据导出：弱 KP + 最近错题 + KP 全量统计 + 整体准确率。
/// 第二阶段 cron 用 by_kp 段的 error_rate 做权重分配错题反馈题。
class LearningExportService {
  final _dao = QuestionDao();
  final _reviewDao = ReviewRequestDao();

  Future<String> buildJson() async {
    final weak = await _dao.getWeakKnowledgePoints();
    final recent = await _dao.getRecentWrongQuestions(limit: 50);
    final stats = await _dao.getOverallStats();
    final byKp = await _getAllKpStats();
    final reviewFeedback = await _buildReviewFeedback();

    final total = stats['total'] ?? 0;
    final correct = stats['correct'] ?? 0;
    final accuracy = total > 0 ? correct / total : 0.0;

    final payload = {
      'exported_at': DateTime.now().toIso8601String(),
      'summary': {
        'total': total,
        'correct': correct,
        'accuracy': double.parse(accuracy.toStringAsFixed(3)),
      },
      'weak_points': weak,
      'recent_wrong': recent,
      'by_kp': byKp,
      // V3.8.3: 家长审核反馈段
      // cron 端用：同模式 ≥3 次 approved → AnswerMatcher 归一化规则待调；
      // 单题 approved → 题包侧 alt_answers 补 / 转选择题 / 删；
      // rejected 不动作（说明判定本身是对的）
      'review_feedback': reviewFeedback,
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// 把已审核的申诉/主观题评分整理成 cron 可读的列表
  Future<List<Map<String, dynamic>>> _buildReviewFeedback() async {
    final reviewed = await _reviewDao.listReviewedForExport();
    if (reviewed.isEmpty) return [];
    final out = <Map<String, dynamic>>[];
    for (final r in reviewed) {
      final q = await _dao.findById(r.questionId);
      if (q == null) continue;
      out.add({
        'request_type': r.requestType.key,
        'status': r.status.key,
        'question_id': r.questionId,
        'subject': q.subject.index,
        'grade': q.grade,
        'knowledge_point': q.knowledgePoint,
        'content': q.content,
        'user_answer': r.userAnswer,
        'standard_answer': r.standardAnswer,
        'child_note': r.childNote,
        'parent_note': r.parentNote,
        'parent_score': r.parentScore?.key,
        'reviewed_at': r.reviewedAt?.toIso8601String(),
      });
    }
    return out;
  }

  /// 全部 KP 的 attempts/errors/error_rate + mastered_count（V3.8.2）
  /// mastered_count = 该 KP 下累计答对 ≥3 次的题数（被"掌握"题数）
  Future<List<Map<String, dynamic>>> _getAllKpStats() async {
    final db = await DatabaseHelper().database;
    return db.rawQuery('''
      WITH kp_stats AS (
        SELECT q.subject, q.grade, q.knowledge_point,
               COUNT(*) as attempts,
               SUM(CASE WHEN r.is_correct = 0 THEN 1 ELSE 0 END) as errors,
               ROUND(1.0 * SUM(CASE WHEN r.is_correct = 0 THEN 1 ELSE 0 END) / COUNT(*), 3) as error_rate
        FROM practice_records r
        JOIN questions q ON r.question_id = q.id
        WHERE q.knowledge_point IS NOT NULL
        GROUP BY q.subject, q.grade, q.knowledge_point
      ),
      mastered AS (
        SELECT q.subject, q.grade, q.knowledge_point,
               COUNT(DISTINCT q.id) as mastered_count
        FROM questions q
        WHERE q.id IN (
          SELECT question_id FROM practice_records
          WHERE is_correct = 1
          GROUP BY question_id
          HAVING COUNT(*) >= 3
        )
        AND q.knowledge_point IS NOT NULL
        GROUP BY q.subject, q.grade, q.knowledge_point
      )
      SELECT s.subject, s.grade, s.knowledge_point,
             s.attempts, s.errors, s.error_rate,
             COALESCE(m.mastered_count, 0) as mastered_count
      FROM kp_stats s
      LEFT JOIN mastered m
        ON m.subject = s.subject AND m.grade = s.grade
        AND m.knowledge_point = s.knowledge_point
      ORDER BY s.error_rate DESC, s.attempts DESC
    ''');
  }

  /// 导出并通过 share_plus 分享出去（保留作为手动备选通道）
  Future<void> exportAndShare() async {
    final json = await buildJson();
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${dir.path}/learning_export_$ts.json');
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: '学情数据 $ts',
    );
  }
}
