#!/usr/bin/env python3
"""V3.12.20 SVG 长度标注审计脚本。

扫所有 batch JSON 中含 SVG 的题，识别"看似长度标注的 text"
但 SVG 不含箭头标记（polygon 或 marker）的问题，输出待修清单。

启发式：
- SVG 含 <text> 内容匹配纯数字 / 数字+单位 (cm,mm,dm,m,km) → 视作长度标注
- 排除 ABCD 等单字母标签、>=3 个等距数字（疑似坐标刻度）
- 长度标注存在 + SVG 不含 <polygon> 也不含 <marker → 违规

输出：tools/realpaper/reports/svg_dim_audit_report.json
"""
import json, glob, re, os, sys

BATCH_DIR = '/home/faminwsl/daughter_learning_app/assets/data/batches'
OUT = '/home/faminwsl/daughter_learning_app/tools/realpaper/reports/svg_dim_audit_report.json'
os.makedirs(os.path.dirname(OUT), exist_ok=True)

TEXT_PAT = re.compile(r'<text[^>]*>([^<]+)</text>')
NUM_PAT = re.compile(r'^\s*[\d.]+\s*(cm|mm|dm|km|m|°|分|cm²|cm³)?\s*$', re.IGNORECASE)
EXPR_PAT = re.compile(r'^\s*[rRdDhH]\s*=\s*[\d.]+', re.IGNORECASE)
LABEL_PAT = re.compile(r'^[A-Za-z][\d′″]?$')
ANCHOR_LABEL_PAT = re.compile(r'^(图\d|甲|乙|丙|丁|起点|终点|始|末|A|B|C|D|M|N|O|P|Q|R)$')

def is_dim_label(t: str) -> bool:
    """长度/尺寸标注判定。"""
    t = t.strip()
    if not t:
        return False
    # 纯数字 / 数字+单位
    if NUM_PAT.match(t):
        return True
    # r=5 / h=10 / d=8
    if EXPR_PAT.match(t):
        return True
    # 含 cm/dm/m/km 单位但其他模式
    if re.search(r'\d+\s*(cm|mm|dm|km)\b', t, re.IGNORECASE):
        return True
    return False

def is_label(t: str) -> bool:
    t = t.strip()
    return bool(LABEL_PAT.match(t)) or bool(ANCHOR_LABEL_PAT.match(t))

def has_arrow_markers(svg: str) -> bool:
    """检查 SVG 是否含三角形 polygon 或 marker。"""
    if '<polygon' in svg:
        return True
    if '<marker' in svg or 'marker-start' in svg or 'marker-end' in svg:
        return True
    return False

def is_coord_scale(numbers: list) -> bool:
    """≥3 个数字等差排列 → 疑似坐标刻度。"""
    nums = []
    for n in numbers:
        try:
            nums.append(float(re.sub(r'[^\d.]','', n)))
        except:
            pass
    if len(nums) < 3:
        return False
    nums = sorted(set(nums))
    if len(nums) < 3:
        return False
    diffs = [nums[i+1]-nums[i] for i in range(len(nums)-1)]
    if max(diffs) - min(diffs) < 0.01 * max(diffs):
        return True
    return False

def audit_q(q, batch_name, idx):
    img = q.get('image_data') or ''
    if not img.startswith('<svg'):
        return None
    texts = TEXT_PAT.findall(img)
    if not texts:
        return None
    dim_texts = [t for t in texts if is_dim_label(t)]
    label_texts = [t for t in texts if is_label(t)]
    other = [t for t in texts if t not in dim_texts and t not in label_texts]
    if not dim_texts:
        return None
    # V3.12.20.1：曲线长度（周长 C= / 弧长）例外
    dim_texts = [t for t in dim_texts if not re.match(r'^\s*C\s*=', t.strip()) and '周长' not in t and '弧长' not in t]
    if not dim_texts:
        return None
    # ≥ 10 个数字 → 几乎肯定是坐标系
    if len(dim_texts) >= 10:
        return {'status': 'coord_scale_skip', 'dim_texts': dim_texts, 'reason': 'too_many_numbers'}
    # 多个数字成等差 → 疑似坐标刻度
    if is_coord_scale(dim_texts):
        return {'status': 'coord_scale_skip', 'dim_texts': dim_texts}
    # 多候选选项图（如展开图 4 候选）：含 A/B/C/D label 且尺寸文本众多
    abcd_count = sum(1 for t in label_texts if t.strip() in ['A','B','C','D','甲','乙','丙','丁'])
    if abcd_count >= 2 and len(dim_texts) >= 6:
        return {'status': 'multi_option_skip', 'dim_texts': dim_texts, 'abcd_count': abcd_count}
    has_arrows = has_arrow_markers(img)
    if has_arrows:
        # 进一步：箭头数量 vs 长度标注数量
        polygon_count = img.count('<polygon')
        marker_count = img.count('<marker') + img.count('marker-start') + img.count('marker-end')
        # 每个长度标注期望 2 个 polygon（双箭头）
        expected_arrows = len(dim_texts) * 2
        actual = polygon_count + marker_count
        if actual < expected_arrows:
            return {
                'status': 'partial_arrow',
                'dim_texts': dim_texts,
                'expected_arrows': expected_arrows,
                'actual': actual,
            }
        return None  # 通过
    return {
        'status': 'no_arrow',
        'dim_texts': dim_texts,
        'other_texts': other,
        'svg_len': len(img),
    }

def main():
    report = {'no_arrow': [], 'partial_arrow': [], 'coord_scale_skip': [], 'multi_option_skip': []}
    total_svg = 0
    total_dim = 0
    for fp in sorted(glob.glob(f'{BATCH_DIR}/*.json')):
        b = json.load(open(fp))
        bname = os.path.basename(fp).replace('.json','')
        for i, q in enumerate(b.get('questions', [])):
            img = q.get('image_data') or ''
            if not img.startswith('<svg'):
                continue
            total_svg += 1
            r = audit_q(q, bname, i)
            if r is None:
                continue
            entry = {
                'batch': bname,
                'idx': i,
                'q_num': i + 1,
                'subject': q.get('subject', '?'),
                'content_preview': (q.get('content') or '')[:80],
                **r,
            }
            status = r['status']
            if status == 'coord_scale_skip':
                report['coord_scale_skip'].append(entry)
            elif status == 'multi_option_skip':
                report['multi_option_skip'].append(entry)
            elif status == 'no_arrow':
                report['no_arrow'].append(entry)
                total_dim += 1
            elif status == 'partial_arrow':
                report['partial_arrow'].append(entry)
                total_dim += 1
    summary = {
        'total_svg_questions': total_svg,
        'no_arrow_count': len(report['no_arrow']),
        'partial_arrow_count': len(report['partial_arrow']),
        'coord_scale_skip_count': len(report['coord_scale_skip']),
        'multi_option_skip_count': len(report['multi_option_skip']),
        'must_fix_total': total_dim,
    }
    final = {'summary': summary, 'no_arrow': report['no_arrow'], 'partial_arrow': report['partial_arrow'], 'coord_scale_skip': report['coord_scale_skip'], 'multi_option_skip': report['multi_option_skip']}
    with open(OUT, 'w') as f:
        json.dump(final, f, ensure_ascii=False, indent=2)
    print(json.dumps(summary, indent=2))
    print(f'\nReport saved: {OUT}')
    if total_dim:
        print(f'\n=== 待修题 (前 30) ===')
        all_fix = report['no_arrow'] + report['partial_arrow']
        for e in all_fix[:30]:
            print(f"  {e['batch']} idx={e['idx']} q{e['q_num']} [{e['status']}] dims={e['dim_texts']}")
            print(f"    {e['content_preview']}")
    return total_dim

if __name__ == '__main__':
    sys.exit(0 if main() == 0 else 1)
