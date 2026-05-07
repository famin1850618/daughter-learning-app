#!/usr/bin/env python3
"""
答案匹配（pipeline step 3）

策略（按优先级）：
1. 同文件答案段（"参考答案"后）→ 题号映射
2. 独立答案文件（同目录 *答案*.* / *解析*.*）→ 配对加载
3. 完全无答案 → 标记 needs_claude_solve

用法：
    python3 match_ans.py <segments.json>  --raw <raw.txt>
    python3 match_ans.py --batch <segment_manifest.json>
"""

import sys
import re
import json
import argparse
from pathlib import Path
from typing import Optional, Dict


RE_ANSWER_BOUNDARY = re.compile(
    r'(参考答案|答案与解析|【参考答案】|答案[:：]|Answer Key|【答案】)',
    re.IGNORECASE,
)
RE_ANSWER_NUM = re.compile(r'(?:^|\n)\s*(\d+)\s*[.、:：]?\s*([^\n]+)')
RE_CHOICE_ANSWER = re.compile(r'^[A-D]$')


def find_answer_section(raw: str) -> str:
    """提取答案段（"参考答案"之后的所有文本）"""
    m = RE_ANSWER_BOUNDARY.search(raw)
    if not m:
        return ''
    return raw[m.end():]


def parse_answers(answer_text: str) -> Dict[int, str]:
    """从答案段抽 题号 → 答案 映射"""
    answers = {}
    for m in RE_ANSWER_NUM.finditer(answer_text):
        try:
            qno = int(m.group(1))
        except ValueError:
            continue
        ans = m.group(2).strip()
        # 单字母 ABCD（选择题答案）
        if len(ans) == 1 and ans.upper() in 'ABCD':
            answers[qno] = ans.upper()
        # 多字母 ABCD（多选）
        elif re.match(r'^[A-D]{1,4}$', ans):
            answers[qno] = ans.upper()
        else:
            # 填空/计算答案：取该行第一句（150 字以内）
            answers[qno] = ans[:200]
    return answers


def match_segments_with_answers(segments: list, raw: str) -> list:
    """给 segments 配答案"""
    answer_text = find_answer_section(raw)
    if not answer_text:
        # 标记所有题为 needs_claude_solve
        for q in segments:
            q['answer'] = None
            q['answer_source'] = 'needs_claude_solve'
        return segments

    ans_map = parse_answers(answer_text)
    for q in segments:
        a = ans_map.get(q['stem_idx'])
        if a:
            q['answer'] = a
            q['answer_source'] = 'paper_section'
        else:
            q['answer'] = None
            q['answer_source'] = 'needs_claude_solve'
    return segments


def find_companion_answer_file(paper_path: Path) -> Optional[Path]:
    """查找同目录下的独立答案文件（如 *答案*.doc）"""
    parent = paper_path.parent
    base = paper_path.stem
    for candidate in parent.iterdir():
        if not candidate.is_file():
            continue
        if candidate == paper_path:
            continue
        # 名字相似 + 含"答案/解析"
        if any(k in candidate.name for k in ['答案', '解析', 'answer']) and \
           any(c in base for c in candidate.stem.split() if len(c) > 2):
            return candidate
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('input', help='segments.json 或 segment_manifest.json')
    ap.add_argument('--raw', help='raw.txt 路径（单文件模式）')
    ap.add_argument('--batch', action='store_true')
    args = ap.parse_args()

    if args.batch:
        manifest = json.loads(Path(args.input).read_text(encoding='utf-8'))
        for entry in manifest:
            seg_path = Path(entry['segments_path'])
            raw_path = seg_path.parent / 'raw.txt'
            if not seg_path.exists() or not raw_path.exists():
                continue
            segs = json.loads(seg_path.read_text(encoding='utf-8'))
            raw = raw_path.read_text(encoding='utf-8', errors='replace')
            matched = match_segments_with_answers(segs, raw)
            out_path = seg_path.parent / 'matched.json'
            out_path.write_text(json.dumps(matched, ensure_ascii=False, indent=2))
            with_ans = sum(1 for q in matched if q.get('answer'))
            print(f'[{with_ans}/{len(matched)}] {Path(entry["source_file"]).name}')
    else:
        segs = json.loads(Path(args.input).read_text(encoding='utf-8'))
        raw_path = args.raw or (Path(args.input).parent / 'raw.txt')
        raw = Path(raw_path).read_text(encoding='utf-8', errors='replace')
        matched = match_segments_with_answers(segs, raw)
        print(json.dumps(matched, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
