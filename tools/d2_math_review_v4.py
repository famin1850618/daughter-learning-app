#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
D2 V3 Math Reviewer — V3.12 D2+ algorithm v3 implementation.

V2 → V3 changes (基于 Famin V2 verify 反馈，B 组 4/5 道偏高 1-2 档):
  1. distractor 单维拉高保护：当 max(step,mental,calc,kp) <= R2 时，
     distractor 上限 R2（不让单维 distractor=3 拉高 max）
  2. mental_flex 阈值下调：hidden_score >= 5 → R3（原 >= 6）
  3. anchor 匹配仅 round ±2 内候选（高噪音去除）
  4. is_kousuan + 多空填带浮点：calc 上限 R2

V2 baseline:

5 dims (per docs/difficulty_algorithm_v2_math.md):
  - step_count          : content-based (numbers / unknowns / unit conv / formulas)
  - mental_flexibility  : LLM-style rubric encoded as heuristic (ref Famin comments)
  - distractor_realness : choice-only, real vs fake trap
  - calculation_volume  : ops + big nums + floats + big-num division + fractions
  - kp_span             : solution-path-based (not surface text)

Combine = max(rounds) ; single-dim virtual-high protection (max - median >= 2 -> high_variance)
Anchor validation: |computed - nearest_anchor.round| >= 2 -> anchor_disagree

Outputs: calibration_log/d2_math_review_v2.jsonl
"""
import json
import glob
import re
import os
import sys
from datetime import datetime
from typing import Optional

ROOT = '/home/faminwsl/daughter_learning_app'
BATCH_GLOB = os.path.join(ROOT, 'assets/data/batches/realpaper_g6_math_*.json')
ANCHOR_PATH = os.path.join(ROOT, 'docs/anchor_questions_g6_math.json')
V1_PATH = os.path.join(ROOT, 'calibration_log/d2_math_review.jsonl')
V2_PATH = os.path.join(ROOT, 'calibration_log/d2_math_review_v2.jsonl')
OUT_PATH = os.path.join(ROOT, 'calibration_log/d2_math_review_v4.jsonl')


# ----------------------------- helpers ------------------------------------
NUM_RE = re.compile(r'(?<![A-Za-z])(\d+(?:\.\d+)?(?:/\d+)?)(?![A-Za-z])')
FRAC_RE = re.compile(r'\\frac\{[^}]+\}\{[^}]+\}')
FRAC_PLAIN_RE = re.compile(r'(?<!\d)(\d+)/(\d+)(?!\d)')
PI_RE = re.compile(r'\\pi|π')
SQRT_RE = re.compile(r'\\sqrt')
OP_CHARS = ['+', '-', '×', '÷', '*', '/', '∶', ':', '$\\times$', '$\\div$']

UNIT_PAIRS = [
    # (small, big) — only used when both standalone tokens present
    ('mm', 'cm'), ('mm', 'm'), ('cm', 'm'), ('cm', 'km'), ('m', 'km'),
    ('dm', 'm'), ('dm', 'cm'),
    ('元', '角'), ('角', '分'),
    ('时', '分钟'), ('小时', '分钟'), ('分钟', '秒'),
    ('kg', 'g'), ('千克', '克'), ('吨', '千克'),
    ('mL', 'L'), ('毫升', '升'), ('立方分米', '立方米'),
]


def _has_unit_token(content: str, unit: str) -> bool:
    """Check 'unit' appears as a standalone token (not e.g. cm inside cm²/cm³)."""
    # Build pattern: unit not followed by ² ³ ² ³ chinese-suffix
    pat = re.escape(unit) + r'(?![²³m])(?![一-鿿])'
    # Add: must be preceded by a digit or whitespace or "是"
    return bool(re.search(r'(?:\d|\s|是|为|长|宽|高)\s*' + pat, content))


def extract_numbers(content: str) -> list:
    """Extract numeric values from content (decimals + plain ints + simple fractions a/b)."""
    nums = []
    # remove latex frac first to avoid double-counting
    c = FRAC_RE.sub(' FRAC ', content)
    for m in NUM_RE.finditer(c):
        s = m.group(1)
        try:
            if '/' in s:
                a, b = s.split('/')
                nums.append(float(a) / float(b))
            else:
                nums.append(float(s))
        except (ValueError, ZeroDivisionError):
            pass
    return nums


def count_unit_conversions(content: str) -> int:
    n = 0
    seen = set()
    for a, b in UNIT_PAIRS:
        if _has_unit_token(content, a) and _has_unit_token(content, b):
            key = (a, b)
            if key not in seen:
                n += 1
                seen.add(key)
    # special: 比例尺 with 图上 X cm + 实际 Y km → cm↔km conversion implicit
    if '比例尺' in content and ('km' in content or '千米' in content):
        n += 1
    # cap unit conv at 2 (typical max)
    return min(n, 2)


def has_unit_conversion(content: str) -> bool:
    return count_unit_conversions(content) > 0


def identify_formulas(content: str, kp: str) -> int:
    """Count distinct formula-class hints. Cap at 2 (typical max for chained formulas)."""
    classes = set()
    # 圆柱/圆锥 体积/表面积 视为同一 formula class（公式类型）
    if '圆柱' in content or '圆柱' in kp:
        if '体积' in content or '体积' in kp:
            classes.add('cyl_vol')
        elif '表面积' in content or '侧面积' in content or '面积' in content:
            classes.add('cyl_surf')
        else:
            classes.add('cyl_other')
    if '圆锥' in content or '圆锥' in kp:
        if '体积' in content or '体积' in kp:
            classes.add('cone_vol')
        else:
            classes.add('cone_other')
    if '比例' in content or '比例' in kp or re.search(r'\d+\s*[∶:]\s*\d+', content):
        classes.add('ratio')
    if '%' in content or '百分' in content:
        classes.add('pct')
    if '速度' in content or '行驶' in content or '相遇' in content or '相向' in content:
        classes.add('speed')
    if '平均' in content:
        classes.add('avg')
    if re.search(r'方程|解比例|x\s*=', content):
        classes.add('eq')
    if any(s in content for s in ['长方体', '正方体', '棱长']):
        classes.add('cuboid')
    return min(len(classes), 2)


KOUSUAN_HINTS = ['直接写出', '口算', '直接计算', '简便计算']


def is_kousuan(content: str) -> bool:
    """口算/直接写出 — many sub-blanks but each is trivial."""
    if any(h in content for h in KOUSUAN_HINTS):
        return True
    # Multiple blanks (>= 4) joined by ; / 、 / "；" → 套题
    if (content.count('(    )') + content.count('（    ）')) >= 4:
        return True
    if content.count('；') >= 3 or content.count(';') >= 3:
        return True
    return False


def calc_step_count(q: dict) -> int:
    content = q.get('content', '')
    kp = q.get('knowledge_point', '')
    nums = extract_numbers(content)
    n_nums = len(nums)

    # 口算/直接写出 → step_count 上限 R2（每个分支再难也是直接套）
    if is_kousuan(content):
        return 2

    # unknowns: blanks "(    )", "___", "?"
    unknowns = content.count('(    )') + content.count('（    ）') + content.count('___') + content.count('？')
    if unknowns == 0 and ('?' in content):
        unknowns = 1
    # cap unknowns: more than 2 blanks usually means 多空填，逻辑是同一道题的多个数 (e.g. fill 三角形三边)
    unknowns = min(unknowns, 2)

    unit_conv = count_unit_conversions(content)
    formulas = identify_formulas(content, kp)
    # number step: cap at 4 (more than 5 nums usually means 数据条件多但不增加步骤)
    nstep = min(max(n_nums - 1, 0), 4)

    s = max(
        nstep,
        unknowns,
        unit_conv + max(formulas - 1, 0),
    )
    return s


def step_round(s: int) -> int:
    if s <= 1:
        return 1
    if s == 2:
        return 2
    if s == 3:
        return 3
    return 4


# ------------ mental_flexibility heuristic (rubric-encoded) ---------------
# Rationale derived from Famin's anchor + flag_review comments:
#  R1=0: 直接套公式 / 概念辨析
#  R2=1: 多步但每步直接（无突破）
#  R3=2: "想到"非显而易见的解法 (求公倍数 / 反证 / 转化 / 思路绕一下)
#  R4=3: 多次思维突破 (步骤转折都不直接 / 方程思维 / 代数前哨)

# Keywords / patterns that boost mental_flex
HIGH_FLEX_PATTERNS = [
    ('最小公倍数', 2), ('最大公约数', 2), ('公倍数', 2), ('公因数', 2),
    ('反推', 2), ('反过来', 2), ('原来', 1),
    ('取整', 2), ('向上取', 2),
    ('设.*=.*k', 2),  # set k variable
    ('找规律', 2), ('依次', 1), ('按这样', 1),
]

# Patterns that suggest hidden multi-step reasoning
HIDDEN_STEP_PATTERNS = [
    ('比.*多.*1/', 2),  # "比 B 多 1/9" / "比 B 少 1/9"
    ('比.*少.*1/', 2),
    ('占.*的.*1/', 1),
    ('(\d+)%.*(\d+)%', 1),  # multiple percentages
    ('共.*([份个])', 1),
    ('又.*多少', 1),
    ('几次', 1),  # 几次运完 → 决策类向上取整
    ('共需要', 1),
]


# Direct-formula hints (cap mental_flex low)
DIRECT_FORMULA_HINTS = [
    '直接写出', '口算', '直接计算', '简便计算',
    '解比例', '解方程',
]


def mental_flex_eval(q: dict) -> int:
    """Return 0..3."""
    content = q.get('content', '')
    answer = str(q.get('answer', ''))
    explanation = q.get('explanation', '')
    kp = q.get('knowledge_point', '')
    qtype = q.get('type', '')

    base = 0

    # Direct-formula / 口算 → R1 cap (unless explicit reasoning twist)
    is_direct_calc = any(h in content for h in DIRECT_FORMULA_HINTS)

    # Hidden reasoning patterns
    hidden_score = 0
    for pat, w in HIGH_FLEX_PATTERNS:
        if re.search(pat, content):
            hidden_score += w
    for pat, w in HIDDEN_STEP_PATTERNS:
        if re.search(pat, content):
            hidden_score += w

    # Multi-ratio chains (e.g. 甲乙比 5:3, 乙丙比 4:3 → need to align ratios) — qimo_003#40
    ratio_pairs = re.findall(r'\d+\s*[∶:]\s*\d+', content)
    if len(ratio_pairs) >= 2:
        hidden_score += 3  # 双比对齐 → 强信号 R4

    # 中点 / 相遇 / 相向 → hidden geometry+motion (xshchu_xian#35)
    if '中点' in content and ('相遇' in content or '相反方向' in content or '相向' in content):
        hidden_score += 3
    elif '相遇' in content or '相向' in content:
        hidden_score += 2

    # 圆柱切割 / 锯成 / 截 / 削 / 拼接 / 浸没 → spatial imagination (xingjitongji#15, qizhong_003#16)
    if any(w in content for w in ['切割', '锯成', '截掉', '削成', '切开', '熔铸', '浸没', '取出', '沉入', '从水中']):
        hidden_score += 2

    # 设 k / 设份数 → algebraic prep (xshchu_xian#36)
    if '设' in explanation and ('k' in explanation or '份' in explanation):
        hidden_score += 2

    # Equation variable required (12k, 11k, 8k pattern)
    if re.search(r'\d+k', explanation) and re.search(r'方程|=.*\d|解得', explanation):
        hidden_score += 1

    # 拓宽 / 还剩 / 又 — hidden incremental relation (xshchu_beijing#28)
    if '还剩' in content and ('%' in content or FRAC_RE.search(content) or FRAC_PLAIN_RE.search(content)):
        hidden_score += 2
    if ('比' in content) and re.search(r'比.*[多少]\s*\d', content):
        hidden_score += 1
    # 第一天/第二天/第三天 多日累积题
    if content.count('天') >= 2 and '%' in content:
        hidden_score += 1

    # 看了 X 页 + 剩下 X 页 + 比例 — 三元关系 (mokuai_daishu#34)
    if '看' in content and ('剩下' in content or '剩' in content) and (FRAC_PLAIN_RE.search(content) or '/' in content):
        hidden_score += 2

    # 钟面 / 时针 / 分针 → 常识题 (xshchu_xian#14)
    if '时针' in content or '分针' in content or '钟面' in content:
        hidden_score += 1

    # 简便计算 with 4-digit numbers → 隐藏构造关系 (anchor r4_3)
    if '简便计算' in content:
        big = [n for n in extract_numbers(content) if n >= 1000]
        if len(big) >= 2:
            hidden_score += 2

    # 蛋糕盒丝带 / 多次绕 / 圆柱周长→直径 反推 (xshchu_xian#7)
    if any(w in content for w in ['丝带', '绕', '缠绕']):
        hidden_score += 1

    # 圆柱削成圆锥 / 圆锥与圆柱等底等高 + 体积差 — hidden ratio
    if ('等底等高' in content) and ('圆柱' in content or '圆锥' in content):
        hidden_score += 1

    # 比例尺 + 实际距离 + 时间速度 — 跨概念
    if '比例尺' in content and ('速度' in content or '时' in content):
        hidden_score += 2

    # Direct-formula / 口算 → R1 cap unless very strong hidden_score
    if is_direct_calc and hidden_score < 3:
        return 0

    # judgment 题 — 概念辨析为主，多数 R0
    if qtype == 'judgment' and hidden_score < 2:
        return 0

    # Map to 0..3
    # V3 改动 #2: hidden_score >= 5 → R3（原 V2 ≥ 6）
    # 让 mokuai_daishu#34 / xshchu_beijing#28（V2=R3 / Famin=R4）边界更准
    if hidden_score >= 5:
        return 3
    if hidden_score >= 3:
        return 2
    if hidden_score >= 1:
        return 1
    return 0


def mental_round(m: int) -> int:
    return m + 1  # 0->R1, 1->R2, 2->R3, 3->R4


# --------------------- distractor_realness ----------------------------
def distractor_eval(q: dict) -> Optional[int]:
    """Choice only. 0..3."""
    if q.get('type') != 'choice':
        return None
    options = q.get('options') or []
    if not options or len(options) < 2:
        return None
    answer = str(q.get('answer', '')).strip()
    content = q.get('content', '')

    # find correct option text
    correct_text = None
    for opt in options:
        # opt format e.g. "A. 50.24"
        m = re.match(r'^([A-DZ])[.．、]\s*(.*)$', opt.strip())
        if m and m.group(1) == answer.upper():
            correct_text = m.group(2).strip()
            break

    distractors = []
    for opt in options:
        m = re.match(r'^([A-DZ])[.．、]\s*(.*)$', opt.strip())
        if m and m.group(1) != answer.upper():
            distractors.append(m.group(2).strip())

    if correct_text is None:
        # fallback by score
        return 1

    # Heuristic: check numeric proximity to correct
    def parse_num(s):
        m = re.search(r'-?\d+\.?\d*', s.replace(',', ''))
        return float(m.group(0)) if m else None

    cn = parse_num(correct_text)
    near_count = 0
    if cn is not None and cn != 0:
        for d in distractors:
            dn = parse_num(d)
            if dn is None:
                continue
            ratio = abs(dn - cn) / max(abs(cn), 1e-6)
            # "factor missing" patterns: answer/2, answer*2, answer*10, answer/10
            if 0.05 <= ratio <= 0.5:
                near_count += 2  # very close
            elif ratio in (0.5, 2.0) or 0.4 < ratio < 0.6 or 1.8 < ratio < 2.2:
                near_count += 2  # missing factor of 2
            elif 9 <= ratio <= 11 or 0.09 <= ratio <= 0.11:
                near_count += 1  # off by factor 10 (unit conversion trap)
            elif ratio > 100:
                near_count += 0  # totally distant → 假陷阱
            else:
                near_count += 1

    # 单位换算陷阱 detection (cm/m, dm/m, mm/cm with same digits but different magnitudes)
    if '$\\pi$' in content or 'π' in content or '取3.14' in content:
        # 圆柱/圆锥题 unit-conversion 陷阱常见
        if has_unit_conversion(content):
            near_count += 1

    # 概念辨析题 (textual options like "正比例 / 反比例 / 不成比例" / "底面积 / 侧面积")
    is_concept = all(parse_num(d) is None for d in distractors) and parse_num(correct_text) is None
    if is_concept:
        # check Famin's "假陷阱" rule: anchor r2_5 → "一眼可知"
        # if answer 直白对立 (正/反)，distractor明显错 → R1
        opposing_pairs = [('正比例', '反比例'), ('增加', '减少'), ('放大', '缩小')]
        for a, b in opposing_pairs:
            if (a in correct_text and any(b in d for d in distractors)) or \
               (b in correct_text and any(a in d for d in distractors)):
                # 直接对立 → 假陷阱
                near_count = max(0, near_count - 1)
        # 概念辨析题 default 1（有点近义）
        if near_count == 0:
            near_count = 1

    # Cap to avoid over-rating concept-辨析 题 (anchor r2_5: 一眼可知, 是假陷阱)
    if is_concept and near_count <= 2:
        return 0

    # cap distractor — π-multiple traps and missing-factor traps are common but
    # the题's overall difficulty depends mostly on step+mental, not just distractor
    if near_count >= 6:
        return 2  # was 3, cap to 2 to avoid R4 single-dim虚高
    if near_count >= 4:
        return 2
    if near_count >= 2:
        return 1
    return 0


def distractor_round(d: Optional[int]) -> Optional[int]:
    if d is None:
        return None
    return d + 1


# --------------------- calculation_volume -----------------------------
def calc_calculation_volume(q: dict) -> float:
    content = q.get('content', '')
    answer = str(q.get('answer', ''))
    explanation = q.get('explanation', '')

    # Operators count from content + explanation (better signal)
    text = content + ' ' + explanation
    op_count = 0
    for op in ['$\\times$', '$\\div$']:
        op_count += text.count(op)
    # Plain ops, but exclude latex
    for op in ['×', '÷']:
        op_count += text.count(op)
    # +- count from content only (avoid counting "-" in explanation prose)
    op_count += content.count('+')
    op_count += content.count('-')

    nums = extract_numbers(content) + extract_numbers(answer)
    max_num = max(nums) if nums else 0
    has_float = ('.' in content or 'π' in content or '\\pi' in content or '小数' in content
                 or any(re.search(r'\d+\.\d+', s) for s in [content, answer]))
    # big-num division: 大数 ÷ 大数
    has_big_div = bool(re.search(r'\d{3,}\s*[÷/]\s*\d{2,}', content + answer + explanation))
    has_frac = bool(FRAC_RE.search(content)) or bool(FRAC_PLAIN_RE.search(content))

    score = (
        (op_count >= 3) * 0.3 +
        (max_num >= 100) * 0.2 +
        bool(has_float) * 0.15 +
        has_big_div * 0.2 +
        has_frac * 0.15
    )
    # bonus: very long explanation or 多步 calculation
    if len(explanation) > 200:
        score += 0.05
    # V3 改动 #4: is_kousuan 时 calc 上限 0.49（即 R2）
    # Famin: kaodian_zonghe_002#10 V2=R3 / 实际 R2，多空填浮点不应升 R3
    if is_kousuan(content):
        score = min(score, 0.49)
    return min(score, 1.0)


def calc_round(c: float) -> int:
    if c < 0.2:
        return 1
    if c < 0.5:
        return 2
    if c < 0.75:
        return 3
    return 4


# --------------------- kp_span (solution-path) ------------------------
def calc_kp_span(q: dict) -> int:
    """Solution-path KP span. 1=single concept, 2=cross 1 KP, 3=cross 2 KP, 4+=综合."""
    content = q.get('content', '')
    explanation = q.get('explanation', '')
    kp = q.get('knowledge_point', '')

    extras = set()
    primary_kp = kp.split('/')[0] if kp else ''

    # 几何 KP 系：圆柱/圆锥/长方体 — 同 chapter 不算 cross
    if '圆柱' in primary_kp or '圆锥' in primary_kp or '比例' in primary_kp:
        # 主 KP 已涵盖 几何/比例
        pass
    else:
        # 主 KP 不是几何/比例，但题里出现 → 跨 KP
        if re.search(r'(圆柱|圆锥|长方体|正方体|棱长)', content):
            extras.add('几何')
        if '比' in content and re.search(r'\d+\s*[∶:]\s*\d+', content):
            extras.add('比例')

    # 单位换算 — 仅 actual conversion needed
    if count_unit_conversions(content) > 0:
        extras.add('单位换算')
    # 方程思维：解释中明确设 x or k 才算
    if re.search(r'设.*=.*[xk]|方程', explanation):
        extras.add('方程思维')
    # 百分数 vs 分数 vs 比 — 只算一种
    if '%' in content or '百分' in content:
        if '百分' not in primary_kp:
            extras.add('百分数')
    elif (FRAC_RE.search(content) or FRAC_PLAIN_RE.search(content)) and '分数' not in primary_kp:
        extras.add('分数')
    # 行程
    if ('速度' in content or '相遇' in content or '相向' in content) and '行程' not in primary_kp:
        extras.add('行程')
    # 数论
    if any(w in content for w in ['公倍数', '公因数', '最大公约', '最小公倍']):
        extras.add('数论')

    span = 1 + len(extras)
    return min(span, 4)


def kp_round(k: int) -> int:
    if k <= 1:
        return 1
    if k == 2:
        return 2
    if k == 3:
        return 3
    return 4


# ----------------------- combine + anchor -----------------------------
def combine_v2(round_per_dim: dict) -> dict:
    """V4 combine: V3 carryover + V4 改动 step_count 单维保护.

    Mental-flex dampening (V2.1):
      - mental_flex == R1 + step >= R3 → step - 1
      - mental_flex == R3 + step <= R2 → mental_floor=3

    V3 改动 #1: distractor 单维拉高保护

    V4 改动 #1: step_count 单维拉满 R4 保护（基于 V3 verify B 组反馈）
      - 当 mental_flex <= 1 + calc <= R2 + kp <= R2 时，step_count 上限 R3
      - 解决 daishu#25 / xshchu_xian#9（多空填空但思维直白被 step=4 拉到 R4）
      - Famin: "完全不拐弯，计算量几乎为 0" / "不拐弯的计算，量也不大"

    V4 改动 #2: mental_flex 高分但其他维都低时降一档保护
      - 当 mental_flex==3 + step<=2 + calc=0 时，mental 降到 2（防 R4 误判）
      - Famin shudaishu#3 (修剧透前) 即此 case
    """
    rpd = dict(round_per_dim)
    mental = rpd.get('mental')
    step = rpd.get('step')
    calc = rpd.get('calc')
    kp = rpd.get('kp')

    # V2.1 dampening
    if mental is not None and step is not None:
        if mental == 1 and step >= 3:
            rpd['step'] = step - 1
        if mental >= 3 and step <= 2:
            rpd['mental_floor'] = 3

    # V4 改动 #1: step_count 单维拉满 R4 保护
    step_now = rpd.get('step', step)
    if (step_now == 4 and (mental is None or mental <= 1)
            and (calc is None or calc <= 2)
            and (kp is None or kp <= 2)):
        rpd['step'] = 3
        rpd['_step_capped'] = True  # 标记

    # V4 改动 #2: mental=3 + step<=2 + calc=R1 → mental 降 2
    if (mental == 3 and (step is not None and step <= 2)
            and (calc is not None and calc <= 1)):
        rpd['mental'] = 2
        rpd['_mental_capped'] = True

    # V3 改动 #1: distractor 单维保护
    distractor = rpd.get('distractor')
    if distractor is not None:
        non_distractor = [v for k, v in rpd.items()
                          if v is not None and k not in ('distractor',)
                          and not isinstance(v, bool) and not k.startswith('_')]
        non_distractor_max = max(non_distractor) if non_distractor else 1
        if non_distractor_max <= 2 and distractor > 2:
            rpd['distractor'] = 2
            rpd['_distractor_capped'] = True

    rounds = [v for k, v in rpd.items()
              if v is not None and not isinstance(v, bool) and not k.startswith('_')]
    if not rounds:
        return {'combined_round': None, 'verdict': 'no_signal'}
    max_r = max(rounds)
    s = sorted(rounds)
    median_r = s[len(s) // 2]
    if max_r - median_r >= 2:
        return {
            'combined_round': max_r,
            'verdict': 'high_variance',
            'spread': max_r - median_r,
            'distractor_capped': rpd.get('_distractor_capped', False),
            'step_capped': rpd.get('_step_capped', False),
            'mental_capped': rpd.get('_mental_capped', False),
        }
    return {
        'combined_round': max_r,
        'verdict': 'confident',
        'distractor_capped': rpd.get('_distractor_capped', False),
        'step_capped': rpd.get('_step_capped', False),
        'mental_capped': rpd.get('_mental_capped', False),
    }


# ---- anchor ----------------------------------------------------------

def load_anchors():
    d = json.load(open(ANCHOR_PATH))
    out = []
    for a in d['anchors']:
        # use famin_round if reviewed, else original round
        r = a.get('_famin_review', {}).get('famin_round') or a['round']
        out.append({
            'id': a['anchor_id'],
            'round': r,
            'kp': a.get('kp', ''),
            'type': a.get('type', ''),
            'content': a.get('content', ''),
        })
    return out


def find_nearest_anchor(q: dict, anchors: list, computed_round: int = None) -> dict:
    """Score: kp match 0.5 + type match 0.3 + content sim 0.2.

    V3 改动 #3: 仅在 round ±2 内候选中找 nearest（去除高噪音）
    - 之前 V2: 314 道 anchor_disagree，绝大多数因 KP 同但 round 远（如 R1 题 → R4 锚点）
    - V3: 候选 anchor 必须 round 与 computed_round 差 ≤ 2 才参与对比
    """
    qkp = q.get('knowledge_point', '')
    qtype = q.get('type', '')
    qcontent = set(re.findall(r'[一-鿿]+', q.get('content', '')))

    # V3 改动 #3: round 过滤
    if computed_round is not None:
        candidates = [a for a in anchors if abs(a['round'] - computed_round) <= 2]
        if not candidates:
            candidates = anchors  # fallback 全候选
    else:
        candidates = anchors

    best = None
    best_score = -1
    for a in candidates:
        kp_match = 1.0 if a['kp'] == qkp else (0.5 if a['kp'].split('/')[0] == qkp.split('/')[0] else 0)
        type_match = 1.0 if a['type'] == qtype else 0
        acontent = set(re.findall(r'[一-鿿]+', a['content']))
        sim = len(qcontent & acontent) / max(len(qcontent | acontent), 1)
        score = kp_match * 0.5 + type_match * 0.3 + sim * 0.2
        if score > best_score:
            best_score = score
            best = a
    return best


# --------------------- V1 lookup --------------------------------------
def load_v1_index():
    idx = {}
    with open(V1_PATH) as f:
        for line in f:
            try:
                rec = json.loads(line)
                idx[rec['question_ref']] = rec.get('suggested_round')
            except json.JSONDecodeError:
                continue
    return idx


# --------------------- main pipeline ----------------------------------
def main():
    anchors = load_anchors()
    v1_idx = load_v1_index()

    files = sorted(glob.glob(BATCH_GLOB))
    out_lines = []
    n_total = 0
    skipped = 0
    for fp in files:
        bd = json.load(open(fp))
        if bd.get('_quality_meta', {}).get('deprecated'):
            skipped += len(bd.get('questions', []))
            continue
        fname = os.path.basename(fp)
        for i, q in enumerate(bd.get('questions', [])):
            ref = f'{fname}#{i}'
            n_total += 1
            original_round = q.get('round', 1)

            sc = calc_step_count(q)
            mf = mental_flex_eval(q)
            dr = distractor_eval(q)
            cv = calc_calculation_volume(q)
            ks = calc_kp_span(q)

            r_step = step_round(sc)
            r_mental = mental_round(mf)
            r_distractor = distractor_round(dr)
            r_calc = calc_round(cv)
            r_kp = kp_round(ks)

            round_per_dim = {
                'step': r_step,
                'mental': r_mental,
                'distractor': r_distractor,
                'calc': r_calc,
                'kp': r_kp,
            }
            comb = combine_v2(round_per_dim)
            v2_round = comb['combined_round']

            # anchor validate (V3 改动 #3: 仅 round ±2 内 candidates)
            anchor = find_nearest_anchor(q, anchors, computed_round=v2_round)
            anchor_id = anchor['id'] if anchor else None
            anchor_round = anchor['round'] if anchor else None
            flag = comb['verdict']
            if flag == 'confident' and anchor and abs(v2_round - anchor['round']) >= 2:
                flag = 'anchor_disagree'

            # verdict
            if v2_round == original_round:
                v2_verdict = 'no_change'
            elif abs(v2_round - original_round) >= 2:
                v2_verdict = 'flag_review'
            else:
                v2_verdict = 'suggest_change'

            v1_sug = v1_idx.get(ref)

            reasoning = (
                f'5维: step={sc}({r_step}) mental={mf}({r_mental}) '
                f'distractor={dr}({r_distractor}) calc={cv:.2f}({r_calc}) kp_span={ks}({r_kp}) | '
                f'max={v2_round}, median={sorted([r for r in round_per_dim.values() if r is not None])[len([r for r in round_per_dim.values() if r is not None])//2]}, flag={flag} | '
                f'anchor={anchor_id} (R{anchor_round})'
            )

            rec = {
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'subject': 'math',
                'question_ref': ref,
                'kp': q.get('knowledge_point', ''),
                'content_preview': (q.get('content', '') or '')[:80],
                'type': q.get('type'),
                'group_id': q.get('group_id'),
                'group_order': q.get('group_order'),
                'original_round': original_round,
                'v1_suggested_round': v1_sug,
                'v2_suggested_round': v2_round,
                'v2_dims': {
                    'step_count': sc,
                    'mental_flexibility': mf,
                    'distractor_realness': dr,
                    'calculation_volume': round(cv, 3),
                    'kp_span': ks,
                },
                'v2_round_per_dim': round_per_dim,
                'v2_combined': v2_round,
                'v2_verdict': v2_verdict,
                'v2_flag': flag,
                'v2_anchor_used': anchor_id,
                'v2_anchor_round': anchor_round,
                'v2_reasoning': reasoning,
            }
            out_lines.append(rec)

    # ----------- V3.12.5 §6.5: 组合题难度统一（ceil 平均）-----------
    # 所有题判完后再做组内统一，确保同 group_id 的子题最终 round 一致
    import math
    from collections import defaultdict
    groups = defaultdict(list)
    for rec in out_lines:
        gid = rec.get('group_id')
        if gid:
            groups[gid].append(rec)

    n_unified = 0
    for gid, recs in groups.items():
        if len(recs) <= 1:
            continue  # 单子题（虽有 group_id 但只 1 道）不处理
        rounds = [r['v2_suggested_round'] for r in recs if r.get('v2_suggested_round') is not None]
        if not rounds:
            continue
        avg = sum(rounds) / len(rounds)
        unified = math.ceil(avg)
        for r in recs:
            individual = r['v2_suggested_round']
            r['v2_round_before_group_unify'] = individual  # 留痕原始
            r['v2_suggested_round'] = unified
            r['v2_combined'] = unified
            # 重算 v2_verdict 基于统一后 round
            orig = r['original_round']
            if unified == orig:
                r['v2_verdict'] = 'no_change'
            elif abs(unified - orig) >= 2:
                r['v2_verdict'] = 'flag_review'
            else:
                r['v2_verdict'] = 'suggest_change'
            # reasoning 末尾追加组统一信息
            r['v2_reasoning'] += f' | group_unify(§6.5): individual=R{individual} → group_avg={avg:.2f} → ceil R{unified}'
            if individual != unified:
                n_unified += 1
    n_groups = sum(1 for recs in groups.values() if len(recs) > 1)

    with open(OUT_PATH, 'w') as f:
        for rec in out_lines:
            f.write(json.dumps(rec, ensure_ascii=False) + '\n')
    print(f'V2 reviewer: {n_total} questions, {skipped} skipped (deprecated), wrote {OUT_PATH}')
    print(f'  §6.5 组合题难度统一: {n_groups} 组（≥2 子题），{n_unified} 道题 round 被改写')
    return n_total


if __name__ == '__main__':
    main()
