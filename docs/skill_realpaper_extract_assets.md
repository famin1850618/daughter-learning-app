# Realpaper-Extract Skill 资产盘点（R1 / V3.12 立项）

> **状态：** V3.12 立项 R1 task（2026-05-08）。本文件清单 V3.10 起稳定的真题入库 pipeline 全部资产，作为 T-RP2 skill 化的输入。skill 生成时按本文件 → `~/.claude/skills/realpaper-extract/` 拷贝/封装。

**协同文档：** `skill_realpaper_extract_template.md`（schema）+ `realpaper_workflow_progress.md`（V3.10 进度）+ `realpaper_observations_*.md`（坑沉淀）

## 一、Pipeline 脚本（tools/realpaper/）

| 文件 | 行数 | 作用 | skill 化时归 |
|------|------|------|------------|
| `extract.py` | 163 | PDF/.doc/.docx → raw.txt（libreoffice headless 转换 + sha1 缓存）| `scripts/extract.py` |
| `segment.py` | 187 | raw.txt → segmented.json（题号识别 + 大题重置 + 答案边界）| `scripts/segment.py` |
| `match_ans.py` | 135 | segmented.json → matched.json（题/答配对：(big_section, local_idx) tuple）| `scripts/match_ans.py` |
| `validate.py` | 174 | JSON schema 验证（解析 555 KP + 180 chapter）| `scripts/validate.py` |

**关键设计决策：**
- sha1 文件缓存（同一文件只转一次）：`.cache/realpaper/<sha1>/{raw.txt, segmented.json, matched.json}`
- 不在脚本里调 LLM，agent 端读 matched.json 后再标 KP/round
- libreoffice 走 PDF 不行（V3.10 实测，当 Draw 处理）→ V3.10 后改 pdftotext，extract.py 注释里要更新

## 二、文档资产（docs/）

| 文件 | 行数 | 作用 | skill 化时归 |
|------|------|------|------------|
| `realpaper_quality_rules.md` | 183 | V3.12 真题质量 5 条原则（数学不剧透 / LaTeX / 英语全英文 / 禁中→英 / 听力 speakers）| `quality_rules.md`（独立保留 + skill 内引用）|
| `realpaper_workflow_progress.md` | 81 | V3.10 进度跟踪 + Stage 0/1 task 状态 | 不进 skill（项目级文档）|
| `realpaper_manifest.json` | 617 | 每卷处理状态（sha1 / sourcefile / status / batch_id / KP / round 分布）| `manifest_schema.md`（仅文档化 schema，不拷数据）|
| `realpaper_kp_pending.json` | 7 | KP 等候区（已用 ≥ 10 卷的 KP 待 Famin review）| `kp_pending_schema.md`（schema 文档化）|
| `cambridge_english_kp_draft.md` | 379 | Cambridge PET/FCE/CAE KP 清单草稿 | 英语题 KP 匹配的输入（kp_match_template.md 英语段引用）|

## 三、Observations 文件（领域知识沉淀）

| 文件 | 行数 | 学科 | 沉淀状态 |
|------|------|------|---------|
| `realpaper_observations_math.md` | 147 | 数学 | V3.10 第 1-9 批 + 第八九批补充；最厚实 |
| `realpaper_observations_chinese.md` | 57 | 语文 | 较少（仅 9 卷入库）|
| `realpaper_observations_english_cambridge.md` | 49 | 英语 PET/FCE/CAE | V3.9 起 |
| `realpaper_observations_english_science.md` | 39 | 英语科学题（保留作扩展）| 较少 |
| `realpaper_observations_physics.md` | 63 | 物理 | 暂无入库，仅 spec 沉淀 |
| `realpaper_observations_chemistry.md` | 63 | 化学 | 同上 |

**skill 化时：**
- 工程坑（Layer 1）→ skill 启动前 hook 必读（O5 强约束）
- 命题艺术（Layer 2）→ 提炼到 patterns.json 后归 composition skill（O10 处理）
- 这份资产盘点本身**不拷进** realpaper-extract skill —— 跨学科 observation 太大，让 agent 按入参 subject 选读

## 四、Cache 结构（.cache/realpaper/）

```
.cache/realpaper/
  <sha1>/                    # 150 个目录（150 卷已 cache）
    raw.txt                  # extract.py 输出
    segmented.json           # segment.py 输出（如已跑）
    matched.json             # match_ans.py 输出（如已跑）
    source_meta.json         # 原文件名 / 学科推断 / OCR 引擎记录
```

**当前规模：** 150 卷已 cache（V3.10 第一批 ~150 卷过 extract，约 50 卷已完整入库）。

**未入库 cache 的处理：** 大约 100 卷已 extract 但还没标注（matched.json 已生成但 batch JSON 没生成）。skill 化后用 `mode=cache_audit` 可批量审看哪些值得入库。

## 五、已踩坑总结（observations 跨学科共性，归 troubleshooting.md）

来自 V3.10 各批 + V3.12 B agent 反馈：

### OCR / 文本提取
- **libreoffice 处理 PDF 错位** → 改用 `pdftotext`
- **扫描版 PDF 无文本层** → 报错让人工预 OCR
- **多列排版错位** → 跳过该卷
- **OCR 乱字**（如分数除法、3 像 5）→ 跳过单题，记录到 manifest
- **↑ 箭头识别为 'I'** → 手动替换（V3.12 第九批新坑）

### Segment（题号识别）
- **题号识别**：`(?:\.(?!\d)|[、．])`（处理"一.1" "1." "1、" "1．"）
- **全角句号** `．` U+FF0E（中文真题标准）
- **大题重置**：遇到 "一. 二. 三." 重置 local_idx
- **答案区跨页断裂** → 手动合并（manifest 标 issue）

### Match Ans
- **答案边界**：`^\s*答案\s*$` 多行模式
- **大题感知配对**：(big_section, local_idx) tuple 避免"一.1 二.1"互覆盖

### 题型 + 答案处理
- **多空填空**：用 "," 分隔答案 + content 末尾说明"按...填，逗号分隔"
- **判断题**：answer = "对"/"错"，UI 端两个大按钮
- **答案不唯一**：候选集合（如比例、同义词）必须列出 alt_answers
- **JSON 内禁双引号**：用「...」或（...）

### 标 KP + round
- **KP 严格匹配 knowledge_points_seed.dart**（feedback_kp_discipline.md）
- **跨年级综合题**：取最高年级
- **chapter 设计**：数理化按教材章节 / 语文/英语按 KP 一级 category
- **综合卷归类**：跨章节 chapter="总复习"，KP 用细分（数代/图几/统计）

### 图依赖
- **图依赖判定**：spec §9.4 复杂图（电路/几何标注/三视图）跳过；纯文字应用题保留
- 入库率：guoguan 类 ~85%，模块统计/概率类 < 60%

## 六、Skill 化映射（T-RP2 实施时）

```
~/.claude/skills/realpaper-extract/
  SKILL.md                  ← 新写（按 skill_realpaper_extract_template.md frontmatter）
  pipeline.md               ← 新写（4 步详解 + 每步 troubleshooting 引用）
  scripts/
    extract.py              ← 拷贝 tools/realpaper/extract.py（注释更新 pdftotext）
    segment.py              ← 拷贝
    match_ans.py            ← 拷贝
    validate.py             ← 拷贝
  kp_match_template.md      ← 新写（grep knowledge_points_seed.dart 全 dump）
  round_assign_guide.md     ← 新写（调 difficulty-<科目> skill 接口说明）
  troubleshooting.md        ← 新写（汇总本文件第五节 + 各 observations 工程坑段）
  manifest_schema.md        ← 新写（不拷数据，仅文档 schema）
```

**6 份新写 + 4 个脚本拷贝。** 总工作量估约 1 个 session 可完成（如下次会话推进 T-RP2）。

## 七、依赖项（T-RP2 / T-RP3 启动前）

- [x] V3.10 pipeline 在 ≥ 5 次 session 复用（已满足）
- [x] T-RP1 资产盘点（**本文件，2026-05-08 完成**）
- [ ] difficulty-<科目> skill schema 已对齐（D5 ✅）
- [ ] kp_match_template.md 全学科 dump（待 T-RP2 实施时做）
- [ ] Famin 拍板"要做 realpaper-extract skill"（按 feedback_skill_extraction.md 不擅自创建原则）

**下次会话接续：** 读本文件 + skill_realpaper_extract_template.md。如 Famin 说"做 skill" → 直接执行 T-RP2 用 1-2 个 session 完成 6 份新写 + 4 脚本拷贝。

---

**生成时间：** 2026-05-08
**对应 task：** R1（V3.12 skill_factory）
