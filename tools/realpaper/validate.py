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

SVG_TEXT_PAT = re.compile(r'<text\s+([^>]*?)>([^<]*)</text>')
SVG_VIEWBOX_PAT = re.compile(r'viewBox="([\d.\s\-]+)"')
SVG_FONTSIZE_PAT = re.compile(r'font-size="([\d.]+)"')
CJK_PAT = re.compile(r'[一-鿿]')


def check_svg_text_quality(q: dict, idx: int) -> str:
    """18. SVG <text> 标签纪律（V3.12.19）：
    a) 仅 ASCII/数字/Latin（避免中文 fallback 字体问题）
    b) <text> bbox 必须在 viewBox 内（rough 估算，避免 text-anchor=middle 裁出）

    例外：data:image/svg+xml 的 base64 不 parse；只校验 inline `<svg>` 文本。
    """
    img = q.get('image_data') or ''
    if not img.lstrip().startswith('<svg'):
        return None
    # a) ASCII only
    for m in SVG_TEXT_PAT.finditer(img):
        content = m.group(2)
        if CJK_PAT.search(content):
            return f'#{idx}: SVG <text> 含中文 {content!r}（应改 ASCII，移动端渲染稳定）'
    # b) viewBox bbox check (rough)
    vb_m = SVG_VIEWBOX_PAT.search(img)
    if not vb_m:
        return None
    parts = vb_m.group(1).split()
    if len(parts) != 4:
        return None
    try:
        vb_x, vb_y, vb_w, vb_h = map(float, parts)
    except ValueError:
        return None
    fs_m = SVG_FONTSIZE_PAT.search(img)
    fs = float(fs_m.group(1)) if fs_m else 12.0
    char_w = fs * 0.55  # rough estimate
    for m in SVG_TEXT_PAT.finditer(img):
        attrs, content = m.group(1), m.group(2)
        if not content.strip():
            continue
        x_m = re.search(r'\bx="([\-\d.]+)"', attrs)
        if not x_m:
            continue
        x = float(x_m.group(1))
        anc_m = re.search(r'text-anchor="(\w+)"', attrs)
        anchor = anc_m.group(1) if anc_m else 'start'
        text_w = len(content) * char_w
        if anchor == 'middle':
            left, right = x - text_w / 2, x + text_w / 2
        elif anchor == 'end':
            left, right = x - text_w, x
        else:
            left, right = x, x + text_w
        # tolerance 2px
        if left < vb_x - 2 or right > vb_x + vb_w + 2:
            return (f'#{idx}: SVG <text> {content!r} (x={x},anchor={anchor}) '
                    f'超 viewBox（[{left:.1f},{right:.1f}] vs [{vb_x},{vb_x+vb_w}]）')
    return None

SVG_DIM_NUM_PAT = re.compile(r'^\s*[\d.]+\s*(cm|mm|dm|km|m|°)?\s*$', re.IGNORECASE)
SVG_DIM_EXPR_PAT = re.compile(r'^\s*[rRdDhHLC]\s*=\s*[\d.]+', re.IGNORECASE)
SVG_DIM_INLINE_PAT = re.compile(r'\d+\s*(cm|mm|dm|km)\b', re.IGNORECASE)
SVG_LABEL_PAT = re.compile(r'^[A-Za-z][\d′″]?$')

def _is_svg_dim_label(t: str) -> bool:
    t = t.strip()
    if not t:
        return False
    if SVG_DIM_NUM_PAT.match(t):
        return True
    if SVG_DIM_EXPR_PAT.match(t):
        return True
    if SVG_DIM_INLINE_PAT.search(t):
        return True
    return False

def check_svg_dim_arrow(q: dict, idx: int) -> str:
    """19. SVG 长度标注必带双箭头（V3.12.20）。

    长度标注（数字±单位 / r= / d= / h= / L= / C=）必须配对左右 ↔ 双箭头三角 polygon。
    判定：每个长度标注期望 ≥2 个 polygon 三角形（双箭头一对），允许 marker 替代。

    例外：
    - ≥10 个数字 text → 视为坐标系，跳
    - 含 ≥2 个 ABCD label + ≥6 个数字 → 多候选展开图，跳
    - 等差数列（≥3 个等距数字）→ 坐标刻度，跳
    """
    img = q.get('image_data') or ''
    if not img.lstrip().startswith('<svg'):
        return None
    texts = SVG_TEXT_PAT.findall(img)
    if not texts:
        return None
    text_contents = [t[1] for t in texts]  # SVG_TEXT_PAT group(2) = content
    dim_texts = [t for t in text_contents if _is_svg_dim_label(t)]
    if not dim_texts:
        return None
    # V3.12.20.1：曲线长度（周长/弧长）例外，不要求双箭头（直线双箭头会误导学生以为是直径）
    dim_texts = [t for t in dim_texts if not re.match(r'^\s*C\s*=', t.strip()) and '周长' not in t and '弧长' not in t]
    if not dim_texts:
        return None
    # 排除坐标系（>=10 个数字）
    if len(dim_texts) >= 10:
        return None
    # 排除等差刻度
    nums = []
    for t in dim_texts:
        m = re.search(r'[\d.]+', t)
        if m:
            try:
                nums.append(float(m.group()))
            except ValueError:
                pass
    if len(nums) >= 3:
        sorted_nums = sorted(set(nums))
        if len(sorted_nums) >= 3:
            diffs = [sorted_nums[i+1]-sorted_nums[i] for i in range(len(sorted_nums)-1)]
            if max(diffs) > 0 and (max(diffs) - min(diffs)) < 0.01 * max(diffs):
                return None
    # 排除多候选展开图
    label_texts = [t for t in text_contents if SVG_LABEL_PAT.match(t.strip())]
    abcd = sum(1 for t in label_texts if t.strip().upper() in ('A','B','C','D'))
    if abcd >= 2 and len(dim_texts) >= 6:
        return None
    # 检查箭头数
    polygon_count = img.count('<polygon')
    marker_count = img.count('<marker') + img.count('marker-start') + img.count('marker-end')
    expected = len(dim_texts) * 2
    actual = polygon_count + marker_count
    if actual < expected:
        return (f'#{idx}: SVG 长度标注 {dim_texts!r} ({len(dim_texts)} 个) '
                f'需双箭头 ×{expected}，实有 polygon/marker {actual}（V3.12.20）')
    return None

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

    # 10/11: 需 LLM/人手动核查
    report['M1_no_spoiler'] = {'pass': None, 'errors': ['【需 LLM/人手动核查 explanation 不剧透题面答案】']}
    report['M2_sample_5'] = {'pass': None, 'errors': ['【需 LLM/人手动核查 5 题】']}

    # V3.12.22: 删 V3.12.20 PDF 路径 5 项（12 svg_priority / 13 svg_4step / 14 dim_consistent / 18 svg_text / 19 svg_dim_arrow）
    # docx 路径不画 SVG，原图直接 base64 用，相关检查无意义
    # V3.12.21 worker 错加 `_image_meta.svg_failed_category=legacy_pre_v3_12_17` 字段绕过旧 check 12，是权宜——本 V3.12.22 升级后该兼容字段不再需要

    # 11. group_id 命名空间（V3.12.17）
    errs = check_group_namespace(batch)
    report['11_group_namespace'] = {'pass': not errs, 'errors': errs}

    # 12. 题面措辞同步（V3.12.17）
    errs = [check_emphasis_phrasing(q, i+1) for i, q in enumerate(questions)]
    errs = [e for e in errs if e]
    report['12_emphasis_phrasing'] = {'pass': not errs, 'errors': errs}

    # 13. choice 题 ABCD 前缀（V3.12.19）
    errs = [check_choice_letter_prefix(q, i+1) for i, q in enumerate(questions)]
    errs = [e for e in errs if e]
    report['13_choice_letter_prefix'] = {'pass': not errs, 'errors': errs}

    # 14. image_data MIME 不含 WMF/EMF（V3.12.21 docx 路径专）
    # docx 路径必须把 WMF/EMF 转 PNG/JPEG 后入库，Flutter 不支持渲染 WMF
    wmf_errors = []
    for i, q in enumerate(questions):
        img = q.get('image_data') or ''
        if img and isinstance(img, str):
            head = img.lstrip()[:60].lower()
            if 'image/x-wmf' in head or 'image/x-emf' in head or 'image/wmf' in head or 'image/emf' in head:
                wmf_errors.append(f'#{i+1}: image_data MIME 是 WMF/EMF（必须 extract_docx.py 转 PNG）')
    report['14_no_wmf_in_image'] = {'pass': not wmf_errors, 'errors': wmf_errors}

    # M3/M4: docx 路径手动核查（替代 V3.12.20 SVG 4 步 + 标注一致）
    report['M3_image_owner'] = {'pass': None, 'errors': ['【需 LLM/人核查 docx 内嵌图归属（用 paragraph_image_map）】']}
    report['M4_image_content_match'] = {'pass': None, 'errors': ['【需 LLM/人核查 content 描述与 image_data 视觉一致】']}

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
    """格式化打印自检报告（V3.12.22 docx 路径简版：13 自动 + 4 手动 M1-M4）"""
    items = [(k, v) for k, v in report.items() if not k.startswith('_')]
    auto_n = sum(1 for k, v in items if v['pass'] is not None)
    manual_n = sum(1 for k, v in items if v['pass'] is None)
    print(f'\n=== Pre-commit check ({batch_name}): {auto_n} 自动 + {manual_n} 手动 ===\n')
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
        # V3.12.22: 跑 14 项完整自检（docx 路径简版，删 V3.12.20 SVG 5 项）
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
