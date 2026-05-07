#!/usr/bin/env python3
"""
batch JSON schema 校验（pipeline step 5）

校验：
- chapter ∈ curriculum_seed.dart 158 chapter（按 subject + grade 过滤）
- knowledge_point ∈ knowledge_points_seed.dart 491 KP（按 subject 过滤）
- type 一致性（题面有 ABCD ↔ type=choice）
- 必填字段齐全

不在 KP 清单的题 → 转移到 kp_pending.json（不入 batch）

用法：
    python3 validate.py <batch.json>          # 单 batch 校验
    python3 validate.py --kp-list             # 输出 KP 清单
    python3 validate.py --chapter-list        # 输出 chapter 清单
"""

import sys
import re
import json
import argparse
from pathlib import Path
from typing import Dict, List, Set, Tuple


PROJECT_ROOT = Path(__file__).resolve().parents[2]
KP_SEED = PROJECT_ROOT / 'lib' / 'database' / 'knowledge_points_seed.dart'
CAMBRIDGE_KP_SEED = PROJECT_ROOT / 'lib' / 'database' / 'cambridge_english_kp_seed.dart'
CHAPTER_SEED = PROJECT_ROOT / 'lib' / 'database' / 'curriculum_seed.dart'
KP_PENDING_PATH = PROJECT_ROOT / 'docs' / 'realpaper_kp_pending.json'


def parse_kp_seed() -> Set[Tuple[str, str]]:
    """解析 dart KP seed → set of (subject, fullPath)"""
    kps = set()
    for path in [KP_SEED, CAMBRIDGE_KP_SEED]:
        if not path.exists():
            continue
        text = path.read_text(encoding='utf-8')
        # 匹配 KnowledgePoint(subject: 'X', category: 'C', name: 'N', ...)
        # 实际生成 fullPath = 'C/N'
        pattern = re.compile(
            r"KnowledgePoint\(\s*"
            r"(?:[a-z_]+:\s*[^,]+,\s*)*?"
            r"subject:\s*'([^']+)'"
            r"[^)]*?"
            r"category:\s*'([^']+)'"
            r"[^)]*?"
            r"name:\s*'([^']+)'",
            re.DOTALL,
        )
        for m in pattern.finditer(text):
            subject, category, name = m.group(1), m.group(2), m.group(3)
            full_path = f'{category}/{name}'
            kps.add((subject, full_path))
    return kps


def parse_chapter_seed() -> Set[Tuple[str, int, str]]:
    """解析 curriculum_seed → set of (subject, grade, chapterName)"""
    chapters = set()
    if not CHAPTER_SEED.exists():
        return chapters
    text = CHAPTER_SEED.read_text(encoding='utf-8')
    # 匹配 Chapter(subject: 'X', grade: N, ..., chapterName: 'C')
    pattern = re.compile(
        r"Chapter\([^)]*?"
        r"subject:\s*'([^']+)'[^)]*?"
        r"grade:\s*(\d+)[^)]*?"
        r"chapterName:\s*'([^']+)'",
        re.DOTALL,
    )
    for m in pattern.finditer(text):
        chapters.add((m.group(1), int(m.group(2)), m.group(3)))
    return chapters


def subject_to_chinese(subj: str) -> str:
    """JSON subject 字符串 → curriculum_seed 内中文 subject"""
    mapping = {
        'math': '数学',
        'chinese': '语文',
        'english': '英语',
        'physics': '物理',
        'chemistry': '化学',
        'AI': 'AI',
    }
    return mapping.get(subj, subj)


def validate_batch(batch: dict, kp_set: set, chapter_set: set) -> tuple:
    """校验 batch JSON。返回 (errors, warnings, kp_gap_questions)"""
    errors = []
    warnings = []
    kp_gaps = []

    subj = batch.get('subject', '')
    subj_cn = subject_to_chinese(subj)
    grade = batch.get('grade')

    questions = batch.get('questions', [])
    for i, q in enumerate(questions):
        # 必填
        for k in ('chapter', 'knowledge_point', 'content', 'type', 'answer'):
            if k not in q or q[k] is None:
                errors.append(f'#{i+1}: missing {k}')

        # chapter 严格映射
        ch = q.get('chapter', '')
        if (subj_cn, grade, ch) not in chapter_set:
            errors.append(f'#{i+1}: chapter "{ch}" not in curriculum_seed (subject={subj_cn} grade={grade})')

        # KP 严格匹配
        kp = q.get('knowledge_point', '')
        if (subj_cn, kp) not in kp_set:
            kp_gaps.append({**q, '_idx': i+1, '_subject': subj_cn, '_grade': grade})

        # 题型一致性
        t = q.get('type', '')
        if t == 'choice' and not q.get('options'):
            warnings.append(f'#{i+1}: type=choice but no options')

    return errors, warnings, kp_gaps


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('batch_path', nargs='?', help='batch JSON 路径')
    ap.add_argument('--kp-list', action='store_true', help='输出 KP 清单')
    ap.add_argument('--chapter-list', action='store_true', help='输出 chapter 清单')
    args = ap.parse_args()

    kp_set = parse_kp_seed()
    chapter_set = parse_chapter_seed()

    if args.kp_list:
        print(f'Total KP: {len(kp_set)}')
        for s, p in sorted(kp_set):
            print(f'  [{s}] {p}')
        return
    if args.chapter_list:
        print(f'Total chapters: {len(chapter_set)}')
        for s, g, c in sorted(chapter_set):
            print(f'  [{s}] grade={g}: {c}')
        return
    if not args.batch_path:
        ap.print_help()
        sys.exit(1)

    batch = json.loads(Path(args.batch_path).read_text(encoding='utf-8'))
    errors, warnings, kp_gaps = validate_batch(batch, kp_set, chapter_set)

    print(f'=== Validate {Path(args.batch_path).name}')
    print(f'Errors: {len(errors)}')
    for e in errors[:20]:
        print(f'  {e}')
    print(f'Warnings: {len(warnings)}')
    for w in warnings[:20]:
        print(f'  {w}')
    print(f'KP gaps (待入等候区): {len(kp_gaps)}')

    if kp_gaps:
        # 追加到 kp_pending.json
        pending = json.loads(KP_PENDING_PATH.read_text(encoding='utf-8'))
        pending['pending'].extend(kp_gaps)
        KP_PENDING_PATH.write_text(json.dumps(pending, ensure_ascii=False, indent=2))
        print(f'Appended {len(kp_gaps)} questions to {KP_PENDING_PATH}')

    sys.exit(1 if errors else 0)


if __name__ == '__main__':
    main()
