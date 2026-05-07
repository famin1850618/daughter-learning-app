import 'package:flutter/material.dart';
import '../screens/plan_settings_screen.dart';

/// 全局设置入口（每个主屏幕 AppBar 右上角）
///
/// 用法：`actions: [settingsAction(context)]`
Widget settingsAction(BuildContext context) {
  return IconButton(
    icon: const Icon(Icons.settings),
    tooltip: '设置',
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlanSettingsScreen()),
    ),
  );
}
