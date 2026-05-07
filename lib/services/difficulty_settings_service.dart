import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 难度档预设：偏基础 / 均衡 / 偏挑战 / 竞赛
enum DifficultyPreset { foundation, balanced, challenge, competition }

extension DifficultyPresetExt on DifficultyPreset {
  String get label {
    switch (this) {
      case DifficultyPreset.foundation:  return '偏基础';
      case DifficultyPreset.balanced:    return '均衡';
      case DifficultyPreset.challenge:   return '偏挑战';
      case DifficultyPreset.competition: return '竞赛';
    }
  }
  /// 4 档比例（R1 R2 R3 R4 顺序，加起来 100）
  List<int> get weights {
    switch (this) {
      case DifficultyPreset.foundation:  return [30, 30, 30, 10];
      case DifficultyPreset.balanced:    return [25, 30, 25, 20];
      case DifficultyPreset.challenge:   return [10, 30, 35, 25];
      case DifficultyPreset.competition: return [5, 15, 30, 50];
    }
  }
}

/// 难度模式：全局 / 分科
enum DifficultyMode { global, perSubject }

/// 难度类型：精确（单档）/ 模糊（4 档比例）
enum DifficultyType { precise, fuzzy }

/// 单个 profile（全局或某科目）
class DifficultyProfile {
  final DifficultyType type;
  /// 精确模式时使用：1-4 档之一，null=不限难度（4 档全混抽）
  final int? preciseRound;
  /// 模糊模式时使用：4 档比例（[r1, r2, r3, r4]，sum=100）
  final List<int> fuzzyWeights;

  const DifficultyProfile({
    this.type = DifficultyType.precise,
    this.preciseRound,
    this.fuzzyWeights = const [25, 30, 25, 20],
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'preciseRound': preciseRound,
    'fuzzyWeights': fuzzyWeights,
  };

  factory DifficultyProfile.fromJson(Map<String, dynamic> j) => DifficultyProfile(
    type: DifficultyType.values.firstWhere(
        (t) => t.name == (j['type'] as String? ?? 'precise'),
        orElse: () => DifficultyType.precise),
    preciseRound: j['preciseRound'] as int?,
    fuzzyWeights: (j['fuzzyWeights'] as List?)?.cast<int>() ?? const [25, 30, 25, 20],
  );

  DifficultyProfile copyWith({
    DifficultyType? type,
    int? preciseRound,
    bool clearPreciseRound = false,
    List<int>? fuzzyWeights,
  }) =>
      DifficultyProfile(
        type: type ?? this.type,
        preciseRound: clearPreciseRound ? null : (preciseRound ?? this.preciseRound),
        fuzzyWeights: fuzzyWeights ?? this.fuzzyWeights,
      );
}

/// V3.8 难度选择系统
class DifficultySettingsService extends ChangeNotifier {
  static const _kData = 'difficulty_settings_v1';
  static const _globalKey = 'global';

  DifficultyMode _mode = DifficultyMode.global;
  Map<String, DifficultyProfile> _profiles = {
    _globalKey: const DifficultyProfile(),
  };
  bool _applyToWeakKp = true;          // 首页薄弱 KP 单条练习
  bool _applyToReviewSimilar = true;    // 错题集"练相似题"

  DifficultyMode get mode => _mode;
  bool get applyToWeakKp => _applyToWeakKp;
  bool get applyToReviewSimilar => _applyToReviewSimilar;

  /// 取某科目（中文名）的 profile；global 模式或科目未配置则回退 global
  DifficultyProfile profileFor(String subjectName) {
    if (_mode == DifficultyMode.global) {
      return _profiles[_globalKey] ?? const DifficultyProfile();
    }
    return _profiles[subjectName] ?? _profiles[_globalKey] ?? const DifficultyProfile();
  }

  DifficultyProfile get globalProfile => _profiles[_globalKey] ?? const DifficultyProfile();

  DifficultySettingsService() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kData);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        _mode = DifficultyMode.values.firstWhere(
          (m) => m.name == (j['mode'] as String? ?? 'global'),
          orElse: () => DifficultyMode.global,
        );
        _applyToWeakKp = (j['applyToWeakKp'] as bool?) ?? true;
        _applyToReviewSimilar = (j['applyToReviewSimilar'] as bool?) ?? true;
        final profs = (j['profiles'] as Map<String, dynamic>?) ?? {};
        _profiles = {
          for (final e in profs.entries)
            e.key: DifficultyProfile.fromJson(e.value as Map<String, dynamic>)
        };
        if (!_profiles.containsKey(_globalKey)) {
          _profiles[_globalKey] = const DifficultyProfile();
        }
      } catch (_) {/* 解析失败用默认值 */}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kData, jsonEncode({
      'mode': _mode.name,
      'applyToWeakKp': _applyToWeakKp,
      'applyToReviewSimilar': _applyToReviewSimilar,
      'profiles': {for (final e in _profiles.entries) e.key: e.value.toJson()},
    }));
  }

  Future<void> setMode(DifficultyMode m) async {
    _mode = m;
    notifyListeners();
    await _save();
  }

  Future<void> setApplyToWeakKp(bool v) async {
    _applyToWeakKp = v;
    notifyListeners();
    await _save();
  }

  Future<void> setApplyToReviewSimilar(bool v) async {
    _applyToReviewSimilar = v;
    notifyListeners();
    await _save();
  }

  /// 更新某 key（全局或科目名）的 profile
  Future<void> setProfile(String key, DifficultyProfile p) async {
    _profiles[key] = p;
    notifyListeners();
    await _save();
  }

  /// 应用预设（一次性设置 fuzzy weights）
  Future<void> applyPreset(String key, DifficultyPreset preset) async {
    final cur = _profiles[key] ?? const DifficultyProfile();
    _profiles[key] = cur.copyWith(
      type: DifficultyType.fuzzy,
      fuzzyWeights: preset.weights,
    );
    notifyListeners();
    await _save();
  }

  /// 切换精确模式（单选某档；null=不限）
  Future<void> setPrecise(String key, int? round) async {
    final cur = _profiles[key] ?? const DifficultyProfile();
    _profiles[key] = cur.copyWith(
      type: DifficultyType.precise,
      preciseRound: round,
      clearPreciseRound: round == null,
    );
    notifyListeners();
    await _save();
  }
}
