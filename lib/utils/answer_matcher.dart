import '../models/question.dart';

/// 答案判定：处理列式过程、π↔pi、^n↔上标、全角符号、多种等价写法
///
/// 题包侧约定：
/// - 单一答案：`answer = 'πr²h/3'`
/// - 多种等价写法：用 `|||` 分隔，如 `'πr²h/3|||pi*r*r*h/3|||(1/3)*pi*r^2*h'`
class AnswerMatcher {
  static const altSeparator = '|||';

  /// 归一化：去空格、全角→半角、π→pi、上标→^n、a*a→a^2、小写
  static String normalize(String s) {
    if (s.isEmpty) return '';
    var x = s;
    // 去所有空白
    x = x.replaceAll(RegExp(r'\s+'), '');
    // 全角符号 → 半角
    x = x
        .replaceAll('（', '(').replaceAll('）', ')')
        .replaceAll('，', ',').replaceAll('。', '.')
        .replaceAll('：', ':').replaceAll('；', ';')
        .replaceAll('！', '!').replaceAll('？', '?');
    // 数学符号统一
    x = x
        .replaceAll('×', '*').replaceAll('·', '*').replaceAll('•', '*')
        .replaceAll('÷', '/').replaceAll('∕', '/')
        .replaceAll('−', '-').replaceAll('—', '-').replaceAll('–', '-');
    // π↔pi（双向都归到 pi）
    x = x.replaceAll('π', 'pi').replaceAll('Π', 'pi');
    // 上下标 → ^数字
    const supers = {
      '⁰': '^0', '¹': '^1', '²': '^2', '³': '^3', '⁴': '^4',
      '⁵': '^5', '⁶': '^6', '⁷': '^7', '⁸': '^8', '⁹': '^9',
    };
    supers.forEach((k, v) => x = x.replaceAll(k, v));
    // 重复乘 → 幂（a*a*a → a^3，a*a → a^2，仅单字母变量）
    x = x.replaceAllMapped(
        RegExp(r'([a-zA-Z])\*\1\*\1\*\1'), (m) => '${m[1]}^4');
    x = x.replaceAllMapped(
        RegExp(r'([a-zA-Z])\*\1\*\1'), (m) => '${m[1]}^3');
    x = x.replaceAllMapped(
        RegExp(r'([a-zA-Z])\*\1'), (m) => '${m[1]}^2');

    // 隐式乘法等价：* 周围至少一侧是字母或括号时去掉（保留纯数字间 *，避免 2*5 → 25）
    // 用 lookbehind/lookaround，单遍可处理所有非重叠 *
    // 字母/) + * + 字母/数字/(  → 去 *（含 r^2*h、(1/3)*pi、a*b、3x*y 等）
    x = x.replaceAll(RegExp(r'(?<=[a-zA-Z\)])\*(?=[a-zA-Z0-9\(])'), '');
    // 数字 + * + 字母/(  → 去 *（含 3*r、2*(...）
    x = x.replaceAll(RegExp(r'(?<=\d)\*(?=[a-zA-Z\(])'), '');

    return x.toLowerCase();
  }

  /// 计算题用：取最后一个 "=" 之后的内容（用户列式答题：1+2*3=7 → "7"）
  /// 若无 "=" 则原样返回
  static String extractFinal(String userAns) {
    final idx = userAns.lastIndexOf('=');
    if (idx >= 0 && idx < userAns.length - 1) {
      final after = userAns.substring(idx + 1).trim();
      if (after.isNotEmpty) return after;
    }
    return userAns;
  }

  /// 判定答题是否正确
  static bool isCorrect({
    required String userAns,
    required String correctAnswerField,
    required QuestionType type,
  }) {
    final accepts = correctAnswerField
        .split(altSeparator)
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
    if (accepts.isEmpty) return false;

    if (type == QuestionType.multipleChoice) {
      // 选择题：精确匹配字母（不归一化，避免 A↔a 之外的误判）
      final u = userAns.trim().toUpperCase();
      return accepts.any((a) => a.trim().toUpperCase() == u);
    }

    if (type == QuestionType.judgment) {
      // V3.10 判断题：归一化 对/正确/√/T → "对"；错/错误/×/F → "错"
      String norm(String s) {
        final t = s.trim().toLowerCase();
        if (['对', '正确', '√', 't', 'true', 'yes', 'y', '√'].contains(t)) return '对';
        if (['错', '错误', '×', 'f', 'false', 'no', 'n', 'x', '✗', '✘'].contains(t)) return '错';
        return t;
      }
      final u = norm(userAns);
      return accepts.any((a) => norm(a) == u);
    }

    final candidate = type == QuestionType.calculation
        ? extractFinal(userAns)
        : userAns;
    final nu = normalize(candidate);
    if (nu.isEmpty) return false;
    if (accepts.any((a) => normalize(a) == nu)) return true;

    // 计算题第二次尝试：用户原文（含列式）整体归一化后看是否包含正确答案末尾
    if (type == QuestionType.calculation) {
      final whole = normalize(userAns);
      for (final a in accepts) {
        final na = normalize(a);
        if (na.isEmpty) continue;
        if (whole.endsWith(na)) return true;
      }
    }
    return false;
  }
}
