# 真题入库 / 现有题审核质量原则（V3.12 起）

> **状态：** V3.12 立项 2026-05-08。Famin 实测 V3.11.0（含 V3.10 系列真题入库）后总结的 5 条新规。
>
> **作用：** 这是真题入库（人工 + agent）以及现有题包审核（B1-B3 agent）的权威。`.cron-spec.md` 第 6 节是基础，本文件是 V3.12 增量补充。**冲突时以本文件为准。**

---

## 1. 数学：禁止题面剧透答案

**问题：** V3.10 真题入库时把题面带答案的卷子原样录入。
- 例（违规）：`content = "把 3/20 化成小数，结果是 ___。已知 3/20 = 0.15。"` —— 答案 0.15 已在题面。
- 例（违规）：`content = "求圆锥体积公式 V = πr²h/3，已知 r=2, h=3，V=?"` —— 公式即答案，纯送分。

**规则：**
- `content` 字段不能含答案文本（`answer` 中的任何 alt_answer 都不行）
- `explanation` 中可以、且应当含完整推导
- 真题原卷如此剧透 → 改写题面隐藏答案部分，或改为 choice（4 选项打散）
- 公式题：题面只给条件 + 提问，不给公式；公式归 explanation
- **审核时自查**：把 `answer` 的每段 alt_answer 拿去 grep 整个 `content`，命中即违规

**例外：**
- 题面定义"设 V 为体积"这类**变量声明**不算剧透
- 给一个示例帮助理解（如"例：3/20 表示分子 3 除以分母 20"）→ 不算剧透，但要审视示例不是答案本身

---

## 2. 数学：LaTeX 公式纪律（重申 + 新坑）

**问题：** V3.10 真题入库部分违反 LaTeX 纪律。
- 比例题用 `1/2 : 1/3` 没用 `$...$` → flutter_math_fork 不渲染，arial 显示丑
- 部分包了 `$...$` 但内含 `$` 或反斜杠转义错位 → 题面显示裸 `$`

**规则（在 .cron-spec.md 第 6 节"数学/物理/化学公式 LaTeX"基础上增强）：**

### 必须用 `$...$` 包的情况
| 情况 | 错误写法 | 正确写法 |
|------|---------|---------|
| 分数 | `1/2` 或 `½` | `$\frac{1}{2}$` |
| 上标 | `r²` `²` | `$r^{2}$` |
| 下标 | `H₂O` | `$H_{2}O$` |
| 希腊字母 | `π` | `$\pi$` |
| 比例 | `1/2 : 1/3` | `$\frac{1}{2}:\frac{1}{3}$`（整体包）|
| 圆周率符号 | `π × r²` | `$\pi \times r^{2}$` |
| 根号 | `√2` | `$\sqrt{2}$` |
| 乘除（数学语境）| `a × b` | `$a \times b$` |
| 化学方程 | `2H2 + O2 -> 2H2O` | `$2H_{2}+O_{2}\rightarrow 2H_{2}O$` |

### 可以不包的情况
- 纯整数运算："5+3=8"
- 题面叙述中的中文数字："共有十只"
- 单位换算："3 元", "2 cm"（cm 不需 LaTeX）

### 禁忌
- ❌ `$...$` 内嵌中文（除非确实有中文数学符号，几乎不存在）
- ❌ `$...$` 套 `$...$`（嵌套 → 渲染失败）
- ❌ 反斜杠后忘空格：`$\frac12$` → 写 `$\frac{1}{2}$`
- ❌ JSON 字符串里 `\` 没转义：JSON 必须 `\\frac` 才能在 Dart 解析后变 `\frac`（**审核时这条最容易翻车，逐道目检**）
- ❌ 选项里部分用 LaTeX 部分不用：4 个选项要么全用要么全不用，不能 A/B 用 C/D 不用

### 审核步骤（数学 41 卷）
1. grep `\$` 看是否有裸 `$`（应均为 `\$\$` 闭合对）
2. grep `[²³√π]` 看是否还有未 LaTeX 化的特殊字符
3. grep `^.*[0-9]/[0-9]` 看是否有未 LaTeX 化的分数
4. 抽样 5 道用 flutter_math_fork 在临时小 widget 渲染检查

---

## 3. 英语：全英文原则

**问题：** V3.10 入库的 PET 200 题部分含中文（题干说明 / 选项中文 prompt）。真实 PET 试卷是全英文的，孩子要适应纯英语环境。

**规则：**
| 字段 | 语言要求 | 备注 |
|------|---------|------|
| `content` | **全英文** | 包括题型说明（"Read the text and choose..."）、题目本身 |
| `options` | **全英文** | 4 选项 A/B/C/D 都英文 |
| `answer` | **英文** | 除答案本身是中文（如听写中文翻译题，但 PET 不应有这类）|
| `audio_text` | **全英文** | 听力原文 |
| `explanation` | **可中文** | 解析给孩子和家长看，中文更清晰，**保留中文** |

### 违规例
- ❌ `content: "选择正确的时态: I ___ a book yesterday."`
- ✅ `content: "Choose the correct tense: I ___ a book yesterday."`
- ❌ `options: ["A. read 读", "B. reads 读", ...]`
- ✅ `options: ["A. read", "B. reads", "C. readed", "D. reading"]`

### 例外
- 极个别需要中文 prompt 的（如真题原卷含 "Translate to English: '我喜欢苹果。'"），保留原貌但**explanation 必须强调"这是 PET 真实题型变体，多数题目全英文"**
- 单词释义题：题干"What does 'apple' mean?" + 选项英文释义；不出"apple = ?"让用户填中文

---

## 4. 英语：禁"给中文写单词 / 给中文翻译"题型

**问题：** V3.10 入库英语题含 fill 题让用户根据中文提示写英语单词（如"苹果 = ___"）。这不符合 PET / FCE / CAE 体系，真实考试中没有"中文 → 英文"转写题。

**规则：**
- 不出 fill 题 content 含中文 prompt 让用户填英文答案
- 不出 fill 题 content 含英文让用户填中文答案
- 词汇题首选 choice（4 个英文选项）+ image（图）+ 英文定义 prompt

### 替代方案
| 原题型 | 替代方案 |
|--------|---------|
| "苹果 = ___" → 填 apple | choice "Which is an apple?" + 4 英文选项 / 加图 |
| "I love you = ___" → 填中文 | choice "What does 'I love you' mean?" + 4 中文选项 |
| 中文 prompt 找英文同义词 | 全英文 prompt: "Choose the synonym of 'happy'" |

### 审核步骤（英语 200 题）
1. grep content 中含中文字符（`[一-鿿]`）的题 → 全要审，凡是 fill 类型直接转 choice
2. grep options 含中文字符的题 → 翻译成英文（除非释义题需要中文）

---

## 5. 听力：speakers 元数据规范

**问题：** 当前 audio_text 是 `"A: Hello B: Hi"` 单 string，TTS 直接读全文（"A colon Hello B colon Hi"）。需要按角色切分 + 不同 voice/pitch。

**新 schema（V3.12 起）：**

```json
{
  "type": "choice",
  "audio_text": "A: Hello, what's your name?\nB: I'm Sarah. Nice to meet you.\nA: Nice to meet you too.",
  "speakers": {
    "A": {"gender": "male", "age": "child"},
    "B": {"gender": "female", "age": "child"}
  }
}
```

### 字段定义
- `speakers`: `Map<String, SpeakerProfile>`，key 是 `audio_text` 中出现的角色标签
- `SpeakerProfile`:
  - `gender`: `"male" | "female"`
  - `age`: `"child" | "teen" | "adult"`

### audio_text 格式约定
- **多角色**：每行一个 turn，`角色名:` 开头，冒号后空格再接文本
  - 角色名只用单字母 A/B 或描述性 M/W/Boy/Girl
  - 行间用 `\n` 分隔（JSON 中 `\\n`）
  - 代码端按正则 `^([A-Za-z]+):\s*(.+)$` 多行解析
- **单角色**（独白）：直接给文本，speakers 用 `{"_": {gender, age}}` 占位

### TTS 端实现（路径 c：先 flutter_tts，效果不够再升级云 TTS）
- voice 列表：启动时 `flutter_tts.getVoices` 拿设备 voice，按 `(locale=en-*, gender)` 缓存
- 角色 → voice 映射：
  - 优先：拿到匹配 (gender) 的 voice
  - fallback 1：`(gender)` 不可用 → male 用 default voice + pitch 0.9，female + pitch 1.3
  - fallback 2：`age=child` 在 male/female 基础上 pitch 再 ×1.15（更高）
  - fallback 3：单角色全无匹配 → default voice，pitch 1.0
- 串行播放：`flutter_tts.awaitSpeakCompletion(true)` + 按 turn 顺序 `await speak(text)`
- 角色切换间小停顿：`await Future.delayed(Duration(milliseconds: 300))`

### 现有题改造
- 现有 PET 200 题（含 ~20 道听力）逐道补 speakers 字段
- 单角色独白（`audio_text` 不含 `^[A-Z]:` 模式）→ `speakers = {"_": {gender: "female", age: "adult"}}`（默认成年女声，PET 朗读官方常见）
- 多角色对话 → 按上下文判断（school 场景多 child，shop 场景多 adult，等）

### B3 agent 任务（依赖 A1 + A5）
- 全审 PET 200 题：去中文（规则 3）+ 改"中→英"题（规则 4）+ 听力题加 speakers（规则 5）

---

## 总结自查清单

每次入库 / 审核新批次前，对照以下清单：

- [ ] **数学**：题面不剧透答案（`content` grep `answer` 段都不命中）
- [ ] **数学**：所有公式 `$...$` 包好（grep 裸 `²³√π`、`[0-9]/[0-9]` 不含 `$` 包围 → 0 命中）
- [ ] **数学**：JSON 中 `\frac` `\pi` 写成 `\\frac` `\\pi`（Dart 解析后才是单反斜杠）
- [ ] **英语**：`content`/`options`/`audio_text` 不含中文（`explanation` 例外）
- [ ] **英语**：fill 题 `content` 不是中文 prompt 找英文答案
- [ ] **听力**：含 audio_text 的题都有 `speakers` 字段
- [ ] **听力**：多角色 audio_text 用 `角色:文本\n` 格式，角色与 speakers key 对得上
- [ ] **抽样**：每批至少 5 道人工试做（数学跑公式、英语听 TTS）

---

## 6. 入库源头可信度（V3.12 D1 锚点审核期间立项；V3.12.3 简化）

**Why：** Famin 2026-05-08 审 D1 锚点题时发现 `chinese_r2_anchor_4`（妻子转述句）原文不存在于 cache raw.txt —— 真身是 `爸爸说："我正为这件事操心。"` 的 fill 题。源头追溯到 V3.10 第六批（commit `62e5eb4`）的"OCR 抢救"路径：3 卷 PDF 嵌入私有字体 → pdftoppm 渲染 + tesseract + **多模态 agent 看 PNG 出题**。受影响 122 道语文题。

**V3.12.3 简化决策（Famin 提醒原则）：** 一开始的纪律就是 `.realpaper-spec.md §9.1`：

> **"图/文字不清晰 → 直接放弃。OCR 失败 / 扫描质量差 / 关键文字模糊 → 整题跳过。不要浪费 token 修复。"**

V3.12.1 我引入的 `_unverified` + reviewer 重写流程**违反了这条原则**（试图修复识别不清的题）。V3.12.3 纠正回归原则：**直接删除 / 不入库**。

### 入库源头两级（简化为允许 vs 拒绝）

| 等级 | 标准 | 处理 |
|------|------|------|
| **可信** | 标准 OCR pipeline（pdftotext / libreoffice）+ raw.txt 字符级与最终入库一致 | 正常入库 |
| **不可信** | OCR 失败 / 扫描质量差 / 关键文字模糊 / cache raw.txt 不可用需多模态看图 | **整题/整卷跳过，不入库**。已入库的 deprecate 后下一版本完全删除 |

### 关键纪律

1. **不修复**：识别不清的题不要尝试 OCR 抢救 / 多模态读图 / reviewer 重写。题量足够，卷子很多，时间成本高且容易出问题。
2. **跳过即完结**：跳过的卷在 `manifest.skipped[]` 注明原因，**不开后续 reviewer task**。
3. **入库前自查**：双写 batch JSON 前运行 `tools/realpaper/validate.py` + 抽样 5-10 道与 raw.txt **字符级 diff**；不一致直接整卷废弃。
4. **多模态 agent 仅允许两种受限场景**：
   - 几何图配文字描述题：agent 描述图 → 写 SVG 入 `image` 字段。**不改原题文字**，文字必须来自 raw.txt。
   - 真题答案区被遮挡/缺失：agent 仅辅助补全 `answer` 字段。**不改 content / options**。
5. **遇到嵌入私有字体 / 扫描版 PDF / 无文本层 → 直接换下一卷**，不投入修复成本。

### 历史事件

- **V3.10 第六批** (commit `62e5eb4`)：3 卷 OCR 抢救语文 122 题入库 → V3.12.1 标 `_unverified_v312` → V3.12.3 **完全删除**（含 batch JSON / question_bank / DB / index.json / main.dart 注册）
- **V3.7-V3.8.3 cron AI 出题**：12 卷语数英 → V3.8.3/V3.10 标 `_deprecated` → V3.12.3 **完全删除**

---

## 7. Round 源头权威性（V3.12 D1 锚点审核期间立项）

**Why：** Famin 2026-05-08 审英语锚点时指出："PET R1 200 题应该都是 R1，AI 生成是先置难度再生成，而不是生成完了再去分难度。" 暴露 D1 agent 把源头 R1 题主观升档作 R2/R3/R4 锚点的错误流程。

### 两类批次的 round 性质不同

| 批次类型 | round 字段性质 | 流程地位 |
|----------|--------------|---------|
| **AI 生成批次**（cron 出题）| **源头权威**：生成时 prompt 指定 round=N，所有题统一标 N（间接 difficulty 字段在 N 内分 easy/medium/hard 微调）| 不可改写 |
| **真题入库批次** | **入库 agent 主观打**：扫真题时按 4 维算法 / rubric 对每道题分别打 round，同卷 mixed | D1/D2/校准的对象 |

### 纪律

1. **AI 生成批次的 round 锁死**：
   - source 命名带 round（如 `batch_2026_05_07_g6_math_r2`）= round=2 是源头属性
   - 任何 agent / 锚点 / reviewer **不得修改**这类批次中题目的 round 字段
   - 内部 difficulty 梯度（easy/medium/hard）只是 round 内部分布微调

2. **真题入库批次的 round 是 D1/D2 校准目标**：
   - 入库 agent 凭 4 维算法 + rubric 打 round，可能偏
   - D1（锚点题）+ D2（reviewer 重审 1925 道）+ D3（Famin 实测反馈）+ D4（学情反推）四源校准
   - 校准后 batch JSON `round` 字段更新 + 备份 `_original_agent_round`

3. **锚点（D1）来源分流原则**：
   - **R1 锚点**必须取自源头 R1 批次（AI 生成 r1 / 真题中已校准 R1）
   - **R2 锚点**必须取自源头 R2 批次（AI 生成 r2 / 真题中已校准 R2）
   - **R3 锚点**同上
   - **R4 锚点**同上
   - **不得跨档主观升降** —— 拿源头 R1 题升档作 R2 锚点 = 流程错误

4. **数据缺口处理**：
   - 缺某档真题数据时（如英语 R2/R3/R4 等 FCE/CAE 入库），**冻结该档锚点**而不是强行造伪锚点
   - 锚点 JSON 中标 `_frozen: true` + 缺口原因
   - difficulty skill 训练时只用源头权威的档作训练样本，缺档走 4 维算法 + 后期校准

### 修锚点 vs 修 skill 的本质

> Famin 2026-05-08 反馈："修锚点意味着出题难度控制不准，主要对应的就是修改 difficulty skill，修正未来出题的难度控制。"

- **锚点**只是 difficulty skill 的训练样本之一
- 真正的难度控制能力在 **difficulty skill 的 evaluate.md 算法 + rubric.md 活文档 + calibration_log 反馈循环**
- 锚点错了应**修 skill**（更新 rubric / 调 4 维权重 / 加新维度），不是反向修锚点的 round 让锚点适配 skill

---

## 8. Batch JSON 与 DB Source 必须同步（V3.12 D1 锚点审核期间立项）

**Why：** Famin 审英语锚点时发现 D1 agent 选了 6 道来自 `batch_2026_05_07_g6_english_r3.json`（V3.7 老外研社 cron），但这卷在 V3.8.3 已经在 DB 迁移层标 `_deprecated`，agent 读 batch JSON 文件时看不到废弃标记，错误地拿来当锚点。

### 根因

V3.8.3 / V3.10 deprecate 时只动 DB 迁移代码，没动 batch JSON 文件本身的 source 字段：
```dart
// database_helper.dart v13/v14 仅 UPDATE DB
UPDATE questions SET source = source || '_deprecated' WHERE ...
```
agent 读 `assets/data/batches/*.json` 看到的 source 仍是不带 `_deprecated` 的版本。

### 纪律

1. **DB source 与 batch JSON source 必须双向同步**：
   - 任何 deprecate 操作必须同时改：
     - DB 迁移层（`database_helper.dart` 加版本迁移）
     - batch JSON 文件 `source` 字段（双写 `assets/data/batches/` + `question_bank/`）
     - batch JSON 顶层 `_quality_meta` 段（详见下方）

2. **batch JSON 顶层 `_quality_meta` 段**：
   ```json
   {
     "source": "batch_xxx_deprecated",
     "_quality_meta": {
       "deprecated": true,
       "deprecated_version": "V3.8.3",
       "deprecated_at": "2026-05-07",
       "deprecated_reason": "...",
       "deprecated_commit": "99ccb92",
       "note": "抽题已通过 _activeSourceFilter 自动排除；保留作低水平兜底参考，不应作锚点/训练样本"
     }
   }
   ```
   类似的 `_quality_meta.risk_level / needs_review` 见 §6（OCR 抢救路径）。

3. **agent 读 batch 前必读 `_quality_meta`**：
   - source 后缀含 `_deprecated` / `_unverified` / `_subj_held` / `_translated_en` → 自动跳过
   - `_quality_meta.deprecated == true` → 不作锚点 / 训练样本
   - `_quality_meta.risk_level == "L3_multimodal_ocr"` → 加 [审] 标
   - 任何 D1 / D2 / O10 / B agent prompt 必须包含此前置检查

4. **历史已 deprecated 但 batch JSON 未同步的卷**（V3.12 修复）：
   - V3.8.3：4 卷英语（外研社老体系）
   - V3.10：8 卷语数（cron AI 出题）
   - 共 12 卷，V3.12 commit 同步动 batch JSON 加 `_deprecated` 后缀 + `_quality_meta`

---

**修订记录**

- 2026-05-08：V3.12 立项，从 Famin V3.11.0 实测反馈整理首版（§1-§5）
- 2026-05-08：D1 锚点审核期间发现幻觉编造伪题，加 §6 入库源头可信度纪律
- 2026-05-08：D1 英语锚点审核期间发现源头 round 改写错误 + DB/JSON source 不同步，加 §7 Round 源头权威 + §8 Batch JSON 与 DB Source 同步
