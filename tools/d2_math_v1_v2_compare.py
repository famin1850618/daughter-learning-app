#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""V1 vs V2 D2 math reviewer comparison report."""
import json
import os
from collections import Counter, defaultdict

ROOT = '/home/faminwsl/daughter_learning_app'
V1 = os.path.join(ROOT, 'calibration_log/d2_math_review.jsonl')
V2 = os.path.join(ROOT, 'calibration_log/d2_math_review_v2.jsonl')


def load(path):
    out = []
    with open(path) as f:
        for line in f:
            try:
                out.append(json.loads(line))
            except json.JSONDecodeError:
                pass
    return out


def main():
    v1 = load(V1)
    v2 = load(V2)
    v1_idx = {r['question_ref']: r for r in v1}
    v2_idx = {r['question_ref']: r for r in v2}

    # Section A: total verdict + flag counts
    v1_verdict = Counter(r.get('verdict') for r in v1)
    v2_verdict = Counter(r.get('v2_verdict') for r in v2)
    v2_flag = Counter(r.get('v2_flag') for r in v2)

    def shift_dist(records, sug_field='suggested_round'):
        d = Counter()
        for r in records:
            o = r.get('original_round')
            s = r.get(sug_field) if sug_field in r else r.get('v2_suggested_round')
            if o is None or s is None:
                continue
            d[s - o] += 1
        return d

    v1_shift = shift_dist(v1, 'suggested_round')
    v2_shift = shift_dist(v2, 'v2_suggested_round')

    print('=== A. V1 vs V2 总体对比 ===')
    print(f'\nV1 verdict: {dict(v1_verdict)}')
    print(f'V2 verdict: {dict(v2_verdict)}')
    print(f'\nV2 flag:    {dict(v2_flag)}')
    print(f'\nV1 shift dist (sug-orig): {sorted(v1_shift.items())}')
    print(f'V2 shift dist (sug-orig): {sorted(v2_shift.items())}')

    # Section B: 15 Famin抽审 alignment
    famin = [
        ('realpaper_g6_math_beishida_kaodian_zonghe_001.json#15', 1, 3, 2),  # orig, v1_sug, famin
        ('realpaper_g6_math_beishida_kaodian_zonghe_002.json#10', 1, 3, 2),
        ('realpaper_g6_math_beishida_mokuai_jisuan_001.json#39', 3, 1, 3),
        ('realpaper_g6_math_beishida_xingjitongji_001.json#15', 3, 1, 3),
        ('realpaper_g6_math_beishida_zhouce_peiyou_004.json#18', 3, 1, 2),
        ('realpaper_g6_math_beishida_xshchu_xian_001.json#14', 3, 1, 1),  # famin = "R1偏上 算R2也行" → take R1 as agree
        ('realpaper_g6_math_beishida_zhouce_peiyou_003.json#16', 3, 1, 1),
        ('realpaper_g6_math_beishida_qizhong_003.json#16', 3, 1, 3),
        ('realpaper_g6_math_beishida_qimo_003.json#40', 3, 1, 4),
        ('realpaper_g6_math_beishida_qimo_003.json#36', 3, 1, 2),
        ('realpaper_g6_math_beishida_mokuai_daishu_001.json#34', 4, 1, 4),  # famin "至少R3，算R4也没问题"
        ('realpaper_g6_math_beishida_xshchu_beijing_001.json#28', 4, 1, 4),  # famin "至少R3"
        ('realpaper_g6_math_beishida_xshchu_xian_001.json#7',  4, 1, 2),
        ('realpaper_g6_math_beishida_xshchu_xian_001.json#36', 4, 2, 4),
        ('realpaper_g6_math_beishida_xshchu_xian_001.json#35', 4, 2, None),  # 拿不准 unsure
    ]

    print('\n=== B. V2 在 15 道 Famin 抽审上的表现 ===')
    print(f'{"ref":<60} {"orig":>4} {"v1":>3} {"v2":>3} {"famin":>5} {"v1≈f":>4} {"v2≈f":>4}')
    v1_align = 0
    v2_align = 0
    v1_close = 0  # within 1
    v2_close = 0
    n_marked = 0
    for ref, orig, v1_sug, famin_r in famin:
        rec_v2 = v2_idx.get(ref, {})
        v2_sug = rec_v2.get('v2_suggested_round')
        if famin_r is None:
            print(f'{ref:<60} {orig:>4} {v1_sug:>3} {v2_sug:>3} {"?":>5} {"-":>4} {"-":>4}')
            continue
        n_marked += 1
        v1_match = '✓' if v1_sug == famin_r else ' '
        v2_match = '✓' if v2_sug == famin_r else ' '
        v1_close_m = '~' if abs(v1_sug - famin_r) <= 1 else ' '
        v2_close_m = '~' if abs(v2_sug - famin_r) <= 1 else ' '
        if v1_sug == famin_r:
            v1_align += 1
        if v2_sug == famin_r:
            v2_align += 1
        if abs(v1_sug - famin_r) <= 1:
            v1_close += 1
        if abs(v2_sug - famin_r) <= 1:
            v2_close += 1
        print(f'{ref:<60} {orig:>4} {v1_sug:>3} {v2_sug:>3} {famin_r:>5} {v1_match}{v1_close_m:>3} {v2_match}{v2_close_m:>3}')
    print(f'\nV1 严格对齐: {v1_align}/{n_marked} | 1档以内: {v1_close}/{n_marked}')
    print(f'V2 严格对齐: {v2_align}/{n_marked} | 1档以内: {v2_close}/{n_marked}')

    # Section C: mental_flex distribution
    print('\n=== C. mental_flexibility 维度实际效果 ===')
    mf_dist = Counter(r['v2_dims']['mental_flexibility'] for r in v2)
    print(f'mental_flex 分布 (0-3): {dict(sorted(mf_dist.items()))}')

    # mf 救了 step_count 的题（mf round > step round, 且最终 max 来自 mf）
    mf_saves = []
    mf_lowers = []
    for r in v2:
        rpd = r['v2_round_per_dim']
        if rpd['step'] is None:
            continue
        # mf round > step round → mf saved (raised)
        if rpd['mental'] > rpd['step'] and rpd['mental'] == r['v2_combined']:
            mf_saves.append(r)
        # step round high but mf low (step >= 3 but mf == 1)
        if rpd['step'] >= 3 and rpd['mental'] == 1:
            mf_lowers.append(r)
    print(f'mental_flex 拉高 step_count 案例: {len(mf_saves)} 道')
    for r in mf_saves[:5]:
        print(f'  {r["question_ref"]} | step={r["v2_round_per_dim"]["step"]} mf={r["v2_round_per_dim"]["mental"]} | {r["content_preview"][:50]}')
    print(f'mental_flex 偏低 (step≥3, mf=1) 案例: {len(mf_lowers)} 道')
    for r in mf_lowers[:5]:
        print(f'  {r["question_ref"]} | step={r["v2_round_per_dim"]["step"]} mf={r["v2_round_per_dim"]["mental"]} | {r["content_preview"][:50]}')

    # Section D: high_variance flag
    print('\n=== D. high_variance flag (max-median≥2) ===')
    hv = [r for r in v2 if r.get('v2_flag') == 'high_variance']
    print(f'数量: {len(hv)} 道')
    for r in hv[:5]:
        print(f'  {r["question_ref"]} | dims={r["v2_round_per_dim"]} | {r["content_preview"][:50]}')

    # Section E: anchor_disagree
    print('\n=== E. anchor_disagree flag (computed vs anchor 差≥2) ===')
    ad = [r for r in v2 if r.get('v2_flag') == 'anchor_disagree']
    print(f'数量: {len(ad)} 道')
    for r in ad[:5]:
        print(f'  {r["question_ref"]} | computed=R{r["v2_combined"]} anchor={r["v2_anchor_used"]}(R{r["v2_anchor_round"]}) | {r["content_preview"][:50]}')


if __name__ == '__main__':
    main()
