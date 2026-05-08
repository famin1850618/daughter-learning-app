#!/usr/bin/env python3
"""
解析 docs/anchor_review_<科目>.md 中 Famin 的 checkbox 标注 + Comment，
提取反馈到 calibration_log/famin_feedback.jsonl，并重排
docs/anchor_questions_g6_<科目>.json 的 round 字段。

用法：
    python3 tools/extract_anchor_review.py math
    python3 tools/extract_anchor_review.py chinese english   # 多科一起
    python3 tools/extract_anchor_review.py --all
"""
import json
import re
import sys
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / 'docs'
LOG_DIR = ROOT / 'calibration_log'
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_PATH = LOG_DIR / 'famin_feedback.jsonl'

ANCHOR_RE = re.compile(r'^### `([a-z][a-z0-9_]*_anchor_\d+)`(.*)$')
CHECKED_RE = re.compile(r'^- \[[xX]\]\s+(同意 R\d|实际是 R\d|\? 拿不准)')
HEADER_RE = re.compile(r'^### `')
# 匹配 **Comment（XX）：内容** 或 **Comment（XX）：** 后下一行的 > 引用
# 关键：冒号后的内容必须不含 * 否则会越过粗体闭合
COMMENT_HDR_RE = re.compile(r'^\*\*Comment[^：:*]*[：:]([^*]*)\*\*\s*$')


def parse_review(md_path: Path):
    """Return list of {anchor_id, audit, choices, comment}."""
    lines = md_path.read_text(encoding='utf-8').splitlines()
    entries = []
    cur = None
    in_comment = False
    comment_buf = []

    for line in lines:
        m = ANCHOR_RE.match(line)
        if m:
            if cur is not None:
                cur['comment'] = '\n'.join(c.strip() for c in comment_buf
                                           if c.strip().startswith('>')).replace('>', '').strip()
                entries.append(cur)
            cur = {
                'anchor_id': m.group(1),
                'audit': '[审]' in m.group(2),
                'choices': [],
                'comment': '',
            }
            in_comment = False
            comment_buf = []
            continue

        if cur is None:
            continue

        cm = CHECKED_RE.match(line)
        if cm:
            cur['choices'].append(cm.group(1))
            in_comment = False
            continue

        chm = COMMENT_HDR_RE.match(line)
        if chm:
            in_comment = True
            comment_buf = []
            inline = chm.group(1).strip()
            if inline:
                comment_buf.append('> ' + inline)
            continue

        if in_comment:
            comment_buf.append(line)

    if cur is not None:
        cur['comment'] = '\n'.join(c.strip() for c in comment_buf
                                   if c.strip().startswith('>')).replace('>', '').strip()
        entries.append(cur)

    return entries


def reconcile(entries, original_anchors_by_id):
    """Given parsed review entries + original anchors, produce per-entry verdict."""
    out = []
    for e in entries:
        anchor = original_anchors_by_id.get(e['anchor_id'])
        if not anchor:
            continue
        # 用 _original_agent_round 优先（idempotent：多次跑不丢 agent 原评定）
        agent_round = anchor.get('_original_agent_round', anchor['round'])
        choices = e['choices']

        if not choices:
            verdict = 'no_mark'
            famin_round = agent_round
            unsure = False
        else:
            agree_choices = [c for c in choices if c.startswith('同意')]
            actual_choices = [c for c in choices if c.startswith('实际是 R')]
            unsure_choices = [c for c in choices if '拿不准' in c]

            if actual_choices:
                actual_round = int(actual_choices[-1].split('R')[-1])
                verdict = 'changed' if actual_round != agent_round else 'agree'
                famin_round = actual_round
                unsure = False
            elif unsure_choices:
                verdict = 'unsure'
                famin_round = agent_round
                unsure = True
            elif agree_choices:
                verdict = 'agree'
                famin_round = agent_round
                unsure = False
            else:
                verdict = 'no_mark'
                famin_round = agent_round
                unsure = False

        out.append({
            'anchor_id': e['anchor_id'],
            'audit_flag': e['audit'],
            'agent_round': agent_round,
            'famin_round': famin_round,
            'verdict': verdict,
            'unsure': unsure,
            'comment': e['comment'],
        })
    return out


def process_subject(subj):
    review_md = DOCS / f'anchor_review_{subj}.md'
    anchors_json = DOCS / f'anchor_questions_g6_{subj}.json'
    if not review_md.exists() or not anchors_json.exists():
        print(f'[skip {subj}] missing review/anchors file')
        return

    entries = parse_review(review_md)
    data = json.loads(anchors_json.read_text(encoding='utf-8'))
    by_id = {a['anchor_id']: a for a in data['anchors']}
    verdicts = reconcile(entries, by_id)

    # stats
    agree = sum(1 for v in verdicts if v['verdict'] == 'agree')
    changed = [v for v in verdicts if v['verdict'] == 'changed']
    unsure = [v for v in verdicts if v['verdict'] == 'unsure']
    no_mark = [v for v in verdicts if v['verdict'] == 'no_mark']

    print(f'\n=== {subj} ===')
    print(f'  total: {len(verdicts)}')
    print(f'  agree: {agree}')
    print(f'  changed: {len(changed)}')
    for v in changed:
        flag = ' [审]' if v['audit_flag'] else ''
        print(f'    {v["anchor_id"]}: R{v["agent_round"]} -> R{v["famin_round"]}{flag}')
        if v['comment']:
            print(f'      "{v["comment"][:80]}"')
    print(f'  unsure: {len(unsure)}')
    for v in unsure:
        print(f'    {v["anchor_id"]} (kept R{v["agent_round"]})')
        if v['comment']:
            print(f'      "{v["comment"][:80]}"')
    if no_mark:
        print(f'  no_mark: {len(no_mark)} (treated as agree)')
        for v in no_mark[:5]:
            print(f'    {v["anchor_id"]}')

    # 写 jsonl 反馈日志
    timestamp = datetime.utcnow().isoformat() + 'Z'
    new_records = 0
    with open(LOG_PATH, 'a', encoding='utf-8') as f:
        for v in verdicts:
            if v['verdict'] in ('changed', 'unsure') or v['comment']:
                rec = {
                    'timestamp': timestamp,
                    'subject': subj,
                    **v,
                }
                f.write(json.dumps(rec, ensure_ascii=False) + '\n')
                new_records += 1
    print(f'  → {new_records} records appended to calibration_log/famin_feedback.jsonl')

    # 重排 anchors JSON 的 round 字段（如有 changed）
    rewrite = False
    for v in verdicts:
        if v['verdict'] == 'changed':
            anchor = by_id[v['anchor_id']]
            anchor['_original_agent_round'] = anchor.get('_original_agent_round', anchor['round'])
            anchor['round'] = v['famin_round']
            anchor['_famin_review'] = {
                'famin_round': v['famin_round'],
                'comment': v['comment'],
                'reviewed_at': timestamp,
            }
            rewrite = True
    if rewrite:
        anchors_json.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n',
                                encoding='utf-8')
        print(f'  → {anchors_json.name} updated (round 字段已重排)')


def main():
    args = sys.argv[1:]
    if not args or '--all' in args:
        subjs = ['math', 'chinese', 'english']
    else:
        subjs = args
    for s in subjs:
        process_subject(s)


if __name__ == '__main__':
    main()
