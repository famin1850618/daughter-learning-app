import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

/// V3.11 数据重置服务
///
/// 试题期间累积的 rewards/assessments/wrong_questions/practice_records/practice_sessions/
/// review_requests 6 表 + plan_items 完成度，可一键归档清空；7 天内可回滚。
///
/// 触发方式：
/// - V3.11 升级首次启动自动触发一次（main.dart 凭 SharedPreferences 标志）
/// - 设置页"重置全部学习数据"按钮（用户主动 + 三段确认）
class DataResetService extends ChangeNotifier {
  static final DataResetService _instance = DataResetService._();
  factory DataResetService() => _instance;
  DataResetService._();

  /// 受归档保护的 5 个用户进度表
  /// 注：错题集不是独立表，由 practice_records.is_correct=0 反推 → 清空 practice_records 即清空错题
  static const _resetTables = [
    'rewards',
    'assessments',
    'practice_records',
    'practice_sessions',
    'review_requests',
  ];

  /// 回滚窗口（天）
  static const int rollbackDays = 7;

  /// 归档 + 清零全部学习进度数据。返回 batchId（成功）或 null（失败）。
  ///
  /// 流程：
  /// 1) 启动 transaction
  /// 2) 给 6 个表里所有行序列化进 data_reset_rows，标 batchId
  /// 3) plan_items 中已完成（status != 0 或 completed_at != null）的行也归档
  /// 4) DELETE 6 个主表
  /// 5) UPDATE plan_items SET status=0, completed_at=NULL
  /// 6) 写 data_reset_archives 一行（含 stats）
  /// 7) commit
  Future<String?> resetAllProgress({required String reason}) async {
    final db = await DatabaseHelper().database;
    final batchId = 'reset_${DateTime.now().millisecondsSinceEpoch}';
    final stats = <String, int>{};

    try {
      await db.transaction((txn) async {
        // 归档 6 个进度表
        for (final t in _resetTables) {
          final rows = await txn.query(t);
          stats[t] = rows.length;
          for (final r in rows) {
            await txn.insert('data_reset_rows', {
              'archive_batch_id': batchId,
              'table_name': t,
              'row_json': jsonEncode(r),
            });
          }
          await txn.delete(t);
        }

        // plan_items 已完成行归档（不删整行，只重置 status / completed_at）
        final completedItems = await txn.query(
          'plan_items',
          where: 'status != 0 OR completed_at IS NOT NULL',
        );
        stats['plan_items_completion'] = completedItems.length;
        for (final r in completedItems) {
          await txn.insert('data_reset_rows', {
            'archive_batch_id': batchId,
            'table_name': 'plan_items_completion',
            'row_json': jsonEncode(r),
          });
        }
        await txn.update(
          'plan_items',
          {'status': 0, 'completed_at': null},
        );

        // 写归档主记录
        await txn.insert('data_reset_archives', {
          'batch_id': batchId,
          'created_at': DateTime.now().toIso8601String(),
          'reason': reason,
          'stats_json': jsonEncode(stats),
        });
      });
    } catch (e) {
      debugPrint('DataResetService.resetAllProgress failed: $e');
      return null;
    }

    notifyListeners();
    return batchId;
  }

  /// 列出未过期且未回滚的归档（按 created_at 倒序）。
  Future<List<DataResetArchive>> listArchives() async {
    final db = await DatabaseHelper().database;
    final cutoff = DateTime.now().subtract(const Duration(days: rollbackDays));
    final rows = await db.query(
      'data_reset_archives',
      where: 'rolled_back_at IS NULL AND created_at >= ?',
      whereArgs: [cutoff.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    return rows.map(DataResetArchive.fromMap).toList();
  }

  /// 回滚一次归档。把 data_reset_rows 中该 batchId 的行写回主表。
  Future<bool> rollbackArchive(String batchId) async {
    final db = await DatabaseHelper().database;
    try {
      final archive = await db.query(
        'data_reset_archives',
        where: 'batch_id = ? AND rolled_back_at IS NULL',
        whereArgs: [batchId],
        limit: 1,
      );
      if (archive.isEmpty) return false;

      // 检查是否过期
      final created = DateTime.parse(archive.first['created_at'] as String);
      if (DateTime.now().difference(created).inDays > rollbackDays) {
        return false;
      }

      await db.transaction((txn) async {
        final rows = await txn.query(
          'data_reset_rows',
          where: 'archive_batch_id = ?',
          whereArgs: [batchId],
        );

        for (final row in rows) {
          final tableName = row['table_name'] as String;
          final dataJson = row['row_json'] as String;
          final data = Map<String, dynamic>.from(jsonDecode(dataJson) as Map);

          if (tableName == 'plan_items_completion') {
            // plan_items 完成度回滚：UPDATE 而不是 INSERT
            final id = data['id'];
            if (id != null) {
              await txn.update(
                'plan_items',
                {
                  'status': data['status'],
                  'completed_at': data['completed_at'],
                },
                where: 'id = ?',
                whereArgs: [id],
              );
            }
          } else {
            // 6 进度表：直接 INSERT（保持原 id）
            try {
              await txn.insert(
                tableName,
                data,
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            } catch (_) {/* 单行失败不阻断 */}
          }
        }

        await txn.update(
          'data_reset_archives',
          {'rolled_back_at': DateTime.now().toIso8601String()},
          where: 'batch_id = ?',
          whereArgs: [batchId],
        );

        // 删归档行（已回滚不再保留）
        await txn.delete('data_reset_rows', where: 'archive_batch_id = ?', whereArgs: [batchId]);
      });
    } catch (e) {
      debugPrint('DataResetService.rollbackArchive failed: $e');
      return false;
    }

    notifyListeners();
    return true;
  }

  /// 启动时调，清理超过 7 天的归档。
  Future<void> gcExpiredArchives() async {
    final db = await DatabaseHelper().database;
    final cutoff = DateTime.now().subtract(const Duration(days: rollbackDays));
    try {
      // 先收集要删的 batchId
      final expired = await db.query(
        'data_reset_archives',
        where: 'created_at < ?',
        whereArgs: [cutoff.toIso8601String()],
      );
      for (final a in expired) {
        final batchId = a['batch_id'] as String;
        await db.delete('data_reset_rows', where: 'archive_batch_id = ?', whereArgs: [batchId]);
      }
      await db.delete(
        'data_reset_archives',
        where: 'created_at < ?',
        whereArgs: [cutoff.toIso8601String()],
      );
    } catch (e) {
      debugPrint('DataResetService.gcExpiredArchives failed: $e');
    }
  }
}

class DataResetArchive {
  final String batchId;
  final DateTime createdAt;
  final String reason;
  final Map<String, int> stats;

  DataResetArchive({
    required this.batchId,
    required this.createdAt,
    required this.reason,
    required this.stats,
  });

  factory DataResetArchive.fromMap(Map<String, Object?> m) {
    final statsJson = m['stats_json'] as String? ?? '{}';
    final raw = jsonDecode(statsJson) as Map<String, dynamic>;
    final stats = raw.map((k, v) => MapEntry(k, (v as num).toInt()));
    return DataResetArchive(
      batchId: m['batch_id'] as String,
      createdAt: DateTime.parse(m['created_at'] as String),
      reason: (m['reason'] as String?) ?? '',
      stats: stats,
    );
  }

  /// 距离过期还剩多少天（已过期为 0）
  int get daysUntilExpiry {
    final expireAt = createdAt.add(const Duration(days: DataResetService.rollbackDays));
    final remaining = expireAt.difference(DateTime.now()).inHours;
    return (remaining / 24).ceil().clamp(0, DataResetService.rollbackDays);
  }

  /// 总归档行数（不含 plan_items_completion 单独记的）
  int get totalRowsArchived =>
      stats.entries.where((e) => e.key != 'plan_items_completion').fold(0, (a, b) => a + b.value);
}
