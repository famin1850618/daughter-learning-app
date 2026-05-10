import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// 把含 `$...$` 和 `**...**` 的字符串渲染为「普通文本 + LaTeX 公式 + 加粗 + GFM 表格」混合排版。
///
/// 约定：
/// - `$...$` 包数学表达（V3.7.9 引入）
/// - `**...**` 包加粗文字（V3.12.7 引入，主要用于语文真题加点字标记）
/// - `| col1 | col2 |` 含分隔行 `| --- | --- |` 的连续行 → GFM 表格（V3.12.22 引入）
///
/// 例：
/// - `化简 $\frac{1}{2}:\frac{1}{3}$ = ?` → 文字 + 分数比例 + 文字
/// - `加点的字「这个**粽**子真好吃」读音是？` → 普通+加粗+普通
/// - 含表格的行被识别成 GFM 表格 → Table widget 渲染，每个 cell 内嵌 MathText
///
/// 解析失败时降级为原文（保留标记符），不会崩溃 UI。
class MathText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  const MathText(this.text, {super.key, this.style, this.textAlign = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    // V3.12.22 Issue 8: 先检测是否含 GFM 表格（≥ 2 行 |...| 含分隔行）→ 拆 text/table 块
    final blocks = _splitTableBlocks(text);
    if (blocks.length > 1 || (blocks.length == 1 && blocks.first.isTable)) {
      // 多块（含表格）：垂直堆叠
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: blocks.map<Widget>((b) {
          if (b.isTable) {
            return _buildTable(context, b.lines);
          } else {
            return _buildInlineText(context, b.text);
          }
        }).toList(),
      );
    }

    return _buildInlineText(context, text);
  }

  Widget _buildInlineText(BuildContext context, String t) {
    final segments = _parse(t);
    if (segments.length == 1 && segments.first.kind == _Kind.plain) {
      return Text(t, style: style, textAlign: textAlign);
    }
    final defaultStyle = DefaultTextStyle.of(context).style;
    final mergedStyle = defaultStyle.merge(style);
    final fontSize = mergedStyle.fontSize ?? 16;
    final color = mergedStyle.color;

    // V3.12.17 修折叠屏横屏公式上移：旧版 Wrap+WrapCrossAlignment.center
    // 按 item 垂直中心对齐，公式高度（分数/上下标）大于文字时，公式相对文字
    // 被推高（"上移"），横屏一行内 item 多更明显。
    // 新版 RichText + WidgetSpan + PlaceholderAlignment.baseline，公式底部
    // 与文字字符基线对齐，跟印刷品一致。
    return Text.rich(
      TextSpan(
        style: mergedStyle,
        children: segments.map<InlineSpan>((s) {
          switch (s.kind) {
            case _Kind.math:
              return WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Math.tex(
                  s.content,
                  mathStyle: MathStyle.text,
                  textStyle: TextStyle(fontSize: fontSize, color: color),
                  onErrorFallback: (err) => Text('\$${s.content}\$', style: mergedStyle),
                ),
              );
            case _Kind.bold:
              return TextSpan(
                text: s.content,
                style: const TextStyle(fontWeight: FontWeight.bold),
              );
            case _Kind.plain:
              return TextSpan(text: s.content);
          }
        }).toList(),
      ),
      textAlign: textAlign,
    );
  }

  /// V3.12.22 Issue 8: 切分文本到 [text 块, table 块, ...] 列表。
  /// 启发式：连续 ≥ 2 行 `|...|` 含分隔行 `| --- |` 的视为 GFM 表格块；其余为 text 块。
  static List<_Block> _splitTableBlocks(String src) {
    final lines = src.split('\n');
    final blocks = <_Block>[];
    int i = 0;
    while (i < lines.length) {
      final l = lines[i].trim();
      // 表格起点候选：当前行是 |...| 且下一行是分隔行 |---|---|
      if (l.startsWith('|') && l.endsWith('|') && l.length >= 3 && i + 1 < lines.length) {
        final next = lines[i + 1].trim();
        // 分隔行特征：`| --- | --- |` 或 `|---|---|` 或 `|:---:|`
        if (RegExp(r'^\|[\s:|-]+\|$').hasMatch(next) && next.contains('-')) {
          // 收集连续 |...| 行
          final tableLines = <String>[];
          int j = i;
          while (j < lines.length) {
            final lj = lines[j].trim();
            if (lj.startsWith('|') && lj.endsWith('|')) {
              tableLines.add(lj);
              j++;
            } else {
              break;
            }
          }
          if (tableLines.length >= 2) {
            blocks.add(_Block.table(tableLines));
            i = j;
            continue;
          }
        }
      }
      // 累积 text 直到下一表格起点
      final textBuf = <String>[];
      while (i < lines.length) {
        final cur = lines[i].trim();
        if (cur.startsWith('|') && cur.endsWith('|') && i + 1 < lines.length) {
          final nxt = lines[i + 1].trim();
          if (RegExp(r'^\|[\s:|-]+\|$').hasMatch(nxt) && nxt.contains('-')) {
            break; // 表格起点 → 跳出
          }
        }
        textBuf.add(lines[i]);
        i++;
      }
      if (textBuf.isNotEmpty) {
        final t = textBuf.join('\n');
        if (t.trim().isNotEmpty) blocks.add(_Block.text(t));
      }
    }
    return blocks;
  }

  /// 渲染 GFM 表格行（第一行表头，第二行分隔，其余 data）
  Widget _buildTable(BuildContext context, List<String> tableLines) {
    if (tableLines.length < 2) return const SizedBox.shrink();
    // parse 每行的 cells（去首尾 `|`，按 `|` 切，trim）
    List<String> parseCells(String line) {
      final inner = line.trim();
      final stripped = inner.substring(1, inner.length - 1); // 去首尾 |
      return stripped.split('|').map((c) => c.trim()).toList();
    }

    final header = parseCells(tableLines[0]);
    // tableLines[1] 是分隔行，跳过
    final dataRows = tableLines.skip(2).map(parseCells).toList();

    final defaultStyle = DefaultTextStyle.of(context).style;
    final mergedStyle = defaultStyle.merge(style);

    Widget cellWrap(String cell, {bool bold = false}) {
      final cellStyle = bold
          ? mergedStyle.copyWith(fontWeight: FontWeight.bold)
          : mergedStyle;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: MathText(cell, style: cellStyle, textAlign: TextAlign.center),
      );
    }

    final tableWidget = Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: TableBorder.all(
        color: Colors.grey.shade400,
        width: 1,
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: header.map((c) => cellWrap(c, bold: true)).toList(),
        ),
        ...dataRows.map((row) => TableRow(
              children: row.map((c) => cellWrap(c)).toList(),
            )),
      ],
    );

    // 表格水平滚动支持（窄屏列多时）
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: tableWidget,
      ),
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

/// V3.12.22 Issue 8: 内容块（text 或 table）
class _Block {
  final bool isTable;
  final String text;          // text 块的文字
  final List<String> lines;   // table 块的 markdown 行（含分隔行）
  const _Block.text(this.text)
      : isTable = false,
        lines = const [];
  const _Block.table(this.lines)
      : isTable = true,
        text = '';
}
