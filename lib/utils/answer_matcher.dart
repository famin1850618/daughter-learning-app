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
    // V3.12.12: 圈数字 → 普通数字（输入法限制：①②③ 等无法输入）
    // 支持 1-20 + 圈字母（少见）。Famin: "看到数字正确就判对"
    const circled = {
      '①': '1', '②': '2', '③': '3', '④': '4', '⑤': '5',
      '⑥': '6', '⑦': '7', '⑧': '8', '⑨': '9', '⑩': '10',
      '⑪': '11', '⑫': '12', '⑬': '13', '⑭': '14', '⑮': '15',
      '⑯': '16', '⑰': '17', '⑱': '18', '⑲': '19', '⑳': '20',
      // 圈字母（如有）→ 字母
      'ⓐ': 'a', 'ⓑ': 'b', 'ⓒ': 'c', 'ⓓ': 'd', 'ⓔ': 'e',
      'Ⓐ': 'A', 'Ⓑ': 'B', 'Ⓒ': 'C', 'Ⓓ': 'D',
    };
    circled.forEach((k, v) => x = x.replaceAll(k, v));
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

  /// V3.20.3 (阶段一): 部分得分判定
  /// 返回 (isCorrect, partialScore)：单空题 score 是 0.0/1.0；多空题 score = 对的空数/总空数
  /// 用 evaluatePartial() 调用，向后兼容 isCorrect()
  static ({bool isCorrect, double partialScore}) evaluatePartial({
    required String userAns,
    required String correctAnswerField,
    required QuestionType type,
    List<String>? answerBlanks,
  }) {
    // 多空题（answerBlanks 非空且 ≥ 2）：算对的空数
    if (answerBlanks != null && answerBlanks.length >= 2 &&
        type != QuestionType.multipleChoice) {
      // V3.20.3: 加全角逗号 ， 作合法分隔符（Famin 实测要求）
      final userBlanks = userAns
          .split(RegExp(r'[,，、\s]+|\|\|\|'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      // 空数对不上不算"部分对"——直接 0 分（避免少填/多填混淆）
      if (userBlanks.length != answerBlanks.length) {
        return (isCorrect: false, partialScore: 0.0);
      }
      int correctCount = 0;
      for (int i = 0; i < answerBlanks.length; i++) {
        final ua = userBlanks[i];
        final ca = answerBlanks[i];
        bool spotCorrect;
        if (type == QuestionType.judgment) {
          String norm(String s) {
            final t = s.trim().toLowerCase();
            if (['对','正确','√','t','true','yes','y'].contains(t)) return '对';
            if (['错','错误','×','f','false','no','n','x','✗','✘'].contains(t)) return '错';
            return t;
          }
          spotCorrect = norm(ua) == norm(ca);
        } else {
          spotCorrect = normalize(ua) == normalize(ca);
        }
        if (spotCorrect) correctCount++;
      }
      final score = correctCount / answerBlanks.length;
      return (isCorrect: score == 1.0, partialScore: score);
    }
    // 单空题或非多空：复用旧 isCorrect 逻辑（0/1 计分）
    final ok = isCorrect(
      userAns: userAns,
      correctAnswerField: correctAnswerField,
      type: type,
      answerBlanks: answerBlanks,
    );
    return (isCorrect: ok, partialScore: ok ? 1.0 : 0.0);
  }

  /// 判定答题是否正确
  /// V3.19.16: 加 answerBlanks 多空答案数组。fill/judgment 类多空题用户输入按
  /// 分隔符（,/、/空格/|||/换行/全角逗号）切分 → 逐空 normalize 比对，全对才算对。
  static bool isCorrect({
    required String userAns,
    required String correctAnswerField,
    required QuestionType type,
    List<String>? answerBlanks,
  }) {
    // V3.19.16: 多空题（answerBlanks 非空且 ≥ 2）专门判定
    if (answerBlanks != null && answerBlanks.length >= 2 &&
        type != QuestionType.multipleChoice) {
      // V3.20.3: 加全角逗号 ， 作合法分隔符
      final userBlanks = userAns
          .split(RegExp(r'[,，、\s]+|\|\|\|'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (userBlanks.length != answerBlanks.length) return false;
      // 逐空比对
      for (int i = 0; i < answerBlanks.length; i++) {
        final ua = userBlanks[i];
        final ca = answerBlanks[i];
        if (type == QuestionType.judgment) {
          String norm(String s) {
            final t = s.trim().toLowerCase();
            if (['对','正确','√','t','true','yes','y'].contains(t)) return '对';
            if (['错','错误','×','f','false','no','n','x','✗','✘'].contains(t)) return '错';
            return t;
          }
          if (norm(ua) != norm(ca)) return false;
        } else {
          if (normalize(ua) != normalize(ca)) return false;
        }
      }
      return true;
    }

    final accepts = correctAnswerField
        .split(altSeparator)
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
    if (accepts.isEmpty) return false;

    if (type == QuestionType.multipleChoice) {
      // V3.12.14 选择题：单选 + 多选共用判定
      // 提取所有字母 → 排序去重 → 比较（"AC"=="CA"=="A,C"=="AC,"）
      String norm(String s) {
        final letters = RegExp(r'[A-DZ]').allMatches(s.toUpperCase())
            .map((m) => m.group(0)!).toSet().toList()..sort();
        return letters.join();
      }
      final u = norm(userAns);
      return accepts.any((a) => norm(a) == u);
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
