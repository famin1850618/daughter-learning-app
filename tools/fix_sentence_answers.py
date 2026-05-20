#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fix_sentence_answers — V3.24.9 (2026-05-21)
处理 fill 答案是"整句话"或"多空合并"导致严格判错的题。

Famin 2026-05-21 反馈：「数学应用题答案是一句话（如'小张的身高是 175 厘米'），
学生只答数字被判错」。扫数学 fill 找疑似题，按策略修：

策略（按 feedback-review-mechanism "判错靠人工审核兜底"）：
- 整句单 value（"12点40分"/"图上距离6厘米处"）→ alt_answers 补短形式
- 多空合并（"奇思136元,妙想36元"）→ 标 is_semi_subjective=true 让家长审核兜底

不改 answer 本身（feedback-realpaper §8 不脑补禁推理）。
"""
import json
import glob
import os
import sys
import re
import hashlib

ROOT = '/home/faminwsl/daughter_learning_app'
BATCH_GLOB = os.path.join(ROOT, 'assets/data/batches/realpaper_g6_*.json')

# 单值 + 冗余文字 → 直接 alt 补
SINGLE_VALUE_PATCHES = {
    # (source, q_idx): [alt_answers list]
    ('realpaper_g6_math_beishida_zhuanxiang_jieda_001', 50): ['12:40', '40分', '40'],
    ('realpaper_g6_math_beishida_zhuanxiang_jieda_001', 48): ['6厘米', '6', '6 厘米', '6厘米处'],
}

# 多空合并答案 → 标 is_semi_subjective 让家长审核兜底
SEMI_SUBJ_PATCHES = [
    ('realpaper_g6_math_beishida_qm_longhua_001', 21),
    ('realpaper_g6_math_beishida_xsc_baoan_001', 6),
    ('realpaper_g6_math_beishida_zhuanxiang_jieda_001', 13),
    ('realpaper_g6_math_beishida_zhuanxiang_jieda_001', 14),
    ('realpaper_g6_math_beishida_zhuanxiang_jieda_001', 43),
]


def existing_alts(q):
    raw = q.get('alt_answers')
    if not raw: return []
    if isinstance(raw, list): return [str(x).strip() for x in raw]
    return [s.strip() for s in str(raw).split(';') if s.strip()]


def main(patch=False):
    files = sorted(glob.glob(BATCH_GLOB))
    src_to_path = {}
    for fp in files:
        bd = json.load(open(fp))
        src_to_path[bd.get('source', '')] = fp

    n_alt_added = 0
    n_semi_set = 0
    patched_sources = set()

    for (src, idx), alts in SINGLE_VALUE_PATCHES.items():
        fp = src_to_path.get(src)
        if not fp:
            print(f'  WARN: source not found {src}')
            continue
        bd = json.load(open(fp))
        q = bd['questions'][idx]
        old = existing_alts(q)
        new = list(dict.fromkeys(old + alts))
        if patch:
            q['alt_answers'] = ';'.join(new)
        n_alt_added += 1
        print(f'  alt: {src} q[{idx}] ans={q.get("answer")!r}')
        print(f'    + alt: {alts}')
        if patch:
            with open(fp, 'w') as f: json.dump(bd, f, ensure_ascii=False, indent=2)
            qb_fp = fp.replace('/assets/data/batches/', '/question_bank/')
            if os.path.exists(qb_fp):
                with open(qb_fp, 'w') as f: json.dump(bd, f, ensure_ascii=False, indent=2)
            patched_sources.add(src)

    for src, idx in SEMI_SUBJ_PATCHES:
        fp = src_to_path.get(src)
        if not fp:
            print(f'  WARN: source not found {src}')
            continue
        bd = json.load(open(fp))
        q = bd['questions'][idx]
        if q.get('is_semi_subjective'):
            print(f'  skip (already semi-subj): {src} q[{idx}]')
            continue
        if patch:
            q['is_semi_subjective'] = True
        n_semi_set += 1
        print(f'  semi-subj: {src} q[{idx}] ans={q.get("answer")!r}')
        if patch:
            with open(fp, 'w') as f: json.dump(bd, f, ensure_ascii=False, indent=2)
            qb_fp = fp.replace('/assets/data/batches/', '/question_bank/')
            if os.path.exists(qb_fp):
                with open(qb_fp, 'w') as f: json.dump(bd, f, ensure_ascii=False, indent=2)
            patched_sources.add(src)

    print()
    print(f'共加 alt: {n_alt_added}，标 semi-subjective: {n_semi_set}')

    if not patch:
        print('Dry run: 加 --patch 实际写入')
        return

    # 同步 manifest hash + bump version (V3.24.6→7 教训)
    if patched_sources:
        idx_path = os.path.join(ROOT, 'question_bank/index.json')
        with open(idx_path) as f: idx_j = json.load(f)
        for b in idx_j['batches']:
            src = b.get('source', '')
            if src not in patched_sources: continue
            path = os.path.join(ROOT, f'question_bank/{src}.json')
            with open(path, 'rb') as f:
                actual = hashlib.sha1(f.read()).hexdigest()
            if b.get('batch_hash') != actual:
                b['batch_hash'] = actual
        idx_j['version'] = idx_j.get('version', 0) + 1
        with open(idx_path, 'w') as f: json.dump(idx_j, f, ensure_ascii=False, indent=2)
        print(f'index.json: 同步 {len(patched_sources)} batch_hash, version → {idx_j["version"]}')


if __name__ == '__main__':
    main(patch='--patch' in sys.argv)
