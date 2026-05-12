#!/usr/bin/env python3
"""V3.21.3 数学 KP remap 脚本

按 V3.21 新 KP 清单（每章 5 + 其它）+ 综合练习一级 KP 规则归一所有数学 batch JSON。

变更：
1. chapter='小升初综合'/'中考综合' → chapter='综合练习', knowledge_point='综合练习'（单段）
2. KP category 名归一：
   - `比和比例/` → `比例/`
   - `正反比例/` → `正比例和反比例/`
   - `数学综合/` → `数学好玩/`
3. KP name 合并：
   - 圆柱与圆锥/圆柱的认识 + /圆锥的认识 → /圆柱圆锥的认识
   - 比例/化简比 + /求比值 → /化简比与求比值
4. 组合题 (form B) 子题 KP 异质 → 整组改 综合练习 单段
5. KP name 不在新清单 → category/其它

usage: python v321_math_kp_remap.py [--dry-run]
"""

import json
from pathlib import Path
import sys
import re

REPO = Path(__file__).resolve().parents[2]
BATCHES_DIR = REPO / 'tools/realpaper/batches'  # worker 工作目录
ASSETS_BATCHES = REPO / 'assets/data/batches'   # app bundled（CDN 同步源）

# V3.21 新清单（数学 g6）
VALID_KPS = {
    '圆柱与圆锥/圆柱圆锥的认识', '圆柱与圆锥/圆柱的表面积', '圆柱与圆锥/圆柱的体积',
    '圆柱与圆锥/圆锥的体积', '圆柱与圆锥/圆柱圆锥综合应用', '圆柱与圆锥/其它',
    '比例/比的意义', '比例/比例的意义', '比例/比例的基本性质',
    '比例/化简比与求比值', '比例/解比例', '比例/其它',
    '图形的运动/轴对称', '图形的运动/平移', '图形的运动/旋转',
    '图形的运动/图形放大缩小', '图形的运动/设计图案', '图形的运动/其它',
    '正比例和反比例/正比例的意义', '正比例和反比例/反比例的意义',
    '正比例和反比例/正反比例的判断', '正比例和反比例/比例尺', '正比例和反比例/比例应用题',
    '正比例和反比例/其它',
    '数学好玩/神奇的几何变换', '数学好玩/生活中的数学', '数学好玩/自行车里的数学',
    '数学好玩/探索图形规律', '数学好玩/数学实践', '数学好玩/其它',
    '总复习/数与代数综合', '总复习/图形与几何综合', '总复习/统计与可能性',
    '总复习/解决问题策略', '总复习/数学应用', '总复习/其它',
    '综合练习',  # 单段一级 KP
}

# 老 KP → 新 KP 映射
KP_RENAME = {
    # category 归一
    '比和比例/比的意义': '比例/比的意义',
    '比和比例/比例的意义': '比例/比例的意义',
    '比和比例/比例的基本性质': '比例/比例的基本性质',
    '比和比例/解比例': '比例/解比例',
    '比和比例/化简比': '比例/化简比与求比值',
    '比和比例/求比值': '比例/化简比与求比值',
    '正反比例/正比例的意义': '正比例和反比例/正比例的意义',
    '正反比例/反比例的意义': '正比例和反比例/反比例的意义',
    '正反比例/正反比例的判断': '正比例和反比例/正反比例的判断',
    '正反比例/比例尺': '正比例和反比例/比例尺',
    '正反比例/正反比例图象': '正比例和反比例/其它',
    '数学综合/神奇的几何变换': '数学好玩/神奇的几何变换',
    '数学综合/生活中的数学': '数学好玩/生活中的数学',
    # KP name 合并
    '圆柱与圆锥/圆柱的认识': '圆柱与圆锥/圆柱圆锥的认识',
    '圆柱与圆锥/圆锥的认识': '圆柱与圆锥/圆柱圆锥的认识',
    # 旧"综合练习/X" → 综合练习 单段
    '综合练习/小升初综合': '综合练习',
    '综合练习/中考综合': '综合练习',
}

# chapter rename
CHAPTER_RENAME = {
    '小升初综合': '综合练习',
    '中考综合': '综合练习',
}


def remap_kp(old_kp: str) -> str:
    """单题 KP 映射。"""
    if old_kp in KP_RENAME:
        return KP_RENAME[old_kp]
    if old_kp in VALID_KPS:
        return old_kp
    # 未在新清单 → 归 category/其它
    if '/' in old_kp:
        category = old_kp.split('/')[0]
        # category 也归一
        category = {'比和比例': '比例', '正反比例': '正比例和反比例', '数学综合': '数学好玩'}.get(category, category)
        candidate = f'{category}/其它'
        if candidate in VALID_KPS:
            return candidate
    # 无法归类 → 综合练习
    return '综合练习'


def process_batch(path: Path, dry_run: bool = False) -> dict:
    """处理 1 个 batch JSON，返回统计。"""
    batch = json.loads(path.read_text(encoding='utf-8'))
    stats = {
        'file': path.name,
        'total_q': len(batch.get('questions', [])),
        'changed': 0,
        'chapter_renamed': 0,
        'group_collapsed': 0,
    }

    # 1. chapter rename
    for q in batch.get('questions', []):
        old_chap = q.get('chapter', '')
        new_chap = CHAPTER_RENAME.get(old_chap, old_chap)
        if new_chap != old_chap:
            q['chapter'] = new_chap
            stats['chapter_renamed'] += 1

    # 2. 单题 KP remap
    for q in batch.get('questions', []):
        old_kp = q.get('knowledge_point', '')
        new_kp = remap_kp(old_kp)
        if new_kp != old_kp:
            q['knowledge_point'] = new_kp
            stats['changed'] += 1

    # 3. 组合题（form B）KP 异质化 → 整组 → 综合练习
    group_kps = {}
    for q in batch.get('questions', []):
        gid = q.get('group_id')
        if not gid:
            continue
        group_kps.setdefault(gid, []).append(q)
    for gid, subs in group_kps.items():
        kps = set(q.get('knowledge_point', '') for q in subs)
        if len(kps) > 1:
            # 异质 → 整组改单段
            # 启发式：若组内所有子题 chapter 同一个（如圆柱与圆锥），则归该 chapter/其它
            # 否则跨章 → 综合练习单段
            chapters = set(q.get('chapter', '') for q in subs)
            if len(chapters) == 1:
                chap = chapters.pop()
                target_kp = f'{chap}/其它' if f'{chap}/其它' in VALID_KPS else '综合练习'
            else:
                target_kp = '综合练习'
            # chapter 也归一（若 target 是综合练习）
            target_chap = '综合练习' if target_kp == '综合练习' else subs[0].get('chapter', '')
            for q in subs:
                q['knowledge_point'] = target_kp
                if target_kp == '综合练习':
                    q['chapter'] = target_chap
            stats['group_collapsed'] += 1

    # 4. 写回
    if not dry_run:
        new_text = json.dumps(batch, ensure_ascii=False, indent=2)
        path.write_text(new_text, encoding='utf-8')

    return stats


def main():
    dry_run = '--dry-run' in sys.argv
    print(f'{"DRY RUN" if dry_run else "EXECUTING"} V3.21.3 数学 KP remap')
    print(f'扫 {BATCHES_DIR}/realpaper_g6_math_*.json + {ASSETS_BATCHES}/realpaper_g6_math_*.json\n')

    grand_total = {'files': 0, 'q': 0, 'changed': 0, 'chapter_renamed': 0, 'group_collapsed': 0}
    for d in [BATCHES_DIR, ASSETS_BATCHES]:
        if not d.exists():
            print(f'  跳过不存在目录 {d}')
            continue
        files = sorted(d.glob('realpaper_g6_math_*.json'))
        print(f'\n=== {d.name}: {len(files)} 文件 ===')
        for f in files:
            s = process_batch(f, dry_run)
            grand_total['files'] += 1
            grand_total['q'] += s['total_q']
            grand_total['changed'] += s['changed']
            grand_total['chapter_renamed'] += s['chapter_renamed']
            grand_total['group_collapsed'] += s['group_collapsed']
            if s['changed'] or s['chapter_renamed'] or s['group_collapsed']:
                print(f"  {s['file']}: {s['total_q']}q, "
                      f"KP改{s['changed']}, chap改{s['chapter_renamed']}, group合并{s['group_collapsed']}")

    print(f'\n=== 总计 ===')
    print(f'  文件 {grand_total["files"]}')
    print(f'  题目 {grand_total["q"]}')
    print(f'  KP 改 {grand_total["changed"]}')
    print(f'  chapter 改 {grand_total["chapter_renamed"]}')
    print(f'  组合题合并 {grand_total["group_collapsed"]}')


if __name__ == '__main__':
    main()
