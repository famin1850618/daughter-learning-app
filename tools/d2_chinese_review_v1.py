#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
D2 V1 Chinese Reviewer — V3.24.5 (2026-05-18)
语文 round 阶段 2 脚本化（让语文从阶段 1 → 阶段 2）

设计依据：
- docs/rubric_chinese.md（§2.1 降档信号 / §2.2 升档信号 / §2.3 unsure）
- docs/anchor_questions_g6_chinese.json（18 有效锚点 + 2 disabled）
- feedback-realpaper §5 Round 判定三阶段渐进沉淀

4 维 + rubric signal override（仿数学 V4 思路简化）：
  1. step_count             理解层级（背诵=1 / 辨析=2 / 概括=3 / 鉴赏综合=4）
  2. distractor_density     选项混淆度（fill=0 / 普通 choice=0.3 / 嵌套=0.9）
  3. kp_span                跨知识点数（单 KP=1 / 综合练习=4）
  4. data_complexity        素材复杂度（短句=0.2 / 段落=0.5 / 长材料=0.8）

Combine：每维度 → round → max(rounds)
Variance：max - median >= 2 → high_variance flag
Rubric override：强信号覆盖（褒贬明显→R1 / 嵌套选项→R4）
Anchor 验证：|computed - anchor.round| >= 2 → anchor_disagree flag

Verdict：
- no_change（== original）
- suggest_change（|diff|=1）
- flag_review（|diff|>=2）

仅 confident 题（无任何 flag）建议 patch；其余留 round=null 等 Famin 抽审。

Outputs:
- calibration_log/d2_chinese_review_v1.jsonl（详细 reasoning）
- 可选 --patch：把 confident 题写回 batch JSON round 字段（仅当 batch 原 round 是 null）
"""
import json
import glob
import re
import os
import math
import sys
from datetime import datetime
from collections import defaultdict, Counter

ROOT = '/home/faminwsl/daughter_learning_app'
BATCH_GLOB = os.path.join(ROOT, 'assets/data/batches/realpaper_g6_chinese_*.json')
# patch 时双写 question_bank（CDN 真源）保持一致
ANCHOR_PATH = os.path.join(ROOT, 'docs/anchor_questions_g6_chinese.json')
RUBRIC_PATH = os.path.join(ROOT, 'docs/rubric_chinese.md')
OUT_PATH = os.path.join(ROOT, 'calibration_log/d2_chinese_review_v1.jsonl')


# =========================================================================
# 维度评分
# =========================================================================

# §2.1 降档信号关键词
DOWNGRADE_PATTERNS = {
    'praise_vs_blame': re.compile(r'(褒贬|实事求是|不懂装装|表里如一|阳奉阴违)'),
    'three_short_one_long': re.compile(r''),  # 由选项长度判
    'in_class_authors': re.compile(r'(鲁迅|老舍|巴金|朱自清|笛福|马克.?吐温|莫泊桑|安徒生|格林兄弟|海伦凯勒|海明威|奥斯特洛夫斯基|罗贯中|施耐庵|吴承恩|曹雪芹)'),
    'narrow_candidates': re.compile(r'下列.{0,3}成语|从.{0,5}中选|根据.{0,5}选'),
}

# §2.2 升档信号关键词
UPGRADE_PATTERNS = {
    'nested_options': re.compile(r'(以上.{0,3}都|包括|涵盖|前两项|前三项|④③②|包含关系)'),
    'multi_blank_xuci': re.compile(r'(莫不|无不|何尝).{0,30}(莫不|无不|何尝)'),  # 同虚词重复
    'appreciation': re.compile(r'(鉴赏|对仗|平仄|工对|拗救|赏析)'),
    'cross_culture_4': re.compile(r'(《.+?》.{0,30}){4,}'),  # 多书名号引用
    'emotion_curve': re.compile(r'(情感曲线|情感变化|情感发展|不同阶段)'),
    'paragraph_link': re.compile(r'(承上启下|过渡段|结构层次|文章脉络|段落衔接)'),
}

# §2.3 unsure 信号
UNSURE_PATTERNS = {
    'no_passage': re.compile(r'(阅读.?下面|阅读.?以下|阅读.?短文|阅读.?选文)'),
}

# chapter / kp → step_count 基线
CHAPTER_STEP_BASELINE = {
    '字词': 1,
    '古诗文': 1,
    '文学常识': 1,
    '句子和语法': 2,
    '阅读理解': 3,
    '综合练习': 2,  # 默认 2，看 content 升降
    '写作': 3,  # writing pending 暂不入库，此处兜底
}

KP_STEP_DELTA = {
    # 升 step_count 的 KP（精确名 + 模糊匹配）
    '主旨': 1,    # 阅读理解/主旨概括
    '段意': 1,    # 阅读理解/段意综合
    '鉴赏': 2,    # 鉴赏评价
    '修辞': 0,    # 默认 chapter baseline，不调
    '近义词': 1,  # 字词/近义词辨析（baseline 1 → 2）
    '病句': 1,    # 句子和语法/病句（baseline 2 → 3？保守 +1）
    '虚词': 1,
}


def text_of(q: dict) -> str:
    """合并 content + options 作为文本特征源"""
    parts = [q.get('content') or '']
    for opt in (q.get('options') or []):
        parts.append(opt or '')
    return '\n'.join(parts)


RECITE_KEYWORDS = re.compile(r'(背诵|默写|按.{0,3}填空|填上.{0,3}句子|根据.{0,3}提示.{0,3}填|补全.{0,3}诗句|完成.{0,3}默写)')


def calc_step_count(q: dict) -> int:
    chapter = q.get('chapter', '')
    kp = q.get('knowledge_point') or q.get('kp', '') or ''
    qtype = q.get('type', '')
    txt = text_of(q)
    content = q.get('content', '') or ''

    # 基线
    base = CHAPTER_STEP_BASELINE.get(chapter, 2)

    # V1 修复：古诗"鉴赏"类 kp 但题型是背诵默写 → 降回 1
    # （KP 命名空间含"鉴赏"但题目其实考默写，不应升档）
    if '古诗文' in chapter and (qtype == 'fill' or RECITE_KEYWORDS.search(content)):
        return 1

    # KP 调整（仅对非默写题）
    for key, delta in KP_STEP_DELTA.items():
        if key in kp:
            base += delta
            break

    # rubric §2.2 升档信号 → 强制 4
    for pat in UPGRADE_PATTERNS.values():
        if pat.search(txt):
            base = max(base, 4)
            break

    # rubric §2.1 降档信号 → 强制 1
    if DOWNGRADE_PATTERNS['praise_vs_blame'].search(txt):
        base = min(base, 1)
    elif DOWNGRADE_PATTERNS['in_class_authors'].search(txt):
        base = min(base, 1)

    return max(1, min(4, base))


def calc_distractor_density(q: dict) -> float:
    if q.get('type') != 'choice':
        return 0.0
    options = q.get('options') or []
    if len(options) <= 1:
        return 0.0

    txt = text_of(q)

    # 嵌套式选项关系 → 升 0.9
    if UPGRADE_PATTERNS['nested_options'].search(txt):
        return 0.9

    # 三短一长（最长 / 平均长 >= 2x）→ 降 0.15
    lens = [len(o or '') for o in options]
    if lens and max(lens) >= 2 * (sum(lens) / len(lens)):
        return 0.15

    # 褒贬对比 → 0.1（明显排除）
    if DOWNGRADE_PATTERNS['praise_vs_blame'].search(txt):
        return 0.1

    # 课内作家 4 选 1 + 嵌套常识 → 0.6
    if UPGRADE_PATTERNS['cross_culture_4'].search(txt):
        return 0.6

    # 多空虚词鉴赏 → 0.8
    if UPGRADE_PATTERNS['multi_blank_xuci'].search(txt):
        return 0.8

    # 默认按选项数量
    if len(options) >= 5:
        return 0.5
    if len(options) >= 4:
        return 0.35
    return 0.2


def calc_kp_span(q: dict) -> int:
    chapter = q.get('chapter', '')
    kp = q.get('knowledge_point') or q.get('kp', '') or ''
    if chapter == '综合练习':
        return 4  # 跨章节归综合练习 = 跨多 KP
    # kp 路径含 '综合' → 跨内部 KP
    if '综合' in kp:
        return 3
    # group_id 题组（多子题）→ +1 跨度
    gid = q.get('group_id')
    if gid:
        return 2
    return 1


def calc_data_complexity(q: dict) -> float:
    content = q.get('content', '') or ''
    explanation = q.get('explanation', '') or ''
    n = len(content)

    if n < 80:
        c = 0.2
    elif n < 300:
        c = 0.5
    else:
        c = 0.8

    # 阅读理解类带原文 → +0.1
    if UNSURE_PATTERNS['no_passage'].search(content) and len(content) > 400:
        c = min(1.0, c + 0.1)

    return c


# ----------------- 维度 → round 映射 -----------------

def step_round(sc: int) -> int:
    return max(1, min(4, sc))


def distractor_round(dd: float) -> int:
    if dd < 0.15: return 1
    if dd < 0.4: return 2
    if dd < 0.7: return 3
    return 4


def kp_round(ks: int) -> int:
    return max(1, min(4, ks))


def data_round(dc: float) -> int:
    # V1 修：长材料不直接 R4（rubric §2.3 反推：有材料 ≠ 鉴赏鉴赏）。
    # data_complexity 顶到 R3 即可，R4 留给 rubric §2.2 升档信号触发。
    if dc < 0.3: return 1
    if dc < 0.55: return 2
    return 3


# ----------------- combine + flag -----------------

def combine_rounds(dims: dict) -> dict:
    """max combine + variance flag"""
    rounds = [r for r in dims.values() if r is not None]
    if not rounds:
        return {'combined_round': None, 'verdict': 'no_data'}
    max_r = max(rounds)
    sorted_r = sorted(rounds)
    median_r = sorted_r[len(sorted_r) // 2]
    verdict = 'confident'
    if max_r - median_r >= 2:
        verdict = 'high_variance'
    return {'combined_round': max_r, 'verdict': verdict, 'median': median_r}


# ----------------- rubric override -----------------

def apply_rubric_override(q: dict, base_round: int) -> tuple:
    """返回 (final_round, signal_applied or None)
    强信号直接覆盖 base_round。"""
    txt = text_of(q)

    # §2.2 升档信号
    for sig, pat in UPGRADE_PATTERNS.items():
        if pat.search(txt):
            return (4, f'upgrade:{sig}')

    # §2.1 降档信号
    if DOWNGRADE_PATTERNS['praise_vs_blame'].search(txt):
        return (1, 'downgrade:praise_vs_blame')
    if DOWNGRADE_PATTERNS['in_class_authors'].search(txt):
        return (1, 'downgrade:in_class_authors')

    # 三短一长（不强制覆盖，仅 reasoning 记录）→ 提示性降到 R2
    options = q.get('options') or []
    if options and len(options) >= 4:
        lens = [len(o or '') for o in options]
        if max(lens) >= 2 * (sum(lens) / len(lens)) and base_round >= 3:
            return (2, 'downgrade:three_short_one_long')

    return (base_round, None)


# ----------------- anchor 验证 -----------------

def load_anchors() -> list:
    with open(ANCHOR_PATH) as f:
        d = json.load(f)
    return [a for a in d.get('anchors', []) if not a.get('_famin_review', {}).get('disabled')]


def find_nearest_anchor(q: dict, anchors: list, computed_round: int) -> dict:
    """同 chapter 优先 + round ±1 内匹配。"""
    chapter = q.get('chapter', '')
    candidates = [a for a in anchors if abs(a['round'] - computed_round) <= 1]
    same_chapter = [a for a in candidates if a.get('chapter') == chapter]
    if same_chapter:
        return same_chapter[0]
    return candidates[0] if candidates else None


# =========================================================================
# main pipeline
# =========================================================================

def review_question(q: dict, anchors: list) -> dict:
    """对一道题跑全流程，返回 review record dict。"""
    sc = calc_step_count(q)
    dd = calc_distractor_density(q)
    ks = calc_kp_span(q)
    dc = calc_data_complexity(q)

    round_per_dim = {
        'step': step_round(sc),
        'distractor': distractor_round(dd),
        'kp': kp_round(ks),
        'data': data_round(dc),
    }
    combined = combine_rounds(round_per_dim)
    base_round = combined['combined_round']

    # rubric override
    final_round, signal = apply_rubric_override(q, base_round)
    if signal:
        rubric_flag = signal
        verdict = 'rubric_override' if final_round != base_round else combined['verdict']
    else:
        rubric_flag = None
        verdict = combined['verdict']

    # anchor 验证
    anchor = find_nearest_anchor(q, anchors, final_round)
    anchor_id = anchor.get('anchor_id') if anchor else None
    anchor_round = anchor.get('round') if anchor else None
    if anchor and abs(final_round - anchor_round) >= 2 and verdict == 'confident':
        verdict = 'anchor_disagree'

    # 与 original 比较
    original_round = q.get('round')
    if original_round is None:
        v_verdict = 'fill_null' if verdict == 'confident' else f'unconfident_{verdict}'
    elif original_round == final_round:
        v_verdict = 'no_change'
    elif abs(original_round - final_round) >= 2:
        v_verdict = 'flag_review'
    else:
        v_verdict = 'suggest_change'

    reasoning = (
        f'4维: step={sc}({round_per_dim["step"]}) distractor={dd:.2f}({round_per_dim["distractor"]}) '
        f'kp_span={ks}({round_per_dim["kp"]}) data_complexity={dc:.2f}({round_per_dim["data"]}) | '
        f'max={base_round}, median={combined.get("median")}'
    )
    if rubric_flag:
        reasoning += f' | rubric_override={rubric_flag}→R{final_round}'
    if anchor:
        reasoning += f' | anchor={anchor_id}(R{anchor_round})'

    return {
        'kp': q.get('knowledge_point') or q.get('kp', ''),
        'chapter': q.get('chapter', ''),
        'content_preview': (q.get('content') or '')[:80],
        'type': q.get('type'),
        'group_id': q.get('group_id'),
        'group_order': q.get('group_order'),
        'original_round': original_round,
        'suggested_round': final_round,
        'dims': {
            'step_count': sc,
            'distractor_density': round(dd, 3),
            'kp_span': ks,
            'data_complexity': round(dc, 3),
        },
        'round_per_dim': round_per_dim,
        'verdict': v_verdict,
        'flag': verdict,
        'rubric_signal': rubric_flag,
        'anchor_used': anchor_id,
        'anchor_round': anchor_round,
        'reasoning': reasoning,
    }


def group_unify(records: list) -> int:
    """同 group_id 子题统一 round（ceil 平均）。返回改写题数。"""
    groups = defaultdict(list)
    for r in records:
        gid = r.get('group_id')
        if gid:
            groups[gid].append(r)

    n_changed = 0
    for gid, recs in groups.items():
        if len(recs) <= 1:
            continue
        rounds = [r['suggested_round'] for r in recs if r.get('suggested_round') is not None]
        if not rounds:
            continue
        avg = sum(rounds) / len(rounds)
        unified = math.ceil(avg)
        for r in recs:
            old = r['suggested_round']
            r['suggested_round_before_group_unify'] = old
            r['suggested_round'] = unified
            r['reasoning'] += f' | group_unify: individual=R{old} → ceil(avg={avg:.2f}) → R{unified}'
            if old != unified:
                n_changed += 1
    return n_changed


def main(patch: bool = False):
    anchors = load_anchors()
    files = sorted(glob.glob(BATCH_GLOB))
    if not files:
        print('No chinese batches found')
        return

    records = []
    file_to_records = defaultdict(list)
    for fp in files:
        bd = json.load(open(fp))
        fname = os.path.basename(fp)
        for i, q in enumerate(bd.get('questions', [])):
            rec = review_question(q, anchors)
            rec['question_ref'] = f'{fname}#{i}'
            rec['_batch_path'] = fp
            rec['_q_index'] = i
            records.append(rec)
            file_to_records[fp].append(rec)

    n_unified = group_unify(records)

    # 统计
    n_total = len(records)
    verdict_counts = Counter(r['verdict'] for r in records)
    flag_counts = Counter(r['flag'] for r in records)
    null_input = sum(1 for r in records if r['original_round'] is None)
    confident_fill_null = sum(1 for r in records
                              if r['original_round'] is None and r['flag'] == 'confident')

    # 写 jsonl
    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    with open(OUT_PATH, 'w') as f:
        for r in records:
            out_r = {k: v for k, v in r.items() if not k.startswith('_')}
            out_r['timestamp'] = datetime.utcnow().isoformat() + 'Z'
            f.write(json.dumps(out_r, ensure_ascii=False) + '\n')

    print(f'语文 D2 V1: {n_total} 题')
    print(f'  原 round=null: {null_input} 题')
    print(f'  其中 confident（脚本可定档）: {confident_fill_null} 题')
    print(f'  group_unify 改写: {n_unified} 题')
    print(f'  verdict 分布: {dict(verdict_counts.most_common())}')
    print(f'  flag 分布: {dict(flag_counts.most_common())}')
    print(f'  输出: {OUT_PATH}')

    if not patch:
        print()
        print('Dry run: 没有 patch batch JSON。加 --patch 把 confident 题的 round 写回。')
        return

    # patch 模式：仅当 original_round=null 且 flag=confident 才写
    # V3.22 双写：assets/data/batches 和 question_bank 两份都要同步
    # V3.24.6 修：必须同步更新 index.json 的 batch_hash，否则 app sync 看 hash 相同会跳过 import
    n_patched = 0
    patched_sources = set()
    for fp, recs in file_to_records.items():
        bd = json.load(open(fp))
        qs = bd.get('questions', [])
        changed = False
        for rec in recs:
            if rec['original_round'] is not None:
                continue
            if rec['flag'] != 'confident':
                continue
            qs[rec['_q_index']]['round'] = rec['suggested_round']
            changed = True
            n_patched += 1
        if changed:
            with open(fp, 'w') as f:
                json.dump(bd, f, ensure_ascii=False, indent=2)
            qb_fp = fp.replace('/assets/data/batches/', '/question_bank/')
            if os.path.exists(qb_fp):
                with open(qb_fp, 'w') as f:
                    json.dump(bd, f, ensure_ascii=False, indent=2)
            patched_sources.add(bd.get('source', ''))
            n_changed_this = sum(1 for r in recs if r["original_round"] is None and r["flag"] == "confident")
            print(f'  patched {os.path.basename(fp)}: {n_changed_this} 题（assets+question_bank 双写）')
    print(f'共 patch {n_patched} 题（仅 confident + original_round=null）')

    # V3.24.6: 同步 index.json batch_hash + bump version
    if patched_sources:
        update_index_hash(patched_sources)


def update_index_hash(patched_sources: set):
    """重算 patched source 的 batch_hash，bump index.json version"""
    import hashlib
    idx_path = os.path.join(ROOT, 'question_bank/index.json')
    with open(idx_path) as f:
        idx = json.load(f)
    n_fixed = 0
    for b in idx['batches']:
        src = b.get('source', '')
        if src not in patched_sources:
            continue
        path = os.path.join(ROOT, f'question_bank/{src}.json')
        with open(path, 'rb') as f:
            actual = hashlib.sha1(f.read()).hexdigest()
        if b.get('batch_hash') != actual:
            b['batch_hash'] = actual
            n_fixed += 1
    idx['version'] = idx.get('version', 0) + 1
    with open(idx_path, 'w') as f:
        json.dump(idx, f, ensure_ascii=False, indent=2)
    print(f'index.json: 更新 {n_fixed} batch_hash, version → {idx["version"]}')


if __name__ == '__main__':
    do_patch = '--patch' in sys.argv
    main(patch=do_patch)
