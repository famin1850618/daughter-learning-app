import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'learning_export_service.dart';

/// 学情数据自动同步到私有 GitHub repo（V3.7.7）
///
/// 数据流：本地 SQLite 错题 → LearningExportService 生成 JSON →
/// GitHub Contents API PUT 到 daughter-learning-data 私有 repo →
/// 第二阶段 cron 拉 repo 读取错题分布做加权出题。
///
/// PAT 由用户输入存到 SharedPreferences（设备本地，不嵌进 APK）。
class LearningSyncService extends ChangeNotifier {
  static const _kEnabled = 'sync_enabled';
  static const _kPat = 'sync_pat';
  static const _kRepoOwner = 'sync_repo_owner';
  static const _kRepoName = 'sync_repo_name';
  static const _kDeviceName = 'sync_device_name';
  static const _kLastAt = 'sync_last_at';

  static const _defaultRepoOwner = 'famin1850618';
  static const _defaultRepoName = 'daughter-learning-data';
  static const _defaultDeviceName = 'daughter-phone';

  /// 同步频率上限：6 小时内不重复推送（手动按钮除外）
  static const _autoSyncCooldown = Duration(hours: 6);

  final _exporter = LearningExportService();

  bool _enabled = false;
  String _pat = '';
  String _repoOwner = _defaultRepoOwner;
  String _repoName = _defaultRepoName;
  String _deviceName = _defaultDeviceName;
  DateTime? _lastAt;

  String _status = '未配置';
  bool _syncing = false;

  bool get enabled => _enabled;
  String get pat => _pat;
  String get repoOwner => _repoOwner;
  String get repoName => _repoName;
  String get deviceName => _deviceName;
  DateTime? get lastAt => _lastAt;
  String get status => _status;
  bool get syncing => _syncing;
  bool get isConfigured => _enabled && _pat.isNotEmpty;

  LearningSyncService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kEnabled) ?? false;
    _pat = prefs.getString(_kPat) ?? '';
    _repoOwner = prefs.getString(_kRepoOwner) ?? _defaultRepoOwner;
    _repoName = prefs.getString(_kRepoName) ?? _defaultRepoName;
    _deviceName = prefs.getString(_kDeviceName) ?? _defaultDeviceName;
    final ts = prefs.getString(_kLastAt);
    if (ts != null) _lastAt = DateTime.tryParse(ts);
    _status = isConfigured
        ? (_lastAt == null ? '已配置，未同步' : '已配置')
        : '未配置';
    notifyListeners();
  }

  Future<void> setEnabled(bool v) async {
    _enabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, v);
    if (!v) _status = '已禁用';
    notifyListeners();
  }

  Future<void> setPat(String v) async {
    _pat = v.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPat, _pat);
    notifyListeners();
  }

  Future<void> setRepoOwner(String v) async {
    _repoOwner = v.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRepoOwner, _repoOwner);
    notifyListeners();
  }

  Future<void> setRepoName(String v) async {
    _repoName = v.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRepoName, _repoName);
    notifyListeners();
  }

  Future<void> setDeviceName(String v) async {
    _deviceName = v.trim().isEmpty ? _defaultDeviceName : v.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDeviceName, _deviceName);
    notifyListeners();
  }

  /// 触发条件：启用且 PAT 非空，且距上次同步超过冷却期
  bool _isDue() {
    if (!isConfigured) return false;
    if (_lastAt == null) return true;
    return DateTime.now().difference(_lastAt!) >= _autoSyncCooldown;
  }

  /// 启动 / 完成练习时自动调；冷却期内静默跳过
  Future<void> syncIfDue() async {
    if (_isDue()) await syncNow(silent: true);
  }

  /// 设置页"立即同步"按钮调，无条件强推
  Future<String> syncNow({bool silent = false}) async {
    if (_syncing) return '同步中，请稍候';
    if (!isConfigured) {
      _status = '未配置（开关或 PAT 缺失）';
      notifyListeners();
      return _status;
    }
    _syncing = true;
    if (!silent) _status = '同步中...';
    notifyListeners();

    try {
      final json = await _exporter.buildJson();
      final today = DateTime.now().toIso8601String().split('T').first;
      final path = 'learning_data/$_deviceName/$today.json';
      final ok = await _putJson(path, json,
          message: 'sync $_deviceName $today');
      if (ok) {
        _lastAt = DateTime.now();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kLastAt, _lastAt!.toIso8601String());
        _status = silent ? '已同步' : '同步成功';
      } else {
        _status = silent ? _status : '同步失败';
      }
    } catch (e) {
      _status = silent ? _status : '同步失败：$e';
      debugPrint('LearningSync error: $e');
    } finally {
      _syncing = false;
      notifyListeners();
    }
    return _status;
  }

  /// PUT 文件到 GitHub Contents API。已存在则带 SHA 覆盖。
  Future<bool> _putJson(String path, String content, {required String message}) async {
    final url = 'https://api.github.com/repos/$_repoOwner/$_repoName/contents/$path';
    final headers = {
      'Authorization': 'Bearer $_pat',
      'Accept': 'application/vnd.github+json',
      'Content-Type': 'application/json',
    };

    // 先 GET 看是否存在 + 拿 SHA（带 SHA 才能 PUT 覆盖）
    String? sha;
    try {
      final resp = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        sha = data['sha'] as String?;
      }
    } catch (_) {/* 忽略，继续 PUT */}

    final body = jsonEncode({
      'message': message,
      'content': base64Encode(utf8.encode(content)),
      if (sha != null) 'sha': sha,
    });

    final put = await http
        .put(Uri.parse(url), headers: headers, body: body)
        .timeout(const Duration(seconds: 20));
    return put.statusCode == 200 || put.statusCode == 201;
  }
}
