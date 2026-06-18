import 'dart:convert';
import 'dart:typed_data';
import '../database/question_dao.dart';
import 'ai_grading_service.dart';
import 'vision_ocr_service.dart';

/// V3.35: 证明题后台批改队列。提交时孩子不等待，记录入库标 grading_pending=1，
/// 这里异步把"手写图 → qwen 识别 → DeepSeek 思考判定"跑完，回填结果。
/// 触发：提交后 fire-and-forget；app 启动续跑（防中途关 app 丢任务）。
/// 单条失败留 pending 下次重试；并发由 _running 防抖。
class GradingQueueService {
  static bool _running = false;

  static Future<void> processAll() async {
    if (_running) return;
    if (!await AiGradingService.isEnabled()) return; // 没开 AI 判分先不处理
    _running = true;
    try {
      final dao = QuestionDao();
      final pending = await dao.getPendingGradingRecords();
      for (final r in pending) {
        if (r.id == null) continue;
        try {
          final q = await dao.getQuestionById(r.questionId);
          if (q == null) continue;
          // ① 手写图 → qwen 识别成文字（证明：逐行转写推理 + 辅助线文字）
          String studentText = r.userAnswer;
          final img = r.answerImage;
          if (img != null && img.isNotEmpty && await VisionOcrService.isEnabled()) {
            final b64 = img.contains(',') ? img.split(',').last : img;
            final bytes = base64Decode(b64);
            final rec = await VisionOcrService()
                .recognize(Uint8List.fromList(bytes), hint: q.content);
            if (rec != null && rec.trim().isNotEmpty) studentText = rec.trim();
          }
          // ② DeepSeek 思考模式判证明
          final v = await AiGradingService().gradeProof(q, studentText);
          if (!v.available) continue; // API 失败 → 留 pending 下次重试
          await dao.finalizeGrade(
            r.id!,
            isCorrect: v.score >= 0.8,
            partial: v.score,
            feedback: v.feedback,
            transcription: studentText,
          );
        } catch (_) {
          // 单条异常 → 留 pending，下次再试
        }
      }
    } finally {
      _running = false;
    }
  }
}
