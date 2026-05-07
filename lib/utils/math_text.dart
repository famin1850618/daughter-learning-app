import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// 把含 `$...$` 的字符串渲染为「普通文本 + LaTeX 公式」混合排版。
///
/// 约定：题包侧 content / explanation 用 `$...$` 包数学表达。
/// 例：`化简 $\frac{1}{2}:\frac{1}{3}$ = ?` → 文字 + 渲染好的分数比例 + 文字。
///
/// LaTeX 解析失败时降级为原文（保留 `$...$`），不会崩溃 UI。
class MathText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  const MathText(this.text, {super.key, this.style, this.textAlign = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    final segments = _parse(text);
    if (segments.length == 1 && !segments.first.isMath) {
      // 纯文本快速路径
      return Text(text, style: style, textAlign: textAlign);
    }
    final fontSize = style?.fontSize ?? 16;
    final color = style?.color ?? DefaultTextStyle.of(context).style.color;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: 4,
      children: segments.map((s) {
        if (s.isMath) {
          return Math.tex(
            s.content,
            mathStyle: MathStyle.text,
            textStyle: TextStyle(fontSize: fontSize, color: color),
            onErrorFallback: (err) => Text('\$${s.content}\$', style: style),
          );
        }
        return Text(s.content, style: style, textAlign: textAlign);
      }).toList(),
    );
  }

  static List<_Segment> _parse(String text) {
    final segments = <_Segment>[];
    int i = 0;
    while (i < text.length) {
      final dollar = text.indexOf(r'$', i);
      if (dollar < 0) {
        segments.add(_Segment(text.substring(i), false));
        break;
      }
      // 转义的 \$ 不算
      if (dollar > 0 && text[dollar - 1] == r'\') {
        segments.add(_Segment(text.substring(i, dollar - 1) + r'$', false));
        i = dollar + 1;
        continue;
      }
      if (dollar > i) {
        segments.add(_Segment(text.substring(i, dollar), false));
      }
      final close = text.indexOf(r'$', dollar + 1);
      if (close < 0) {
        // 找不到闭合 $，剩下的当普通文本
        segments.add(_Segment(text.substring(dollar), false));
        break;
      }
      final formula = text.substring(dollar + 1, close);
      segments.add(_Segment(formula, true));
      i = close + 1;
    }
    return segments;
  }
}

class _Segment {
  final String content;
  final bool isMath;
  const _Segment(this.content, this.isMath);
}
