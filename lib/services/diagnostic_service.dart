import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';

/// V3.12.9_fix: 诊断服务（feedback_bug_diagnosis_discipline.md 的 app 端实施）
///
/// 职责:
/// - 启动时跑 self-check（DB 题数 / 各 source 状态 / 关键字段健康）
/// - 持久化错误日志（SharedPreferences，最近 50 条）
/// - 提供诊断面板查询接口
///
/// 设计原则: 用户可见 + 可导出 + 不依赖 debugPrint。
class DiagnosticService extends ChangeNotifier {
  static final DiagnosticService _instance = DiagnosticService._();
  factory DiagnosticService() => _instance;
  DiagnosticService._();

  static const _logKey = 'diag_error_log';
  static const _maxLogs = 50;

  /// 启动 self-check 报告（json string list）
  List<DiagnosticEntry> _startupReport = [];
  List<DiagnosticEntry> get startupReport => _startupReport;

  /// 持久化错误日志
  List<ErrorLog> _errorLogs = [];
  List<ErrorLog> get errorLogs => _errorLogs;

  /// 错误数量（UI 红点用）
  int get errorCount => _errorLogs.where((e) => e.level == 'error').length;

  /// 启动时跑（main.dart 调）
  Future<void> runStartupSelfCheck() async {
    _startupReport.clear();
    final db = await DatabaseHelper().database;

    // 检查 1: DB version (sqflite getVersion 通过 rawQuery)
    final verRows = await db.rawQuery('PRAGMA user_version');
    final ver = (verRows.first.values.first as int?) ?? 0;
    _startupReport.add(DiagnosticEntry(
      key: 'db_version', value: '$ver', ok: ver >= 19,
    ));

    // 检查 2: questions 总数 + by subject
    final total = await db.rawQuery('SELECT COUNT(*) as c FROM questions');
    final totalCount = (total.first['c'] as int?) ?? 0;
    _startupReport.add(DiagnosticEntry(
      key: 'questions_total', value: '$totalCount',
      ok: totalCount > 0,
      hint: totalCount == 0 ? '题库为空，可能首次启动或 import 失败' : null,
    ));

    // by subject (subject 是 enum index: 0=chinese, 1=math, 2=english, 3=physics, 4=chemistry, 5=ai)
    final bySubject = await db.rawQuery(
      'SELECT subject, COUNT(*) as c FROM questions GROUP BY subject ORDER BY subject');
    final names = ['语文', '数学', '英语', '物理', '化学', 'AI'];
    for (final row in bySubject) {
      final idx = (row['subject'] as int?) ?? 0;
      final c = (row['c'] as int?) ?? 0;
      final name = idx < names.length ? names[idx] : 'subject_$idx';
      _startupReport.add(DiagnosticEntry(
        key: 'questions_$name', value: '$c', ok: c > 0,
      ));
    }

    // 检查 3: 各 batch source 状态
    final sources = await db.rawQuery(
      'SELECT source, COUNT(*) as c FROM questions GROUP BY source ORDER BY source');
    _startupReport.add(DiagnosticEntry(
      key: 'distinct_sources', value: '${sources.length}',
      ok: sources.length > 0,
    ));

    // 检查 4: 关键字段缺失（content/answer null）
    final brokenContent = await db.rawQuery(
      "SELECT COUNT(*) as c FROM questions WHERE content IS NULL OR content = ''");
    final bcCount = (brokenContent.first['c'] as int?) ?? 0;
    _startupReport.add(DiagnosticEntry(
      key: 'questions_broken_content', value: '$bcCount',
      ok: bcCount == 0,
      hint: bcCount > 0 ? '$bcCount 道题 content 缺失（数据损坏）' : null,
    ));

    // 检查 5: round 字段非 null（4b 阶段后应该全有）
    final nullRound = await db.rawQuery(
      'SELECT COUNT(*) as c FROM questions WHERE round IS NULL');
    final nrCount = (nullRound.first['c'] as int?) ?? 0;
    _startupReport.add(DiagnosticEntry(
      key: 'questions_null_round', value: '$nrCount',
      ok: nrCount == 0,
      hint: nrCount > 0 ? '$nrCount 道题 round 是 null' : null,
    ));

    // 加载持久化错误日志
    await _loadErrorLogs();

    notifyListeners();
  }

  /// 记录错误（任何 try-catch 应该调这个，不要 silent fail）
  Future<void> logError({
    required String level, // 'error' / 'warn' / 'info'
    required String context, // 模块 / 操作
    required Object error, // exception 或 message
    StackTrace? stack,
  }) async {
    final log = ErrorLog(
      timestamp: DateTime.now(),
      level: level,
      context: context,
      message: error.toString(),
      stack: stack?.toString(),
    );
    _errorLogs.insert(0, log);
    if (_errorLogs.length > _maxLogs) {
      _errorLogs = _errorLogs.sublist(0, _maxLogs);
    }
    await _saveErrorLogs();
    notifyListeners();
  }

  Future<void> _saveErrorLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _errorLogs.map((l) => l.toJson()).toList();
    await prefs.setString(_logKey, raw.join('\n---\n'));
  }

  Future<void> _loadErrorLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_logKey) ?? '';
    if (s.isEmpty) return;
    _errorLogs = s.split('\n---\n').map(ErrorLog.fromJson).whereType<ErrorLog>().toList();
  }

  /// 用户主动清空错误日志
  Future<void> clearErrorLogs() async {
    _errorLogs.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logKey);
    notifyListeners();
  }

  /// 导出错误日志（用户复制粘贴给开发者）
  String exportErrorLogs() {
    final lines = <String>['=== 错误日志（最近 ${_errorLogs.length} 条）==='];
    for (final l in _errorLogs) {
      lines.add('[${l.timestamp.toIso8601String()}] ${l.level.toUpperCase()} ${l.context}');
      lines.add('  ${l.message}');
      if (l.stack != null) lines.add('  stack: ${l.stack!.split('\n').take(3).join(" / ")}');
    }
    lines.add('');
    lines.add('=== Self-check 报告 ===');
    for (final e in _startupReport) {
      lines.add('${e.ok ? "✓" : "✗"} ${e.key}: ${e.value}${e.hint != null ? " [${e.hint}]" : ""}');
    }
    return lines.join('\n');
  }
}

class DiagnosticEntry {
  final String key;
  final String value;
  final bool ok;
  final String? hint;
  DiagnosticEntry({required this.key, required this.value, required this.ok, this.hint});
}

class ErrorLog {
  final DateTime timestamp;
  final String level;
  final String context;
  final String message;
  final String? stack;

  ErrorLog({
    required this.timestamp,
    required this.level,
    required this.context,
    required this.message,
    this.stack,
  });

  String toJson() => '${timestamp.toIso8601String()}|$level|$context|$message|${stack ?? ""}';

  static ErrorLog? fromJson(String s) {
    final parts = s.split('|');
    if (parts.length < 4) return null;
    try {
      return ErrorLog(
        timestamp: DateTime.parse(parts[0]),
        level: parts[1],
        context: parts[2],
        message: parts[3],
        stack: parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null,
      );
    } catch (_) {
      return null;
    }
  }
}
