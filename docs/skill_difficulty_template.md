# Skill 模板：difficulty-<科目>

> **状态：** V3.12 立项 schema 草案（2026-05-08）。本文件是 Layer 3 Skill 化的设计文档，**未生成实际 skill** —— 校准数据足后才执行 T6 生成。
>
> **协同 schema：** `skill_composition_template.md` / `skill_realpaper_extract_template.md`

## 设计目标

封装锚点题 + rubric 校准为可调用 skill，**评估**或**校准**任意题目的 round（1-4）。专注做难度判定一件事，不出题、不入库。与 composition skill 联合调用即可精确控档出题。

## 目录结构

```
~/.claude/skills/difficulty-math/
  SKILL.md                  # 入口
  anchors.json              # 锚点题 R1-R4 各 5 道（带 reasoning）
  rubric.md                 # 校准后的文字 rubric（活文档，版本化）
  evaluate.md               # 评估算法（步骤数 / 陷阱密度 / KP 跨度 / 数据复杂度）
  calibration_log/          # 校准证据滚动累积
    famin_feedback.jsonl    # T3 实测反馈
    learning_data.jsonl     # T4 学情数据反推
    reviewer_runs.jsonl     # T2 reviewer agent 重审记录
```

每科一份独立 skill：`difficulty-math` / `difficulty-chinese` / `difficulty-english`。

## SKILL.md frontmatter

```yaml
---
name: difficulty-math
description: 当需要评估或校准数学题难度（round 1-4）时使用。典型场景：composition skill 出题后二次确认 round、入库前对真题/AI 生成题打标、错题变体保 round 一致、reviewer agent 重审历史 batch、Famin 实测反馈累积后 rubric 自动调整。skill 内置 20 道公认锚点题（R1-R4 各 5 道带 reasoning）+ 活 rubric + 4 维评估算法（步骤数/陷阱密度/KP 跨度/数据复杂度）。配合 composition-math skill 联合调用可精确控档出题。
version: 0.1.0
tools: ["Read"]
---
```

## 调用方式

### 评估模式（mode=evaluate）
```
Skill(skill="difficulty-math",
      args="content=<题面> kp=<KP> mode=evaluate")
→ 返回 {round_actual, confidence, reasoning, anchor_match}
```

### 校准模式（mode=calibrate）
```
Skill(skill="difficulty-math",
      args="content=<题面> round_target=3 mode=calibrate")
→ 返回 {round_actual, gap, advice}
gap < 0：题偏简单于 target，建议加 [陷阱/隐藏条件/单位换算]
gap > 0：题偏难于 target，建议减 [步骤/概念跨度]
gap = 0：符合 target，可入库
```

### 批量重审模式（mode=batch_review）
```
Skill(skill="difficulty-math",
      args="batch_path=<json> mode=batch_review")
→ 返回每题修改建议清单（reviewer agent 用，不直接改文件）
```

### 用户触发
```
/difficulty-math
→ 询问要评估哪道题 / 哪个 batch
```

## 入参 schema

| 字段 | 必填 | 说明 |
|------|------|------|
| `content` | 视 mode | 题面（mode=evaluate/calibrate 必填）|
| `options` | ✗ | choice 题选项（评估陷阱密度用）|
| `answer` | ✗ | 标准答案（评估解题步骤数用）|
| `kp` | ✓ | KP 路径（找匹配锚点）|
| `mode` | ✓ | evaluate / calibrate / batch_review |
| `round_target` | calibrate 必填 | 目标 round 1-4 |
| `batch_path` | batch_review 必填 | batch JSON 路径 |
| `subject_meta` | ✓ | grade / textbook |

## 出参 schema

### Evaluate 模式
```json
{
  "round_actual": 3,
  "confidence": 0.85,
  "reasoning": "3 步推理 + 隐藏'开口圆柱'条件 + 跨章节(圆柱+比例)。陷阱选项含'忘开口'和'单位换算错'两类干扰，符合 R3 features.",
  "anchor_match": {
    "anchor_id": "math_r3_anchor_3",
    "similarity": 0.78,
    "anchor_reasoning": "..."
  },
  "evaluation_breakdown": {
    "step_count": 3,
    "distractor_density": 0.75,
    "kp_span": 2,
    "data_complexity": 0.6
  }
}
```

### Calibrate 模式
```json
{
  "round_actual": 2,
  "round_target": 3,
  "gap": -1,
  "advice": [
    "加 1 个隐藏条件（如'开口圆柱'/'底面被遮挡')",
    "选项加 1 个'部分对'陷阱（步骤少一步的结果）",
    "数据用 7 ↔ 22/7 这类隐性π近似挑战"
  ],
  "reasoning": "原题只有 2 步纯公式，无干扰项设计，建议升级到 R3 需补全 distractor_design"
}
```

## 三联协作接口

```
INPUT 来源：
  composition skill output → {content, kp, _meta.round_self_assessed}
  realpaper-extract output → {content, kp}
  Famin 直接输入 → {content, mode}

OUTPUT 去向：
  composition skill feedback → 不符 round_target 时反馈调整 ai_template_params
  入库 hook → 标 round 字段后写题包 JSON
  calibration_log → 每次 evaluate/calibrate 落档（学情反推用）
```

## anchors.json 数据 schema（T1 锚点题成果）

```json
[
  {
    "subject": "math",
    "grade": 6,
    "round": 3,
    "anchor_id": "math_r3_anchor_3",
    "content": "...",
    "options": [...],
    "answer": "...",
    "kp": "圆柱与圆锥/表面积",
    "reasoning": "R3 因为 3 步推理（公式 + 单位换算 + 减底面） + 隐藏'开口'条件 + 选项 4 个陷阱设计中 2 个'部分对'",
    "source_ref": "北师大六下教材 P88 单元综合 5",
    "evaluation_breakdown": {
      "step_count": 3,
      "distractor_density": 0.75,
      "kp_span": 2,
      "data_complexity": 0.6
    }
  }
]
```

每科 20 道（R1×5 / R2×5 / R3×5 / R4×5）。reasoning 段 = composition skill craft 的 r{N}_features 训练样本（T1 与 observation_loop T9 协同）。

## evaluate.md 算法草案

```markdown
# 难度评估 4 维算法

## 维度 1: 步骤数（step_count）
解题需要的概念应用步骤。
- 1 步：直接代公式 / 直接选答案 → R1
- 2 步：1 个公式 + 1 次单位换算 / 1 次比较 → R2
- 3 步：多公式综合 / 隐含步骤 → R3
- 4+ 步：跨章节综合 / 反证 / 多解 → R4

## 维度 2: 陷阱密度（distractor_density, choice 题）
4 选项中"看似合理但有偏差"的选项占比：
- 0.0-0.25：1 对 3 错（错答明显） → R1
- 0.25-0.5：1 对 2 错 1 近似 → R2
- 0.5-0.75：1 对 1 部分对 2 概念偏差 → R3
- 0.75+：错选项需正向算才能排除 → R4

## 维度 3: KP 跨度（kp_span）
涉及概念数：1 → R1，2 → R2/R3，3+ → R3/R4

## 维度 4: 数据复杂度（data_complexity）
- 整数小数 < 100 → R1
- 加单位换算 / 分数 → R2
- 隐性 π 近似 / 多步运算 → R3
- 字母代数 / 极限化 → R4

## 综合 round
取 4 维 round 的中位数 + 锚点题相似度加权（max similarity > 0.7 时直接采用锚点 round）
```

## SKILL.md body 核心段（草案）

```markdown
# Difficulty Skill - 数学

## 何时使用
- composition skill 出题后二次确认 round（联合调用）
- 真题入库前打 round 标
- 错题变体保 round 一致
- reviewer agent 重审历史 batch（T2）
- Famin 临时拿一道题问"这是 R 几"

## 工作流（evaluate）
1. 读 anchors.json，按 args.kp 找最近 5 道锚点
2. 用 evaluate.md 4 维算法分别打分（step_count / distractor_density / kp_span / data_complexity）
3. 4 维 round 中位数 + 锚点相似度加权 → round_actual
4. 检查 calibration_log/ 看本 KP 是否有近期 Famin 反馈或学情反推记录 → 微调 round_actual
5. 输出 round_actual + confidence + reasoning

## 工作流（calibrate）
1. 先 evaluate 拿 round_actual
2. 与 round_target 比较 gap
3. gap < 0 → 列升档建议（加陷阱/隐藏条件/换算）
4. gap > 0 → 列降档建议（减步骤/缩 KP 跨度）
5. gap = 0 → 直接放行

## 不做的事
- 不出题（让 composition skill 做）
- 不改 batch JSON（让 reviewer agent 或主 session 做）
- 不擅自更新 rubric.md（要走 T7 升级流程，Famin 拍板）
```

## rubric.md 活文档约定

- rubric.md 是版本化文档，每次 Famin 反馈 / 学情反推触发更新都加 changelog
- 改 rubric → 重生成 skill（T6）
- changelog 段：
  ```
  ## 2026-05-22 update (Famin 反馈 #15)
  - R3 数学题"3 步推理"标准下调到"2 步 + 1 隐藏条件"，因女儿实测 3 步纯公式题感觉是 R2
  - 影响 batch：realpaper_g6_math_d1_guoguan_001 中 #5 #8 重赋 R2
  ```

## 进入 ~/.claude/skills/ 前的 checklist

T6 实施时需先满足：
- [ ] anchors.json 含 ≥ 20 道带 reasoning（T1 完成）
- [ ] T2 reviewer agent 跑过至少一轮（reviewer_runs.jsonl 有 ≥ 50 条记录）
- [ ] T3 Famin 反馈累积 ≥ 30 条
- [ ] composition-<科目> skill schema 已对齐（本文件 + skill_composition_template.md 互查）
- [ ] Famin 拍板 skill 化
