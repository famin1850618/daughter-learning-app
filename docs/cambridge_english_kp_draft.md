# Cambridge 英语 KP 清单（V3.9 备稿）

> 草案，等 Famin review 后转 `lib/database/cambridge_english_kp_seed.dart` 并入库。
> **全英文环境** — 既然走 Cambridge 体系，英语 subject 下不出现任何中文（KP / category / 解析等）。

---

## 0. 设计原则

### 0.1 体系映射

| Grade | Cambridge Level | CEFR | Vocabulary Goal |
|---|---|---|---|
| 6 (六下) | **PET** | B1 | ~3500 words |
| 7 (初一) | **FCE Entry-Mid** | B2 | ~5000 words |
| 8 (初二) | **FCE Mid-High** | B2 | ~6000 words |
| 9 (初三) | **CAE Foundation**（excl. advanced Writing/complex Listening）| C1 entry | ~7000 words |

每 level 4 round × 200 题 = 800 题；总 PET 800 + FCE 1600 (G7+G8) + CAE Foundation 800 = **3200 questions**。

### 0.2 KP Naming

`full_path = "{category}/{name}"` — **全英文**，无中文。例：
- `Grammar/Present Simple`
- `Vocabulary/Family & Relationships`
- `Reading/Scanning for detail`

KP 严格匹配纪律不变（feedback_kp_discipline.md）：题包侧 `knowledge_point` 字段必须严格用此 full_path。

### 0.3 Categories — 4 类（学科领域维度）

| category |
|---|
| Vocabulary |
| Grammar |
| Reading |
| Listening |

**题型不做 category**（V3.9 决策）：
- 题型由 `type` 字段表达（choice / fill）
- Cambridge Part 由 `chapter` 字段标记（如 `chapter = "FCE Part 3"`）
- 像 Word Formation / Key Word Transformations / Cloze 这些「题型」按其考察的本质归到 Grammar / Vocabulary / Reading 之下
- Reading MC / Multiple Matching / Gapped Text 按其考察的阅读技能归到 Reading 之下

> Writing 暂不出（等 AI 评分 API；详见 `project_writing_pending.md` 记忆）

### 0.4 V3.8.3 Schema 兼容性

- **题型字段** type：choice / fillBlank / calculation（subjective 暂不用）
- 词形转换 / 关键词改写 / Open Cloze 用 `fillBlank`，遵守输入法限制白名单（feedback_question_quality.md）：英文短词 ≤8 字母走 fill；超长答案改 choice
- **难度档** 用 `round` 字段
- **chapter 字段** 用于标记 Cambridge Part：`PET` / `FCE Part 1` / `FCE Part 3` / `CAE Part 5` 等
- **阅读 cluster** 用 `group_id` + `group_order`（V3.8.2 已支持）
- **听力题** 用 `audio_text`（TTS 朗读）

---

## 1. PET (B1) — Grade 6 (20 KP)

### 1.1 Vocabulary (6)

- `Vocabulary/Family & Relationships`
- `Vocabulary/Travel & Holidays`
- `Vocabulary/School & Study`
- `Vocabulary/Food & Daily Life`
- `Vocabulary/Hobbies & Leisure`
- `Vocabulary/Shopping & Money`

### 1.2 Grammar (9)

- `Grammar/Present Simple`
- `Grammar/Present Continuous`
- `Grammar/Past Simple`
- `Grammar/Past Continuous`
- `Grammar/Present Perfect (basic)`
- `Grammar/Future Tenses (will / going to / Present Continuous)`
- `Grammar/Modals (can/could/should/might/must)`
- `Grammar/Comparatives & Superlatives`
- `Grammar/Conditionals 0 & 1`

### 1.3 Reading (3)

- `Reading/Scanning for detail`
- `Reading/Skimming for gist`
- `Reading/Inferring meaning from context`

### 1.4 Listening (2)

- `Listening/Listening for gist`
- `Listening/Listening for detail`

**PET total: 6 + 9 + 3 + 2 = 20 KP**

> PET 题型分布：Vocabulary MC 直接挂 `Vocabulary/<topic>` KP；Grammar MC 挂 `Grammar/<point>`；Cloze (short) 看主要考 vocab 还是 grammar，挂对应；Reading MC 挂 Reading 技能 KP；Listening 同理。

---

## 2. FCE (B2) — Grades 7 & 8 (27 KP new)

> Grade 7 = FCE entry-mid (round 1-2 mainly); Grade 8 = FCE mid-high (round 3-4 mainly).
> FCE 抽题时可混入 PET KP 做基础题。

### 2.1 Vocabulary (7 new)

- `Vocabulary/Work & Career`
- `Vocabulary/Technology & Digital`
- `Vocabulary/Health & Fitness`
- `Vocabulary/Environment & Nature`
- `Vocabulary/Media & Entertainment`
- `Vocabulary/City & Community`
- `Vocabulary/Word Choice (Cloze)` ← FCE Part 1 / CAE Part 1 多考词汇辨析归此

### 2.2 Grammar (14 new)

- `Grammar/Present Perfect Continuous`
- `Grammar/Past Perfect`
- `Grammar/Past Perfect Continuous`
- `Grammar/Future Perfect & Future Continuous`
- `Grammar/Conditionals 2 / 3 / Mixed`
- `Grammar/Modals Perfect (could have / should have / must have)`
- `Grammar/Passive (all tenses)`
- `Grammar/Reported Speech (all tenses & verbs)`
- `Grammar/Relative Clauses (defining / non-defining)`
- `Grammar/Linking Words (although / despite / however / whereas)`
- `Grammar/Phrasal Verbs (high-frequency)`
- `Grammar/Word Formation` ← 含 prefix/suffix 规则 + FCE/CAE Part 3 题型
- `Grammar/Sentence Transformation` ← FCE/CAE Part 4 题型（Key Word Transformations）
- `Grammar/Open Cloze` ← FCE/CAE Part 2 题型（多考介词/冠词/连词）

### 2.3 Reading (4 new)

- `Reading/Inferring author's stance`
- `Reading/Identifying logical relationships`
- `Reading/Text Coherence` ← FCE Part 6 / CAE Part 7 (Gapped Text)
- `Reading/Multiple Matching` ← FCE Part 7 / CAE Part 8

### 2.4 Listening (2 new)

- `Listening/Listening for opinion & attitude`
- `Listening/Multi-speaker listening`

**FCE new total: 7 + 14 + 4 + 2 = 27 KP**

---

## 3. CAE Foundation (C1 entry) — Grade 9 (18 KP new)

> 跳过高阶 Writing（全部）+ 复杂 Listening (Part 3-4 academic monologue)。
> 仅取 C1 entry-level（vocab / grammar / general reading / general cloze）。
> CAE 的 Word Formation / Open Cloze / Sentence Transformation 共用 FCE Grammar KP，不再新增。

### 3.1 Vocabulary (5 new)

- `Vocabulary/Abstract Concepts`
- `Vocabulary/Tech Deepening (AI / Privacy / Automation)`
- `Vocabulary/Social Issues`
- `Vocabulary/Economics & Finance`
- `Vocabulary/Cultural Differences & Globalization`

### 3.2 Grammar (7 new — C1 entry)

- `Grammar/Inversion (never / rarely / only when / hardly)`
- `Grammar/Subjunctive & Hypothetical Past`
- `Grammar/Gerund vs Infinitive (verbs of preference)`
- `Grammar/Participle Clauses & Absolute Structures`
- `Grammar/Cleft Sentences (It is X that... / What X is...)`
- `Grammar/Complex Conditionals (mixed tenses)`
- `Grammar/Advanced Linking (nonetheless / albeit / insofar as)`

### 3.3 Reading (5 new — Advanced)

- `Reading/Identifying implied meaning`
- `Reading/Distinguishing similar options`
- `Reading/Recognizing irony & sarcasm`
- `Reading/Paragraph main idea`
- `Reading/Cross-text Matching` ← CAE Part 6 (Cross-text Multiple Matching)

### 3.4 Listening (1 new — light)

- `Listening/Academic conversation (light, no full lecture)`

**CAE Foundation new total: 5 + 7 + 5 + 1 = 18 KP**

---

## 4. Question Templates (V3.9 出题用)

### 4.1 Vocabulary MC

```json
{
  "type": "choice",
  "round": 2,
  "subject": 2,
  "grade": 6,
  "chapter": "PET",
  "knowledge_point": "Vocabulary/Family & Relationships",
  "content": "She is my mother's sister, so she is my ____.",
  "options": ["A. uncle", "B. aunt", "C. cousin", "D. niece"],
  "answer": "B",
  "explanation": "Mother's sister = aunt."
}
```

### 4.2 Grammar MC

```json
{
  "type": "choice",
  "round": 2,
  "chapter": "PET",
  "knowledge_point": "Grammar/Present Simple",
  "content": "She ____ to school every day.",
  "options": ["A. go", "B. goes", "C. going", "D. went"],
  "answer": "B",
  "explanation": "Third-person singular subject in Present Simple takes -es."
}
```

### 4.3 Word Formation (FCE Part 3 / CAE Part 3)

```json
{
  "type": "fill",
  "round": 3,
  "chapter": "FCE Part 3",
  "knowledge_point": "Grammar/Word Formation",
  "content": "The new policy was met with widespread ____. (APPROVE)",
  "answer": "approval|||APPROVAL",
  "explanation": "approve (verb) → approval (noun). Need a noun as object."
}
```

### 4.4 Key Word Transformations (FCE Part 4 / CAE Part 4)

```json
{
  "type": "fill",
  "round": 4,
  "chapter": "FCE Part 4",
  "knowledge_point": "Grammar/Sentence Transformation",
  "content": "He started learning piano five years ago.\nFOR\nHe ____ for five years.",
  "answer": "has been learning piano|||has been learning the piano",
  "explanation": "started X years ago → has been doing for X years (Present Perfect Continuous)."
}
```

### 4.5 Open Cloze (FCE Part 2 / CAE Part 2)

```json
{
  "type": "fill",
  "round": 3,
  "chapter": "FCE Part 2",
  "knowledge_point": "Grammar/Open Cloze",
  "content": "Despite ____ his best, he failed the exam.",
  "answer": "doing|||trying",
  "explanation": "After 'Despite' (preposition), we use a gerund. 'doing his best' is a fixed expression."
}
```

### 4.6 MC Cloze (FCE Part 1 / CAE Part 1)

```json
{
  "type": "choice",
  "round": 2,
  "chapter": "FCE Part 1",
  "knowledge_point": "Vocabulary/Word Choice (Cloze)",
  "content": "She ____ a great deal of attention to detail.",
  "options": ["A. gives", "B. pays", "C. makes", "D. takes"],
  "answer": "B",
  "explanation": "'pay attention' is the standard collocation."
}
```

### 4.7 Reading Cluster (group_id + group_order)

```json
[
  {
    "type": "choice",
    "round": 3,
    "chapter": "FCE Part 5",
    "knowledge_point": "Reading/Inferring author's stance",
    "group_id": "fce_reading_cluster_001",
    "group_order": 1,
    "content": "[Reading passage: 300 words on environmental policy]\n\nQuestion 1: What is the author's main concern in paragraph 2?",
    "options": ["A. ...", "B. ...", "C. ...", "D. ..."],
    "answer": "C",
    "explanation": "..."
  }
]
```

### 4.8 Listening (with audio_text)

```json
{
  "type": "choice",
  "round": 1,
  "chapter": "PET",
  "knowledge_point": "Listening/Listening for detail",
  "content": "Listen and choose the correct answer.\n\nWhere are the speakers going?",
  "audio_text": "A: Hi, are you ready? — B: Almost. Let me grab my umbrella. — A: Good idea, it might rain at the park.",
  "options": ["A. School", "B. Park", "C. Cinema", "D. Restaurant"],
  "answer": "B",
  "explanation": "The speakers explicitly mention 'park'."
}
```

> **All explanations in English.** Sustained immersion principle.

---

## 5. KP Count Summary

| Level | Vocabulary | Grammar | Reading | Listening | Subtotal |
|---|---|---|---|---|---|
| PET (G6) | 6 | 9 | 3 | 2 | **20** |
| FCE (G7+G8) — new | 7 | 14 | 4 | 2 | **27** (PET KPs reused) |
| CAE Foundation (G9) — new | 5 | 7 | 5 | 1 | **18** |
| **Total new** | **18** | **30** | **12** | **5** | **65** |

题型不再单独 KP，由 `type` (choice/fill) + `chapter` (Cambridge Part 标识) 表达。

> Writing 暂不出（待 AI 评分 API；估约 ~10 KP 后续添加）。

---

## 6. Output Schedule

| Stage | Content | Question Count |
|---|---|---|
| Stage 1 | PET R1 (G6 entry) | 200 — even ~10 per KP across 20 KPs |
| Stage 2 | PET R2 (G6 mid) | 200 |
| Stage 3 | PET R3 (G6 high) | 200 |
| Stage 4 | PET R4 (G6 bridge to FCE) | 200 — Complete PET 800 |
| Stage 5-8 | FCE R1-R4 (G7) | 800 |
| Stage 9-12 | FCE R1-R4 (G8) | 800 |
| Stage 13-16 | CAE Foundation R1-R4 (G9) | 800 |

每 stage 用 1-2 Agent 并行（~150K tokens / 200 questions），1-2 stages per session。

---

## 7. PET R1 Distribution

20 KPs × 10 题 = **200 题，均匀分布**。

- Vocabulary 6 × 10 = 60
- Grammar 9 × 10 = 90
- Reading 3 × 10 = 30
- Listening 2 × 10 = 20
- **Total: 200** ✓

---

## 8. Dart Seed File Format

`lib/database/cambridge_english_kp_seed.dart`:

```dart
import '../models/knowledge_point.dart';

const List<KnowledgePoint> cambridgeEnglishKpSeed = [
  // ── PET (B1) — Grade 6 ──
  KnowledgePoint(
    subject: 'english',
    category: 'Vocabulary',
    name: 'Family & Relationships',
    fullPath: 'Vocabulary/Family & Relationships',
    introducedGrade: 6,
  ),
  // ... 65 total
];
```

`main.dart._seedDatabase` 启动时调 `KnowledgePointDao().insertIfMissing(cambridgeEnglishKpSeed)` 幂等添加。
