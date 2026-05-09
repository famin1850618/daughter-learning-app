#!/usr/bin/env python3
"""
crop_question.py — 真题图精准切边工具（V3.12.13 spec §9.2）

解决"截入下一题/重复文字" 反复 bug：
  1. pdfplumber 拿题号 char bbox → 精确题界
  2. 在题界范围内找 image / lines / curves 元素 bbox → 仅图形区
  3. 200 dpi 渲染 + 裁剪图形 bbox → PNG → base64

用法:
    python3 crop_question.py <pdf> <page_num> <q_num> [next_q_num] [out.png]

返回:
    成功 → 写出 PNG + 打印 base64 字符长度 (用于估算入库 image_data 字段)
    失败 → 错误信息 + exit code 1

设计原则 (spec §9.2 V3.12.13):
  - 仅截图形 bbox，不裁文字段（避免与 content 重复）
  - 严格题界（cur_top → next_top，间留 5px margin）
  - 200 dpi 起，base64 ≤ 200KB

依赖:
    pip install pdfplumber pillow
"""
import sys
import os
import re
import io
import base64
import argparse
from pathlib import Path

try:
    import pdfplumber
    from PIL import Image
except ImportError as e:
    print(f'ERROR: missing dep: {e}\nInstall: pip3 install pdfplumber pillow', file=sys.stderr)
    sys.exit(2)


def find_question_top_y(page, q_num):
    """找题号 q_num 在页面的 char y 坐标（top edge）。

    匹配格式：
      `1．` 全角句号
      `1.` 半角句号
      `1、` 顿号
      `(1)` 子题号 — 不匹配此函数
    """
    chars = page.chars
    # 精确匹配 "q_num" 后跟 "．/./、"
    targets = [f'{q_num}．', f'{q_num}.', f'{q_num}、']
    # 重组每行 chars 找完整 token
    # 简化：找单个数字 char y 坐标 + 紧跟 "．/."
    qstr = str(q_num)
    if len(qstr) > 2:
        return None  # 题号过长，不靠谱
    candidates = []
    for i, c in enumerate(chars):
        if c['text'] == qstr[0]:
            # 检查 next char 是否匹配
            if len(qstr) > 1:
                if i + 1 < len(chars) and chars[i + 1]['text'] == qstr[1]:
                    next_idx = i + 2
                else:
                    continue
            else:
                next_idx = i + 1
            if next_idx < len(chars):
                next_t = chars[next_idx]['text']
                if next_t in ('．', '.', '、'):
                    candidates.append(c['top'])
    if not candidates:
        return None
    # 返回最早出现的（题号一般在题首）
    return min(candidates)


def find_graphic_bbox(page, top_y, bot_y, margin=5):
    """在 [top_y, bot_y] 范围内找图形 bbox（image / lines / curves）。

    返回:
      (x0, top, x1, bot) 形式 bbox，或 None 如果范围内无图形
    """
    elements = []
    # PDF images
    for img in page.images:
        if top_y - margin <= img['top'] and img['bottom'] <= bot_y + margin:
            elements.append((img['x0'], img['top'], img['x1'], img['bottom']))
    # PDF lines/curves（几何题用）
    for ln in page.lines:
        if top_y - margin <= ln['top'] and ln['bottom'] <= bot_y + margin:
            elements.append((ln['x0'], ln['top'], ln['x1'], ln['bottom']))
    for cv in page.curves:
        if top_y - margin <= cv['top'] and cv['bottom'] <= bot_y + margin:
            elements.append((cv['x0'], cv['top'], cv['x1'], cv['bottom']))
    if not elements:
        return None
    # 合并 bbox（最小外接矩形）
    x0 = min(e[0] for e in elements)
    top = min(e[1] for e in elements)
    x1 = max(e[2] for e in elements)
    bot = max(e[3] for e in elements)
    # 加点 padding 但裁到题边界内
    pad = 3
    return (
        max(0, x0 - pad),
        max(top_y - margin, top - pad),
        min(page.width, x1 + pad),
        min(bot_y + margin, bot + pad),
    )


def crop_to_png(pdf_path, page_num, q_num, next_q_num=None, dpi=200):
    """主入口：返回 PIL Image 或 None。"""
    with pdfplumber.open(pdf_path) as pdf:
        if page_num >= len(pdf.pages):
            raise ValueError(f'page_num {page_num} out of range (total {len(pdf.pages)})')
        page = pdf.pages[page_num]
        cur_top = find_question_top_y(page, q_num)
        if cur_top is None:
            raise ValueError(f'cannot locate question {q_num} top y on page {page_num}')
        if next_q_num is not None:
            next_top = find_question_top_y(page, next_q_num)
            if next_top is None:
                next_top = page.height  # 当前题是页底最后一题
        else:
            next_top = page.height
        bbox = find_graphic_bbox(page, cur_top, next_top - 5)
        if bbox is None:
            return None  # 该题范围内无图形元素
        # 裁剪 + 渲染
        cropped = page.crop(bbox)
        return cropped.to_image(resolution=dpi).original


def png_to_base64(img):
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    return base64.b64encode(buf.getvalue()).decode('ascii')


def main():
    ap = argparse.ArgumentParser(description='Precise question image cropper (spec §9.2)')
    ap.add_argument('pdf', help='source PDF path')
    ap.add_argument('page', type=int, help='page number (0-indexed)')
    ap.add_argument('q_num', type=int, help='question number')
    ap.add_argument('next_q', type=int, nargs='?', default=None,
                    help='next question number (helps bound) — omit for last on page')
    ap.add_argument('--out', default=None, help='output PNG path (omit → only print base64 length)')
    ap.add_argument('--dpi', type=int, default=200)
    ap.add_argument('--max-base64-kb', type=int, default=200,
                    help='abort if base64 > this KB (spec §9.2)')
    args = ap.parse_args()

    img = crop_to_png(args.pdf, args.page, args.q_num, args.next_q, args.dpi)
    if img is None:
        print(f'NO_IMAGE: question {args.q_num} on page {args.page} has no graphic elements', file=sys.stderr)
        sys.exit(1)

    b64 = png_to_base64(img)
    kb = len(b64) // 1024
    if kb > args.max_base64_kb:
        print(f'WARN: base64 = {kb} KB exceeds {args.max_base64_kb} KB cap. Lower --dpi or trim.',
              file=sys.stderr)

    if args.out:
        img.save(args.out, format='PNG')
        print(f'wrote {args.out} ({img.size[0]}x{img.size[1]} px, {kb} KB base64)')
    else:
        print(f'OK: {img.size[0]}x{img.size[1]} px, {kb} KB base64')


if __name__ == '__main__':
    main()
