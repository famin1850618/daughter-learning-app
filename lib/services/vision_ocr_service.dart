import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// V3.34 视觉 OCR（Step 2）：通义千问 qwen-vl（DashScope OpenAI 兼容）把手写图片识别成文字。
/// 识别后的文字再走 DeepSeek 文字判分（AnswerMatcher + recheckFill）。
/// 国产 API，孩子设备直连。未配置 / 失败 → 返回 null，调用方提示重写或改键盘（不静默）。
class VisionOcrService {
  static const prefKey = 'qwen_vl_api_key';
  static const prefModel = 'qwen_vl_model';
  static const prefEnabled = 'vision_ocr_enabled';
  static const _endpoint =
      'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions';
  static const _defaultModel = 'qwen3.6-flash';

  /// 功能是否可用（已开启 + 配了 key）
  static Future<bool> isEnabled() async {
    final p = await SharedPreferences.getInstance();
    return (p.getBool(prefEnabled) ?? false) &&
        ((p.getString(prefKey) ?? '').trim().isNotEmpty);
  }

  static Future<String> _model() async {
    final p = await SharedPreferences.getInstance();
    final m = p.getString(prefModel)?.trim() ?? '';
    return m.isNotEmpty ? m : _defaultModel;
  }

  static Future<String> _key() async {
    final p = await SharedPreferences.getInstance();
    return (p.getString(prefKey) ?? '').trim();
  }

  /// 识别手写 PNG → 纯文本。失败返回 null（调用方提示）。
  /// hint=题目内容，帮助模型在歧义时按题意识别（不参与判分）。
  Future<String?> recognize(Uint8List png, {String hint = ''}) async {
    final key = await _key();
    if (key.isEmpty) return null;
    final model = await _model();
    final b64 = base64Encode(png);
    const sys = '你是手写识别助手。把图片里学生手写的内容**原样**识别成纯文本'
        '（数学算式/数字/汉字/拼音/字母）。分数写成 a/b，不解释、不判分、不补充、'
        '不要加"识别结果"等前缀，只输出识别到的内容本身。';
    final userText = hint.trim().isEmpty
        ? '识别图中手写内容。'
        : '识别图中手写内容（题目供参考，仅辅助断歧义，不要回答题目）：${hint.trim()}';
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
                {'role': 'system', 'content': sys},
                {
                  'role': 'user',
                  'content': [
                    {'type': 'text', 'text': userText},
                    {
                      'type': 'image_url',
                      'image_url': {'url': 'data:image/png;base64,$b64'}
                    },
                  ],
                },
              ],
              'temperature': 0,
              'max_tokens': 300,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map;
      final content =
          (((data['choices'] as List).first as Map)['message'] as Map)['content'];
      // qwen-vl 的 content 可能是 String 或分段 List
      String text;
      if (content is String) {
        text = content;
      } else if (content is List) {
        text = content
            .map((e) => e is Map ? (e['text']?.toString() ?? '') : e.toString())
            .join();
      } else {
        return null;
      }
      return text.trim().isEmpty ? null : text.trim();
    } catch (e) {
      return null;
    }
  }

  /// 测试连接（设置页"测试"按钮）。文字 ping 验证 key + 端点。
  Future<String> testConnection() async {
    final key = await _key();
    if (key.isEmpty) return '连接失败：未配置 API Key';
    final model = await _model();
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
                {'role': 'user', 'content': '回复 ok'}
              ],
              'max_tokens': 10,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) return '连接成功 ✅';
      final body = utf8.decode(resp.bodyBytes);
      return '连接失败：HTTP ${resp.statusCode} ${body.substring(0, body.length.clamp(0, 120))}';
    } catch (e) {
      return '连接失败：$e';
    }
  }
}
