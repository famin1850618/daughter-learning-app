#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
D2 Math Fallback V1 — V3.24.6 (2026-05-18)
处理 d2_math_review_v4.jsonl 里 52 道 unconfident（high_variance + anchor_disagree）的 round=null。

按 Famin 2026-05-18 难度分类执行授权（feedback-realpaper §5）自主决定 fallback 规则：

规则：
- anchor_disagree (32 道) → 用 v2_anchor_round（anchor 是 Famin verify 过的 ground truth）
- high_variance   (20 道) → 用 5 维 median（max combine 单维拉满不可信）

预期分布：30+11=41 R1 / 9 R2 / 2 R4 = 52 道

输出：直接 patch assets + question_bank 双写。
"""
import json
import glob
import os
import sys
import statistics
from collections import Counter, defaultdict

ROOT = '/home/faminwsl/daughter_learning_app'
BATCH_GLOB = os.path.join(ROOT, 'assets/data/batches/realpaper_g6_math_*.json')
V4_PATH = os.path.join(ROOT, 'calibration_log/d2_math_review_v4.jsonl')


def compute_fallback(rec: dict) -> tuple:
    """返回 (fallback_round, reason)"""
    flag = rec.get('v2_flag')
    if flag == 'anchor_disagree':
        ar = rec.get('v2_anchor_round')
        if ar is not None:
            return (ar, f'anchor_disagree → anchor_round R{ar}')
        # 极端 fallback：无 anchor 时用 median
    if flag == 'high_variance' or rec.get('v2_anchor_round') is None:
        dims = rec.get('v2_round_per_dim', {})
        vals = [v for v in dims.values() if v is not None]
        if vals:
            m = statistics.median(vals)
            mi = int(m) if m == int(m) else int(round(m))
            return (mi, f'high_variance → 5维 median R{mi}')
    return (None, 'no fallback rule')


def main(patch: bool = False):
    # 读 V4 jsonl 索引
    v4_by_ref = {}
    with open(V4_PATH) as f:
        for line in f:
            r = json.loads(line)
            v4_by_ref[r['question_ref']] = r

    files = sorted(glob.glob(BATCH_GLOB))
    n_total_null = 0
    n_patched = 0
    by_round = Counter()
    by_reason = Counter()
    decisions = []

    for fp in files:
        bd = json.load(open(fp))
        fname = os.path.basename(fp)
        qs = bd.get('questions', [])
        changed = False
        for i, q in enumerate(qs):
            if q.get('round') is not None:
                continue
            n_total_null += 1
            ref = f'{fname}#{i}'
            rec = v4_by_ref.get(ref)
            if not rec:
                decisions.append((ref, None, 'not_in_v4_jsonl'))
                continue
            r, reason = compute_fallback(rec)
            if r is None:
                decisions.append((ref, None, reason))
                continue
            decisions.append((ref, r, reason))
            by_round[r] += 1
            by_reason[reason.split(' → ')[0]] += 1
            if patch:
                qs[i]['round'] = r
                qs[i]['_round_source'] = 'd2_math_fallback_v1'
                changed = True
                n_patched += 1
        if patch and changed:
            with open(fp, 'w') as f:
                json.dump(bd, f, ensure_ascii=False, indent=2)
            qb_fp = fp.replace('/assets/data/batches/', '/question_bank/')
            if os.path.exists(qb_fp):
                with open(qb_fp, 'w') as f:
                    json.dump(bd, f, ensure_ascii=False, indent=2)
            print(f'  patched {fname}')

    print()
    print(f'数学 round=null 总数: {n_total_null}')
    print(f'按 fallback 规则可填: {sum(by_round.values())} 道')
    print(f'  round 分布: {dict(sorted(by_round.items()))}')
    print(f'  规则分布: {dict(by_reason.most_common())}')
    if patch:
        print(f'已 patched {n_patched} 道（assets + question_bank 双写）')
    else:
        print('Dry run: 没有 patch。加 --patch 实际写入。')


if __name__ == '__main__':
    do_patch = '--patch' in sys.argv
    main(patch=do_patch)
