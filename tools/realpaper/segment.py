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


# 切题正则
RE_BIG_HEADER = re.compile(r'(?:^|\n)\s*([一二三四五六七八九十]+)[、.](?P<title>[^\n]*)')
RE_NUM_HEADER = re.compile(r'(?:^|\n)\s*(\d+)\s*[.、](?!\d)')  # 1. / 1、（避免误切小数）
RE_SUB_HEADER = re.compile(r'(?:^|\n)\s*[（(](\d+)[)）]')

# 答案段开始标记（用于切除答案部分）
RE_ANSWER_BOUNDARY = re.compile(
    r'(参考答案|答案与解析|【参考答案】|答案[:：]|Answer Key|【答案】)',
    re.IGNORECASE,
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


def segment_paper(raw: str) -> List[Dict]:
    """把题目段切成单题数组"""
    paper, _ = split_paper_and_answers(raw)
    # 用小题号切（最常见）
    chunks = re.split(RE_NUM_HEADER, paper)
    # chunks[0] = 题号 1 之前的导语；之后 (idx, content) 交替
    questions = []
    if len(chunks) < 3:
        return questions
    # iterate: [preamble, '1', content1, '2', content2, ...]
    for i in range(1, len(chunks) - 1, 2):
        try:
            qno = int(chunks[i])
        except ValueError:
            continue
        content = chunks[i + 1].strip()
        if not content or len(content) < 5:
            continue
        # 截到下一个大题或答案段开始
        # （此处简单实现：直接用 content；可后续改进）
        questions.append({
            'stem_idx': qno,
            'raw_text': content[:2000],  # 截 2000 字防爆炸
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
