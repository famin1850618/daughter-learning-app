# Agent Prompt 模板（O5 / V3.12 立项）

> **用途：** 任何 daughter_learning_app 项目相关 agent（入库 / 审核 / 提炼 pattern / round 校准 / 难度评估 / 出题）启动前**必须**走 prompt ack gate，强制读权威文档清单。
>
> **背景：** V3.12 阶段连续踩坑（OCR 抢救伪题 / 老 deprecated 题被错用作锚点 / 源头 round 被改写）的根因都是 agent 没读 / 没记牢已存在的纪律。本模板把"前置阅读"从口头要求变成结构化 prompt 模式。
>
> **协同：** `realpaper_quality_rules.md` / `realpaper_observations_*.md` / `feedback_unclear_abandon.md` / `feedback_question_quality.md` / `feedback_kp_discipline.md`

---

## 通用 Prompt 模式

每个 agent prompt 都有 5 段（顺序固定）：

```
1. 任务目标（一句话 + 输出要求）
2. ⚠️ Ack Gate：前置阅读清单 + 强制 ack
3. 输入数据（路径 + 结构）
4. 操作步骤
5. 输出 schema + 边界（不允许的事）
```

### Ack Gate 段（核心创新）

```markdown
## ⚠️ Ack Gate（必读 + 必 ack）

启动前必须读以下文件并在第一段 reply 里**逐条 ack**：

- [ ] `docs/realpaper_quality_rules.md` 全文（V3.12 八条质量原则）
- [ ] `docs/realpaper_observations_<科目>.md`（学科特化历史坑）
- [ ] `<本任务相关其他文档>`

**Ack 格式：**
> 已读 quality_rules.md（共 N 节，§1 数学不剧透 / §2 LaTeX 双反斜杠 / ... / §8 Batch JSON 与 DB 同步）
> 已读 observations_math.md（含 X 条历史坑，最关键 N 条：...）
> 已读 [其他文档]

**未 ack 直接进入 step 3 = 流程错误，立刻 abort 退出。**

## 🛑 Hard Constraints（核心边界，违反即 abort）

1. **识别不清直接放弃** —— OCR 失败 / 多模态读图 / 图模糊 / 任何"不太确定"的资源 → 整题/整卷跳过，不修复（详见 `feedback_unclear_abandon.md`）
2. **AI 生成批次 round 不可改写** —— 源头 source 带 `_r1/_r2/_r3` 标识 round，agent 不能把 r1 题升档作 r2 锚点（详见 quality_rules.md §7）
3. **KP 严格匹配 knowledge_points_seed.dart** —— 不在清单的 KP 不允许出现（详见 `feedback_kp_discipline.md`）
4. **不读 `_quality_meta.deprecated == true` / source 含 `_deprecated` / `_unverified` 的批次** —— 这些是已下架题（详见 quality_rules.md §6/§8）
5. **入库前 raw.txt 字符级 diff** —— 抽样 5-10 道，不一致整卷废弃（不修复）
6. **不擅自创建 ~/.claude/skills/ 文件** —— skill 化是用户决策（详见 `feedback_skill_extraction.md`）
```

---

## 模板 1：真题入库 agent

```markdown
# 真题入库 Agent — <学科 + 卷次 + 数量>

## 任务目标

把 `<source PDF/cache 路径>` 转成 daughter_learning_app 标准 batch JSON，
双写到 `assets/data/batches/<source>.json` 和 `question_bank/<source>.json`，
注册 index.json + main.dart `_bundledBatchAssets`。

## ⚠️ Ack Gate（必读 + 必 ack）

- [ ] `docs/realpaper_quality_rules.md` 全 8 节
- [ ] `docs/realpaper_observations_<科目>.md` 历史坑
- [ ] `feedback_unclear_abandon.md`（识别不清放弃原则）
- [ ] `feedback_kp_discipline.md`（KP 严格匹配）
- [ ] `feedback_question_quality.md`（输入法限制 / 禁开放题）
- [ ] `lib/database/knowledge_points_seed.dart`（学科 KP 清单）
- [ ] 第一原则段：识别不清直接跳过，**禁止** OCR 抢救 / 多模态出题 / reviewer 重写

请第一段 ack 这 7 条。未 ack 直接 abort。

## 🛑 Hard Constraints

1. raw.txt 字符级与最终 batch JSON 一致（抽样 5 道 diff）
2. KP 严格匹配 knowledge_points_seed.dart 学科清单
3. round 由本 agent 按 4 维算法打（步骤数/陷阱密度/KP 跨度/数据复杂度）
4. 输入法限制：fill 答案纯数字 / 简单分数 / 单字短词；含 π/²/×/拼音声调 → choice
5. 多模态仅允许补 `image` 字段（SVG）和 `answer` 字段（被遮挡），不改 content/options
6. OCR 失败 / 私有字体 / 扫描版 → 整卷跳过，记 manifest.skipped[]，**不进入 cache 抢救流程**

## 输入数据

[路径 + cache sha1 + 学科/年级/教材版本]

## 操作步骤

1. 读 cache raw.txt（如不存在或乱码 → abort 跳过）
2. segment + match_ans
3. 标 KP（对照 knowledge_points_seed）+ 打 round（4 维算法）
4. validate.py 检查
5. 抽样 5 道与 raw.txt 字符级 diff（不一致整卷废）
6. 双写 batch JSON + 注册 index/main.dart

## 输出 schema

[标准 batch JSON 字段]

## 报告（< 500 字）

- 入库题数 / 跳过题数 + 原因
- KP 覆盖
- round 分布
- 抽样 diff 结果
- token 估算
```

---

## 模板 2：题包审核 agent（B1/B2/B3 类）

```markdown
# 题包审核 Agent — <学科 + 范围>

## 任务目标

审核 `<batch JSON 路径列表>` 中现有题，按 quality_rules.md 修违规：
- 数学：不剧透 / LaTeX 双反斜杠 / 选项格式
- 语文：拼音 / 修辞客观化 / 答案唯一
- 英语：全英文 / 禁中→英 / 听力 speakers

## ⚠️ Ack Gate（必读 + 必 ack）

- [ ] `docs/realpaper_quality_rules.md` 全文
- [ ] `docs/realpaper_observations_<科目>.md` 历史坑
- [ ] `feedback_unclear_abandon.md`
- [ ] `feedback_question_quality.md`
- [ ] **`<batch JSON 路径>` 顶层 `_quality_meta` 段** —— 如 `deprecated == true` 或 `risk_level == "L3_..."` → abort，不审已下架题

请第一段 ack 这 5 条 + 报告每个 batch 的 _quality_meta 状态。

## 🛑 Hard Constraints

1. 审核范围严格 —— 不碰 `_deprecated` / `_unverified` 的 batch
2. 修违规题的同时**双写** assets/data/batches + question_bank（diff 必须 0）
3. 不改源头 round（仅修内容/选项/答案，round 字段不动）
4. JSON 反斜杠双写：`\\frac \\pi \\times \\sqrt`
5. 不能"为修而修"：原题就这样的题（如争议性标点题）保留，标 comment

## 操作步骤 / 输出 / 报告

[同模板 1 结构]
```

---

## 模板 3：Reviewer agent（D2 / O10 类，从已入库题逆向提炼）

```markdown
# Reviewer Agent — <D2 round 校准 / O10 pattern 提炼 / 合并任务>

## 任务目标

扫 `<batch JSON 路径列表>` 已入库题，输出：
- D2: 每道题 round 调档建议（对照 D1 锚点 `docs/anchor_questions_g6_<科目>.json`）
- O10: 提炼 30-50 个 pattern → 填充 `docs/composition_craft_<科目>.md` patterns 数组

## ⚠️ Ack Gate（必读 + 必 ack）

- [ ] `docs/realpaper_quality_rules.md` §7 (round 源头权威) + §6 (识别不清放弃)
- [ ] `docs/skill_difficulty_template.md` evaluate.md 4 维算法段
- [ ] `docs/skill_composition_template.md` patterns.json schema
- [ ] `docs/anchor_questions_g6_<科目>.json` Famin 已审 round（部分锚点 _frozen 跳过）
- [ ] `docs/composition_craft_<科目>.md` 现有 patterns 数组（避免重复 pattern_id）

请第一段 ack 这 5 条 + 列举锚点已审/冻结状态。

## 🛑 Hard Constraints

1. **AI 生成批次 round 不可改写**（source 含 `_pet_r1` / `_r2` / `_r3` 等标识）
2. 真题批次 round 是入库 agent 主观打的 → 是 D2 校准对象
3. pattern 入库门槛：≥ 3 道真题样例同模式才入（孤例不留）
4. pattern_id 用蛇形小写英文，不重复
5. reasoning 段必须 4 维分别说明
6. 输出独立两份产物：D2 调档清单 jsonl + O10 patterns 数组追加

## 操作步骤 / 输出 / 报告

[详细按任务实例化]
```

---

## 模板 4：AI 出题 agent（未来 cron 重启 / 错题变体 / 冷门补题）

```markdown
# AI 出题 Agent — <kp / round / count / mode>

## 任务目标

按 (kp, round, count) 生成新题，输出 batch JSON 候选。

## ⚠️ Ack Gate（必读 + 必 ack）

- [ ] `docs/realpaper_quality_rules.md` 全 8 节
- [ ] `docs/composition_craft_<科目>.md` patterns 数组（按 kp 找匹配 pattern_id）
- [ ] `docs/skill_difficulty_template.md` rubric 段（保 round 一致）
- [ ] `lib/database/knowledge_points_seed.dart` 学科 KP 清单
- [ ] `feedback_question_quality.md` 输入法限制 / 禁开放题

## 🛑 Hard Constraints

1. **先置 round 再生成** —— 输入 round=N 后所有题统一标 N，禁止生成混档
2. 严格按 pattern_id 的 ai_template 参数空间生成
3. 套 distractor_design 做选项陷阱，不臆造新陷阱
4. self-check：生成后跑 difficulty skill evaluate 一次，不符 round 退回重生
5. 不在 ~/.claude/skills/ 留任何文件

## 操作步骤 / 输出 / 报告

[详细按任务实例化]
```

---

## 模板 5：自由探索 agent（最低约束，仅前两条 hard constraint）

适用：研究 / 实验 / spike / 一次性数据分析。

```markdown
# Exploratory Agent — <topic>

## 任务目标 + 输出

[简短]

## ⚠️ Minimal Ack Gate

- [ ] `feedback_unclear_abandon.md`（识别不清放弃）
- [ ] `feedback_skill_extraction.md`（不擅自动 ~/.claude/skills/）

## 🛑 仅两条 Hard Constraint

1. 识别不清放弃
2. 不擅自创建 skill 文件
```

---

## 模板用法（agent prompt 写法示例）

任何 agent 任务，prompt 顶部第一段必须显式拷贝 Ack Gate + Hard Constraints 段：

```markdown
# <任务标题>

[任务目标]

## ⚠️ Ack Gate
[拷贝模板 N 的 Ack 段 + 任务特化追加]

## 🛑 Hard Constraints
[拷贝模板 N 的 Constraints 段 + 任务特化追加]

## 操作步骤
[详细]
```

不要把 ack/constraints 段缩写成"按规范执行"——LLM 容易跳过抽象描述，必须列明清单。

---

## 反例（绝不要这么做）

❌ **Bad prompt（无 ack gate）**：
```
扫六下数学 41 卷真题，提炼 pattern 输出 craft.md。
```

❌ **Bad prompt（口头规范）**：
```
扫六下数学 41 卷真题，注意 quality_rules，提炼 pattern。
```

✅ **Good prompt（结构化 + 强 ack）**：
```
[模板 3 全段 + 任务特化参数]
```

---

## 维护

每次 agent 工作出现新坑（不在现有 ack 清单里）→ append 到对应模板 + 同步到 `realpaper_observations_*.md`。

`docs/agent_prompt_templates.md` 本身也是 agent ack 清单的成员之一（递归约束）。

---

**生成时间：** 2026-05-08
**对应 task：** O5（V3.12 observation_loop Layer 1）
