import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// 把含 `$...$` 和 `**...**` 的字符串渲染为「普通文本 + LaTeX 公式 + 加粗」混合排版。
///
/// 约定：
/// - `$...$` 包数学表达（V3.7.9 引入）
/// - `**...**` 包加粗文字（V3.12.7 引入，主要用于语文真题加点字标记）
///
/// 例：
/// - `化简 $\frac{1}{2}:\frac{1}{3}$ = ?` → 文字 + 分数比例 + 文字
/// - `加点的字「这个**粽**子真好吃」读音是？` → 普通+加粗+普通
///
/// 解析失败时降级为原文（保留标记符），不会崩溃 UI。
class MathText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  const MathText(this.text, {super.key, this.style, this.textAlign = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    final segments = _parse(text);
    if (segments.length == 1 && segments.first.kind == _Kind.plain) {
      return Text(text, style: style, textAlign: textAlign);
    }
    final fontSize = style?.fontSize ?? 16;
    final color = style?.color ?? DefaultTextStyle.of(context).style.color;
    final boldStyle = (style ?? const TextStyle()).copyWith(fontWeight: FontWeight.bold);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: 4,
      children: segments.map((s) {
        switch (s.kind) {
          case _Kind.math:
            return Math.tex(
              s.content,
              mathStyle: MathStyle.text,
              textStyle: TextStyle(fontSize: fontSize, color: color),
              onErrorFallback: (err) => Text('\$${s.content}\$', style: style),
            );
          case _Kind.bold:
            return Text(s.content, style: boldStyle, textAlign: textAlign);
          case _Kind.plain:
            return Text(s.content, style: style, textAlign: textAlign);
        }
      }).toList(),
    );
  }

  /// 两阶段解析：先按 `$...$` 切 math 段，再对非 math 段按 `**...**` 切 bold 段。
  static List<_Segment> _parse(String text) {
    // 阶段 1: 切 math
    final mathSegments = _splitByPair(text, r'$', r'$', _Kind.math);
    // 阶段 2: 对非 math 段切 bold
    final result = <_Segment>[];
    for (final seg in mathSegments) {
      if (seg.kind == _Kind.math) {
        result.add(seg);
      } else {
        result.addAll(_splitByPair(seg.content, '**', '**', _Kind.bold));
      }
    }
    return result;
  }

  /// 通用配对切分。openTag/closeTag 相同时（如 `$...$` 或 `**...**`），
  /// 按顺序找下一个出现作为闭合。
  static List<_Segment> _splitByPair(
    String text,
    String openTag,
    String closeTag,
    _Kind matchedKind,
  ) {
    final segments = <_Segment>[];
    int i = 0;
    while (i < text.length) {
      final open = text.indexOf(openTag, i);
      if (open < 0) {
        if (i < text.length) {
          segments.add(_Segment(text.substring(i), _Kind.plain));
        }
        break;
      }
      // 转义的 \$ 或 \* 跳过
      if (open > 0 && text[open - 1] == r'\') {
        segments.add(_Segment('${text.substring(i, open - 1)}$openTag', _Kind.plain));
        i = open + openTag.length;
        continue;
      }
      if (open > i) {
        segments.add(_Segment(text.substring(i, open), _Kind.plain));
      }
      final close = text.indexOf(closeTag, open + openTag.length);
      if (close < 0) {
        // 找不到闭合，剩下的当普通文本
        segments.add(_Segment(text.substring(open), _Kind.plain));
        break;
      }
      final inner = text.substring(open + openTag.length, close);
      segments.add(_Segment(inner, matchedKind));
      i = close + closeTag.length;
    }
    return segments;
  }
}

enum _Kind { plain, math, bold }

class _Segment {
  final String content;
  final _Kind kind;
  const _Segment(this.content, this.kind);
}
