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
    r'(参考答案|答案与解析|【参考答案】|答案[:：]|Answer Key|【答案】|(?:^|\n)\s*答案\s*(?:\n|$))',
    re.IGNORECASE | re.MULTILINE,
)
RE_ANS_BIG_SECTION = re.compile(r'(?:^|\n)\s*([一二三四五六七八九十]+)\s*[、.．]')
RE_ANS_NUM = re.compile(r'(\d+)\s*(?:\.(?!\d)|[、．])\s*([^\d\n][^\n]*?)(?=(?:\s+\d+\s*(?:\.(?!\d)|[、．]))|\n|$)')


def find_answer_section(raw: str) -> str:
    """提取答案段（"参考答案"之后的所有文本）"""
    m = RE_ANSWER_BOUNDARY.search(raw)
    if not m:
        return ''
    return raw[m.end():]


def parse_answers_by_section(answer_text: str) -> Dict[tuple, str]:
    """按大题切答案段，返回 {(big_section, local_idx): answer_str}"""
    answers = {}
    sections = list(RE_ANS_BIG_SECTION.finditer(answer_text))
    if not sections:
        # 兜底：整段当一个无名 section
        for m in RE_ANS_NUM.finditer(answer_text):
            answers[('', int(m.group(1)))] = m.group(2).strip()[:200]
        return answers
    for i, m in enumerate(sections):
        big = m.group(1)
        start = m.end()
        end = sections[i + 1].start() if i + 1 < len(sections) else len(answer_text)
        body = answer_text[start:end]
        for am in RE_ANS_NUM.finditer(body):
            try:
                local = int(am.group(1))
            except ValueError:
                continue
            ans = am.group(2).strip()
            answers[(big, local)] = ans[:200]
    return answers


def match_segments_with_answers(segments: list, raw: str) -> tuple:
    """给 segments 配答案。返回 (matched_segments, answer_section_text)"""
    answer_text = find_answer_section(raw)
    if not answer_text:
        for q in segments:
            q['answer'] = None
            q['answer_source'] = 'needs_claude_solve'
        return segments, ''

    ans_map = parse_answers_by_section(answer_text)
    for q in segments:
        big = q.get('big_section', '')
        local = q.get('local_idx') or q.get('stem_idx')
        a = ans_map.get((big, local)) or ans_map.get(('', local))
        if a:
            q['answer'] = a
            q['answer_source'] = 'paper_section'
        else:
            q['answer'] = None
            q['answer_source'] = 'needs_claude_solve'
    return segments, answer_text


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
            matched, ans_text = match_segments_with_answers(segs, raw)
            out_path = seg_path.parent / 'matched.json'
            out_path.write_text(json.dumps(matched, ensure_ascii=False, indent=2))
            (seg_path.parent / 'answer_section.txt').write_text(ans_text, encoding='utf-8')
            with_ans = sum(1 for q in matched if q.get('answer'))
            print(f'[{with_ans}/{len(matched)}] {Path(entry["source_file"]).name}')
    else:
        segs = json.loads(Path(args.input).read_text(encoding='utf-8'))
        raw_path = args.raw or (Path(args.input).parent / 'raw.txt')
        raw = Path(raw_path).read_text(encoding='utf-8', errors='replace')
        matched, ans_text = match_segments_with_answers(segs, raw)
        ans_out = Path(raw_path).parent / 'answer_section.txt'
        ans_out.write_text(ans_text, encoding='utf-8')
        print(json.dumps(matched, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
