#!/usr/bin/env python3
"""V3.23 一致性 check：lib/database/curriculum_seed.dart vs question_bank/curriculum.json

防止 V3.22 漏改 question_bank/curriculum.json 那种 bug 复发：
- seed 改了章节，但 CDN curriculum.json 没跟着 bump，导致 app 启动被 syncFromRemote 回滚

退出码：
  0 = 一致
  1 = 不一致（列出差异）
  2 = 解析错误（文件丢失/格式坏）
"""
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SEED = ROOT / 'lib/database/curriculum_seed.dart'
CDN = ROOT / 'question_bank/curriculum.json'


def parse_seed():
    if not SEED.exists():
        print(f'[FATAL] {SEED} 不存在', file=sys.stderr); sys.exit(2)
    pat = re.compile(
        r"Chapter\(\s*subject:\s*'([^']+)',\s*grade:\s*(\d+),\s*orderIndex:\s*(\d+),\s*chapterName:\s*'([^']+)'"
    )
    out = set()
    for m in pat.finditer(SEED.read_text()):
        out.add((m.group(1), int(m.group(2)), m.group(4), int(m.group(3))))
    return out


def parse_cdn():
    if not CDN.exists():
        print(f'[FATAL] {CDN} 不存在', file=sys.stderr); sys.exit(2)
    try:
        d = json.loads(CDN.read_text())
    except Exception as e:
        print(f'[FATAL] {CDN} JSON 解析失败: {e}', file=sys.stderr); sys.exit(2)
    out = set()
    for c in d.get('chapters', []):
        out.add((c['subject'], int(c['grade']), c['chapter_name'], int(c['order_index'])))
    return out, d.get('version', 0)


def main():
    seed = parse_seed()
    cdn, ver = parse_cdn()

    only_seed = seed - cdn
    only_cdn = cdn - seed
    if not only_seed and not only_cdn:
        print(f'[OK] curriculum.json v{ver} 与 seed 完全一致（{len(seed)} 章）')
        return 0

    print(f'[FAIL] curriculum.json v{ver} 与 seed 不一致')
    if only_seed:
        print(f'\n  seed 有但 CDN 没有（{len(only_seed)}）:')
        for s, g, ch, o in sorted(only_seed):
            print(f'    + {s} g{g} order={o} {ch}')
    if only_cdn:
        print(f'\n  CDN 有但 seed 没有（{len(only_cdn)}）:')
        for s, g, ch, o in sorted(only_cdn):
            print(f'    - {s} g{g} order={o} {ch}')
    print('\n  修复：跑 `python3 tools/sync_curriculum_json.py` 或手动改')
    return 1


if __name__ == '__main__':
    sys.exit(main())
