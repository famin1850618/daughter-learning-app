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
  static const _manifestUrls = [
    // 首选：jsDelivr 全球 CDN（国内访问稳定）
    'https://cdn.jsdelivr.net/gh/famin1850618/daughter-learning-app@main/question_bank/index.json',
    // 备选：GitHub raw（国内可能慢）
    'https://raw.githubusercontent.com/famin1850618/daughter-learning-app/main/question_bank/index.json',
  ];

  static const _batchUrlPrefixes = [
    'https://cdn.jsdelivr.net/gh/famin1850618/daughter-learning-app@main/question_bank/',
    'https://raw.githubusercontent.com/famin1850618/daughter-learning-app/main/question_bank/',
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

  /// 主入口：拉 manifest → diff 本地 source → 下载缺失批次 → 导入
  Future<String> checkAndImport({bool silent = false}) async {
    if (_syncing) return '同步中，请稍候';
    _syncing = true;
    if (!silent) _status = '检查更新...';
    notifyListeners();

    try {
      final manifestJson = await _fetchWithFallback(_manifestUrls);
      if (manifestJson == null) {
        _status = silent ? _status : '无法连接更新服务（已离线兜底）';
        return _status;
      }

      final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
      final batches = (manifest['batches'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      final missing = <Map<String, dynamic>>[];
      for (final b in batches) {
        final src = b['source'] as String;
        if (!await _hasSource(src)) missing.add(b);
      }

      if (missing.isEmpty) {
        _status = '题库已是最新';
        await _saveLastSync();
        return _status;
      }

      _status = '下载 ${missing.length} 个新题包...';
      notifyListeners();

      int totalNewQuestions = 0;
      for (final b in missing) {
        final src = b['source'] as String;
        final fileName = '$src.json';
        final urls = _batchUrlPrefixes.map((p) => '$p$fileName').toList();
        final body = await _fetchWithFallback(urls);
        if (body == null) continue;

        try {
          totalNewQuestions += await _importBatchJson(body);
        } catch (_) {
          // 单批失败不影响其他批
          continue;
        }
      }

      await _saveLastSync();
      _status = totalNewQuestions == 0
          ? '更新完成（无新增题目）'
          : '成功导入 $totalNewQuestions 道新题';
    } catch (e) {
      _status = silent ? _status : '同步失败：$e';
    } finally {
      _syncing = false;
      notifyListeners();
    }
    return _status;
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
        answer: m['answer'] as String,
        explanation: m['explanation'] as String?,
        imageData: (m['image'] as String?) ?? (m['image_data'] as String?),
        audioText: m['audio_text'] as String?,
        speakers: speakers,
        round: m['round'] as int?,
        groupId: m['group_id'] as String?,
        groupOrder: m['group_order'] as int?,
        source: source,
      );
    }).toList();

    // V3.12.7：用 (source + batch_hash) 决定增量/覆盖。修反复出现的"题数不更新"bug。
    // 同 source 不同 hash → 自动 DELETE 旧题 + INSERT 新数据。
    final batchHash = sha1.convert(utf8.encode(jsonStr)).toString();
    return await _qDao.upsertBatchByHash(source, batchHash, questions);
  }

  Future<bool> _hasSource(String source) async {
    final db = await _dbHelper.database;
    final r = await db.rawQuery(
        'SELECT 1 FROM questions WHERE source = ? LIMIT 1', [source]);
    return r.isNotEmpty;
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
