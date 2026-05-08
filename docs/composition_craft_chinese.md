# 命题艺术 — 语文（Composition Craft）

> **状态：** V3.12 立项 O9 task（2026-05-08）。本文件是 Layer 2 命题艺术的结构化沉淀，用于未来 AI 出题。
>
> **当前：** schema + 字段说明 + 留空 patterns 数组（**待 O10 reviewer agent 从 342 道真题逆向提炼填充**）
>
> **协同文档：** `realpaper_observations_chinese.md` / `skill_composition_template.md` / `realpaper_quality_rules.md`

## 用途与读者

读者：**未来 AI 出题 agent**（错题反馈生成同 KP 变体 / 冷门章节补题）。
- **必读时机**：任何语文出题 agent 启动前
- **应用方式**：按 `kp` 找匹配 `pattern_id` → 用 `ai_template` 生成 → 套 `distractor_design` 做选项

## Schema 说明

字段同 composition_craft_math.md，但**语文特有调整**：

- `step_count` 改"理解层级"：字面 1 / 推断 2 / 综合分析 3 / 鉴赏评价 4
- `latex_pattern` 字段改为 `material_type`：text 段 / 古诗 / 文言 / 对联
- 新增 `material_excerpt` 字段（典型阅读材料/古诗原文范例）

| 字段 | 类型 | 说明 |
|------|------|------|
| `pattern_id` | string | 唯一 ID |
| `pattern_name` | string | 中文短名 |
| `kp` | string | KP 路径 |
| `chapter` | string | 章节归属 |
| `typical_form` | string | 典型形态描述 |
| `rounds_seen` | int[] | 已观察 round 档 |
| `r1_features` | string | R1 特征（直接字面理解 / 1 个明显答案）|
| `r2_features` | string | R2 特征（1 步推断 / 中等阅读量 / 近义干扰）|
| `r3_features` | string | R3 特征（综合分析 / 长材料 / 跨课文比较）|
| `r4_features` | string | R4 特征（鉴赏评价 / 文化典故 / 文言综合）|
| `distractor_design` | string[] | 干扰项策略（如修辞类 4 选项必含同类近义）|
| `real_examples` | string[] | 真题样例引用 |
| `ai_template` | string | AI 生成参数空间 |
| `material_type` | string | text / 古诗 / 文言 / 对联 / 名著节选 / 单字 |
| `material_excerpt` | string | 典型材料范例（仅作生成参考）|
| `common_pitfalls` | string[] | 出题坑（如"答案不唯一" / "拼音声调误导"）|

## 与质量规则协同

V3.12 quality_rules.md 的语文相关条款在 craft 应用层强化：
- 拼音题区分"标声调"和"不标声调"，content 不剧透（V3.12 B1 修过 18 道）
- fill 答案纯关键词（古诗背诵 / 修辞名 / 作家名）
- 课文/名著类默认 choice，开放题不收

## Patterns 数组（待 O10 填充）

```json
{
  "subject": "chinese",
  "grade": 6,
  "schema_version": "0.1.0",
  "patterns": [
    // ===== 待 O10 reviewer agent 提炼填充 =====
    // 估计 20-30 个 pattern_id（语文 342 道真题）
    //
    // 已知雏形：
    //
    // {
    //   "pattern_id": "pinyin_with_tone_to_chars",
    //   "pattern_name": "看带声调拼音写词语",
    //   "kp": "字音字形/拼音读音",
    //   "chapter": "专项·字音字形",
    //   "typical_form": "给一组带声调拼音（如 yuán dàn / nuó yí），让用户填对应汉字词语",
    //   "rounds_seen": [1, 2],
    //   "r1_features": "常用词（如元旦/责任），单义无歧义",
    //   "r2_features": "形近字易混（如挪/那）；多音字（如长 cháng/zhǎng）需上下文判断",
    //   "r3_features": "成语 / 文言词；声调相同字形不同（如 jì 计 / 记 / 季）",
    //   "r4_features": "罕用词 / 古汉语保留音",
    //   "distractor_design": ["不适用 - 这是 fill 题"],
    //   "real_examples": [
    //     "realpaper_g6_chinese_bubian_d1_kp1_001#3",
    //     "realpaper_g6_chinese_bubian_qimo_quanzhen_001#14"
    //   ],
    //   "ai_template": "随机选六下教材生字 N 个，按声调标注 → 答案 = 汉字",
    //   "material_type": "单字/词组",
    //   "material_excerpt": "yuán dàn (元旦) / nuó yí (挪移) / zé rèn (责任)",
    //   "common_pitfalls": [
    //     "题面写'不带声调'但答案给了带声调（V3.11 实测发现，B1 已修 18 道）",
    //     "多音字未给上下文 → 答案有歧义"
    //   ]
    // }
  ]
}
```

## 语文命题艺术粗分类（待 O10 细化）

### 字音字形
- pinyin_with_tone_to_chars（看带声调拼音写词）
- pinyin_no_tone_to_chars（看不带声调拼音写词）
- pinyin_judge_correct（拼音读音判断·选择题）
- character_form_correction（字形纠错）
- duo_yin_in_context（多音字上下文判断）

### 修辞与句式
- rhetoric_identification（修辞辨识·比喻/拟人/排比/夸张）
- rhetoric_compare_choice（修辞对比·四选项同类）
- sentence_pattern_conversion（句式转换·陈述/反问/比喻）
- bingju_correction（病句修改）

### 文学常识
- author_work_match（作家作品对应）
- character_in_classics（名著人物对应）
- literature_genre（文体常识·诗/词/曲/赋）

### 古诗文
- poetry_recite_fill（古诗背诵填空·上下句对应）
- poetry_appreciation（古诗鉴赏·情感/手法/意境）
- classical_chinese_translate（文言文翻译·重点词）
- classical_chinese_understand（文言理解·主旨/人物形象）

### 阅读理解
- reading_short_text（短文阅读·3-5 题 cluster，content 含完整材料）
- reading_long_text（长文阅读·6-8 题 cluster）
- reading_main_idea（主旨概括·choice）
- reading_supporting_detail（细节理解·fill 答关键词）

### 综合应用
- compound_writing_short（写作·短句/对联/标语）
- comprehensive_review（总复习综合卷·跨 KP）

**注：** 与 D1 锚点题协同 —— D1 各档 5 道锚点必涵盖以上分类的代表。

---

**生成时间：** 2026-05-08
**对应 task：** O9（V3.12 observation_loop Layer 2）
