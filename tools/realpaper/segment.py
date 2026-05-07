#!/usr/bin/env python3
"""
纯文本 → 题目数组（pipeline step 2）

正则切题：
- 大题（"一、""二、""三、"...）
- 小题（"1." "2." "1、" "2、"）
- 子题（"(1)" "(2)" "（1）" "（2）"）

用法：
    python3 segment.py <raw.txt 路径>
    python3 segment.py --batch <extract_manifest.json>

输出：题目数组 JSON（stdout 或写到 .cache/realpaper/<sha1>/segments.json）
"""

import sys
import re
import json
import argparse
from pathlib import Path
from typing import List, Dict, Optional


# 切题正则（含全角句号 ．U+FF0E）
RE_BIG_HEADER = re.compile(r'(?:^|\n)\s*([一二三四五六七八九十]+)\s*[、.．](?P<title>[^\n]*)')
RE_NUM_HEADER = re.compile(r'(?:^|\n)\s*(\d+)\s*(?:\.(?!\d)|[、．])')  # 1. / 1． / 1、（半角点避免小数；全角／顿号无歧义）
RE_SUB_HEADER = re.compile(r'(?:^|\n)\s*[（(](\d+)[)）]')

# 答案段开始标记（用于切除答案部分）
# 含：'参考答案'/'答案与解析'/'【参考答案】'/'答案：'/'Answer Key'/'【答案】'/独行'答案'
RE_ANSWER_BOUNDARY = re.compile(
    r'(参考答案|答案与解析|【参考答案】|答案[:：]|Answer Key|【答案】|(?:^|\n)\s*答案\s*(?:\n|$))',
    re.IGNORECASE | re.MULTILINE,
)

# 页脚/水印噪声（按行删）
RE_NOISE_LINE = re.compile(
    r'(关注微信公众号|获取更多学习资料|第\s*\d+\s*页|^\s*-?\s*\d+\s*-?\s*$)',
)


def split_paper_and_answers(raw: str) -> tuple:
    """把整卷文本分成题目段 + 答案段（按"参考答案"等关键词分割）"""
    m = RE_ANSWER_BOUNDARY.search(raw)
    if not m:
        return raw, ''
    return raw[:m.start()], raw[m.start():]


def is_choice_question(stem_text: str) -> bool:
    """检查题面是否含 ABCD 选项"""
    # 至少 3 个 A/B/C/D 或 ABCD 大写字母后跟句点的模式
    abcd_count = len(re.findall(r'[\n\s]\s*[A-D]\s*[.．、]', stem_text))
    return abcd_count >= 3


def extract_options(stem_text: str) -> Optional[List[str]]:
    """从题面提取 ABCD 选项"""
    if not is_choice_question(stem_text):
        return None
    parts = re.split(r'[\n\s]\s*([A-D])\s*[.．、]', stem_text)
    # parts 形如 [题面, 'A', '选项A 内容', 'B', '选项B 内容', ...]
    options = []
    for i in range(1, len(parts) - 1, 2):
        letter = parts[i]
        content = parts[i + 1].strip().replace('\n', ' ')
        # 截断到下一个选项前（防止把 B/C/D 拉到 A 里）
        options.append(f'{letter}. {content[:200]}')
    return options if len(options) >= 4 else None


def detect_type(stem_text: str) -> str:
    """启发式判定题型"""
    # 主观题先判
    if re.search(r'(作文|根据材料写|谈谈你的看法|不少于\s*\d+\s*字|写一篇|谈谈感受|论述)', stem_text):
        return 'subjective'
    # 选择题
    if is_choice_question(stem_text):
        return 'choice'
    # 计算题
    if re.search(r'(计算下列|解方程|列式|求.{0,8}的值|证明|说明理由)', stem_text):
        return 'calculation'
    # 填空（默认）
    if '____' in stem_text or '_____' in stem_text or re.search(r'[（(]\s+[）)]', stem_text):
        return 'fill'
    # 兜底
    return 'fill'


def strip_noise(raw: str) -> str:
    """去除页脚水印行"""
    lines = []
    for line in raw.split('\n'):
        if RE_NOISE_LINE.search(line):
            continue
        lines.append(line)
    return '\n'.join(lines)


def split_big_sections(paper: str) -> List[Dict]:
    """按大题（一、二、三...）切。返回 [{title, body}]"""
    matches = list(RE_BIG_HEADER.finditer(paper))
    if not matches:
        return [{'title': '', 'body': paper}]
    sections = []
    for i, m in enumerate(matches):
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(paper)
        sections.append({
            'title': m.group('title').strip(),
            'big_idx': i + 1,
            'big_label': m.group(1),
            'body': paper[start:end],
        })
    return sections


def segment_paper(raw: str) -> List[Dict]:
    """把题目段切成单题数组（跨大题，全局连续编号）"""
    raw = strip_noise(raw)
    paper, _ = split_paper_and_answers(raw)
    sections = split_big_sections(paper)
    questions = []
    global_idx = 0
    for sec in sections:
        chunks = re.split(RE_NUM_HEADER, sec['body'])
        if len(chunks) < 3:
            continue
        for i in range(1, len(chunks) - 1, 2):
            try:
                local_qno = int(chunks[i])
            except ValueError:
                continue
            content = chunks[i + 1].strip()
            if not content or len(content) < 5:
                continue
            global_idx += 1
            questions.append({
                'stem_idx': global_idx,
                'big_section': sec.get('big_label', ''),
                'big_section_title': sec.get('title', ''),
                'local_idx': local_qno,
                'raw_text': content[:2000],
                'detected_type': detect_type(content),
                'options': extract_options(content),
            })
    return questions


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('input', help='raw.txt 路径')
    ap.add_argument('--batch', action='store_true', help='input 是 extract_manifest.json，批量处理')
    args = ap.parse_args()

    if args.batch:
        manifest = json.loads(Path(args.input).read_text(encoding='utf-8'))
        all_segments = []
        for entry in manifest:
            if not entry.get('ok'):
                continue
            cache = Path(entry['cache_path'])
            if not cache.exists():
                continue
            text = cache.read_text(encoding='utf-8', errors='replace')
            segs = segment_paper(text)
            seg_path = cache.parent / 'segments.json'
            seg_path.write_text(json.dumps(segs, ensure_ascii=False, indent=2))
            all_segments.append({
                'sha1': entry['sha1'],
                'source_file': entry['source_file'],
                'segments_path': str(seg_path),
                'question_count': len(segs),
            })
            print(f'[{len(segs):3d}q] {Path(entry["source_file"]).name}')
        out = Path(args.input).parent / 'segment_manifest.json'
        out.write_text(json.dumps(all_segments, ensure_ascii=False, indent=2))
        print(f'\nSegment manifest: {out}')
    else:
        text = Path(args.input).read_text(encoding='utf-8', errors='replace')
        segs = segment_paper(text)
        print(json.dumps(segs, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
