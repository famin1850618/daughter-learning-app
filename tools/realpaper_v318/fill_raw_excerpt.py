#!/usr/bin/env python3
"""V3.18 修补 worker：批量补全 _raw_excerpt 字段。
策略：
  - 读 batch json + raw_with_omath.txt
  - 对每个 _raw_excerpt 缺失/太短的题：
      a. 去除 content 中的 LaTeX/标点，得"指纹"前缀（前 18 字、12 字、8 字等多档候选）
      b. 在 raw_with_omath.txt 去空白版中 find 指纹起点
      c. 截取自指纹起点到下一个题号边界（题号正则）或直至 ≥40 字处的整行边界
      d. 组合题（同一 group_id）：每子题取本子题对应行；首题加 _common_prefix_raw
  - 找不到则进 _skipped_for_future（reason=v318_no_raw_match）
  - 不修 content / 不修 answer
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Optional

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'assets/data/batches_v2'
QBANK = ROOT / 'question_bank/batches_v2'
CACHE = ROOT / '.cache/docx'

# 与 normalize_aggressive 保持一致的字符类（用作 raw 端 normalize）
PUNCT_PATTERN = r'[，,。．：:；;！!？?、（）()【】\[\]\{\}"\'“”‘’«»—_\.\-=＝≠＞＜≥≤><≈→←↑↓·•※*×÷±°￥$%／/\\|]'

# 题号正则：12．  12. 24． 二、 三、 (1) （2） 1. 2.
QNUM_RE = re.compile(r'(?:^|\s)(?:[一二三四五六七八九十]+、|\d+[．\.]|\(\d+\)|（\d+）)')

# 噪声字符：标点/空白/全角空格
def normalize(s: str) -> str:
    """去掉所有空白 + LaTeX $ 包装 + 不影响识别的标点。"""
    if not s:
        return ''
    # 移除 LaTeX $...$ 但保留内部数字/字母
    s = re.sub(r'\$([^$]*)\$', r'\1', s)
    # 去掉空白
    s = ''.join(s.split())
    return s


def normalize_aggressive(s: str) -> str:
    """更激进：去除所有标点 + 数学符号 + 全角空格。"""
    s = normalize(s)
    # 移除常见 LaTeX 命令的反斜杠片段（\frac \sim \times \,等）
    s = re.sub(r'\\(?:frac|sim|times|div|cdot|approx|leq|geq|neq|circ|text|mathrm|left|right)\b', '', s)
    s = re.sub(r'\\[a-zA-Z]+', '', s)  # 兜底所有 \xxx
    s = re.sub(r'\\[,;\s]', '', s)  # \, \; \
    # 去掉常见标点 + 全角等号/不等号/数学符号 + 各种引号 + 上下标
    s = re.sub(PUNCT_PATTERN, '', s)
    s = s.replace('　', '')
    s = s.replace('「', '').replace('」', '')
    s = s.replace('『', '').replace('』', '')
    s = s.replace('~', '').replace('～', '')
    return s


def candidate_fingerprints(content: str) -> list[str]:
    """从 content 中提取多个候选指纹（去 LaTeX/标点/空白后的纯字符串）。
    顺序：
      1. 整 content normalize 后头 22/16/12 字
      2. 跳过开头括号 () （） 包裹后头 18/14/10 字
      3. 中段 substring：取 content 中 5..25 的字符
      4. 末段：content 后 14/10 字
    去重、长度 >=8。
    """
    cn = normalize_aggressive(content)
    if not cn:
        return []
    fps = []
    for L in (22, 18, 14, 10, 8):
        if len(cn) >= L:
            fps.append(cn[:L])

    # 去掉开头括号包裹
    # content 原文中先去掉开头连续的 (..)/（..）
    c2 = content
    # 匹配开头 (xxx) 或 （xxx）（xxx）...
    while True:
        m = re.match(r'^\s*[\(（][^)）]*[\)）]\s*', c2)
        if m:
            c2 = c2[m.end():]
        else:
            break
    cn2 = normalize_aggressive(c2)
    for L in (18, 14, 10, 8):
        if len(cn2) >= L and cn2[:L] not in fps:
            fps.append(cn2[:L])

    # 中段
    if len(cn) >= 18:
        for offset in (4, 8, 12):
            if len(cn) >= offset + 12:
                seg = cn[offset:offset+12]
                if seg not in fps:
                    fps.append(seg)

    # 末段
    if len(cn) >= 18:
        for L in (14, 10, 8):
            seg = cn[-L:]
            if seg not in fps:
                fps.append(seg)

    # 加上整 cn（适合短题）
    if cn and cn not in fps:
        fps.append(cn)
    if cn2 and cn2 != cn and cn2 not in fps:
        fps.append(cn2)

    # 兜底：取 content 中所有连续中文/字母段（≥6 字），按长度降序
    chinese_segs = re.findall(r'[一-鿿]{6,}', content)
    chinese_segs.sort(key=len, reverse=True)
    for seg in chinese_segs:
        if seg not in fps:
            fps.append(seg)
    # 也取 4-5 字中文段作末位指纹
    short_segs = re.findall(r'[一-鿿]{4,5}', content)
    short_segs.sort(key=len, reverse=True)
    for seg in short_segs:
        if seg not in fps:
            fps.append(seg)

    # cn 的滑动窗口：在 cn 上枚举各种长度 substring（避免漏掉中文+数字混合）
    if cn:
        for L in (10, 8, 6, 5, 4):
            if len(cn) < L: continue
            for off in range(0, len(cn) - L + 1):
                seg = cn[off:off+L]
                if seg not in fps:
                    fps.append(seg)
                    if len(fps) > 300: break
            if len(fps) > 300: break

    # 短题降到 5 字
    return [f for f in fps if len(f) >= 4]


def find_excerpt_in_raw(content: str, raw_full: str, raw_norm: str, used_ranges: list, min_pos: int = 0, max_pos: Optional[int] = None, norm_map=None, raw_norm_agg: Optional[str] = None) -> Optional[tuple[int, int, str]]:
    """在 raw_full 中找 content 对应的原段。
    min_pos: norm_agg 中下界（保证单调递增）
    max_pos: norm_agg 中上界（避免越过下一题已锚定位置）
    """
    cn = normalize_aggressive(content)
    if len(cn) < 6:
        cn = normalize(content)
    if not cn:
        return None

    if raw_norm_agg is None:
        raw_norm_agg = normalize_aggressive(raw_norm)

    fps = candidate_fingerprints(content)
    fallback_pos_for_long_fp = None
    fallback_fp_for_long = None
    for fp_idx, fp in enumerate(fps):
        positions = []
        start = max(0, min_pos - len(fp))  # 允许 fp 部分跨越 min_pos
        while True:
            pos = raw_norm_agg.find(fp, start)
            if pos == -1:
                break
            # 必须 pos >= min_pos（fp 起点在 min_pos 之后）
            # 但若 fp 是 cn 中段，real_start = pos - fp_offset 才是题面起点
            fp_off = cn.find(fp) if cn else 0
            real_start = pos - fp_off if fp_off > 0 else pos
            if real_start >= min_pos and (max_pos is None or pos < max_pos):
                positions.append(pos)
            start = pos + 1
        if not positions:
            continue
        chosen_pos = None
        for pos in positions:
            est_end = pos + max(len(cn), 30)
            overlap = False
            for (us, ue) in used_ranges:
                if pos < ue and est_end > us:
                    overlap = True
                    break
            if not overlap:
                chosen_pos = pos
                break
        if chosen_pos is None:
            if len(fp) >= 10 and fallback_pos_for_long_fp is None:
                fallback_pos_for_long_fp = positions[0]
                fallback_fp_for_long = fp
            continue

        # chosen_pos 是指纹起点，但实际题面起点可能在它之前（指纹是中段时）
        # 用 cn 在 raw_norm_agg 中"反向对齐"：找 fp 在 cn 中的偏移
        fp_offset_in_cn = cn.find(fp) if cn else 0
        if fp_offset_in_cn > 0:
            real_start_norm = max(0, chosen_pos - fp_offset_in_cn)
            # 验证：real_start_norm 处的若干字符应跟 cn 头部对齐
            window = raw_norm_agg[real_start_norm:real_start_norm + min(20, len(cn))]
            if window != cn[:len(window)]:
                # 对不齐，回退到 chosen_pos 起算
                real_start_norm = chosen_pos
        else:
            real_start_norm = chosen_pos

        return _extract_from_raw(raw_full, real_start_norm, cn, used_ranges, norm_map=norm_map)

    # fallback：用长指纹的 overlap 命中（说明本题与已抄题共享段，宽容接受）
    if fallback_pos_for_long_fp is not None:
        fp = fallback_fp_for_long
        fp_offset = cn.find(fp) if cn else 0
        real_start = max(0, fallback_pos_for_long_fp - fp_offset) if fp_offset > 0 else fallback_pos_for_long_fp
        return _extract_from_raw(raw_full, real_start, cn, used_ranges, norm_map=norm_map)
    return None


def _build_norm_to_raw_map(raw_full: str) -> list[int]:
    """为 normalize_aggressive(raw_full) 中每个字符位置 i，给出对应 raw_full 中的位置。
    保证一致性：用 normalize_aggressive 流式构造，记录每个保留字符的 raw_full 索引。
    """
    s = raw_full
    # 与 normalize_aggressive 一致的处理：先 LaTeX，再标点等
    # 但 normalize 步会做 LaTeX $...$ 移除并保留内容——这一步会改变字符序列
    # 简化：构造 normalize 后串 + raw_full pos 映射
    # 步骤：
    #   1. 移除空白：每保留字符记 pos
    #   2. 后续移除 LaTeX cmd / punct / OMATH
    # 但 LaTeX cmd 是 \\xxx：跳过整个 token

    out = []
    out_pos = []  # raw_full 中位置
    PUNCT_RE = re.compile(PUNCT_PATTERN)
    i = 0
    n = len(s)
    while i < n:
        ch = s[i]
        # 跳过空白
        if ch.isspace() or ch == '　':
            i += 1
            continue
        # 跳过 LaTeX $ ... $（但保留中间内容）
        if ch == '$':
            i += 1
            continue
        # LaTeX command: \xxx
        if ch == '\\':
            j = i + 1
            while j < n and s[j].isalpha():
                j += 1
            i = j
            # 也吃掉一个紧随空白
            if i < n and s[i] in ' \t,;':
                i += 1
            continue
        if ch in '「」『』~～':
            i += 1
            continue
        if PUNCT_RE.match(ch):
            i += 1
            continue
        # 保留
        out.append(ch)
        out_pos.append(i)
        i += 1
    return ''.join(out), out_pos


def _extract_from_raw(raw_full: str, chosen_norm_agg_pos: int, cn: str, used_ranges: list, norm_map=None) -> Optional[tuple[int, int, str]]:
    """从 raw_full 中提取从 normalize_aggressive 位置 chosen_norm_agg_pos 开始的连续片段。
    片段截止：遇下一个题号 OR 长度达 max(len(cn) + 60, 80) OR 遇连续 2 行空。
    返回 (norm_agg_start, norm_agg_end, excerpt_str_with_whitespace)
    """
    PUNCT_RE = re.compile(PUNCT_PATTERN)

    def is_skip(ch):
        if ch.isspace() or ch == '　':
            return True
        if ch in '「」『』~～':
            return True
        if PUNCT_RE.match(ch) is not None:
            return True
        return False

    # 用 norm_map（如提供）将 chosen_norm_agg_pos 直接映射到 raw_full 索引
    if norm_map is not None and chosen_norm_agg_pos < len(norm_map):
        start_in_raw = norm_map[chosen_norm_agg_pos]
    else:
        # 兜底：walk 法（与 normalize_aggressive 不完全一致，可能错位）
        norm_idx = 0
        start_in_raw = None
        for i, ch in enumerate(raw_full):
            if not is_skip(ch):
                if norm_idx == chosen_norm_agg_pos:
                    start_in_raw = i
                    break
                norm_idx += 1
        if start_in_raw is None:
            return None

    # 决定 end：尽早在题号边界截断
    # target_len 用于"够长"的硬上限
    target_len = max(len(cn) + 30, 50)
    target_len = min(target_len, 180)

    end_in_raw = start_in_raw
    norm_taken = 0
    consecutive_newlines = 0
    i = start_in_raw
    while i < len(raw_full):
        ch = raw_full[i]
        if not is_skip(ch):
            norm_taken += 1
            consecutive_newlines = 0
        if ch == '\n':
            consecutive_newlines += 1
            # 任何换行：peek 下一行起始是不是题号；若是且已抄 ≥10 norm，则截断
            j = i + 1
            while j < len(raw_full) and raw_full[j].isspace():
                j += 1
            if j < len(raw_full) and norm_taken >= 10:
                rest = raw_full[j:j+10]
                if re.match(r'\d+[．\.]', rest) or re.match(r'[一二三四五六七八九十]+、', rest):
                    end_in_raw = i
                    break
                # 也检测 (1) （2） 这种子题号，但仅在已经超过本题 cn 长度时才截
                if (re.match(r'[\(（]\d+[\)）]', rest)) and norm_taken >= max(len(cn), 30):
                    end_in_raw = i
                    break
            if consecutive_newlines >= 2 and norm_taken >= 10:
                end_in_raw = i
                break
            if norm_taken >= target_len:
                end_in_raw = i
                break
        i += 1
    else:
        end_in_raw = i

    # 提取
    excerpt = raw_full[start_in_raw:end_in_raw].strip()
    # 截断尾部空白和孤立换行
    excerpt = re.sub(r'\s+\n', '\n', excerpt)
    excerpt = excerpt.strip()

    # 确保 ≥10 norm-char
    if len(normalize(excerpt)) < 10:
        # 再延长
        end2 = min(len(raw_full), end_in_raw + 80)
        excerpt = raw_full[start_in_raw:end2].strip()

    # 计算 norm_agg_end
    norm_agg_end = chosen_norm_agg_pos + norm_taken
    return (chosen_norm_agg_pos, norm_agg_end, excerpt)


def fingerprint_exists_in_raw(excerpt: str, raw_full: str) -> bool:
    """模拟 validate.py check 17：去空白后头 20 + 尾 20 在 raw_full 去空白中存在。"""
    raw_norm = ''.join(raw_full.split())
    e_norm = ''.join(excerpt.split())
    if len(e_norm) < 30:
        head = tail = e_norm
    else:
        head = e_norm[:20]
        tail = e_norm[-20:]
    return head in raw_norm and tail in raw_norm


def process_batch(batch_path: Path, dry_run: bool = False) -> dict:
    batch = json.loads(batch_path.read_text(encoding='utf-8'))
    sha1 = batch.get('_source_docx_sha1', '')
    if not sha1:
        return {'error': 'no sha1', 'filled': 0, 'skipped': 0}
    cache_file = CACHE / sha1 / 'raw_with_omath.txt'
    if not cache_file.exists():
        return {'error': f'no cache {cache_file}', 'filled': 0, 'skipped': 0}
    raw_full = cache_file.read_text(encoding='utf-8', errors='ignore')
    raw_norm = normalize(raw_full)

    questions = batch.get('questions', [])
    skipped_for_future = batch.setdefault('_skipped_for_future', [])
    # 与 normalize_aggressive 严格一致的 raw_norm_agg + raw_full pos 映射
    raw_norm_agg, norm_map = _build_norm_to_raw_map(raw_full)

    # Pass 1：为每题计算 anchor（norm_agg 中 pos）
    # 已有 _raw_excerpt 的题：用其 fp 找 pos
    anchors = [None] * len(questions)
    for i, q in enumerate(questions):
        re_field = q.get('_raw_excerpt')
        if re_field and len(re_field.strip()) >= 10:
            cn_q = normalize_aggressive(re_field)
            if cn_q:
                fp = cn_q[:18] if len(cn_q) >= 18 else cn_q
                pos = raw_norm_agg.find(fp)
                if pos != -1:
                    # 用较短的覆盖（避免 anchor 跨越多题）
                    cover = min(len(cn_q), 50)
                    anchors[i] = (pos, pos + cover)

    # Pass 2：按 question 顺序补全；用 monotonic 增序约束
    used_ranges = [a for a in anchors if a is not None]
    filled = 0
    failed = []
    new_questions = []
    skipped_idx = []

    for i, q in enumerate(questions):
        re_field = q.get('_raw_excerpt')
        if re_field and len(re_field.strip()) >= 10:
            new_questions.append(q)
            continue

        content = q.get('content', '') or ''
        sub_fp = None
        if q.get('group_id'):
            lines = [ln.strip() for ln in content.split('\n') if ln.strip()]
            for ln in lines[::-1]:
                if re.match(r'^\d+[．\.]', ln) or re.match(r'^[（(]\d+[)）]', ln):
                    sub_fp = ln
                    break
        search_content = sub_fp if sub_fp else content

        # 不强制 monotonic，仅靠 used_ranges 避免重复占用
        result = find_excerpt_in_raw(search_content, raw_full, raw_norm, used_ranges, norm_map=norm_map, raw_norm_agg=raw_norm_agg)
        if result is None and search_content != content:
            result = find_excerpt_in_raw(content, raw_full, raw_norm, used_ranges, norm_map=norm_map, raw_norm_agg=raw_norm_agg)

        if result is None:
            # 进 skipped_for_future
            failed.append({'idx': i+1, 'content': content[:60], 'group_id': q.get('group_id')})
            skipped_idx.append(i)
            skip_entry = {
                'reason': 'v318_no_raw_match',
                'original_question': q,
                '_v318_note': 'raw_with_omath.txt 中未找到对应段，可能 worker 当初用了 raw.txt 或自创题面',
            }
            skipped_for_future.append(skip_entry)
            continue

        norm_agg_start, norm_agg_end, excerpt = result
        # 验证 fingerprint
        if not fingerprint_exists_in_raw(excerpt, raw_full):
            # 截断头尾再试：去掉末尾换行/空白后再看
            excerpt2 = excerpt.strip()
            if not fingerprint_exists_in_raw(excerpt2, raw_full):
                failed.append({'idx': i+1, 'content': content[:60], 'reason': 'fingerprint fail'})
                skipped_idx.append(i)
                skip_entry = {
                    'reason': 'v318_no_raw_match',
                    'original_question': q,
                    '_v318_note': 'raw_with_omath.txt 中找到候选但 fingerprint 校验失败',
                }
                skipped_for_future.append(skip_entry)
                continue
            excerpt = excerpt2

        # 质量门：cn 中长度 ≥6 的"实质短语"（4+ 中文字）必须有一个出现在 excerpt 中
        cn_check = normalize_aggressive(content)
        en_check_full = normalize_aggressive(re.sub(r'\[OMATH:[^\]]*\]', '', excerpt))
        # 提取 cn 中 4-8 字中文片段（去 LaTeX/数字后）
        chinese_phrases = re.findall(r'[一-鿿]{4,}', content)
        chinese_phrases = sorted(set(chinese_phrases), key=lambda s: -len(s))
        phrase_match = False
        matched_phrase = None
        for ph in chinese_phrases:
            ph_norm = normalize_aggressive(ph)
            if len(ph_norm) >= 4 and ph_norm in en_check_full:
                phrase_match = True
                matched_phrase = ph_norm
                break
        # 兜底：cn 中 6+ 字的 substring（含数字混杂）出现在 en 中
        if not phrase_match and cn_check:
            for L in (10, 8, 6):
                if len(cn_check) < L: continue
                for off in range(0, len(cn_check) - L + 1):
                    seg = cn_check[off:off+L]
                    if seg in en_check_full:
                        phrase_match = True
                        matched_phrase = seg
                        break
                if phrase_match: break
        if not phrase_match:
            failed.append({'idx': i+1, 'content': content[:60], 'reason': 'no shared phrase'})
            skipped_idx.append(i)
            skip_entry = {
                'reason': 'v318_no_raw_match',
                'original_question': q,
                '_v318_note': '命中位置 excerpt 与 content 无共享短语 (≥4 中文/≥6 混杂)',
            }
            skipped_for_future.append(skip_entry)
            continue

        q['_raw_excerpt'] = excerpt
        # 占用 range 用较短长度（防止下一题被错挡）
        cover = min(norm_agg_end - norm_agg_start, 50)
        used_ranges.append((norm_agg_start, norm_agg_start + cover))
        anchors[i] = (norm_agg_start, norm_agg_start + cover)
        filled += 1
        new_questions.append(q)

    batch['questions'] = new_questions

    if not dry_run:
        batch_path.write_text(json.dumps(batch, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        # 双写到 question_bank
        qbank_path = QBANK / batch_path.name
        if qbank_path.exists() or True:
            qbank_path.parent.mkdir(parents=True, exist_ok=True)
            qbank_path.write_text(json.dumps(batch, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

    return {
        'filled': filled,
        'skipped': len(skipped_idx),
        'failed': failed,
    }


if __name__ == '__main__':
    targets = [
        'realpaper_g6_math_beishida_zhuanxiang_xuanze_yi_001.json',
        'realpaper_g6_math_beishida_xsc_zdzx_001.json',
        'realpaper_g6_math_beishida_xsc_zdzx_002.json',
        'realpaper_g6_math_beishida_xsc_yati_jingxuan_001.json',
        'realpaper_g6_math_beishida_zhuanxiang_xuanze_er_001.json',
        'realpaper_g6_math_beishida_xsc_baoan_003.json',
        'realpaper_g6_math_beishida_zhuanxiang_jieda_001.json',
        'realpaper_g6_math_beishida_zhuanxiang_tiankong_001.json',
        'realpaper_g6_math_beishida_xsc_longgang_002.json',
        'realpaper_g6_math_beishida_xsc_luohu_001.json',
        'realpaper_g6_math_beishida_xsc_nanshan_001.json',
        'realpaper_g6_math_beishida_zhuanxiang_xuanze_san_001.json',
        'realpaper_g6_chinese_bubian_qm_longgang_002.json',
        'realpaper_g6_math_beishida_xsc_baoan_001.json',
        'realpaper_g6_math_beishida_xsc_baoan_002.json',
    ]
    if len(sys.argv) > 1 and sys.argv[1] == '--one':
        targets = [sys.argv[2]]

    dry_run = '--dry' in sys.argv

    total_filled = 0
    total_skipped = 0
    summary_lines = []
    for fn in targets:
        p = ASSETS / fn
        r = process_batch(p, dry_run=dry_run)
        total_filled += r.get('filled', 0)
        total_skipped += r.get('skipped', 0)
        line = f'{fn[:60]:60} filled={r.get("filled",0):3} skipped={r.get("skipped",0):2}'
        if r.get('error'):
            line += f' ERROR={r["error"]}'
        summary_lines.append(line)
        if r.get('failed'):
            for f in r['failed'][:5]:
                summary_lines.append(f'   FAIL idx={f.get("idx")} content={f.get("content")!r}')
    print('\n'.join(summary_lines))
    print(f'\nTOTAL filled={total_filled} skipped={total_skipped}')
