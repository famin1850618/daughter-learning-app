import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../models/subject.dart';
import '../models/question.dart';
import '../services/practice_service.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PracticeService>();

    if (!service.sessionActive) {
      return _SubjectSelectionView();
    }

    if (service.currentQuestion == null) {
      return _ResultView(
        score: service.score,
        total: service.currentQuestions.length,
      );
    }

    return _QuestionView(question: service.currentQuestion!);
  }
}

class _SubjectSelectionView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模拟练习')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('选择科目开始练习', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...Subject.values
                .where((s) => s.isAvailableForGrade(6))
                .map((s) => Card(
                  child: ListTile(
                    leading: Text(s.emoji, style: const TextStyle(fontSize: 28)),
                    title: Text(s.displayName),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.read<PracticeService>().startSession(
                      subject: s, grade: 6, count: 10),
                  ),
                )),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('错题重练'),
              onPressed: () => context.read<PracticeService>().startWrongQuestionSession(10),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionView extends StatefulWidget {
  final Question question;
  const _QuestionView({required this.question});

  @override
  State<_QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<_QuestionView> {
  String? _selected;
  bool? _result;
  final _fillCtrl = TextEditingController();

  void _submit() async {
    final answer = widget.question.type == QuestionType.multipleChoice
        ? _selected ?? ''
        : _fillCtrl.text;
    final correct = await context.read<PracticeService>().submitAnswer(answer);
    setState(() => _result = correct);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final service = context.read<PracticeService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('第 ${service.currentIndex + 1} / ${service.currentQuestions.length} 题'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (service.currentIndex + 1) / service.currentQuestions.length,
              backgroundColor: Colors.grey[200],
              color: AppTheme.primary,
            ),
            const SizedBox(height: 16),
            Text(q.content, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            if (q.type == QuestionType.multipleChoice)
              ...q.options!.map((opt) => RadioListTile<String>(
                value: opt.substring(0, 1),
                groupValue: _selected,
                title: Text(opt),
                activeColor: AppTheme.primary,
                onChanged: _result == null ? (v) => setState(() => _selected = v) : null,
              ))
            else
              TextField(
                controller: _fillCtrl,
                enabled: _result == null,
                decoration: const InputDecoration(
                  labelText: '请输入答案',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            if (_result != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _result! ? AppTheme.success.withOpacity(0.15) : AppTheme.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _result! ? AppTheme.success : AppTheme.secondary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_result! ? '✅ 回答正确！' : '❌ 回答错误',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _result! ? AppTheme.success : AppTheme.secondary)),
                    if (!_result!) Text('正确答案：${q.answer}'),
                    if (q.explanation != null) ...[
                      const SizedBox(height: 4),
                      Text('解析：${q.explanation}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.read<PracticeService>().nextQuestion(),
                  child: const Text('下一题'),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('提交答案'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final int score;
  final int total;
  const _ResultView({required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (score / total * 100).round() : 0;
    return Scaffold(
      appBar: AppBar(title: const Text('练习完成')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(percent >= 80 ? '🎉' : percent >= 60 ? '😊' : '💪',
                style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('$score / $total', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
            Text('正确率 $percent%', style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.read<PracticeService>().nextQuestion(),
              child: const Text('再来一次'),
            ),
          ],
        ),
      ),
    );
  }
}
