import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';

/// 全量数据备份/恢复
///
/// 这版起 app 进入正式使用，必须保证升级 / 重装 / 换设备 不丢数据。
/// V3.7 上线 CloudBase 同步前，本地手动备份是唯一兜底。
class DataBackupService {
  static const _backupTables = [
    'questions',
    'practice_records',
    'knowledge_points',
    'points',
    'plan_groups',
    'plan_items',
    'curriculum',
  ];

  static const _backupVersion = 1;

  Future<String> buildBackupJson() async {
    final db = await DatabaseHelper().database;
    final tables = <String, List<Map<String, Object?>>>{};
    for (final t in _backupTables) {
      final rows = await db.query(t);
      tables[t] = rows;
    }
    final payload = {
      'backup_version': _backupVersion,
      'app_version': 'V3.6',
      'created_at': DateTime.now().toIso8601String(),
      'tables': tables,
    };
    return jsonEncode(payload);
  }

  Future<void> exportAndShare() async {
    final json = await buildBackupJson();
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${dir.path}/learning_backup_$ts.json');
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: '学习小助手数据备份 $ts',
    );
  }

  /// 让用户选 JSON 文件 → 解析 → 覆盖本地
  /// 返回 (success, message)
  Future<(bool, String)> pickAndRestore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) {
      return (false, '已取消');
    }
    final path = result.files.single.path;
    if (path == null) return (false, '无法读取文件路径');

    try {
      final content = await File(path).readAsString();
      return await restoreFromJson(content);
    } catch (e) {
      return (false, '读取失败：$e');
    }
  }

  Future<(bool, String)> restoreFromJson(String jsonStr) async {
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return (false, '不是有效的 JSON');
    }

    final tables = payload['tables'] as Map<String, dynamic>?;
    if (tables == null || tables.isEmpty) {
      return (false, '备份不含任何表数据');
    }

    final missing = _backupTables.where((t) => !tables.containsKey(t)).toList();
    if (missing.length > 3) {
      return (false, '备份缺失关键表：${missing.join(', ')}');
    }

    final db = await DatabaseHelper().database;
    int totalRestored = 0;
    await db.transaction((txn) async {
      for (final t in _backupTables) {
        final rows = (tables[t] as List?)?.cast<Map<String, dynamic>>();
        if (rows == null) continue;
        await txn.delete(t);
        for (final row in rows) {
          await txn.insert(t, row);
          totalRestored++;
        }
      }
    });

    return (true, '已恢复 $totalRestored 条记录');
  }
}
