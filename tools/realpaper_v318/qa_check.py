#!/usr/bin/env python3
"""检查所填 _raw_excerpt 与 content 的对齐质量。"""
import json
import sys
import re
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from fill_raw_excerpt import normalize_aggressive, ASSETS, QBANK

def alignment_score(content: str, excerpt: str) -> tuple[float, str]:
    """对齐度：去除 raw 内 OMATH 标记后做对齐。
    取 cn 头若干字符，看 raw_norm 中包含程度。
    返回 (0..1 score, reason)
    """
    # raw 端去 OMATH 标记
    excerpt_clean = re.sub(r'\[OMATH:[^\]]*\]', '', excerpt)
    # 也去掉子题号 (1) （2）
    cn = normalize_aggressive(content)
    en = normalize_aggressive(excerpt_clean)
    if not cn or not en:
        return 0.0, 'empty'

    # excerpt 应包含 cn 头的某种连续片段
    matched = 0
    cn_head = cn[:20] if len(cn) >= 20 else cn
    # 滑窗：找 en 中包含的 cn_head 子串最长
    best_len = 0
    for L in range(len(cn_head), 2, -1):
        for off in range(0, len(cn_head) - L + 1):
            seg = cn_head[off:off+L]
            if seg in en:
                best_len = max(best_len, L)
                break
        if best_len >= L:
            break
    score = best_len / max(len(cn_head), 1)
    return score, f'best_match_len={best_len}/cn_head={len(cn_head)}'


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

low_score = []
for fn in targets:
    p = ASSETS / fn
    b = json.load(open(p))
    qs = b['questions']
    for i, q in enumerate(qs):
        excerpt = q.get('_raw_excerpt', '')
        content = q.get('content', '')
        if not excerpt:
            continue
        score, reason = alignment_score(content, excerpt)
        if score < 0.4:
            low_score.append((fn, i+1, score, content[:60], excerpt[:60]))

print(f'TOTAL low-score (<0.4): {len(low_score)}')
for fn, idx, sc, c, e in low_score[:50]:
    print(f'  {fn[-50:]:50} idx={idx} score={sc:.2f}')
    print(f'    content: {c!r}')
    print(f'    excerpt: {e!r}')
