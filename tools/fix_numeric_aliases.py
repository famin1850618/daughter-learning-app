#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fix_numeric_aliases — V3.24.8 (2026-05-18)
扫 batch JSON：答案是单个中文数字 → 自动加阿拉伯数字 alt_answer（双向兼容）。
按 feedback-realpaper §3：纯数字答案必须给 alt_answers 列等价写法。

反例：xsc_shenzhen_001 q[8] 端午粽子题答案"三"，学生答"3" 被判错（2026-05-18 Famin 反馈）。

扫描范围：assets/data/batches + question_bank 双写。
patch 时自动同步 index.json batch_hash（V3.24.6→7 教训）。

Usage:
  python3 tools/fix_numeric_aliases.py          # dry run
  python3 tools/fix_numeric_aliases.py --patch  # 实际写入
"""
import json
import glob
import os
import sys
import hashlib

ROOT = '/home/faminwsl/daughter_learning_app'
BATCH_GLOB = os.path.join(ROOT, 'assets/data/batches/realpaper_g6_*.json')

ZH = '零一二三四五六七八九十'
ZH_TO_ARABIC = {z: str(i) if i < 10 else '10' for i, z in enumerate(ZH)}
ARABIC_TO_ZH = {v: k for k, v in ZH_TO_ARABIC.items()}


def existing_alts(q):
    raw = q.get('alt_answers')
    if not raw:
        return []
    if isinstance(raw, list):
        return [str(x).strip() for x in raw]
    return [s.strip() for s in str(raw).split(';') if s.strip()]


def needs_fix(q):
    """返回需要添加的 alt 列表 (阿拉伯/中文双向)"""
    if q.get('type') != 'fill':
        return []
    ans = (q.get('answer') or '').strip()
    if not ans:
        return []
    alts = existing_alts(q)
    to_add = []
    # 中文单数字 → 加阿拉伯
    if ans in ZH and ZH_TO_ARABIC[ans] not in alts and ZH_TO_ARABIC[ans] != ans:
        to_add.append(ZH_TO_ARABIC[ans])
    # 阿拉伯单数字 0-10 → 加中文
    if ans in ARABIC_TO_ZH and ARABIC_TO_ZH[ans] not in alts and ARABIC_TO_ZH[ans] != ans:
        # 仅当答案语义是"数量/个数/种数"时加中文（避免给 "x=3" 这种代数答案加"三"）
        content = q.get('content') or ''
        if any(kw in content for kw in ['种', '共有', '一共', '几个', '多少', '几种', '几次', '几名', '几只']):
            to_add.append(ARABIC_TO_ZH[ans])
    return to_add


def main(patch=False):
    files = sorted(glob.glob(BATCH_GLOB))
    n_total_fix = 0
    patched_sources = set()
    for fp in files:
        bd = json.load(open(fp))
        qs = bd.get('questions', [])
        changed = False
        for i, q in enumerate(qs):
            adds = needs_fix(q)
            if not adds:
                continue
            old_alts = existing_alts(q)
            new_alts = old_alts + adds
            if patch:
                qs[i]['alt_answers'] = ';'.join(new_alts) if old_alts else ';'.join(adds)
                changed = True
            n_total_fix += 1
            print(f'  {os.path.basename(fp)} q[{i}] ans={q.get("answer")!r} + alt={adds}')
        if patch and changed:
            with open(fp, 'w') as f:
                json.dump(bd, f, ensure_ascii=False, indent=2)
            qb_fp = fp.replace('/assets/data/batches/', '/question_bank/')
            if os.path.exists(qb_fp):
                with open(qb_fp, 'w') as f:
                    json.dump(bd, f, ensure_ascii=False, indent=2)
            patched_sources.add(bd.get('source', ''))

    print()
    print(f'共 {n_total_fix} 道需要补 alt_answers')
    if not patch:
        print('Dry run: 加 --patch 实际写入')
        return

    # 同步 index.json batch_hash + bump version (V3.24.6→7 教训)
    if patched_sources:
        idx_path = os.path.join(ROOT, 'question_bank/index.json')
        with open(idx_path) as f:
            idx = json.load(f)
        for b in idx['batches']:
            src = b.get('source', '')
            if src not in patched_sources:
                continue
            path = os.path.join(ROOT, f'question_bank/{src}.json')
            with open(path, 'rb') as f:
                actual = hashlib.sha1(f.read()).hexdigest()
            if b.get('batch_hash') != actual:
                b['batch_hash'] = actual
        idx['version'] = idx.get('version', 0) + 1
        with open(idx_path, 'w') as f:
            json.dump(idx, f, ensure_ascii=False, indent=2)
        print(f'index.json: 同步 {len(patched_sources)} batch_hash, version → {idx["version"]}')


if __name__ == '__main__':
    main(patch='--patch' in sys.argv)
