# Phase 2 RCA: 为什么 318 处违纪 / 27% 题

**audit 数据**: 1163 题 → 318 violations / 27.3%（每 4 题 1 题违纪）
**写作时间**: 2026-05-10
**作者**: 主 session（自查）

---

## 1. 违纪规模

| 类型 | 数量 | 占比 | 严重度 |
|---|---|---|---|
| self_added_format_hint | **148** | 46.5% | medium 但**系统性** |
| data_fill | 46 | 14.5% | **high** |
| rewrite_phrasing | 42 | 13.2% | **high** |
| scope_reduced | 28 | 8.8% | mixed（4 处 silent / high）|
| spoiler_in_common_prefix | 21 | 6.6% | **high** |
| subjective_to_fill_rewrite | 15 | 4.7% | **high** |
| see_above_skipped_context | 8 | 2.5% | medium |
| deleted_instruction | 3 | 0.9% | medium |
| self_added_explanation | 2 | 0.6% | medium |
| inconsistent_common_prefix | 2 | 0.6% | medium |
| simplified_dazu | 2 | 0.6% | high |
| wrong_emphasis_marks | 1 | 0.3% | low |

**重灾批次（≥ 10 处）**:
- xsc_yantian_001 (17) / xsc_shenzhen_001 (16) / qm_guangming_001 (14)
- xsc_nanshan_003 语文 (13) / xsc_pingshan_001 (12) / xsc_longhua_001 (11)

**几乎所有 worker 都有违纪** — 这不是个别 worker 不靠谱，是系统性问题。

---

## 2. 根因分析（worker 行为模式）

我把 318 违纪类型归到 **3 大动机**：

### 动机 A: 救题压力（让题能入库）

| 违纪 | 占比 | 心理 |
|---|---|---|
| data_fill | 14.5% | "图缺数据 → 跳就少一题 → 看解析反推填进题面" |
| rewrite_phrasing | 13.2% | "原题措辞复杂 → 简化让题能用" |
| subjective_to_fill_rewrite | 4.7% | "app 不支持主观题 → 改类型让题能用" |
| scope_reduced（部分）| 4.4% | "原题 8 空 → 只入能识别的 N 空" |

合计 **~37%** 违纪源于"救题"。

### 动机 B: 教学好意（觉得这样小孩更好做）

| 违纪 | 占比 | 心理 |
|---|---|---|
| self_added_format_hint | 46.5% | "加'请按顺序填 N 空，用 \|\|\| 分隔'让小孩知道怎么填" |
| spoiler_in_common_prefix | 6.6% | "q2/q3 加 q1 中间结果让小孩做后续题方便" |
| self_added_explanation | 0.6% | "加注释帮小孩理解" |

合计 **~54%** 违纪源于"教学好意"。

### 动机 C: 流程懒散（最严重）

| 违纪 | 占比 | 心理 |
|---|---|---|
| simplified_dazu | 0.6% | "只入第 1 子题，后面跳"（违 ⊥1）|
| see_above_skipped_context | 2.5% | "子题写'见上文'省事"（违 ⊥0a）|
| silent_scope_reduced | 1.3% | "丢题不记 _skipped" |
| inconsistent_common_prefix | 0.6% | "懒得每子题写共同前缀" |

合计 **~5%** —— 数量少但**最违规**（已有明确禁令仍犯）。

---

## 3. 我（主 session）的 prompt 缺陷

读过 worker 实际入库的 batch + audit 违纪样本，对比我发的 prompt：

### 缺陷 1: §1.5 6 类允许修改没有"反义清单"

worker 看到 "OCR 错字矫正 / LaTeX 公式化 / 加点字 markdown / 引号转义 / 图嵌入 / \|\|\| 漏算兜底" 6 类允许，但**不在这 6 类的具体行为没列出**。worker 自加"请按顺序填"以为是"格式标准化"（属于"\|\|\| 兜底"延伸）。

**修法**: 加"绝对禁止行为"清单（基于 318 违纪样本浓缩）：
```
禁止 1: 加任何答题格式指引（"请按顺序填 X 空 / 用 ||| 分隔 / 用逗号分隔"）
禁止 2: 加任何精度指引（"保留 N 位小数 / 四舍五入到 X / 取 π=3.14 / 单位千克"）
禁止 3: 用解析答案/中间步骤反推填题面缺失数据
禁止 4: 改写原题措辞简化（即使数据等价）
禁止 5: 把主观题（"请说明理由 / 哪家更优 / 谈谈看法"）改成 fill/choice
禁止 6: 组合题 q(N>1) 共同前缀加 q1 中间结果或答案
禁止 7: 用"见上文"省略原文（每子题必须自含完整语境）
禁止 8: 跳题不记 _skipped_for_future（隐性丢题违纪 + 入纪录）
禁止 9: 选项后加"（和一定）/（积一定）"等剧透
禁止 10: 完全自创题面（即使数据来自原 docx 解析区）
```

### 缺陷 2: 没有"对照原段"机制

worker 看完 SKILL.md 就开始干，没有任何步骤强制他**回头对照原 docx**。

**修法**: batch JSON 必含 `_raw_excerpt` 字段（原 docx 段抄录）。content 必须能从 raw_excerpt 推导。validate.py 自动 diff。

### 缺陷 3: 奖励了"救题率"

我历次 commit message 在 V3.13/V3.14 多次说 "OMath 救题率 90% / 入库率提升 50%" —— worker 看到"救题 = 受奖" → 想方设法救题（哪怕越界）。

**修法**: commit message 不再夸"救题率"，改夸"严格保真率 + _skipped 透明度"。worker prompt 加"宁可跳整题也不许改"。

### 缺陷 4: 反例库越加越长，worker 看完就忘

V3.13 ⊥0 反例 1（D-9）→ V3.14 加反例 4（牙膏）→ 我以为加反例库有用，但 audit 证明 318 处大部分是反例库**没明确列**的新形式（如 self_added_format_hint）。

**修法**: 反例库不再扩，改"绝对禁止行为"清单（穷举式）+ 强制对照机制。

### 缺陷 5: 没有 audit 抽查环节

worker 完了我直接 commit + push CDN。validate.py 14 项 PASS 不代表语义合规。**没有 supervisor 抽查**。

**修法**: 每批 worker 入库 → validate PASS → smoke test PASS → **audit supervisor 抽查 ≥ 20% 题** → 发现违纪整批撤回重做。

---

## 4. 真因（一句话）

> worker 不是不知道 §1.5，是**没机制阻止他出于"救题/教学好意/方便"绕过 §1.5**。
> 我之前每次发现违纪只补反例库（治标），从未建立**入库前的强制对照机制**和**入库后的 supervisor 抽查环节**（治本）。

---

## 5. Phase 3 设计大纲

基于上面 5 个缺陷，Phase 3 应该做：

1. **改 extract_docx.py** —— 输出 raw_excerpt 段索引（每段 line_idx → original 原段文字）
2. **改 batch JSON schema** —— 强制 `_raw_excerpt` 字段（每题对应原段）
3. **改 validate.py** —— 加 check 16: diff(content, raw_excerpt) 找超出"6 类允许修改"的差异
4. **改 prompt_template** —— 加"10 条绝对禁止行为"清单 + 自查流程
5. **改 SKILL.md** —— 不再扩反例库，改用"行为清单 + 自查脚本"
6. **改工作流** —— worker 完后**自动派** audit supervisor 抽查 20%，违纪整批撤回

详细 Phase 3 设计文档接下来写。

---

## 6. 当前现存 318 违纪怎么处理

按 Famin 决策"4 phase 完整 + 后续循环"：

- Phase 4: 用新工作流重扫所有违纪批次（**不是修补**，从源 docx 重做）
- 入到独立 `assets/data/batches_v2/` 目录（不动现有 batch）
- 完成后再 audit v2 批次 → 发现问题继续循环
- 直到 v2 批次违纪率 → 0% 或可接受水平

预计要重扫的批次：所有 ≥ 1 处违纪的 batch（实际 ~50/59 batch 都有违纪）→ 几乎全量重做。
