#!/usr/bin/env python3
"""
extract_emphasis.py — 检测 PDF 中的"加点字"并生成 markdown 加粗替换映射。

V3.12.7 实施 spec §5.6 加点字文本标记规则。

用法：
    python3 tools/realpaper/extract_emphasis.py <pdf_path> [--page N]
    → 输出 JSON: 每页含 emphasized_chars[] 列表（含 page/text/bbox/dot_bbox）

算法：
    1. 用 pdfplumber 读 PDF 每页字符 + 坐标
    2. 找所有中点字符（· ・ ･ . 等候选）
    3. 对每个中点，向上扫 3-8 px 找最近的中文字符 → 标记为加点
    4. 输出每个加点字的位置和内容

API（其他脚本调用）：
    detect_emphasis(pdf_path) -> List[EmphasisRecord]
    apply_emphasis_to_text(text, records) -> str  # 返回带 **字** 标记的文本
"""
import json
import sys
from pathlib import Path
from dataclasses import dataclass, asdict

try:
    import pdfplumber
except ImportError:
    print("ERROR: pdfplumber 未安装。运行: pip install --break-system-packages pdfplumber", file=sys.stderr)
    sys.exit(1)


# 加点候选字符
# - · ・ ･: 紧贴字符底部的中点（少见）
# - ．（FF0E 全角句号）: 部编版常见手法——下一行用全角句号占位标记加点字
# 不含半角 .（容易跟题号 1./2./A. 混淆造成大量误判）
DOT_CHARS = {'·', '・', '･', '．'}
# 中文字符范围（粗判）；c 可能是单字符或多字符（嵌入字体异常时 pdfplumber 会给字符串）
def is_chinese(c: str) -> bool:
    if not c or len(c) != 1:
        return False
    cp = ord(c)
    return 0x4E00 <= cp <= 0x9FFF


@dataclass
class EmphasisRecord:
    page: int
    char: str
    char_x0: float
    char_top: float
    char_bottom: float
    dot_x0: float
    dot_top: float


def detect_emphasis(pdf_path: str, page_filter: int = None) -> list:
    """
    检测 PDF 中所有加点字。

    Returns: List[EmphasisRecord]
    """
    records = []
    with pdfplumber.open(pdf_path) as pdf:
        pages = pdf.pages
        if page_filter is not None:
            pages = [pdf.pages[page_filter - 1]] if page_filter <= len(pdf.pages) else []

        for page_idx, page in enumerate(pages, start=1 if page_filter is None else page_filter):
            chars = page.chars
            # 找所有中点字符
            dots = [c for c in chars if c['text'] in DOT_CHARS]

            # 估算行高（字符高度的中位数）
            char_heights = sorted([c['height'] for c in chars if c.get('height')])
            row_h = char_heights[len(char_heights)//2] if char_heights else 14

            # 加点检测：dot 应该在加点字符的 bbox 内偏下位置 或 紧贴字符 bbox 下方
            # 实测部编六下语文：dot.top 通常在 char.top + 0.2~0.5 row_h 区间（即 char bbox 内底部 1/3）
            # 共同约束：
            #   y: char.top + 0.1 row_h <= dot.top <= char.bottom + 0.5 row_h
            #   x: dot 中心 在 char 的水平范围内（± 0.3 row_h 容差）
            x_tol = max(row_h * 0.3, 3)
            y_min_offset = row_h * 0.1   # dot.top - char.top >= row_h * 0.1
            y_max_offset = row_h * 0.5   # dot.top - char.bottom <= row_h * 0.5

            for dot in dots:
                dot_cx = (dot['x0'] + dot.get('x1', dot['x0'])) / 2

                candidates = [
                    c for c in chars
                    if (
                        is_chinese(c['text'])
                        and (c['x0'] - x_tol <= dot_cx <= c['x1'] + x_tol)
                        and (dot['top'] - c['top'] >= y_min_offset)
                        and (dot['top'] - c['bottom'] <= y_max_offset)
                    )
                ]
                if candidates:
                    # V3.12.16 修：tie-break 改成 x 中心主、y 副。
                    # 旧版主排序按 y 距离，相邻字 bottom 差 1-2px（字形）就误判。
                    # 例：「浏览」加点在「浏」下方，但「览」字 bottom 比「浏」低 1px →
                    # 旧版优先选「览」。新版按 x 中心主排序：dot 和加点字 x 中心
                    # 应几乎完全对齐（< 1px），相邻字差 5+px，区分明显。
                    target = min(
                        candidates,
                        key=lambda c: (
                            abs(dot_cx - (c['x0']+c['x1'])/2),  # 主: x 中心对齐
                            abs(dot['top'] - c['bottom']),       # 副: y 距离
                        )
                    )
                    records.append(EmphasisRecord(
                        page=page_idx,
                        char=target['text'],
                        char_x0=target['x0'],
                        char_top=target['top'],
                        char_bottom=target['bottom'],
                        dot_x0=dot['x0'],
                        dot_top=dot['top'],
                    ))
    return records


def apply_emphasis_to_text(text: str, records: list) -> str:
    """
    把 pdftotext 抽出的纯文本里被加点的字标记为 **字**。

    简单实现：按"字符 + 出现次数"匹配。第 N 次出现的某字（如"粽"）如果在
    records 里被标加点，就替换为 **粽**。

    Note: 这是 best-effort 实现。pdftotext 与 pdfplumber 的字符顺序大致一致，
    但少数情况（如多列布局）可能错位。准确实现需要传入 page-level 上下文 +
    每个加点字符在该页中的字符索引。

    用法举例：
        records = detect_emphasis("paper.pdf")
        text = open("paper.txt").read()
        marked = apply_emphasis_to_text(text, records)
    """
    # 按页聚合
    from collections import defaultdict
    by_page = defaultdict(list)
    for r in records:
        by_page[r.page].append(r)

    # 简单实现：对每个 record 的字符，按出现顺序在原文中替换第 N 次
    # 注意：这个实现假设 pdftotext 输出字符顺序与 pdfplumber chars 顺序一致
    # 实际中文真题大多单列布局，假设成立
    counter = {}
    out = list(text)
    for r in records:
        ch = r.char
        target_idx = counter.get(ch, 0) + 1  # 第 target_idx 次出现要标加点
        counter[ch] = target_idx
        # 在 out 里找第 target_idx 次出现的 ch
        seen = 0
        for i, c in enumerate(out):
            if c == ch:
                seen += 1
                if seen == target_idx and not (i > 0 and out[i-1:i+2] == list(f'**{ch}')):
                    # 标记为 **字**
                    out[i] = f'**{ch}**'
                    break
    return ''.join(out)


def main():
    args = sys.argv[1:]
    if not args:
        print("用法: extract_emphasis.py <pdf_path> [--page N]", file=sys.stderr)
        sys.exit(1)
    pdf_path = args[0]
    page_filter = None
    if '--page' in args:
        page_filter = int(args[args.index('--page') + 1])

    records = detect_emphasis(pdf_path, page_filter=page_filter)
    print(json.dumps([asdict(r) for r in records], ensure_ascii=False, indent=2))
    print(f"\n# 检测到 {len(records)} 个加点字", file=sys.stderr)


if __name__ == '__main__':
    main()
