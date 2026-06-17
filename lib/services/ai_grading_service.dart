import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';

/// V3.26: DeepSeek（OpenAI 兼容）判分服务。
/// 两用途：① 主观题判分 ② 填空被字符串匹配判错后的"复判"。
/// 国产 API，孩子设备不挂梯子直连。失败/未配置 → available=false，调用方走人工兜底。
class AiVerdict {
  final bool ok; // 可接受 / 正确
  final double score; // 0..1
  final String feedback; // 评语 / 理由（面向小学生）
  final bool available; // API 是否成功返回（false = 网络/配置失败 → 走兜底）

  AiVerdict({
    required this.ok,
    required this.score,
    required this.feedback,
    this.available = true,
  });

  factory AiVerdict.unavailable(String why) =>
      AiVerdict(ok: false, score: 0, feedback: why, available: false);
}

class AiGradingService {
  static const prefKey = 'deepseek_api_key';
  static const prefModel = 'deepseek_model';
  static const prefEnabled = 'ai_grading_enabled';
  static const _endpoint = 'https://api.deepseek.com/chat/completions';
  static const _defaultModel = 'deepseek-v4-flash';

  /// 功能是否可用（已开启 + 配了 key）
  static Future<bool> isEnabled() async {
    final p = await SharedPreferences.getInstance();
    return (p.getBool(prefEnabled) ?? false) &&
        ((p.getString(prefKey) ?? '').trim().isNotEmpty);
  }

  Future<AiVerdict> _call(String systemPrompt, String userPrompt) async {
    final p = await SharedPreferences.getInstance();
    // V3.27.1: trim — 粘贴的 key 带尾随空格/换行会让 Authorization 头失效(401)
    final key = (p.getString(prefKey) ?? '').trim();
    final model = (p.getString(prefModel)?.trim().isNotEmpty ?? false)
        ? p.getString(prefModel)!.trim()
        : _defaultModel;
    if (key.isEmpty) return AiVerdict.unavailable('未配置 API Key');
    try {
      final resp = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $key',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': userPrompt},
              ],
              'temperature': 0,
              'response_format': {'type': 'json_object'},
              'max_tokens': 500,
            }),
          )
          .timeout(const Duration(seconds: 25));
      if (resp.statusCode != 200) {
        return AiVerdict.unavailable('HTTP ${resp.statusCode}');
      }
      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map;
      final content =
          (((data['choices'] as List).first as Map)['message'] as Map)['content']
              as String;
      final j = jsonDecode(content) as Map;
      final ok = (j['correct'] == true) || (j['acceptable'] == true);
      final score = (j['score'] is num)
          ? (j['score'] as num).toDouble().clamp(0.0, 1.0)
          : (ok ? 1.0 : 0.0);
      final fb = (j['feedback'] ?? j['reason'] ?? '').toString();
      return AiVerdict(ok: ok, score: score, feedback: fb);
    } catch (e) {
      // V3.26.1: 透出真实错误（silent catch 是头号杀手），便于设置页"测试连接"排查
      return AiVerdict.unavailable('调用失败：$e');
    }
  }

  /// 测试连接（设置页"测试"按钮用）。返回面向人的提示。
  Future<String> testConnection() async {
    final v = await _call('只输出 json。', '请输出 json：{"ok": true}');
    return v.available ? '连接成功 ✅' : '连接失败：${v.feedback}';
  }

  /// 填空被判错后复判：学生答案是否可接受（语义/数值对即可，不必字面一致）。
  Future<AiVerdict> recheckFill(Question q, String studentAnswer) {
    const sys = '你是中小学题目判分助手。判断学生的填空答案是否可接受：'
        '语义或数值正确即算对，不要求与标准答案字面完全一致（如省略单位、括号、同义表述均可接受）。'
        '但要严格：古诗文/字词默写要求逐字正确（错别字判错）；数值或单位写错判错。'
        '只输出 json，不要多余文字。';
    final blanks = q.answerBlanks != null
        ? '（各空标准答案：${q.answerBlanks!.join(' / ')}）'
        : '';
    final user = '题目：${q.content}\n'
        '标准答案：${q.answer}$blanks\n'
        '学生答案：$studentAnswer\n'
        '请按此 json 输出：{"acceptable": true 或 false, "score": 0到1的小数, "reason": "一句话理由"}';
    return _call(sys, user);
  }

  /// 主观题判分：依据参考答案/要点给判定 + 面向小学生的简短评语。
  Future<AiVerdict> gradeSubjective(Question q, String studentAnswer) {
    const sys = '你是中小学主观题批改老师。依据参考答案与要点判定学生答案对错或给分，'
        '评语简短、鼓励为主、指出可改进点。只输出 json，不要多余文字。';
    final expl = q.explanation != null && q.explanation!.isNotEmpty
        ? '\n解析/要点：${q.explanation}'
        : '';
    final user = '题目：${q.content}\n'
        '参考答案：${q.answer}$expl\n'
        '学生答案：$studentAnswer\n'
        '请按此 json 输出：{"correct": true 或 false, "score": 0到1的小数, "feedback": "面向小学生的简短评语"}';
    return _call(sys, user);
  }
}
