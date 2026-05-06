import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/question_dao.dart';

/// 学情数据导出：弱 KP + 最近错题 + 整体准确率，生成 JSON 让 Famin 发给我做下批生成的输入
class LearningExportService {
  final _dao = QuestionDao();

  Future<String> buildJson() async {
    final weak = await _dao.getWeakKnowledgePoints();
    final recent = await _dao.getRecentWrongQuestions(limit: 50);
    final stats = await _dao.getOverallStats();

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
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// 导出并通过 share_plus 分享出去
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
