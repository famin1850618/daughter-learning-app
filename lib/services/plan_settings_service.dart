import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plan_settings.dart';

class PlanSettingsService extends ChangeNotifier {
  static const _key = 'plan_settings_v1';

  PlanSettings _settings = const PlanSettings();
  PlanSettings get settings => _settings;

  PlanSettingsService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _settings = PlanSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> save(PlanSettings s) async {
    _settings = s;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(s.toJson()));
    notifyListeners();
  }
}
