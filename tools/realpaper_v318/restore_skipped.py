#!/usr/bin/env python3
"""把 v318_no_raw_match 的 skipped 题恢复到 questions（清掉 _raw_excerpt）。"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
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

total_restored = 0
for fn in targets:
    p = ASSETS / fn
    b = json.loads(p.read_text(encoding='utf-8'))
    questions = b.get('questions', [])
    skipped = b.get('_skipped_for_future', [])
    new_skipped = []
    restored_in_file = 0
    for entry in skipped:
        if entry.get('reason') == 'v318_no_raw_match' and 'original_question' in entry:
            q = entry['original_question']
            q.pop('_raw_excerpt', None)  # 清掉填错的
            questions.append(q)
            restored_in_file += 1
        else:
            new_skipped.append(entry)
    b['_skipped_for_future'] = new_skipped
    b['questions'] = questions
    if restored_in_file:
        p.write_text(json.dumps(b, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        qb = QBANK / fn
        if qb.exists():
            qb.write_text(json.dumps(b, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        print(f'{fn[:60]:60} restored={restored_in_file} questions_now={len(questions)}')
    total_restored += restored_in_file
print(f'\nTOTAL restored={total_restored}')
