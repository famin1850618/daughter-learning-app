#!/usr/bin/env python3
"""V3.14 防同步错的端到端 smoke test。

模拟 app `_importBatchJson` 的字段访问 + cast 路径，任何异常立即报。
主 session push CDN 前必跑：python3 tools/realpaper/check_app_import_schema.py

跟 dart `_importBatchJson` (lib/services/question_update_service.dart) 严格对应。
任何 dart 端字段访问改了，本脚本也要同步更新。
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def simulate_import_batch(batch_path: Path) -> list:
    """模拟 dart _importBatchJson 的 cast 路径。返回错误列表（空 = OK）。"""
    errs = []
    try:
        d = json.loads(batch_path.read_text(encoding='utf-8'))
    except Exception as e:
        return [f'JSON 解析失败: {e}']

    # 顶层必填
    src = d.get('source')
    if not isinstance(src, str): errs.append(f'source 类型 {type(src).__name__} 应 str')
    subject_key = d.get('subject')
    if not isinstance(subject_key, str): errs.append(f'subject 类型 {type(subject_key).__name__} 应 str')
    grade = d.get('grade')
    if not isinstance(grade, int): errs.append(f'grade 类型 {type(grade).__name__} 应 int')

    # 1. knowledge_points_added 兼容性（V3.14 修 42 错教训）
    kpsAdded = d.get('knowledge_points_added')
    if kpsAdded is not None:
        if not isinstance(kpsAdded, list):
            errs.append(f'knowledge_points_added 应 list, 实 {type(kpsAdded).__name__}')
        else:
            for i, item in enumerate(kpsAdded):
                if isinstance(item, str):
                    if '/' not in item:
                        errs.append(f'kp_added[{i}] str "{item}" 缺 / 分隔')
                elif isinstance(item, dict):
                    if not isinstance(item.get('category'), str):
                        errs.append(f'kp_added[{i}] dict 缺 category:str')
                    if not isinstance(item.get('name'), str):
                        errs.append(f'kp_added[{i}] dict 缺 name:str')
                else:
                    errs.append(f'kp_added[{i}] 类型 {type(item).__name__} 应 str/dict')

    # 2. questions 必须 list
    qs = d.get('questions')
    if not isinstance(qs, list):
        errs.append(f'questions 应 list, 实 {type(qs).__name__}')
        return errs

    # 3. 每题字段 cast 模拟
    for i, q in enumerate(qs):
        prefix = f'q[{i}]'
        if not isinstance(q, dict):
            errs.append(f'{prefix} 应 dict, 实 {type(q).__name__}')
            continue
        # 必填 cast（dart 用 as String 强 cast）
        if not isinstance(q.get('chapter'), str):
            errs.append(f'{prefix}.chapter 应 str, 实 {type(q.get("chapter")).__name__}')
        if not isinstance(q.get('content'), str):
            errs.append(f'{prefix}.content 应 str')
        if not isinstance(q.get('answer'), str):
            errs.append(f'{prefix}.answer 应 str')
        if not isinstance(q.get('type'), str):
            errs.append(f'{prefix}.type 应 str (typeFromKey 解析)')
        # 可选
        kp = q.get('knowledge_point')
        if kp is not None and not isinstance(kp, str):
            errs.append(f'{prefix}.knowledge_point 应 str/null, 实 {type(kp).__name__}')
        diff = q.get('difficulty')
        if diff is not None and not isinstance(diff, str):
            errs.append(f'{prefix}.difficulty 应 str/null')
        rd = q.get('round')
        if rd is not None and not isinstance(rd, int):
            errs.append(f'{prefix}.round 应 int/null')
        opts = q.get('options')
        if opts is not None and not isinstance(opts, list):
            errs.append(f'{prefix}.options 应 list/null')
        elif opts and any(o is not None and not isinstance(o, str) for o in opts):
            errs.append(f'{prefix}.options 元素应 str')
        opt_imgs = q.get('option_images')
        if opt_imgs is not None and not isinstance(opt_imgs, list):
            errs.append(f'{prefix}.option_images 应 list/null')
        gid = q.get('group_id')
        if gid is not None and not isinstance(gid, str):
            errs.append(f'{prefix}.group_id 应 str/null')
        gor = q.get('group_order')
        if gor is not None and not isinstance(gor, int):
            errs.append(f'{prefix}.group_order 应 int/null')
        # V3.13 _ai_dispute（兼容 worker 写 string 或 dict）
        ad = q.get('_ai_dispute')
        if ad is not None and not isinstance(ad, dict):
            errs.append(f'{prefix}._ai_dispute 应 dict/null, 实 {type(ad).__name__}')
        # speakers
        sp = q.get('speakers')
        if sp is not None and not isinstance(sp, dict):
            errs.append(f'{prefix}.speakers 应 dict/null')
    return errs


def main():
    batch_dir = ROOT / 'assets' / 'data' / 'batches'
    qb_dir = ROOT / 'question_bank'
    all_batches = sorted(batch_dir.glob('*.json'))
    if not all_batches:
        print(f'❌ {batch_dir} 找不到 batch JSON', file=sys.stderr)
        return 1

    total_errs = 0
    bad_batches = []
    for f in all_batches:
        errs = simulate_import_batch(f)
        if errs:
            total_errs += len(errs)
            bad_batches.append((f.name, errs))
        # 同时检查 question_bank/ 双写
        qb = qb_dir / f.name
        if qb.exists():
            qb_errs = simulate_import_batch(qb)
            if qb_errs:
                bad_batches.append((f'{f.name} (question_bank)', qb_errs))
                total_errs += len(qb_errs)

    print(f'扫 {len(all_batches)} batch JSON × 2（双写）')
    if not bad_batches:
        print(f'✅ 全部 PASS, 0 cast 异常风险')
        return 0
    print(f'❌ {len(bad_batches)} batch 有 schema 错（共 {total_errs} 处），app import 必失败:')
    for name, errs in bad_batches[:20]:
        print(f'\n  {name}:')
        for e in errs[:5]:
            print(f'    {e}')
        if len(errs) > 5:
            print(f'    ... +{len(errs) - 5} 处')
    if len(bad_batches) > 20:
        print(f'\n  ... +{len(bad_batches) - 20} batch 未列出')
    return 1


if __name__ == '__main__':
    sys.exit(main())
