# Difficulty 算法 V2 — 数学（V3.12 D2 反馈迭代）

> **状态：** V3.12 D2 数学 reviewer V1 跑出 1010 道，Famin 抽审 15 道 flag_review，**算法准确率仅 13%**。本 V2 算法基于 19 个 Famin 标注样本（D1 锚点 4 改档 + D2 抽审 15）反向提炼。
>
> **协同：** `skill_difficulty_template.md`（schema）/ `anchor_questions_g6_math.json`（锚点 20 道，已修 source_ref +1 偏移）/ `realpaper_quality_rules.md` §7（round 源头权威）

---

## V1 → V2 核心改动

| 改动 | V1 | V2 |
|------|-----|-----|
| step_count 实现 | 数 explanation 中"先...再..."等关键词 | **从 content 独立分析**（数字/未知量/换算/公式调用） |
| 维度数 | 4 维（step / distractor / kp_span / data_complexity） | **5 维**（拆 data_complexity → calculation_volume；新增 mental_flexibility） |
| distractor_density | 数 4 选项语义近似度 | **改名 distractor_realness**：1 对 3 错明显（假陷阱）vs 部分对（真陷阱） |
| kp_span 实现 | 数题面提到的概念名 | **从解题路径分析**（不看题面文字） |
| 综合方式 | 中位数 | **max + 单维虚高保护**（max 与中位数差 ≥ 2 → flag_review） |

---

## 5 维详细规范

### 维度 1：step_count（步骤数，实现修正）

**不依赖 explanation。从 content 独立分析。**

```python
def calc_step_count(content, type, options=None):
    数字数 = count_numbers_in_content(content)  # 含分数 / 单位带的数字
    未知量数 = content.count('（') + content.count('___') + content.count('?')
    单位换算 = count_unit_conversions(content)  # cm↔m / 元↔角 / 时↔分 / kg↔g
    公式调用 = identify_formulas(content, kp)   # 圆柱体积/比例/方程
    
    return max(
        max(数字数 - 1, 0),
        未知量数,
        单位换算 + max(公式调用 - 1, 0),
    )
```

档位：
| step_count | round |
|----|----|
| 0-1 | R1 |
| 2 | R2 |
| 3 | R3 |
| 4+ | R4 |

**Famin 数据验证：**
- `qimo_003#40`（"小明班 9/41 是男生..."）：数字 4 个 / 未知量 1 / 比例换算 2 → step_count = 3 → R3 ✓（Famin 实际 R4，差 1 档可接受）
- `xingjitongji_001#15`：圆柱体积 + 单位换算 → step_count = 3 → R3 ✓（Famin "至少 R3"）
- `kaodian_zonghe_001#15`（"算两个分数加减乘除..."）：数字 5 个 + 4 运算 → step_count = 4 → R4 ⚠️（Famin "R2"，因 mental_flex 低）

### 维度 2：mental_flexibility（思维灵活性，**新增**）

**LLM 看 content + answer，判断是否需要"非显而易见的解法"。**

```yaml
rubric:
  R1 (=0):
    description: 直接套公式 / 概念辨析
    examples:
      - 已知 r,h 求圆柱体积
      - 圆柱与圆锥关系判断（"等底等高时圆锥体积是圆柱 1/3"）
  
  R2 (=1):
    description: 多步但每步都直接（无突破）
    examples:
      - 计算量大但思路直白（先算面积再算体积）
      - 比例传递（a/b 与 b/c 推 a/c）
  
  R3 (=2):
    description: 需要"想到"非显而易见的解法
    keywords: ["求公倍数", "反证", "转化", "思维要绕一下"]
    examples:
      - mokuai_jisuan#39（"思维上不容易找到求公倍数的想法"）
      - qizhong_003#16（"思路稍微要绕一下"）
  
  R4 (=3):
    description: 需要多次思维突破
    keywords: ["几个步骤的转折都不是直接的", "思维需要转不少弯"]
    examples:
      - mokuai_daishu#34（"至少 R3，从步骤和思维要求上看"）
      - xshchu_xian#36（"思维需要转不少弯。小学生没有太强的方程思维能力"）
```

**实现：** LLM agent 看完 content + answer + explanation 后给 0-3 评分，必须引用 anchor `_famin_review.comment` 作判断锚定。

### 维度 3：distractor_realness（陷阱真实性，原 distractor_density 修正）

**仅 choice 题用。fill / calc / judgment 不参与。**

```yaml
rubric:
  R1 (=0):
    description: 1 对 3 错，错答都明显错（"假陷阱"）
    examples:
      - chinese_r3_anchor_1（"褒贬明显，选项无任何迷惑性"，Famin 改 R1）
  
  R2 (=1):
    description: 1 对 2 错 1 近似（数值 / 同类）
    
  R3 (=2):
    description: 1 对 1 部分对 2 概念偏差（"真陷阱"）
  
  R4 (=3):
    description: 错选项需正向算才能排除
```

**实现：** LLM 看 4 个选项 + 答案推导，判断每个错选项的"陷阱迷惑力强度"。

### 维度 4：calculation_volume（计算量，**从 data_complexity 拆**）

**Famin 数据：5 道明确反馈"计算量本身值 R2"。**

```python
def calc_calculation_volume(content):
    运算符数 = count(content, ['+', '-', '×', '÷', '*', '/', '∶'])
    最大数字 = max(extract_numbers(content))
    含浮点 = '.' in content or 'π' in content
    含大数除法 = check_division_complexity(content)
    含分数 = '/' in content and not is_ratio(content)
    
    score = (
        (运算符数 >= 3) * 0.3 +
        (最大数字 >= 100) * 0.2 +
        含浮点 * 0.15 +
        含大数除法 * 0.2 +
        含分数 * 0.15
    )
```

档位：
| score | round |
|----|----|
| 0.0-0.2 | R1 |
| 0.2-0.5 | R2 |
| 0.5-0.75 | R3 |
| 0.75+ | R4 |

**Famin 数据验证：**
- `kaodian_zonghe_001#15`（多步计算）：运算符 5 / 大数 / 浮点 → 0.65 → R3 ⚠️ Famin 觉得 R2（mental_flex 应 R1 拉低）
- `qimo_003#36`（圆柱表面积带 π）：运算符 4 / 含 π → 0.45 → R2 ✓
- `xshchu_xian#7`（圆柱圆锥应用）：运算符 4 / 含浮点 → 0.45 → R2 ✓

### 维度 5：kp_span（KP 跨度，实现修正）

**从解题路径分析，不看题面文字。**

```python
def calc_kp_span(content, answer, kp):
    # 主 KP（数据中的 knowledge_point 字段）
    primary_kp = parse_kp_path(kp)
    
    # 解题路径中需要的额外 KP
    extra_kps = []
    if has_unit_conversion(content): extra_kps.append('单位换算')
    if has_proportion_in_solution(answer): extra_kps.append('比例')
    if has_formula_in_solution(answer): extra_kps.append('公式应用')
    if has_geometric_thinking(content): extra_kps.append('几何')
    if has_algebra_thinking(answer): extra_kps.append('方程思维')
    
    return 1 + len(set(extra_kps))
```

档位：
| kp_span | round |
|----|----|
| 1 | R1 |
| 2 | R2 |
| 3 | R3 |
| 4+ | R4 |

---

## 综合算法（max + 单维虚高保护）

```python
def combine_v2(round_per_dim: dict) -> dict:
    """
    round_per_dim = {
      'step_count': 3,
      'mental_flexibility': 2,
      'distractor_realness': 1,  # choice only, else None
      'calculation_volume': 2,
      'kp_span': 1,
    }
    """
    rounds = [r for r in round_per_dim.values() if r is not None]
    
    if not rounds:
        return {'combined_round': None, 'verdict': 'no_signal'}
    
    max_r = max(rounds)
    median_r = sorted(rounds)[len(rounds) // 2]
    
    # 单维虚高保护：max 与中位数差 ≥ 2 → flag_review
    if max_r - median_r >= 2:
        # 单维拉高，需要 Famin 复核
        return {
            'combined_round': max_r,
            'verdict': 'high_variance_flag_review',
            'spread': max_r - median_r,
        }
    
    return {'combined_round': max_r, 'verdict': 'confident'}
```

---

## 锚点对比验证（额外保护）

```python
def anchor_validate(question, computed_round, anchors):
    """
    1. 找最近邻锚点（同 KP + 同题型 + 题面相似度）
    2. 对比 computed_round 与 anchor.round（Famin 修正后的）
    3. 差 ≥ 2 档 → flag_review（可能算法在该 KP 仍偏）
    """
    nearest = find_nearest(question, anchors, weights={'kp': 0.5, 'type': 0.3, 'sim': 0.2})
    if not nearest:
        return None
    
    shift = abs(computed_round - nearest['round'])
    if shift >= 2:
        return {'flag': 'anchor_disagree', 'anchor': nearest['anchor_id'],
                'anchor_round': nearest['round'], 'computed': computed_round}
    return None
```

---

## 优先级（综合三层信号）

```python
def final_round(question, anchors):
    dims = {
      'step_count': calc_step_count(question),
      'mental_flexibility': llm_eval_mental_flex(question),
      'distractor_realness': llm_eval_distractor(question) if question['type']=='choice' else None,
      'calculation_volume': calc_calculation_volume(question),
      'kp_span': calc_kp_span(question),
    }
    combined = combine_v2(dims)
    
    if combined['verdict'] == 'high_variance_flag_review':
        return {'round': combined['combined_round'], 'flag': 'high_variance', 'dims': dims}
    
    anchor_check = anchor_validate(question, combined['combined_round'], anchors)
    if anchor_check:
        return {'round': combined['combined_round'], 'flag': anchor_check['flag'],
                'anchor': anchor_check, 'dims': dims}
    
    return {'round': combined['combined_round'], 'flag': 'confident', 'dims': dims}
```

---

## 预期 V2 改进

基于 19 个 Famin 标注样本回归测试：

| 指标 | V1 | V2 预期 |
|------|-----|--------|
| 算法准确率（flag_review 抽审）| 13%（2/15）| **40-60%** |
| R3→R1 严重低估 | 151 道 | < 50 道 |
| max 综合让 step_count=3 不被拉低 | ❌ | ✓ |
| mental_flexibility 区分"步骤多但简单"vs"思维转弯" | ❌ | ✓ |

**仍主观的部分：**
- mental_flexibility 仍是 LLM 看题判断（无法完全量化）
- distractor_realness 同上

但比 V1 大幅减少跨档冲突（特别 R3↔R1）。

---

## 跨科目适配（语文 / 英语 V2 依据本草案改写各自维度）

数学 V2 完成后，语文 / 英语 V2 各自版本：

**语文：**
- step_count → "理解层级"（字面 / 推断 / 综合分析 / 鉴赏评价）
- calculation_volume → "阅读字数 + 文言难度"
- mental_flexibility → "鉴赏深度"
- distractor_realness → "近义/同类干扰强度"
- kp_span → "跨课文/跨修辞"

**英语：**
- step_count → "语言层级"（词形 / 句型 / 段 / 篇）
- calculation_volume → "句长 + CEFR 词汇"
- mental_flexibility → "推断深度"
- distractor_realness → "时态相近 / 介词混淆"
- kp_span → "跨语法点"

---

## 验证流程

1. 实现算法 V2（脚本 + LLM 主观维度）
2. 跑数学 1010 题（D2 V2）
3. 对比 V1 vs V2 verdict 收敛：
   - V1 flag_review 163 道 → V2 多少？
   - V1 算法 vs Famin 抽 15 道 13% → V2 多少？
4. Famin 再抽 10 道复核 V2 输出
5. 算法稳定后落到 `~/.claude/skills/difficulty-math/evaluate.md`（T6 skill 化时）

---

**生成时间：** 2026-05-08
**对应 task：** D2+ 算法升级（V3.12 D2 反馈迭代）
