#!/usr/bin/env python3
"""把对齐度过低的 _raw_excerpt 清掉（让 fill 脚本重做）。"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from qa_check import alignment_score
from fill_raw_excerpt import ASSETS, QBANK

targets = [
    'realpaper_g6_math_beishida_zhuanxiang_xuanze_yi_001.json',
    'realpaper_g6_math_beishida_xsc_zdzx_001.json',
    'realpaper_g6_math_beishida_xsc_zdzx_002.json',
    'realpaper_g6_math_beishida_xsc_yati_jingxuan_001.json',
    'realpaper_g6_math_beishida_zhuanxiang_xuanze_er_001.json',
    'realpaper_g6_math_beishida_xsc_baoan_003.json',
    'realpaper_g6_math_beishida_zhuanxiang_jieda_001.json',
    'realpaper_g6_math_beishida_zhuanxiang_tiankong_001.json',
    'realpaper_g6_math_beishida_xsc_longgang_002.json',
    'realpaper_g6_math_beishida_xsc_luohu_001.json',
    'realpaper_g6_math_beishida_xsc_nanshan_001.json',
    'realpaper_g6_math_beishida_zhuanxiang_xuanze_san_001.json',
    'realpaper_g6_chinese_bubian_qm_longgang_002.json',
    'realpaper_g6_math_beishida_xsc_baoan_001.json',
    'realpaper_g6_math_beishida_xsc_baoan_002.json',
]

THRESHOLD = float(sys.argv[1]) if len(sys.argv) > 1 else 0.4

total_cleaned = 0
for fn in targets:
    p = ASSETS / fn
    b = json.loads(p.read_text(encoding='utf-8'))
    qs = b['questions']
    cleaned_in_file = 0
    for q in qs:
        excerpt = q.get('_raw_excerpt', '')
        content = q.get('content', '')
        if not excerpt:
            continue
        score, _ = alignment_score(content, excerpt)
        if score < THRESHOLD:
            q.pop('_raw_excerpt', None)
            cleaned_in_file += 1
    if cleaned_in_file:
        p.write_text(json.dumps(b, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        qb = QBANK / fn
        if qb.exists():
            qb.write_text(json.dumps(b, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    total_cleaned += cleaned_in_file
    if cleaned_in_file:
        print(f'{fn[:60]:60} cleaned={cleaned_in_file}')
print(f'\nTOTAL cleaned={total_cleaned}')
