#!/usr/bin/env python3
"""把 lib/database/curriculum_seed.dart 同步到 question_bank/curriculum.json。

跑这个之后再 commit 就能通过 check_curriculum_consistency.py。
"""
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SEED = ROOT / 'lib/database/curriculum_seed.dart'
CDN = ROOT / 'question_bank/curriculum.json'


def main():
    pat = re.compile(
        r"Chapter\(\s*subject:\s*'([^']+)',\s*grade:\s*(\d+),\s*orderIndex:\s*(\d+),\s*chapterName:\s*'([^']+)'"
    )
    chapters = []
    for m in pat.finditer(SEED.read_text()):
        chapters.append({
            'subject': m.group(1),
            'grade': int(m.group(2)),
            'chapter_name': m.group(4),
            'order_index': int(m.group(3)),
        })
    chapters.sort(key=lambda c: (c['subject'], c['grade'], c['order_index']))

    old = json.loads(CDN.read_text()) if CDN.exists() else {'version': 0}
    new = {'version': old.get('version', 0) + 1, 'chapters': chapters}
    CDN.write_text(json.dumps(new, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'curriculum.json v{old.get("version", 0)} -> v{new["version"]}, {len(chapters)} chapters')


if __name__ == '__main__':
    main()
