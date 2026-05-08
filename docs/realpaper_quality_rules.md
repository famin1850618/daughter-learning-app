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

**修订记录**

- 2026-05-08：V3.12 立项，从 Famin V3.11.0 实测反馈整理首版
