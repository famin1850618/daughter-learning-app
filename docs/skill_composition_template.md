# Skill 模板：composition-<科目>

> **状态：** V3.12 立项 schema 草案（2026-05-08）。本文件是 Layer 3 Skill 化的设计文档，**未生成实际 skill** —— 数据填充（observation_loop T10）后才执行 T14 生成。
>
> **协同 schema：** `skill_difficulty_template.md` / `skill_realpaper_extract_template.md`

## 设计目标

封装从真题中提炼的命题艺术（Layer 2 craft）成可调用 skill。任何 AI 出题场景（错题变体 / 冷门章节补题 / 临时控档 / 未来 cron 重启）调用 skill 即获能力，跨 session 自然加载。

## 目录结构

```
~/.claude/skills/composition-math/
  SKILL.md                # 入口
  patterns.json           # 题型范式结构化数据（craft schema 实例）
  distractor_lib.md       # 干扰项设计库（按学科）
  examples/               # 真题样例 10-20 道，带 reasoning
    cylinder_packaging.md
    proportion_scale.md
    ...
  rounds_features.md      # R1-R4 各档命题技法
```

每科一份独立 skill：`composition-math` / `composition-chinese` / `composition-english`（未来扩 `composition-physics` / `composition-chemistry`）。

## SKILL.md frontmatter

```yaml
---
name: composition-math
description: 当需要按真题命题艺术生成数学题时使用。典型场景：错题反馈生成同 KP 变体题、冷门章节补题、临时按指定 KP+round 出 N 道题、未来 cron 自动出题。skill 内置 30-50 个 pattern_id（如圆柱表面积·包装类、比例尺与实际距离、统计图选项陷阱），按 pattern 模板生成保证质量。配合 difficulty-math skill 联合使用可精确控档。
version: 0.1.0
tools: ["Read", "Write"]
---
```

`description` 是 Claude 决定是否触发此 skill 的关键字段，要明确写清：
- **何时用**（错题变体 / 临时出题 / cron）
- **核心能力**（pattern + craft）
- **协作 hint**（配合 difficulty skill）

## 调用方式

### 用户触发
```
/composition-math
→ Claude 询问参数：KP / round / count / 题型偏好 → 生成
```

### Agent 调用
```
Skill(skill="composition-math",
      args="kp=圆柱与圆锥/表面积 round=3 count=10 type=mixed")
```

### 自动调用（错题变体 hook）
```
某错题 (kp, original_round) → 自动 invoke composition-<科目>
                              args="kp=<原 kp> round=<原 round> count=3 mode=variant"
```

## 入参 schema

| 字段 | 必填 | 说明 |
|------|------|------|
| `kp` | ✓ | 严格匹配 `lib/database/knowledge_points_seed.dart` 清单（"category/name" 形式）|
| `round` | ✓ | 1/2/3/4，目标难度档（用 difficulty skill 二次确认）|
| `count` | ✓ | 题数（建议 ≤ 20，过多分批）|
| `type` | ✗ | choice / fill / calculation / judgment / mixed（默认 mixed）|
| `mode` | ✗ | new（新出题，默认）/ variant（基于错题变体）/ anchor（基于锚点题变体）|
| `seed_question` | ✗ | mode=variant 时传错题原文 |
| `subject_meta` | ✓ | grade / textbook（如 "北师大六下"）|

## 出参 schema（与 difficulty skill 对齐）

```json
{
  "questions": [
    {
      "chapter": "...",
      "knowledge_point": "...",
      "content": "...",
      "type": "choice|fill|calculation|judgment",
      "options": [...],
      "answer": "...",
      "explanation": "...",
      "round": 3,
      "image": "<svg>...</svg>|null",
      "audio_text": null,
      "speakers": null,
      "_meta": {
        "pattern_id": "cylinder_surface_packaging",
        "round_self_assessed": 3,
        "needs_difficulty_review": true,
        "distractor_strategy": ["忘×2", "忘+底面", ...],
        "ai_template_params": {"r": 5, "h": 10, "情境": "包装"}
      }
    }
  ],
  "skill_version": "0.1.0",
  "generation_meta": {
    "kp_matched_pattern": "cylinder_surface_packaging",
    "fallback_used": false
  }
}
```

**关键：** `_meta` 段是 difficulty skill 的输入。`round_self_assessed` 是 composition 自评，`needs_difficulty_review` 标记是否需要 difficulty skill 二次确认。

## 三联协作接口

```
composition-math output  →  difficulty-math input
{questions[].content,        {content, kp, round_target}
 _meta.round_self_assessed,
 _meta.distractor_strategy}

difficulty-math output  →  composition-math feedback
{round_actual,                 → 不符 round_target 时
 distractor_score,                重新 invoke composition
 calibration_advice}              with adjusted ai_template_params
```

## SKILL.md body 核心段（草案）

```markdown
# Composition Skill - 数学

## 何时使用
- 错题反馈生成同 KP 变体（mode=variant）
- 冷门章节补题（mode=new + kp 指定）
- 临时控档出题（配合 difficulty-math）
- 未来 cron 自动出题（场景 D）

## 工作流
1. 读 patterns.json，按 args.kp 找匹配 pattern_id
2. 找不到匹配 → fallback 到 examples/ 找最接近真题
3. 用 ai_template 生成（参数随机但 LaTeX/单位/陷阱设计严格按 pattern）
4. 套 distractor_lib.md 的干扰项策略
5. self-check 是否符合 round_self_assessed 的 r{N}_features 描述
6. 输出 + 标 `needs_difficulty_review: true`

## 不做的事
- 不评估 round（让 difficulty skill 做）
- 不入库（让 realpaper-extract 或主 session 做）
- 不绕过 KP 严格匹配（args.kp 不在清单 → 报错）
```

## patterns.json 数据 schema（与 observation_loop T9 一致）

```json
[
  {
    "subject": "math",
    "grade": 6,
    "pattern_id": "cylinder_surface_packaging",
    "pattern_name": "圆柱表面积应用·包装/油漆类",
    "typical_form": "给定 r, h，问需要多少 m² 包装纸 / 多少升油漆",
    "rounds_seen": [1, 2, 3],
    "r1_features": "整数 r/h，纯表面积；选项明显错（忘×2/忘+底面）",
    "r2_features": "加单位换算；近似值干扰",
    "r3_features": "隐藏'开口圆柱'提示；陷阱'忘开口'",
    "r4_features": "跨章节（圆柱+比例+利润）",
    "distractor_design": [
      "忘×2（只算单底）",
      "忘+底面（只算侧面）",
      "单位换算错（cm² 没转 m²）",
      "开口圆柱减底面但减成俩"
    ],
    "real_examples": [
      "realpaper_g6_math_beishida_d1_guoguan_001#5",
      "realpaper_g6_math_beishida_kaodian_guoguan_002#12"
    ],
    "ai_template": "r ∈ {2,3,5,10}, h ∈ {6,8,10,15}, 情境 ∈ {油漆/包装/标签}, 单位陷阱 ∈ {cm/m}",
    "latex_pattern": "$S=2\\pi r^{2}+2\\pi rh$"
  }
]
```

## 与现有项目代码的接口

- 严格遵循 `daughter_learning_app/docs/realpaper_quality_rules.md` 五条原则
- KP 严格匹配 `lib/database/knowledge_points_seed.dart`
- 输出 JSON 与 `lib/services/question_update_service.dart` 的 `_importBatchJson` 兼容
- 数学公式 LaTeX 双反斜杠（JSON 中 `\\frac` `\\pi`），Dart 解析后单反斜杠

## 进入 ~/.claude/skills/ 前的 checklist

T14 实施时需先满足：
- [ ] patterns.json 累积 ≥ 20 个 pattern（observation_loop T10 完成）
- [ ] distractor_lib.md 累积 ≥ 30 条干扰项策略
- [ ] examples/ 含 ≥ 10 道带 reasoning 的真题样例
- [ ] difficulty-<科目> skill schema 已对齐（本文件 + skill_difficulty_template.md 互查）
- [ ] Famin 拍板 skill 化（按 feedback_skill_extraction.md "不擅自创建"原则）
