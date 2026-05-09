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

  /// V3.12.9: 重置/回滚版本号，每次 mutation +1。
  /// UI 用 context.select<DataResetService,int>((s)=>s.resetVersion) + ValueKey
  /// 强制重建依赖控件（错题集/薄弱 KP），修 V3.12.7 listener 在某些设备不触发的问题。
  int _resetVersion = 0;
  int get resetVersion => _resetVersion;

  /// 归档 + 清零全部学习进度数据。返回 batchId（成功）或 null（失败）。
  ///
  /// [wipePlans] = true 时（V3.12 新增）：除 5 个进度表外，连同 plan_groups +
  /// plan_items 整表全部归档并 DELETE，回滚时整体恢复。默认 false 仅重置完成度。
  ///
  /// 流程：
  /// 1) 启动 transaction
  /// 2) 5 个进度表全行归档 → DELETE
  /// 3a) wipePlans=false：plan_items 已完成行归档（'plan_items_completion'），
  ///     UPDATE plan_items SET status=0, completed_at=NULL
  /// 3b) wipePlans=true：plan_groups + plan_items 全表归档 → DELETE
  /// 4) 写 data_reset_archives 一行（含 stats / wipe_plans 标志）
  /// 5) commit
  Future<String?> resetAllProgress({
    required String reason,
    bool wipePlans = false,
  }) async {
    final db = await DatabaseHelper().database;
    final batchId = 'reset_${DateTime.now().millisecondsSinceEpoch}';
    final stats = <String, int>{};

    try {
      await db.transaction((txn) async {
        // 归档 5 个进度表
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

        if (wipePlans) {
          // 整表归档 plan_groups + plan_items（FK 顺序要求：先 items 再 groups
          // 才能 DELETE 不被 FK 阻挡；但归档顺序无所谓，回滚时显式排序）
          for (final t in const ['plan_items', 'plan_groups']) {
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
        } else {
          // 仅归档已完成 plan_items 行（不删整行，只重置 status / completed_at）
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
        }

        // wipe_plans 标志通过 stats 里是否存在 'plan_groups' key 反推（避免 schema 改动）
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

    _resetVersion++;
    notifyListeners();
    return batchId;
  }

  /// V3.12.9: 删除归档（不回滚，直接清归档行 + data_reset_rows）。
  /// 用户不想回滚某次重置时直接删，避免归档列表越积越多。
  Future<bool> deleteArchive(String batchId) async {
    final db = await DatabaseHelper().database;
    try {
      await db.transaction((txn) async {
        await txn.delete('data_reset_rows',
            where: 'archive_batch_id = ?', whereArgs: [batchId]);
        await txn.delete('data_reset_archives',
            where: 'batch_id = ?', whereArgs: [batchId]);
      });
      _resetVersion++;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('DataResetService.deleteArchive failed: $e');
      return false;
    }
  }

  /// V3.12.9: 强制重建题库（清 questions 表，让 main.dart 启动钩子重 import bundled）。
  /// 用户主动触发；适用题量显示错误（DB 升级 DELETE 没生效等场景）。
  /// 注：不影响 practice_records 等学情数据（题被删 → 错题集 view 自动消失，不会孤儿 FK）。
  Future<int> rebuildQuestions() async {
    final db = await DatabaseHelper().database;
    try {
      final before = await db.rawQuery('SELECT COUNT(*) as c FROM questions');
      final beforeCount = (before.first['c'] as int?) ?? 0;
      await db.delete('questions');
      _resetVersion++;
      notifyListeners();
      return beforeCount;
    } catch (e) {
      debugPrint('DataResetService.rebuildQuestions failed: $e');
      return -1;
    }
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
          orderBy: 'id ASC',
        );

        // 三批分组保 FK 顺序：
        //   1. 进度表 + plan_groups → INSERT
        //   2. plan_items → INSERT（依赖 plan_groups 已先回）
        //   3. plan_items_completion → UPDATE 完成度
        final firstPass = <Map<String, Object?>>[];
        final itemRows = <Map<String, Object?>>[];
        final completionRows = <Map<String, Object?>>[];
        for (final row in rows) {
          final t = row['table_name'] as String;
          if (t == 'plan_items') {
            itemRows.add(row);
          } else if (t == 'plan_items_completion') {
            completionRows.add(row);
          } else {
            firstPass.add(row);
          }
        }

        Future<void> insertRow(Map<String, Object?> row) async {
          final tableName = row['table_name'] as String;
          final dataJson = row['row_json'] as String;
          final data = Map<String, dynamic>.from(jsonDecode(dataJson) as Map);
          try {
            await txn.insert(
              tableName,
              data,
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          } catch (_) {/* 单行失败不阻断 */}
        }

        for (final row in firstPass) {
          await insertRow(row);
        }
        for (final row in itemRows) {
          await insertRow(row);
        }
        for (final row in completionRows) {
          final dataJson = row['row_json'] as String;
          final data = Map<String, dynamic>.from(jsonDecode(dataJson) as Map);
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
        }

        await txn.update(
          'data_reset_archives',
          {'rolled_back_at': DateTime.now().toIso8601String()},
          where: 'batch_id = ?',
          whereArgs: [batchId],
        );

        await txn.delete('data_reset_rows',
            where: 'archive_batch_id = ?', whereArgs: [batchId]);
      });
    } catch (e) {
      debugPrint('DataResetService.rollbackArchive failed: $e');
      return false;
    }

    _resetVersion++;
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

  /// 这次归档是否一并清空了计划（plan_groups + plan_items）
  bool get includesPlans => stats.containsKey('plan_groups');
}
