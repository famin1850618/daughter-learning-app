import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/question.dart';
import '../models/speaker_profile.dart';
import '../models/subject.dart';
import '../models/knowledge_point.dart';
import '../database/database_helper.dart';
import '../database/question_dao.dart';
import '../database/knowledge_point_dao.dart';

/// 通过 GitHub + jsDelivr CDN 拉取静态题包做增量更新。
/// 不是 API（没有后端代码）—— 本质就是下载 JSON 文件 + 按 source 幂等导入。
class QuestionUpdateService extends ChangeNotifier {
  // V3.12.15: GitHub raw 优先（实时无缓存）/ jsDelivr 备选
  // V3.12.14 实测: jsDelivr 多边缘节点缓存延迟 30+ min, 部分节点拿老版本
  // GitHub raw 实时反映 commit, 国内偶尔慢但可接受 + jsDelivr fallback 兜底
  static const _manifestUrls = [
    'https://raw.githubusercontent.com/famin1850618/daughter-learning-app/main/question_bank/index.json',
    'https://cdn.jsdelivr.net/gh/famin1850618/daughter-learning-app@main/question_bank/index.json',
  ];

  static const _batchUrlPrefixes = [
    'https://raw.githubusercontent.com/famin1850618/daughter-learning-app/main/question_bank/',
    'https://cdn.jsdelivr.net/gh/famin1850618/daughter-learning-app@main/question_bank/',
  ];

  static const _keyLastSync = 'q_last_sync';
  static const _keyAutoCheck = 'q_auto_check';

  final _qDao = QuestionDao();
  final _kpDao = KnowledgePointDao();
  final _dbHelper = DatabaseHelper();

  String _status = '待同步';
  bool _syncing = false;
  bool _autoCheck = true;
  DateTime? _lastSync;

  String get status => _status;
  bool get syncing => _syncing;
  bool get autoCheck => _autoCheck;
  DateTime? get lastSync => _lastSync;

  QuestionUpdateService() { _loadPrefs(); }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _autoCheck = prefs.getBool(_keyAutoCheck) ?? true;
    final ts = prefs.getString(_keyLastSync);
    if (ts != null) _lastSync = DateTime.tryParse(ts);
    notifyListeners();
  }

  Future<void> setAutoCheck(bool v) async {
    _autoCheck = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoCheck, v);
    notifyListeners();
  }

  /// V3.12.11 CDN-first mirror sync：本地 = 云端最新版本 1:1 镜像
  ///
  /// 三向 diff 算法：
  ///   - 新增（云端有 source / 本地无）→ INSERT
  ///   - 调整（云端 hash 异 / 本地有同 source）→ DELETE source + INSERT
  ///   - 去除（本地有 source / 云端无）→ DELETE FROM questions WHERE source = ?
  ///
  /// 返回结果含 added/updated/removed/skipped 计数 + error 列表
  /// 失败抛 SyncException（含 phase: manifest|download|import|delete + 详细信息）
  ///
  /// silent=true 时不更新 _status（用于自动后台同步）
  Future<SyncResult> checkAndImport({bool silent = false}) async {
    if (_syncing) {
      throw SyncException('manifest', '同步中，请稍候（已有同步在跑）');
    }
    _syncing = true;
    if (!silent) _status = '检查更新...';
    notifyListeners();

    final result = SyncResult();
    try {
      // Step 1: 拉 manifest
      final manifestJson = await _fetchWithFallback(_manifestUrls);
      if (manifestJson == null) {
        throw SyncException('manifest', '无法拉取 CDN manifest（jsDelivr + GitHub raw 都失败，请检查网络）');
      }
      final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
      final remoteBatches = (manifest['batches'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      result.manifestVersion = manifest['version'] as int? ?? 0;

      // Step 2: 拉本地 source + hash 列表
      final localMap = await _qDao.getSourceHashMap();

      // Step 3: 三向 diff
      final remoteSources = <String>{};
      final toAddOrUpdate = <Map<String, dynamic>>[];
      for (final b in remoteBatches) {
        final src = b['source'] as String;
        final remoteHash = b['batch_hash'] as String? ?? '';
        remoteSources.add(src);
        final localHash = localMap[src];
        if (localHash == null) {
          // 新增
          toAddOrUpdate.add({...b, '_action': 'add'});
        } else if (localHash != remoteHash) {
          // 调整
          toAddOrUpdate.add({...b, '_action': 'update'});
        }
        // 否则跳过（同步无变化）
      }
      // 本地多出来的（云端没有 → 去除）
      final toRemove = localMap.keys.where((s) => !remoteSources.contains(s)).toList();

      if (!silent) {
        _status = 'Diff: +${toAddOrUpdate.where((b) => b['_action'] == 'add').length} '
            '~${toAddOrUpdate.where((b) => b['_action'] == 'update').length} '
            '-${toRemove.length}';
        notifyListeners();
      }

      // Step 4: 删除"云端去除"的 source
      for (final src in toRemove) {
        try {
          await _qDao.deleteSource(src);
          result.removed++;
        } catch (e, stack) {
          result.errors.add(SyncErrorInfo('delete', src, e.toString(), stack.toString()));
        }
      }

      // Step 5: 下载 + 导入新增/调整 batches
      for (final b in toAddOrUpdate) {
        final src = b['source'] as String;
        final action = b['_action'] as String;
        final urls = _batchUrlPrefixes.map((p) => '$p$src.json').toList();
        final body = await _fetchWithFallback(urls);
        if (body == null) {
          result.errors.add(SyncErrorInfo('download', src, 'CDN 下载失败', null));
          continue;
        }
        try {
          await _importBatchJson(body);
          if (action == 'add') {
            result.added++;
          } else {
            result.updated++;
          }
        } catch (e, stack) {
          result.errors.add(SyncErrorInfo('import', src, e.toString(), stack.toString()));
        }
      }

      await _saveLastSync();
      _status = result.errors.isEmpty
          ? '同步完成 (+${result.added} ~${result.updated} -${result.removed})'
          : '同步完成 (+${result.added} ~${result.updated} -${result.removed}; ${result.errors.length} 错)';
    } catch (e, stack) {
      if (e is SyncException) rethrow;
      throw SyncException('unknown', e.toString(), stack: stack.toString());
    } finally {
      _syncing = false;
      notifyListeners();
    }
    return result;
  }

  /// 强制全量重置 + 拉云端最新（"刷新题库"按钮调）
  /// 1. 清空 questions 表（用 PRAGMA foreign_keys=OFF 包，避免 FK 约束错）
  /// 2. 拉 CDN 全量
  Future<SyncResult> refreshAll({bool silent = false}) async {
    await _qDao.deleteAllQuestionsBypassingFK();
    return await checkAndImport(silent: silent);
  }

  /// 公开方法：解析任意 batch JSON 字符串并入库（assets 首装与 CDN 同步共用）
  Future<int> importBatchJsonString(String jsonStr) => _importBatchJson(jsonStr);

  Future<int> _importBatchJson(String jsonStr) async {
    final batch = jsonDecode(jsonStr) as Map<String, dynamic>;
    final source = batch['source'] as String;
    final subjectKey = batch['subject'] as String;
    final subject = _subjectFromKey(subjectKey);
    final grade = batch['grade'] as int;

    // 1. 合并 knowledge_points_added 到 KP 表（subject 用中文，与 curriculum 一致）
    final kpsAdded = (batch['knowledge_points_added'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    if (kpsAdded.isNotEmpty) {
      final kps = kpsAdded.map((m) => KnowledgePoint(
            subject: subject.displayName,
            category: m['category'] as String,
            name: m['name'] as String,
            introducedGrade: grade,
          )).toList();
      await _kpDao.insertIfMissing(kps);
    }

    // 2. 题目按 source 幂等
    final qList = (batch['questions'] as List).cast<Map<String, dynamic>>();
    final questions = qList.map((m) {
      // V3.12: 解析 speakers 字段（多角色 TTS 元数据）
      Map<String, SpeakerProfile>? speakers;
      final raw = m['speakers'];
      if (raw is Map) {
        speakers = raw.map(
          (k, v) => MapEntry(
            k.toString(),
            SpeakerProfile.fromMap((v as Map).cast<String, dynamic>()),
          ),
        );
      }
      return Question(
        subject: subject,
        grade: grade,
        chapter: m['chapter'] as String,
        knowledgePoint: m['knowledge_point'] as String?,
        content: m['content'] as String,
        type: _typeFromKey(m['type'] as String),
        // V3.12.9 修：difficulty 改 nullable cast。V3.12.7 batch 不带 difficulty
        // 字段（4a 阶段 spec §2.1 只判 round，不判 difficulty）。旧代码强 cast
        // String 触发异常 → 整道题 import 失败 → main.dart 的 try-catch 静默吞错 →
        // 用户看到"导入完成无新增题目"。这是反复修不好题量 bug 的真凶。
        difficulty: _difficultyFromKey(m['difficulty'] as String?),
        options: (m['options'] as List?)?.cast<String>(),
        // V3.12.22 A3: option_images 解析（与 options 同长，每元素 base64 data URL 或 null）
        optionImages: (m['option_images'] as List?)?.map((e) =>
            e == null || (e is String && e.isEmpty) ? null : e as String).toList(),
        answer: m['answer'] as String,
        explanation: m['explanation'] as String?,
        imageData: (m['image'] as String?) ?? (m['image_data'] as String?),
        audioText: m['audio_text'] as String?,
        speakers: speakers,
        round: m['round'] as int?,
        groupId: m['group_id'] as String?,
        groupOrder: m['group_order'] as int?,
        // V3.13: 解析 _ai_dispute 元数据（worker 入库时若发现答案算法冲突写）
        aiDispute: (m['_ai_dispute'] as Map?)?.cast<String, dynamic>(),
        source: source,
      );
    }).toList();

    // V3.12.7：用 (source + batch_hash) 决定增量/覆盖。修反复出现的"题数不更新"bug。
    // 同 source 不同 hash → 自动 DELETE 旧题 + INSERT 新数据。
    final batchHash = sha1.convert(utf8.encode(jsonStr)).toString();
    return await _qDao.upsertBatchByHash(source, batchHash, questions);
  }

  Future<String?> _fetchWithFallback(List<String> urls) async {
    for (final url in urls) {
      try {
        final resp = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 12));
        if (resp.statusCode == 200) return utf8.decode(resp.bodyBytes);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Future<void> _saveLastSync() async {
    _lastSync = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSync, _lastSync!.toIso8601String());
  }

  /// JSON 顶层 "subject" 字段使用 Dart enum 标识符（math/chinese/english/...）
  /// Subject extension 已用 displayName 返回中文，所以这里用 toString 解析
  Subject _subjectFromKey(String k) {
    final lower = k.toLowerCase();
    return Subject.values.firstWhere(
      (s) => s.toString().split('.').last.toLowerCase() == lower,
      orElse: () => Subject.math,
    );
  }

  QuestionType _typeFromKey(String k) {
    switch (k) {
      case 'choice': return QuestionType.multipleChoice;
      case 'fill': return QuestionType.fillBlank;
      case 'calculation': return QuestionType.calculation;
      case 'subjective': return QuestionType.subjective;
      case 'judgment': return QuestionType.judgment;
      default: return QuestionType.fillBlank;
    }
  }

  Difficulty _difficultyFromKey(String? k) {
    if (k == null) return Difficulty.easy;
    switch (k) {
      case 'easy': return Difficulty.easy;
      case 'medium': return Difficulty.medium;
      case 'hard': return Difficulty.hard;
      default: return Difficulty.easy;
    }
  }
}

/// Sync 结果（V3.12.11 mirror sync）
class SyncResult {
  int manifestVersion = 0;
  int added = 0;     // 云端新增
  int updated = 0;   // 云端调整（hash 异）
  int removed = 0;   // 云端去除（本地有但云端无）
  final List<SyncErrorInfo> errors = [];

  bool get success => errors.isEmpty;
  int get totalChanges => added + updated + removed;

  @override
  String toString() => 'SyncResult(+$added ~$updated -$removed, ${errors.length} errors)';
}

class SyncErrorInfo {
  final String phase;   // manifest|download|import|delete
  final String source;
  final String error;
  final String? stack;
  SyncErrorInfo(this.phase, this.source, this.error, this.stack);
  @override
  String toString() => '[$phase] $source: $error';
}

class SyncException implements Exception {
  final String phase;
  final String message;
  final String? stack;
  SyncException(this.phase, this.message, {this.stack});
  @override
  String toString() => 'SyncException[$phase]: $message';
}
