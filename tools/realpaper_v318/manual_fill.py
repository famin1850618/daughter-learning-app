#!/usr/bin/env python3
"""手工补 5 题剩余 v318_no_raw_match。从 _skipped 恢复并直接填 _raw_excerpt。"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from fill_raw_excerpt import ASSETS, QBANK, fingerprint_exists_in_raw, normalize_aggressive
import re

# 手工映射 (batch_filename, content_keyword_in_skipped, manual_excerpt)
MANUAL = [
    # baoan_001 - 37.5% 第 3 子题（小数）
    (
        'realpaper_g6_math_beishida_xsc_baoan_001.json',
        '$37.5\\% = (\\ \\ ):24 = 24\\div(\\ \\ ) = \\dfrac{(\\ \\ )}{(\\ \\ )} = (\\ \\ )$（小数）。\n\n3. 最后一空（小数）应填',
        '3．（2分）37.5%　   　：24＝24÷　     　＝　        　【填小数】\n  [OMATH: $=\\frac{()}{()}=$]',
    ),
    (
        'realpaper_g6_math_beishida_xsc_baoan_001.json',
        '已知 $37.5\\%$ 与一系列等价表达',
        '3．（2分）37.5%　   　：24＝24÷　     　＝　        　【填小数】\n  [OMATH: $=\\frac{()}{()}=$]',
    ),
    (
        'realpaper_g6_math_beishida_xsc_baoan_001.json',
        '解比例：$18:x = 6:5$',
        '18．（6分）求未知数．\n30%x+5＝17\n18：x＝6：5\n2yy．',
    ),
    # zdzx_002 - -2°C
    (
        'realpaper_g6_math_beishida_xsc_zdzx_002.json',
        '$-2°C$ 表示零下 $2°C$',
        '20．-2℃表示零下2℃，0℃表示没有温度。                          (       )',
    ),
    # zhuanxiang_xuanze_er_001 - 对称轴最多
    (
        'realpaper_g6_math_beishida_zhuanxiang_xuanze_er_001.json',
        '下列图形中，对称轴最多的是',
        '28．（2022•龙岗区）下列图形中，对称轴最多的是（　　）\nA．正方形\tB．长方形\tC．等边三角形\tD．圆\nE．扇形',
    ),
]

restored = 0
for batch_fn, key, excerpt in MANUAL:
    p = ASSETS / batch_fn
    b = json.loads(p.read_text(encoding='utf-8'))

    # 在 _skipped 中找匹配
    skipped = b.get('_skipped_for_future', [])
    new_skipped = []
    found = False
    for s in skipped:
        if found:
            new_skipped.append(s)
            continue
        if s.get('reason') == 'v318_no_raw_match' and key in s.get('original_question', {}).get('content', ''):
            q = s['original_question']
            q['_raw_excerpt'] = excerpt
            b['questions'].append(q)
            found = True
            restored += 1
            print(f'{batch_fn[:55]:55} key={key[:40]!r} restored')
        else:
            new_skipped.append(s)
    b['_skipped_for_future'] = new_skipped

    if found:
        p.write_text(json.dumps(b, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        qb = QBANK / batch_fn
        if qb.exists():
            qb.write_text(json.dumps(b, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    else:
        print(f'WARN {batch_fn[:55]:55} key={key[:40]!r} NOT FOUND')

print(f'\nTOTAL restored={restored}')
