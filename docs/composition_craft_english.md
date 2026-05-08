# 命题艺术 — 英语（Composition Craft）

> **状态：** V3.12 立项 O9 task（2026-05-08）。本文件是 Layer 2 命题艺术的结构化沉淀，用于未来 AI 出题。
>
> **当前：** schema + 字段说明 + 留空 patterns 数组（**待 O10 reviewer agent 从 200+ 道 PET / FCE / CAE 真题逆向提炼填充**）
>
> **协同文档：** `realpaper_observations_english_cambridge.md` / `cambridge_english_kp_draft.md` / `skill_composition_template.md` / `realpaper_quality_rules.md`（§3-§5 全英文 / 禁中→英 / 听力 speakers）

## 用途与读者

读者：**未来 AI 出题 agent**（PET/FCE/CAE 出题 / 错题反馈生成同 KP 变体）。
- **必读时机**：任何英语出题 agent 启动前
- **核心约束**：本 craft 的所有 ai_template 输出必须遵循 quality_rules.md §3-§5

## Schema 说明

字段同 composition_craft_math.md，但**英语特有调整**：

- `step_count` 改"语言层级"：词形 1 / 句型 2 / 段落理解 3 / 篇章综合 4
- 新增 `cefr_level` 字段（A1 / A2 / B1 / B2 / C1）—— 与 round 协同（PET=A2-B1 / FCE=B2 / CAE=C1）
- 新增 `audio_required` + `speakers_template`（听力题）

| 字段 | 类型 | 说明 |
|------|------|------|
| `pattern_id` | string | 唯一 ID |
| `pattern_name` | string | 英文短名（如 "tense_past_simple_choice"）|
| `kp` | string | KP 路径（参考 cambridge_english_kp_draft.md）|
| `chapter` | string | 章节归属（PET/FCE/CAE 体系）|
| `typical_form` | string | 典型形态描述 |
| `rounds_seen` | int[] | 已观察 round 档 |
| `cefr_level` | string | A1/A2/B1/B2/C1 |
| `r1_features` | string | R1 特征（基础词汇 / 单时态 / 短句）|
| `r2_features` | string | R2 特征（句型转换 / 复合时态 / 中等阅读）|
| `r3_features` | string | R3 特征（语境推断 / 高频固定搭配 / 长篇阅读）|
| `r4_features` | string | R4 特征（高阶语法 / 同义辨析 / 深度写作）|
| `distractor_design` | string[] | 干扰项策略（时态相近 / 介词混淆 / 词义近似）|
| `real_examples` | string[] | 真题样例引用 |
| `ai_template` | string | AI 生成参数空间 + 句型骨架 |
| `audio_required` | bool | 是否听力题 |
| `speakers_template` | object\|null | 听力题 speakers 默认配置（V3.12 multi-role TTS）|
| `common_pitfalls` | string[] | 出题坑（含中文 / 给中文写英文 / 听力无 speakers）|

## 与质量规则协同

V3.12 quality_rules.md 的英语条款在 craft 应用层强化：
- §3 全英文：所有 ai_template 输出 content/options/audio_text **必须英文**
- §4 禁中→英：fill 类型不出"苹果 = ___"让填 apple；用 image / 英文释义代替
- §5 听力 speakers：含 audio_text 的题必填 speakers 字段（多角色按场景分配 gender/age）

## Patterns 数组（待 O10 填充）

```json
{
  "subject": "english",
  "grade": 6,
  "schema_version": "0.1.0",
  "patterns": [
    // ===== 待 O10 reviewer agent 提炼填充 =====
    // 估计 15-25 个 pattern_id（PET 200 题 + 未来 FCE/CAE 入库后扩）
    //
    // 已知雏形：
    //
    // {
    //   "pattern_id": "tense_past_simple_choice",
    //   "pattern_name": "Past Simple Tense - Choice",
    //   "kp": "时态/一般过去时",
    //   "chapter": "PET·Grammar",
    //   "typical_form": "Choose the correct past form: I ___ (read) a book yesterday.",
    //   "rounds_seen": [1, 2],
    //   "cefr_level": "A2",
    //   "r1_features": "regular verbs only / clear time markers (yesterday/last week)",
    //   "r2_features": "irregular verbs (read/wrote/went) / multi-clause context",
    //   "r3_features": "mixed tense distractors (past simple vs past continuous) / no time marker",
    //   "r4_features": "past simple in conditional/reported speech",
    //   "distractor_design": [
    //     "wrong tense (present simple form)",
    //     "wrong subject-verb agreement (was/were misuse)",
    //     "regularization of irregular verb (readed/goed)",
    //     "past continuous as confusion"
    //   ],
    //   "real_examples": [
    //     "batch_2026_05_07_g6_english_pet_r1.json#67",
    //     "batch_2026_05_07_g6_english_pet_r1.json#82"
    //   ],
    //   "ai_template": "subject ∈ {I,you,he,she,we,they}, verb ∈ irregular_verbs_a2_list, time_marker ∈ {yesterday,last_week,in_2020,when_X_happened}",
    //   "audio_required": false,
    //   "speakers_template": null,
    //   "common_pitfalls": [
    //     "中文 prompt 让填英文（违反 §4）",
    //     "选项含中文释义（违反 §3）"
    //   ]
    // }
  ]
}
```

## speakers_template 标准配置（V3.12 multi-role TTS）

听力题按场景预设 speakers：

```json
"speakers_template": {
  "school": {
    "A": {"gender": "male", "age": "child"},
    "B": {"gender": "female", "age": "adult"}
  },
  "store": {
    "A": {"gender": "female", "age": "adult"},
    "B": {"gender": "male", "age": "adult"}
  },
  "home": {
    "A": {"gender": "female", "age": "adult"},
    "B": {"gender": "male", "age": "child"}
  },
  "playground": {
    "A": {"gender": "male", "age": "child"},
    "B": {"gender": "female", "age": "child"}
  },
  "monologue_announcement": {
    "_": {"gender": "female", "age": "adult"}
  },
  "monologue_kid_describing": {
    "_": {"gender": "female", "age": "child"}
  }
}
```

AI 生成听力题时按 typical_form 选场景，speakers 字段直接套对应模板。

## 英语命题艺术粗分类（待 O10 细化）

### Vocabulary（词汇）
- vocab_definition_match（英文定义 → 词汇 choice）
- vocab_synonym_choice（同义词选择）
- vocab_antonym_choice（反义词选择）
- vocab_in_context（上下文猜词义）
- vocab_collocation（高频搭配）

### Grammar（语法）
- tense_present_simple_choice（一般现在时）
- tense_past_simple_choice（一般过去时）
- tense_present_continuous_choice（现在进行时）
- tense_present_perfect_choice（现在完成时·FCE 起）
- modal_verbs_choice（情态动词）
- comparative_superlative_choice（比较级最高级）
- preposition_choice（介词·time/place/movement）
- article_choice（冠词 a/an/the）
- subject_verb_agreement_choice（主谓一致）

### Reading（阅读）
- reading_main_idea_choice（主旨题）
- reading_specific_detail_choice（细节题）
- reading_inference_choice（推断题·R3+）
- reading_vocabulary_in_context（语境词义）
- reading_writers_attitude（作者态度·B2+）

### Listening（听力）
- listen_short_dialogue_choice（短对话理解·A 题）
- listen_specific_info_choice（特定信息·B 题）
- listen_monologue_announcement（独白通知）
- listen_long_conversation（长对话·多角色多回合）

### Writing（PET 不出，FCE/CAE 起）
- writing_email_short（短邮件·100 词）
- writing_story_continuation（故事续写）
- writing_essay_argument（议论文）

**注：** 当前 daughter app 仅入库 PET 200 题，FCE/CAE 待 V3.9 完整体系实施。本 craft 留给 PET 范围足够，FCE/CAE pattern 等真题入库后用 O12（双向 update）追加。

---

**生成时间：** 2026-05-08
**对应 task：** O9（V3.12 observation_loop Layer 2）
