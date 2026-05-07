import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../database/question_dao.dart';

/// 学情数据导出：弱 KP + 最近错题 + KP 全量统计 + 整体准确率。
/// 第二阶段 cron 用 by_kp 段的 error_rate 做权重分配错题反馈题。
class LearningExportService {
  final _dao = QuestionDao();

  Future<String> buildJson() async {
    final weak = await _dao.getWeakKnowledgePoints();
    final recent = await _dao.getRecentWrongQuestions(limit: 50);
    final stats = await _dao.getOverallStats();
    final byKp = await _getAllKpStats();

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
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// 全部 KP 的 attempts/errors/error_rate（不过滤），用于第二阶段加权
  Future<List<Map<String, dynamic>>> _getAllKpStats() async {
    final db = await DatabaseHelper().database;
    return db.rawQuery('''
      SELECT q.subject, q.grade, q.knowledge_point,
             COUNT(*) as attempts,
             SUM(CASE WHEN r.is_correct = 0 THEN 1 ELSE 0 END) as errors,
             ROUND(1.0 * SUM(CASE WHEN r.is_correct = 0 THEN 1 ELSE 0 END) / COUNT(*), 3) as error_rate
      FROM practice_records r
      JOIN questions q ON r.question_id = q.id
      WHERE q.knowledge_point IS NOT NULL
      GROUP BY q.subject, q.grade, q.knowledge_point
      ORDER BY error_rate DESC, attempts DESC
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
