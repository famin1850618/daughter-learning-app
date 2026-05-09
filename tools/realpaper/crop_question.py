#!/usr/bin/env python3
"""
crop_question.py — 真题图精准切边工具（V3.12.16 spec §9.2 修订）

V3.12.13 设计：bbox = 图形元素外接矩形，page.crop(bbox).to_image() raster。
V3.12.13 实战发现：page.crop 是按矩形区域 raster 渲染，bbox 内的题面 chars
（题号、中文段落、分值标记、页脚二维码标识）一并被渲染——结果图带文字噪声。
73% 现存图截到题面/题号/分值。

V3.12.16 修订（本次）：保留 bbox 找法不变（仍用 image+lines+curves 外接矩形），
但 raster 后用 PIL 白色覆盖 bbox 内的：
  1. ≥2 连续中文 chars（题面段落 / "线段比例尺" / "改写成数值比例尺是"）
  2. 题号头（"1．" / "9." / "(2)" 等）
  3. (N 分) 分值标记
  4. 页脚标识（"微信公众号"/"关注"/"第 N 页"）
保留：
  - 数字串（坐标轴 0/1/2/3、尺寸标注 60 cm）
  - 单字母（候选 A/B/C/D、点 P/Q）
  - 孤立中文（尺寸标注"长"/"宽"/"高"，1 char 不抹）

用法:
    python3 crop_question.py <pdf> <page_num> <q_num> [next_q_num] [--out PATH]

返回:
    成功 → 写出 PNG + 打印 base64 字符长度
    失败 → 错误信息 + exit code 1

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


# === V3.12.16 新增：文字 mask 后处理 ===

def cluster_chars_into_lines(chars, line_threshold_factor=0.5):
    """按 y 坐标把 chars 聚成行（同一行的 chars y 相近）。"""
    if not chars:
        return []
    sorted_chars = sorted(chars, key=lambda c: (c['top'], c['x0']))
    lines = []
    current = [sorted_chars[0]]
    for c in sorted_chars[1:]:
        ref_top = current[0]['top']
        ref_h = current[0]['bottom'] - current[0]['top']
        if abs(c['top'] - ref_top) < ref_h * line_threshold_factor:
            current.append(c)
        else:
            lines.append(sorted(current, key=lambda x: x['x0']))
            current = [c]
    lines.append(sorted(current, key=lambda x: x['x0']))
    return lines


def _is_chinese(ch):
    return '一' <= ch <= '鿿'


def find_mask_runs(page, bbox, side_margin=5):
    """找 bbox 内需要 mask 的文字 runs。

    返回 [(x0, top, x1, bot), ...] PDF 坐标列表。

    Mask 规则:
      1. ≥2 连续中文 chars 的 run（题面段落/中文标题）
      2. 题号开头 (\\d+[．.、] / (\\d+))
      3. (N 分) 分值标记
      4. 页脚关键词 ("微信"/"公众号"/"关注"/"第 N 页")
    """
    x0, top, x1, bot = bbox
    chars = [
        c for c in page.chars
        if top - 1 <= c['top'] <= bot + 1
        and x0 - side_margin <= c['x0']
        and c['x1'] <= x1 + side_margin
    ]
    if not chars:
        return []
    masks = []
    for line in cluster_chars_into_lines(chars):
        # 1. 连续中文 ≥ 2 chars
        run = []
        for c in line:
            if _is_chinese(c['text']):
                run.append(c)
            else:
                if len(run) >= 2:
                    masks.append(_run_bbox(run))
                run = []
        if len(run) >= 2:
            masks.append(_run_bbox(run))
        # 2. 题号 / 3. (N 分) / 4. 页脚关键词 — 从行 text 找 substring 位置
        text = ''.join(c['text'] for c in line)
        # 题号头
        m = re.match(r'^(\(?\d+\)?\s*[．\.、])', text)
        if m:
            masks.append(_run_bbox(line[: len(m.group(1))]))
        # (N 分)
        for m in re.finditer(r'\(\d+\s*分\)', text):
            masks.append(_run_bbox(line[m.start(): m.end()]))
        # 页脚关键词
        for kw in ('微信公众号', '公众号', '关注', '第'):
            idx = text.find(kw)
            if idx >= 0:
                # 整行从 kw 起 mask 到行尾（页脚一般占整行）
                masks.append(_run_bbox(line[idx:]))
                break
    return masks


def _run_bbox(chars_subset, pad=1):
    if not chars_subset:
        return None
    return (
        min(c['x0'] for c in chars_subset) - pad,
        min(c['top'] for c in chars_subset) - pad,
        max(c['x1'] for c in chars_subset) + pad,
        max(c['bottom'] for c in chars_subset) + pad,
    )


def mask_runs_in_raster(img, masks, bbox, dpi=200):
    """在 raster 后的 PIL Image 上白色覆盖 masks（PDF 坐标转像素）。"""
    if not masks:
        return img
    from PIL import ImageDraw
    draw = ImageDraw.Draw(img)
    bx0, btop, _, _ = bbox
    scale = dpi / 72.0  # PDF 默认 72 dpi
    w, h = img.size
    for m in masks:
        if m is None:
            continue
        mx0, mtop, mx1, mbot = m
        px_x0 = max(0, int(round((mx0 - bx0) * scale)))
        px_top = max(0, int(round((mtop - btop) * scale)))
        px_x1 = min(w, int(round((mx1 - bx0) * scale)))
        px_bot = min(h, int(round((mbot - btop) * scale)))
        if px_x1 > px_x0 and px_bot > px_top:
            draw.rectangle([px_x0, px_top, px_x1, px_bot], fill='white')
    return img


def find_footer_top_y(page):
    """用关键词找页脚顶部 y 坐标（避免靠固定 px 误排图形）。

    返回页脚行的 top y，若无页脚关键词返回 page.height。
    """
    keywords = ('微信公众号', '公众号', '关注微信', '获取更多')
    candidates = []
    chars = sorted(page.chars, key=lambda c: c['top'])
    # 聚行
    for line in cluster_chars_into_lines(chars):
        text = ''.join(c['text'] for c in line)
        for kw in keywords:
            if kw in text:
                candidates.append(min(c['top'] for c in line))
                break
    if candidates:
        return min(candidates)
    # 兜底：找 "第 N 页" 模式
    for line in cluster_chars_into_lines(chars):
        text = ''.join(c['text'] for c in line)
        if re.search(r'第\s*\d+\s*页', text):
            return min(c['top'] for c in line)
    return page.height


def crop_to_png(pdf_path, page_num, q_num, next_q_num=None, dpi=200,
                mask_text=True):
    """主入口：返回 PIL Image 或 None。

    V3.12.16: 加 mask_text（默认开）排除 bbox 内题面文字 runs；
              用关键词检测页脚（替代固定 px 排除）避免误排底部图形。
    """
    with pdfplumber.open(pdf_path) as pdf:
        if page_num >= len(pdf.pages):
            raise ValueError(f'page_num {page_num} out of range (total {len(pdf.pages)})')
        page = pdf.pages[page_num]
        effective_page_bot = find_footer_top_y(page) - 2  # 页脚顶上 2px margin
        cur_top = find_question_top_y(page, q_num)
        if cur_top is None:
            raise ValueError(f'cannot locate question {q_num} top y on page {page_num}')
        if next_q_num is not None:
            next_top = find_question_top_y(page, next_q_num)
            if next_top is None:
                next_top = effective_page_bot
        else:
            next_top = effective_page_bot
        bbox = find_graphic_bbox(page, cur_top, next_top - 5)
        if bbox is None:
            return None  # 该题范围内无图形元素
        # 健康检查（V3.12.16）
        bbox_w = bbox[2] - bbox[0]
        bbox_h = bbox[3] - bbox[1]
        if bbox_w * bbox_h < 500:  # 面积过小（疑似页脚装饰）
            return None
        # 裁剪 + 渲染
        cropped = page.crop(bbox)
        img = cropped.to_image(resolution=dpi).original
        # V3.12.16 文字 mask 后处理
        if mask_text:
            masks = find_mask_runs(page, bbox)
            img = mask_runs_in_raster(img, masks, bbox, dpi=dpi)
        return img


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
