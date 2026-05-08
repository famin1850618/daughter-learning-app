# Skill 模板：realpaper-extract

> **状态：** V3.12 立项 schema 草案（2026-05-08）。本文件是 Layer 3 Skill 化的设计文档，**未生成实际 skill** —— V3.10 pipeline 资产盘点（T-RP1）后才执行 T-RP2 生成。
>
> **协同 schema：** `skill_composition_template.md` / `skill_difficulty_template.md`

## 设计目标

把 V3.10 起稳定的真题入库 pipeline（PDF/图片 → 标准 batch JSON）封装成 skill。Famin 提供 PDF 即可调用 skill 一键完成 extract → segment → match_ans → KP 标 → round 评估 → 双写 JSON → 注册。

V3.10 起这个 workflow 已在 ≥ 5 次 session 复用（V3.10.0 / 各批次 / V3.12 B 阶段都用），完全符合 `feedback_skill_extraction.md` 4 条触发条件中的 1 + 2 + 3。

## 目录结构

```
~/.claude/skills/realpaper-extract/
  SKILL.md                  # 入口
  pipeline.md               # 4 步 pipeline 详解 + 每步常见报错
  scripts/                  # V3.10 已稳定脚本拷贝
    extract.py              # PDF → raw text（pdftotext）
    segment.py              # raw text → 题目段（含全角句号 / 大题感知）
    match_ans.py            # 题目段 ↔ 答案配对（big_section + local_idx）
    validate.py             # JSON schema 验证
  kp_match_template.md      # 标 KP 时的对照清单
  round_assign_guide.md     # round 评估接口（调 difficulty skill）
  troubleshooting.md        # OCR 乱字 / 全角句号 / 大题重置等踩过的坑
  manifest_schema.md        # docs/realpaper_manifest.json schema 说明
```

仅一份 skill，跨学科通用（输入参数指定 subject / grade / textbook）。

## SKILL.md frontmatter

```yaml
---
name: realpaper-extract
description: 当需要把真题 PDF（北师大数学/部编语文/人教物理化学/PET 英语）转成 daughter_learning_app 标准 batch JSON 入库时使用。典型场景：Famin 提供 PDF 一键入库、批量处理 cache 中已下载真题、新教材版本扩展。Skill 内置 V3.10 起稳定的 4 步 pipeline（pdftotext → segment → match_ans → validate）+ 踩坑清单（OCR 乱字、全角句号、大题感知配对、双引号替换）+ KP 匹配模板 + 与 difficulty skill 联动评 round。输出标准 batch JSON 双写 assets/data/batches/ 和 question_bank/。
version: 0.1.0
tools: ["Read", "Write", "Bash", "Edit"]
---
```

## 调用方式

### 用户触发
```
/realpaper-extract
→ Skill 询问：PDF 路径 / subject / grade / textbook / 卷子类型（单元卷/期中/期末/真题）
→ 跑 pipeline → 输出 batch JSON
```

### Agent 调用
```
Skill(skill="realpaper-extract",
      args="pdf=/path/to/paper.pdf subject=math grade=6 textbook=北师大 paper_type=guoguan unit=1 batch_id=001")
```

### 批量调用
```
Skill(skill="realpaper-extract",
      args="cache_dir=.cache/realpaper subject=math grade=6 limit=10 mode=batch")
→ 处理 cache 中已下载未标注的卷
```

## 入参 schema

| 字段 | 必填 | 说明 |
|------|------|------|
| `pdf` 或 `cache_dir` | ✓ | 单卷 PDF 路径 / 批量 cache 目录 |
| `subject` | ✓ | math / chinese / english / physics / chemistry |
| `grade` | ✓ | 6 / 7 / 8 / 9 |
| `textbook` | ✓ | 北师大 / 部编 / 外研社 / 人教 / Cambridge-PET |
| `paper_type` | ✓ | guoguan（单元过关）/ qizhong（期中）/ qimo（期末）/ zhouce（周测）/ zonghe（综合）/ other |
| `unit` | ✗ | 单元号（1-N，按教材）|
| `batch_id` | ✗ | 同 paper_type+unit 多次入库时区分（001/002/...）|
| `mode` | ✗ | single（单卷，默认）/ batch / cache_audit（仅审 cache 不入库）|
| `evaluate_round` | ✗ | true/false（默认 true）；true 时调 difficulty-<科目> skill 评每题 round |
| `dry_run` | ✗ | true/false；true 仅生成 JSON 不双写 + 不注册（看效果用）|

## 出参 schema

```json
{
  "batch_id": "realpaper_g6_math_beishida_kaodian_guoguan_009",
  "source": "realpaper_g6_math_beishida_kaodian_guoguan_009",
  "questions": [...],
  "stats": {
    "total_extracted": 28,
    "total_segmented": 25,
    "total_matched": 23,
    "skipped_image_dependent": 5,
    "skipped_subjective": 0,
    "type_distribution": {"choice": 8, "fill": 10, "calculation": 5},
    "round_distribution": {"1": 5, "2": 12, "3": 5, "4": 1}
  },
  "files_written": [
    "assets/data/batches/realpaper_g6_math_beishida_kaodian_guoguan_009.json",
    "question_bank/realpaper_g6_math_beishida_kaodian_guoguan_009.json"
  ],
  "registry_updates": {
    "index_json_added": true,
    "main_dart_bundled_added": true
  },
  "observations_appended": [
    "新坑：本卷有 4 题用 ↑ 箭头表示数量增加，OCR 识别为 'I'，已手动替换"
  ],
  "skill_versions_used": {
    "realpaper-extract": "0.1.0",
    "difficulty-math": "0.1.0"
  }
}
```

## pipeline.md 4 步草案

```markdown
# Realpaper Extract Pipeline

## Step 1: extract.py
PDF → raw.txt
- 工具：pdftotext（不要 libreoffice，会当 Draw 处理）
- 输出：.cache/realpaper/<sha1>/raw.txt
- 常见报错：
  - 扫描版 PDF（无文本层）→ 报错，提示 Famin 用 OCR 引擎重新预处理
  - 复杂表格错位 → 跳过该卷，记 manifest

## Step 2: segment.py
raw.txt → segmented.json（题目段列表）
- 题号识别：`(?:\.(?!\d)|[、．])` 大题 + 全角句号 U+FF0E
- 大题重置：遇到 "一." "二." "三." 重置 local_idx
- 答案边界：`^\s*答案\s*$` 多行模式
- 常见报错：
  - 题号识别错（如英文真题用阿拉伯数字 + ）→ 切 alt_pattern
  - 答案区在末尾跨页断裂 → 手动合并

## Step 3: match_ans.py
segmented.json → matched.json（题 + 答案配对）
- key: (big_section, local_idx) tuple
- 避免 "一.1 二.1 三.1" 互覆盖

## Step 4: validate.py + 标 KP + 评 round
- 用 kp_match_template.md 对照清单标 KP（严格匹配 knowledge_points_seed.dart）
- 调 difficulty-<科目> skill 评 round（如 evaluate_round=true）
- 套 realpaper_quality_rules.md 5 条原则自查
- 输出标准 batch JSON
- 双写 assets/data/batches/ + question_bank/
- 更新 question_bank/index.json
- 更新 lib/main.dart 的 _bundledBatchAssets 数组
```

## 三联协作接口

```
realpaper-extract output → difficulty-<科目> input
{questions[].content,         {content, kp, mode=evaluate}
 questions[].kp}              ← 每题调一次

difficulty-<科目> output → realpaper-extract input
{round_actual,                  → realpaper-extract 设置 batch JSON 中 round 字段
 confidence}

realpaper-extract output → composition skill 反向 update
{questions[],                    → composition skill 检查是否有新 pattern
 stats}                          → 如有 → append 到 patterns.json
                                 → 闭环：未来 AI 出题就有这层新模式

realpaper-extract → observations_<科目>.md
{踩坑沉淀 + dedup}              → 工程坑层闭环
```

## kp_match_template.md 草案

按 subject + grade 列已存 KP 清单（从 knowledge_points_seed.dart dump），agent 标 KP 时只能选清单内项：

```markdown
# 数学六下 KP 匹配清单

## 圆柱与圆锥
- 圆柱与圆锥/侧面积
- 圆柱与圆锥/表面积
- 圆柱与圆锥/体积
- 圆柱与圆锥/展开图
- 圆柱与圆锥/与正方体长方体比较
- 圆柱与圆锥/实际应用

## 比和比例
- 比和比例/化简比
...
```

## 进入 ~/.claude/skills/ 前的 checklist

T-RP2 实施时需先满足：
- [x] V3.10 pipeline 在 ≥ 5 次 session 复用（已满足）
- [ ] T-RP1 资产盘点（4 个脚本 + manifest schema + observations）完成
- [ ] difficulty-<科目> skill schema 已对齐（本文件 + skill_difficulty_template.md 互查）
- [ ] kp_match_template.md 全学科 dump（grep knowledge_points_seed.dart）
- [ ] Famin 拍板 skill 化

## 与现有项目代码的接口

- 输出 JSON 与 `lib/services/question_update_service.dart._importBatchJson` 兼容
- 注册到 `question_bank/index.json` + `lib/main.dart._bundledBatchAssets`
- 严格遵循 `daughter_learning_app/docs/realpaper_quality_rules.md`
- 沉淀踩坑到 `docs/realpaper_observations_<科目>.md`
- 与 `feedback_kp_discipline.md`：扩题前先列 KP，名字严格匹配
- 与 `feedback_question_quality.md`：禁开放题、输入法限制、抽样试做

## 设计权衡（一份 skill 跨学科 vs 每科一份）

**选定：一份 realpaper-extract 跨学科**（与 composition / difficulty 每科一份相反）

**Why：**
- pipeline 步骤跨学科一致（PDF→文本→段→配对→标 KP→评 round）
- 学科差异在数据层（KP 清单 / 教材结构 / 题型分布）—— 通过入参传，不需要分 skill
- composition / difficulty 跨学科差异在能力层（命题艺术 / 评估算法）—— 必须分 skill
- 一份 skill 维护成本低，pipeline 升级一次全学科受益
