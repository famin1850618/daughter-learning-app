import '../models/question.dart';

/// 答案判定：处理列式过程、π↔pi、^n↔上标、全角符号、多种等价写法
///
/// 题包侧约定：
/// - 单一答案：`answer = 'πr²h/3'`
/// - 多种等价写法：用 `|||` 分隔，如 `'πr²h/3|||pi*r*r*h/3|||(1/3)*pi*r^2*h'`
///
/// V3.25: 「安全别名展开」修系统性假判错（Famin 2026-06-17 实测：括号/前置词/单位强制）。
/// 对每个标准答案自动派生更宽松的等价变体（剥外围括号、可省尾部单位、剥前置词），
/// 命中任一即对。变体**只从该正确答案派生**，绝不跨接受错误答案
/// （如 `5平方米` 不会误判 `5立方米`，因为变体集只含 `{5平方米, 5}`）。
class AnswerMatcher {
  static const altSeparator = '|||';

  /// 尾部单位词典（按长度/特异性降序——先匹配 `平方米` 再 `米`，`分钟` 先于 `分`）
  static const _units = [
    '平方千米', '平方厘米', '平方分米', '平方毫米', '平方米',
    '立方厘米', '立方分米', '立方毫米', '立方米',
    '千米', '分米', '厘米', '毫米', '千克', '毫升', '小时', '分钟', '公顷',
    'cm²', 'cm³', 'km²', 'm²', 'm³', 'km', 'cm', 'mm', 'dm', 'kg', 'mg', 'ml',
    '米', '升', '克', '吨', '元', '角', '分', '秒', '度', '岁', '次', '倍',
    '个', '只', '本', '块', '人', '份', '棵', '朵', '°', '%',
  ];

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
    const circled = {
      '①': '1', '②': '2', '③': '3', '④': '4', '⑤': '5',
      '⑥': '6', '⑦': '7', '⑧': '8', '⑨': '9', '⑩': '10',
      '⑪': '11', '⑫': '12', '⑬': '13', '⑭': '14', '⑮': '15',
      '⑯': '16', '⑰': '17', '⑱': '18', '⑲': '19', '⑳': '20',
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
    // 隐式乘法等价
    x = x.replaceAll(RegExp(r'(?<=[a-zA-Z\)])\*(?=[a-zA-Z0-9\(])'), '');
    x = x.replaceAll(RegExp(r'(?<=\d)\*(?=[a-zA-Z\(])'), '');

    return x.toLowerCase();
  }

  /// 计算题用：取最后一个 "=" 之后的内容（用户列式答题：1+2*3=7 → "7"）
  static String extractFinal(String userAns) {
    final idx = userAns.lastIndexOf('=');
    if (idx >= 0 && idx < userAns.length - 1) {
      final after = userAns.substring(idx + 1).trim();
      if (after.isNotEmpty) return after;
    }
    return userAns;
  }

  /// 剥掉成对的外围括号（对称、无语义损失：坐标 `(3,2)` 与 `3,2` 等价）。
  static String _stripOuterParens(String s) {
    var x = s.trim();
    // 只剥一层、且必须首尾成对包住整体
    final m = RegExp(r'^[\(（]\s*(.+?)\s*[\)）]$').firstMatch(x);
    return m != null ? m.group(1)! : x;
  }

  /// 规范形：normalize 后再剥外围括号。**两侧都用**——这一步只去纯格式差异。
  static String _canon(String s) => _stripOuterParens(normalize(s));

  /// 从一个**正确答案**派生宽松等价变体集（规范形）。
  /// 仅做"卷面格式残留"的剥离：外围括号 / 尾部单位 / 前置词（答：解：x=）。
  /// 关键安全性：变体只来自该正确答案本身，绝不会接受语义不同的答案。
  static Set<String> _answerVariants(String ans) {
    final seeds = <String>{ans.trim()};

    // 剥前置词：答：/解：（冒号必需，避免误剥"答案"）/x=/y=/=
    final lead = RegExp(r'^\s*(答[:：]|解[:：]|[a-zA-Z]\s*=|=)\s*');
    final lm = lead.firstMatch(ans);
    if (lm != null && lm.end < ans.length) {
      seeds.add(ans.substring(lm.end).trim());
    }

    // 对每个 seed 再尝试剥尾部单位
    final more = <String>{};
    for (final s in seeds) {
      for (final u in _units) {
        if (s.length > u.length && s.endsWith(u)) {
          more.add(s.substring(0, s.length - u.length).trim());
          break; // 最长匹配，剥一次
        }
      }
    }
    seeds.addAll(more);

    // 全部转规范形（含剥外围括号）
    return seeds.map(_canon).where((s) => s.isNotEmpty).toSet();
  }

  /// 单空/单答案命中：用户规范形 ∈ 该答案的宽松变体集。
  static bool _matchOne(String user, String answer, QuestionType type) {
    if (type == QuestionType.judgment) {
      String norm(String s) {
        final t = s.trim().toLowerCase();
        if (['对', '正确', '√', 't', 'true', 'yes', 'y'].contains(t)) return '对';
        if (['错', '错误', '×', 'f', 'false', 'no', 'n', 'x', '✗', '✘']
            .contains(t)) return '错';
        return t;
      }
      return norm(user) == norm(answer);
    }
    final u = _canon(user);
    if (u.isEmpty) return false;
    return _answerVariants(answer).contains(u);
  }

  /// 逐空输入框 UI 把各空文本用此分隔符 ‖ 拼接（U+2016，答案里不会出现）。
  static const blankSep = '‖';

  /// 把用户输入切成多空。
  /// - 逐空 UI（含 ‖ 分隔符）：按位置切、**保留空段**以对位（坐标含内部逗号也安全）。
  /// - 单框输入（兼容旧路径）：按 ,，、;；空格 ||| 切、丢空段。
  static List<String> splitUserBlanks(String userAns) {
    if (userAns.contains(blankSep)) {
      return userAns.split(blankSep).map((s) => s.trim()).toList();
    }
    return userAns
        .split(RegExp(r'[,，、;；\s]+|\|\|\|'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// V3.20.3 (阶段一) + V3.25: 部分得分判定
  /// 返回 (isCorrect, partialScore)：单空 0/1；多空 = 对的空数/总空数
  static ({bool isCorrect, double partialScore}) evaluatePartial({
    required String userAns,
    required String correctAnswerField,
    required QuestionType type,
    List<String>? answerBlanks,
  }) {
    // 多空题（answerBlanks ≥ 2）：算对的空数
    if (answerBlanks != null && answerBlanks.length >= 2 &&
        type != QuestionType.multipleChoice) {
      final userBlanks = splitUserBlanks(userAns);
      if (userBlanks.length != answerBlanks.length) {
        return (isCorrect: false, partialScore: 0.0);
      }
      int correctCount = 0;
      for (int i = 0; i < answerBlanks.length; i++) {
        if (_matchOne(userBlanks[i], answerBlanks[i], type)) correctCount++;
      }
      final score = correctCount / answerBlanks.length;
      return (isCorrect: score == 1.0, partialScore: score);
    }
    final ok = isCorrect(
      userAns: userAns,
      correctAnswerField: correctAnswerField,
      type: type,
      answerBlanks: answerBlanks,
    );
    return (isCorrect: ok, partialScore: ok ? 1.0 : 0.0);
  }

  /// 逐空判定：返回每个空的对错（供逐空 UI / 逐空申诉用）。
  /// 用户输入按位置切分；空数对不上时，多余/缺失位置记 false。
  static List<bool> perBlankResults({
    required List<String> userBlanks,
    required List<String> answerBlanks,
    required QuestionType type,
  }) {
    return List<bool>.generate(answerBlanks.length, (i) {
      if (i >= userBlanks.length) {
        return false;
      }
      return _matchOne(userBlanks[i], answerBlanks[i], type);
    });
  }

  /// 判定答题是否正确
  static bool isCorrect({
    required String userAns,
    required String correctAnswerField,
    required QuestionType type,
    List<String>? answerBlanks,
  }) {
    // 多空题（answerBlanks ≥ 2）专门判定
    if (answerBlanks != null && answerBlanks.length >= 2 &&
        type != QuestionType.multipleChoice) {
      final userBlanks = splitUserBlanks(userAns);
      if (userBlanks.length != answerBlanks.length) return false;
      for (int i = 0; i < answerBlanks.length; i++) {
        if (!_matchOne(userBlanks[i], answerBlanks[i], type)) return false;
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
      String norm(String s) {
        final letters = RegExp(r'[A-DZ]').allMatches(s.toUpperCase())
            .map((m) => m.group(0)!).toSet().toList()..sort();
        return letters.join();
      }
      final u = norm(userAns);
      return accepts.any((a) => norm(a) == u);
    }

    if (type == QuestionType.judgment) {
      return accepts.any((a) => _matchOne(userAns, a, type));
    }

    // fill / calculation：用安全别名变体匹配
    final candidate = type == QuestionType.calculation
        ? extractFinal(userAns)
        : userAns;
    if (accepts.any((a) => _matchOne(candidate, a, type))) return true;

    // 计算题第二次尝试：用户原文（含列式）整体规范化后看是否以正确答案结尾
    if (type == QuestionType.calculation) {
      final whole = _canon(userAns);
      for (final a in accepts) {
        for (final v in _answerVariants(a)) {
          if (v.isNotEmpty && whole.endsWith(v)) return true;
        }
      }
    }
    return false;
  }
}
