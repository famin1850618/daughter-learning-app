import 'package:flutter/material.dart';
import '../services/question_update_service.dart';

/// V3.12.11 首次启动 / 强制刷新后题库为空时的 splash + 阻塞同步
///
/// 流程：
///   1. 显示 loading + 状态文字
///   2. 调 QuestionUpdateService.checkAndImport() 拉云端
///   3. 成功 → Navigator.pushReplacement(主 LearningApp)
///   4. 失败 → 显示错误 + 重试按钮
class InitialSyncApp extends StatelessWidget {
  const InitialSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planning',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const InitialSyncScreen(),
    );
  }
}

class InitialSyncScreen extends StatefulWidget {
  const InitialSyncScreen({super.key});

  @override
  State<InitialSyncScreen> createState() => _InitialSyncScreenState();
}

class _InitialSyncScreenState extends State<InitialSyncScreen> {
  String _status = '准备从云端拉取题库...';
  String? _error;
  bool _syncing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSync());
  }

  Future<void> _runSync() async {
    setState(() {
      _syncing = true;
      _error = null;
      _status = '正在连接云端...';
    });
    final svc = QuestionUpdateService();
    svc.addListener(() {
      if (!mounted) return;
      setState(() => _status = svc.status);
    });
    try {
      final result = await svc.checkAndImport();
      if (!mounted) return;
      if (result.errors.isNotEmpty && (result.added + result.updated) == 0) {
        // 都失败了
        setState(() {
          _syncing = false;
          _error = '同步失败:\n${result.errors.take(3).map((e) => e.toString()).join("\n")}';
        });
        return;
      }
      // 成功 → 重启 app 进 LearningApp
      // 简单做法：用 main 中相同的入口重新 runApp
      _bootMainApp();
    } on SyncException catch (e) {
      if (!mounted) return;
      setState(() {
        _syncing = false;
        _error = '${e.phase}: ${e.message}';
      });
    } catch (e, stack) {
      if (!mounted) return;
      setState(() {
        _syncing = false;
        _error = '$e\n\n$stack';
      });
    }
  }

  /// 同步完成后切到主 app（运行时 runApp 替换 widget tree）
  void _bootMainApp() {
    // 通过 main.dart export 的全局 launchMainApp 切换
    launchMainAppCallback?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.school, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Planning',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '首次启动需联网下载题库',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              if (_syncing) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                Text(_status, textAlign: TextAlign.center),
              ] else if (_error != null) ...[
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                const Text('同步失败',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _error!,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('请检查网络连接，确认能访问 jsdelivr.net 或 raw.githubusercontent.com',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                  onPressed: _runSync,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// main.dart 设置回调，让 InitialSyncScreen 完成后切到 LearningApp
void Function()? launchMainAppCallback;
