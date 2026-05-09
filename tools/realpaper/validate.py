#!/usr/bin/env python3
"""
batch JSON schema 校验（pipeline step 5）

校验：
- chapter ∈ curriculum_seed.dart 158 chapter（按 subject + grade 过滤）
- knowledge_point ∈ knowledge_points_seed.dart 491 KP（按 subject 过滤）
- type 一致性（题面有 ABCD ↔ type=choice）
- 必填字段齐全

不在 KP 清单的题 → 转移到 kp_pending.json（不入 batch）

用法：
    python3 validate.py <batch.json>          # 单 batch 校验
    python3 validate.py --kp-list             # 输出 KP 清单
    python3 validate.py --chapter-list        # 输出 chapter 清单
"""

import sys
import re
import json
import argparse
from pathlib import Path
from typing import Dict, List, Set, Tuple


PROJECT_ROOT = Path(__file__).resolve().parents[2]
KP_SEED = PROJECT_ROOT / 'lib' / 'database' / 'knowledge_points_seed.dart'
CAMBRIDGE_KP_SEED = PROJECT_ROOT / 'lib' / 'database' / 'cambridge_english_kp_seed.dart'
CHAPTER_SEED = PROJECT_ROOT / 'lib' / 'database' / 'curriculum_seed.dart'
KP_PENDING_PATH = PROJECT_ROOT / 'docs' / 'realpaper_kp_pending.json'


def parse_kp_seed() -> Set[Tuple[str, str]]:
    """解析 dart KP seed → set of (subject, fullPath)"""
    kps = set()
    for path in [KP_SEED, CAMBRIDGE_KP_SEED]:
        if not path.exists():
            continue
        text = path.read_text(encoding='utf-8')
        # 匹配 KnowledgePoint(subject: 'X', category: 'C', name: 'N', ...)
        # 实际生成 fullPath = 'C/N'
        pattern = re.compile(
            r"KnowledgePoint\(\s*"
            r"(?:[a-z_]+:\s*[^,]+,\s*)*?"
            r"subject:\s*'([^']+)'"
            r"[^)]*?"
            r"category:\s*'([^']+)'"
            r"[^)]*?"
            r"name:\s*'([^']+)'",
            re.DOTALL,
        )
        for m in pattern.finditer(text):
            subject, category, name = m.group(1), m.group(2), m.group(3)
            full_path = f'{category}/{name}'
            kps.add((subject, full_path))
    return kps


def parse_chapter_seed() -> Set[Tuple[str, int, str]]:
    """解析 curriculum_seed → set of (subject, grade, chapterName)"""
    chapters = set()
    if not CHAPTER_SEED.exists():
        return chapters
    text = CHAPTER_SEED.read_text(encoding='utf-8')
    # 匹配 Chapter(subject: 'X', grade: N, ..., chapterName: 'C')
    pattern = re.compile(
        r"Chapter\([^)]*?"
        r"subject:\s*'([^']+)'[^)]*?"
        r"grade:\s*(\d+)[^)]*?"
        r"chapterName:\s*'([^']+)'",
        re.DOTALL,
    )
    for m in pattern.finditer(text):
        chapters.add((m.group(1), int(m.group(2)), m.group(3)))
    return chapters


def subject_to_chinese(subj: str) -> str:
    """JSON subject 字符串 → curriculum_seed 内中文 subject"""
    mapping = {
        'math': '数学',
        'chinese': '语文',
        'english': '英语',
        'physics': '物理',
        'chemistry': '化学',
        'AI': 'AI',
    }
    return mapping.get(subj, subj)


def validate_batch(batch: dict, kp_set: set, chapter_set: set) -> tuple:
    """校验 batch JSON。返回 (errors, warnings, kp_gap_questions)"""
    errors = []
    warnings = []
    kp_gaps = []

    subj = batch.get('subject', '')
    subj_cn = subject_to_chinese(subj)
    grade = batch.get('grade')

    questions = batch.get('questions', [])
    for i, q in enumerate(questions):
        # 必填
        for k in ('chapter', 'knowledge_point', 'content', 'type', 'answer'):
            if k not in q or q[k] is None:
                errors.append(f'#{i+1}: missing {k}')

        # chapter 严格映射
        ch = q.get('chapter', '')
        if (subj_cn, grade, ch) not in chapter_set:
            errors.append(f'#{i+1}: chapter "{ch}" not in curriculum_seed (subject={subj_cn} grade={grade})')

        # KP 严格匹配
        kp = q.get('knowledge_point', '')
        if (subj_cn, kp) not in kp_set:
            kp_gaps.append({**q, '_idx': i+1, '_subject': subj_cn, '_grade': grade})

        # 题型一致性
        t = q.get('type', '')
        if t == 'choice' and not q.get('options'):
            warnings.append(f'#{i+1}: type=choice but no options')

    return errors, warnings, kp_gaps


# === V3.12.17 16 项自检 D 方案脚本化 ===

IMAGE_INDICATORS = ['如图', '下图', '右图', '左图', '示意图', '图中', '图所示',
                    '看图', '观察图', '图为', '图是', '据图', '看下面']

EMPHASIS_OLD_PHRASES = ['加点字', '加点的字', '加点词', '加点的「',
                       '画波浪线的句子', '波浪线的句子',
                       '画线句子', '划线句子', '画线的句子', '划线的句子']


def check_double_write(batch_path: Path) -> str:
    """1. 双写 diff=0：assets/data/batches vs question_bank 同名文件 sha1 一致"""
    import hashlib
    name = batch_path.name
    qb_path = PROJECT_ROOT / 'question_bank' / name
    assets_path = PROJECT_ROOT / 'assets' / 'data' / 'batches' / name
    if not qb_path.exists() or not assets_path.exists():
        return None
    h_qb = hashlib.sha1(qb_path.read_bytes()).hexdigest()
    h_assets = hashlib.sha1(assets_path.read_bytes()).hexdigest()
    if h_qb != h_assets:
        return f'❌ 双写 diff != 0: question_bank sha1={h_qb[:8]} != assets sha1={h_assets[:8]}'
    return None


def check_image_indicator(q: dict, idx: int) -> str:
    """2. 题面提"如图..."必须有 image_data 或 SVG / 或显式 _image_skip_reason"""
    content = q.get('content', '') or ''
    has_indicator = any(kw in content for kw in IMAGE_INDICATORS)
    if not has_indicator:
        return None
    img = q.get('image_data') or ''
    if img and (img.lstrip().startswith('<svg') or img.startswith('data:image/')):
        return None
    if '<svg' in content:
        return None
    # V3.12.17 加：合法例外（"示意图"为描述用语等）需明示 _image_skip_reason
    if q.get('_image_skip_reason'):
        return None
    return f'#{idx}: 题面提图但无 image_data / SVG（合法例外需加 _image_skip_reason）'


def check_source_naming(batch: dict) -> str:
    """4. source 命名符合 §4 (realpaper_g{grade}_{subject}_{textbook}_{papertype}_{nnn})

    papertype 段允许含数字（如 d1_guoguan / qizhong / xsc_beijing）
    """
    src = batch.get('source', '')
    pattern = r'^realpaper_g\d_(math|chinese|english|physics|chemistry)_[a-z0-9]+(?:_[a-z0-9]+)*_\d{3}$'
    if not re.match(pattern, src):
        return f'❌ source 命名不规范: {src!r}（应符合 realpaper_g6_math_xxx_001）'
    return None


def check_round_filled(q: dict, idx: int) -> str:
    """6. round 字段非 null（4b 阶段已落）"""
    if q.get('round') is None:
        return f'#{idx}: round 字段为 null（4b 阶段未走完？）'
    return None


def check_group_continuity(batch: dict) -> list:
    """7. 系列组合 group_id 索引连续 + group_order 单调（spec §5.4.1 子规则 1）"""
    errors = []
    questions = batch.get('questions', [])
    seen_groups = {}  # gid -> last_index
    for i, q in enumerate(questions):
        gid = q.get('group_id')
        if not gid: continue
        if gid in seen_groups:
            if i - seen_groups[gid] > 1:
                errors.append(f'group_id={gid!r} 索引不连续（中间被打断 q{seen_groups[gid]+1}→q{i+1}）')
        seen_groups[gid] = i
    # group_order 严格递增
    by_gid = {}
    for i, q in enumerate(questions):
        gid = q.get('group_id')
        if not gid: continue
        by_gid.setdefault(gid, []).append((i, q.get('group_order')))
    for gid, items in by_gid.items():
        orders = [o for _, o in items if o is not None]
        if orders != sorted(orders):
            errors.append(f'group_id={gid!r} group_order 不单调: {orders}')
    return errors


def check_fill_inputmethod(q: dict, idx: int) -> str:
    """8. fill 答案符合输入法限制：含 π/²/³/分式 / 公式 → 转 choice"""
    if q.get('type') != 'fill': return None
    a = str(q.get('answer', ''))
    forbidden = ['π', '²', '³', '\\frac', '\\sqrt']
    for f in forbidden:
        if f in a:
            return f'#{idx}: fill answer 含 {f!r}（输入法限制 → 转 choice）'
    return None


def check_no_double_quotes(q: dict, idx: int) -> str:
    """9. content / options 内不用 ASCII 双引号 / 单引号（用「」或（））"""
    bad_chars = ['"', "'"]
    for fld in ['content', 'explanation']:
        v = q.get(fld) or ''
        if any(c in v for c in bad_chars):
            # 排除 LaTeX 数学环境内的（$...$）
            stripped = re.sub(r'\$[^$]*\$', '', v)
            if any(c in stripped for c in bad_chars):
                return f'#{idx}: {fld} 含 ASCII 引号（应用「」或（））'
    return None


def check_group_namespace(batch: dict) -> list:
    """15. group_id 必须含 batch source 前缀（§9.3.3 V3.12.17）"""
    src_short = batch.get('source', '').replace('realpaper_g6_math_beishida_', '') \
                                       .replace('realpaper_g6_chinese_bubian_', '') \
                                       .replace('realpaper_g6_english_', '') \
                                       .replace('.json', '')
    errors = []
    for i, q in enumerate(batch.get('questions', [])):
        gid = q.get('group_id')
        if gid and not gid.startswith(src_short + '_'):
            errors.append(f'#{i+1}: group_id={gid!r} 缺 batch 前缀，应改为 {src_short}_{gid}')
    return errors


def check_emphasis_phrasing(q: dict, idx: int) -> str:
    """16. 题面/解析无"加点字/画波浪线/画线"等旧措辞（§5.6.7 V3.12.17）"""
    text = (q.get('content') or '') + (q.get('explanation') or '')
    # 在 explanation 中保留"为原题加点字"自我说明
    text = text.replace('为原题加点字', '').replace('原题加点字', '')
    for phrase in EMPHASIS_OLD_PHRASES:
        if phrase in text:
            return f'#{idx}: 仍含旧措辞 {phrase!r}（应改"加粗字/加粗的句子"）'
    return None


CHOICE_LETTER_PAT = re.compile(r'^[ABCDZ][.、:：．]')

def check_choice_letter_prefix(q: dict, idx: int) -> str:
    """17. choice 题 options 必须 'A. xxx' 格式 + answer 字母（§5.1 V3.12.19）

    存为裸文本（无 ABCD 前缀）会让 practice_screen.dart 取首字符当字母编号，
    所有选项共享同首字符 → UI 全选 + LaTeX 砍前 2 字符崩溃。
    例外：options=['A','B','C','D'] 是图选项题（option 文本是字母占位符）。
    """
    if q.get('type') != 'choice':
        return None
    opts = q.get('options') or []
    if not opts:
        return None
    # 例外：options 全是单字母 (图选项)
    if all((o or '').strip().upper() in ('A', 'B', 'C', 'D', 'Z') for o in opts):
        # answer 必须也是字母
        ans = (q.get('answer') or '').strip().upper()
        if not re.fullmatch(r'[ABCDZ]+', ans):
            return f'#{idx}: 图选项题 answer 应为字母，实为 {q.get("answer")!r}'
        return None
    # 正常文本选项：必须全部 ABCD 前缀
    if not all(CHOICE_LETTER_PAT.match(o or '') for o in opts):
        return f'#{idx}: 选项缺 ABCD 前缀（例 {opts[0][:30]!r}）'
    # answer 必须是字母（A/B/C/D 或多选 AC）
    ans = (q.get('answer') or '').strip().upper()
    # 接受 'A'、'AC'、'A,C'、'A、C'
    letters_only = re.sub(r'[^ABCDZ]', '', ans)
    if not letters_only:
        return f'#{idx}: answer 应为字母（A/B/AC 等），实为 {q.get("answer")!r}'
    return None


def run_full_check(batch: dict, batch_path: Path, kp_set: set, chapter_set: set) -> dict:
    """跑全 16 项自检（D 方案：可脚本化的 12 项）。

    返回报告 dict，包含每项 PASS/FAIL + 错误列表。
    """
    questions = batch.get('questions', [])
    report = {}

    # 1. 双写 diff
    err = check_double_write(batch_path)
    report['1_double_write'] = {'pass': err is None, 'errors': [err] if err else []}

    # 2. 题面提图必有 image
    errs = [check_image_indicator(q, i+1) for i, q in enumerate(questions)]
    errs = [e for e in errs if e]
    report['2_image_indicator'] = {'pass': not errs, 'errors': errs}

    # 3. KP 严格匹配（已在 validate_batch 实现）
    legacy_errors, _, kp_gaps = validate_batch(batch, kp_set, chapter_set)
    kp_errs = [e for e in legacy_errors if 'chapter' not in e]
    report['3_kp_match'] = {'pass': not kp_gaps and not kp_errs,
                              'errors': kp_errs + [f'KP gap: {len(kp_gaps)} 题入等候区'] if kp_gaps else kp_errs}

    # 4. source 命名
    err = check_source_naming(batch)
    report['4_source_naming'] = {'pass': err is None, 'errors': [err] if err else []}

    # 5. chapter 符合 §3
    chap_errs = [e for e in legacy_errors if 'chapter' in e]
    report['5_chapter_match'] = {'pass': not chap_errs, 'errors': chap_errs}

    # 6. round 非 null
    errs = [check_round_filled(q, i+1) for i, q in enumerate(questions)]
    errs = [e for e in errs if e]
    report['6_round_filled'] = {'pass': not errs, 'errors': errs}

    # 7. 系列组合
    errs = check_group_continuity(batch)
    report['7_group_continuity'] = {'pass': not errs, 'errors': errs}

    # 8. fill 输入法
    errs = [check_fill_inputmethod(q, i+1) for i, q in enumerate(questions)]
    errs = [e for e in errs if e]
    report['8_fill_inputmethod'] = {'pass': not errs, 'errors': errs}

    # 9. 直引号
    errs = [check_no_double_quotes(q, i+1) for i, q in enumerate(questions)]
    errs = [e for e in errs if e]
    report['9_no_double_quotes'] = {'pass': not errs, 'errors': errs}

    # 10/11/13/14: 需 LLM/人，标 manual_required
    report['10_no_spoiler'] = {'pass': None, 'errors': ['【需 LLM/人手动核查】']}
    report['11_sample_5'] = {'pass': None, 'errors': ['【需 LLM/人手动核查 5 题】']}

    # 12. 理科 SVG 优先
    sci_screenshot = []
    for i, q in enumerate(questions):
        if q.get('subject') in ('math', 'physics', 'chemistry'):
            img = q.get('image_data') or ''
            if img and not img.lstrip().startswith('<svg'):
                meta = q.get('_image_meta', {})
                if not meta.get('svg_attempted_failed'):
                    sci_screenshot.append(f'#{i+1}: 理科用 screenshot 但无 svg_attempted_failed 标记')
    report['12_science_svg_priority'] = {'pass': not sci_screenshot, 'errors': sci_screenshot}

    report['13_svg_4step_followed'] = {'pass': None, 'errors': ['【需 LLM/人核查 commit message】']}
    report['14_dim_consistent'] = {'pass': None, 'errors': ['【需 LLM/人对照原图】']}

    # 15. group_id 命名空间
    errs = check_group_namespace(batch)
    report['15_group_namespace'] = {'pass': not errs, 'errors': errs}

    # 16. 题面措辞同步
    errs = [check_emphasis_phrasing(q, i+1) for i, q in enumerate(questions)]
    errs = [e for e in errs if e]
    report['16_emphasis_phrasing'] = {'pass': not errs, 'errors': errs}

    # 17. choice 题 ABCD 前缀（V3.12.19）
    errs = [check_choice_letter_prefix(q, i+1) for i, q in enumerate(questions)]
    errs = [e for e in errs if e]
    report['17_choice_letter_prefix'] = {'pass': not errs, 'errors': errs}

    # summary
    auto_items = [k for k, v in report.items() if v['pass'] is not None]
    pass_count = sum(1 for k in auto_items if report[k]['pass'])
    fail_count = sum(1 for k in auto_items if not report[k]['pass'])
    manual_items = [k for k, v in report.items() if v['pass'] is None]
    report['_summary'] = {
        'auto_pass': pass_count,
        'auto_fail': fail_count,
        'auto_total': len(auto_items),
        'manual_required': manual_items,
    }
    return report


def print_full_report(report: dict, batch_name: str):
    """格式化打印 16 项自检报告"""
    print(f'\n=== Pre-commit check 16 项 ({batch_name}) ===\n')
    items = [(k, v) for k, v in report.items() if not k.startswith('_')]
    for k, v in items:
        if v['pass'] is None:
            mark = '⚠️ '
            label = '需手动'
        elif v['pass']:
            mark = '✅'
            label = 'PASS'
        else:
            mark = '❌'
            label = 'FAIL'
        print(f'  {mark} {k:<30} {label}')
        for e in v['errors'][:5]:
            print(f'       {e}')
        if len(v['errors']) > 5:
            print(f'       ... 还有 {len(v["errors"]) - 5} 处')
    s = report['_summary']
    print(f'\nSummary: 自动检 {s["auto_pass"]}/{s["auto_total"]} pass, '
          f'manual {len(s["manual_required"])} 项: {s["manual_required"]}')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('batch_path', nargs='?', help='batch JSON 路径')
    ap.add_argument('--kp-list', action='store_true', help='输出 KP 清单')
    ap.add_argument('--chapter-list', action='store_true', help='输出 chapter 清单')
    ap.add_argument('--full', action='store_true',
                    help='V3.12.17 16 项自检完整报告（D 方案脚本化）')
    args = ap.parse_args()

    kp_set = parse_kp_seed()
    chapter_set = parse_chapter_seed()

    if args.kp_list:
        print(f'Total KP: {len(kp_set)}')
        for s, p in sorted(kp_set):
            print(f'  [{s}] {p}')
        return
    if args.chapter_list:
        print(f'Total chapters: {len(chapter_set)}')
        for s, g, c in sorted(chapter_set):
            print(f'  [{s}] grade={g}: {c}')
        return
    if not args.batch_path:
        ap.print_help()
        sys.exit(1)

    batch = json.loads(Path(args.batch_path).read_text(encoding='utf-8'))

    if args.full:
        # V3.12.17: 跑 16 项完整自检
        report = run_full_check(batch, Path(args.batch_path), kp_set, chapter_set)
        print_full_report(report, Path(args.batch_path).name)
        # 任一自动项 fail → exit 1
        any_fail = any(not v['pass'] for k, v in report.items()
                       if not k.startswith('_') and v['pass'] is False)
        sys.exit(1 if any_fail else 0)

    errors, warnings, kp_gaps = validate_batch(batch, kp_set, chapter_set)

    print(f'=== Validate {Path(args.batch_path).name}')
    print(f'Errors: {len(errors)}')
    for e in errors[:20]:
        print(f'  {e}')
    print(f'Warnings: {len(warnings)}')
    for w in warnings[:20]:
        print(f'  {w}')
    print(f'KP gaps (待入等候区): {len(kp_gaps)}')

    if kp_gaps:
        # 追加到 kp_pending.json
        pending = json.loads(KP_PENDING_PATH.read_text(encoding='utf-8'))
        pending['pending'].extend(kp_gaps)
        KP_PENDING_PATH.write_text(json.dumps(pending, ensure_ascii=False, indent=2))
        print(f'Appended {len(kp_gaps)} questions to {KP_PENDING_PATH}')

    sys.exit(1 if errors else 0)


if __name__ == '__main__':
    main()
