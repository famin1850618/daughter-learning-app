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

## Patterns 数组（O10 已填充 2026-05-08）

```json
{
  "subject": "chinese",
  "grade": 6,
  "schema_version": "0.1.0",
  "_meta": {
    "created": "2026-05-08",
    "task": "O10 reviewer agent 提炼自 6 卷 251 题（六下语文真题）",
    "source_batches": [
      "realpaper_g6_chinese_bubian_d1_kp1_001 (32 题)",
      "realpaper_g6_chinese_bubian_d2_kp1_001 (48 题)",
      "realpaper_g6_chinese_bubian_d3_kp1_001 (28 题)",
      "realpaper_g6_chinese_bubian_qimo_quanzhen_001 (35 题)",
      "realpaper_g6_chinese_bubian_qizhong_002 (37 题)",
      "realpaper_g6_chinese_bubian_zhuanxiang_zixingyin_001 (71 题)"
    ],
    "total_questions_scanned": 251,
    "pattern_threshold": "≥ 3 道真题样例同模式才入库（孤例不留）",
    "famin_anchor_calibration": "r2/r3/r4 锚点 Famin comment 已纳入 craft（褒贬明显→R1; 三短一长→不升 R3+; 段意概括→R2）",
    "d5/d6/d4_skipped": "V3.12.3 已删除 OCR 抢救伪题；本批仅扫 6 卷有效真题",
    "total_patterns": 23,
    "removed_below_threshold": [
      {
        "pattern_id": "sentence_pattern_conversion_quote",
        "examples": 1,
        "reason": "本批 6 卷样例不足 3 道，schema 待补"
      },
      {
        "pattern_id": "punctuation_4option_choice",
        "examples": 2,
        "reason": "本批 6 卷样例不足 3 道，schema 待补"
      },
      {
        "pattern_id": "bingju_correction_choice",
        "examples": 2,
        "reason": "本批 6 卷样例不足 3 道，schema 待补"
      },
      {
        "pattern_id": "reading_emotion_curve_choice",
        "examples": 1,
        "reason": "本批 6 卷样例不足 3 道，schema 待补"
      }
    ]
  },
  "patterns": [
    {
      "pattern_id": "pinyin_no_tone_to_chars",
      "pattern_name": "看不带声调拼音写词语",
      "kp": "字词/字形",
      "chapter": "字词",
      "typical_form": "给一组不带声调拼音（如 nuo yi / qi liang / zha lan），让用户填对应汉字词语；常见两字词或三字词",
      "rounds_seen": [
        1,
        2
      ],
      "r1_features": "课文常用词（如挪移/凄凉/栅栏），单义无歧义，2 字常用搭配",
      "r2_features": "形近字易混（如蹒跚/潸潸；徘徊/绯徊）；AABB 叠词（躲躲藏藏）；4 字成语（狼吞虎咽）",
      "r3_features": "罕见双音节（如踽踽/逡巡），上下文不足以唯一判定（语文 6 下少见）",
      "r4_features": "文言保留音 / 语文 6 下未涉及",
      "distractor_design": [
        "不适用 - fill 题"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_zhuanxiang_zixingyin_001.json#7  (suan cu 酸醋)",
        "realpaper_g6_chinese_bubian_zhuanxiang_zixingyin_001.json#14 (nuo yi 挪移)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#4  (qi liang 凄凉)",
        "realpaper_g6_chinese_bubian_qimo_quanzhen_001.json#10 (fěn suì 粉碎)",
        "realpaper_g6_chinese_bubian_qizhong_002.json#0  (jiàn duàn 间断)"
      ],
      "ai_template": "随机选六下教材生字词 N 个 → 拼音不带声调形式给出 → 答案 = 汉字词语；约 80% 选 R1 常用词 + 20% R2 形近字干扰类",
      "material_type": "单字/词组（拼音提示）",
      "material_excerpt": "suan cu (酸醋) / nuo yi (挪移) / qi liang (凄凉) / zha lan (栅栏)",
      "common_pitfalls": [
        "题面写「不带声调」但答案给了带声调（V3.11 实测发现，B1 已修 18 道）",
        "多音字未给上下文 → 答案有歧义",
        "AABB 叠词答案需注明叠词形式（如 duo duo cang cang → 躲躲藏藏，不能写「躲藏」）"
      ]
    },
    {
      "pattern_id": "pinyin_in_context_blank",
      "pattern_name": "看带声调拼音填语境空",
      "kp": "字词/字形",
      "chapter": "字词",
      "typical_form": "给一段含 pinyin 的语境句（如「除夕家家 dēnɡ huǒ tōnɡ xiāo (    )」），让用户在括号填汉字词语",
      "rounds_seen": [
        1,
        2
      ],
      "r1_features": "拼音带声调 + 完整语境句，唯一指向常用 2-4 字词（如灯火通宵/蒸融/惆怅）",
      "r2_features": "拼音字形涉及难写字（如 zhēng róng 蒸融的「融」），需正确书写形旁",
      "r3_features": "（数据中未见）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "不适用 - fill 题"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_d1_kp1_001.json#0 (zā lā bā zhōu 腊八粥)",
        "realpaper_g6_chinese_bubian_d1_kp1_001.json#1 (dēnɡ huǒ tōnɡ xiāo 灯火通宵)",
        "realpaper_g6_chinese_bubian_d3_kp1_001.json#6 (zhēng róng 蒸融)",
        "realpaper_g6_chinese_bubian_qizhong_002.json#1 (fáng yù 防御)"
      ],
      "ai_template": "选六下课文典型片段 → 关键词改拼音（带声调）→ 答案 = 词语；语境提供唯一指向",
      "material_type": "语境句（含 pinyin）",
      "material_excerpt": "除夕家家 dēnɡ huǒ tōnɡ xiāo (    )；过去的日子如薄雾，被初阳 zhēng róng 了",
      "common_pitfalls": [
        "拼音与常见多音字冲突需上下文消歧",
        "繁简体差异（语文教材用简体）"
      ]
    },
    {
      "pattern_id": "char_pronunciation_choice",
      "pattern_name": "加点字读音判断·选择",
      "kp": "字词/字音",
      "chapter": "字词",
      "typical_form": "给一个含加点字的词或句（如「薄雾」中加点的「薄」），4 选项给不同读音（多为 2 选项为常考多音字）",
      "rounds_seen": [
        1,
        2
      ],
      "r1_features": "课内常考多音字（薄/挣/挨/晃/正月/铭等），2 选项 A/B 简单干扰，语境提示读音明显",
      "r2_features": "4 选项读音相近（如 zhū/zhù/shū/yǔ），考查具体生僻字（杼/峻/沧/笼）",
      "r3_features": "（数据中未见）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "近声母异韵母（如 zhū vs zhù）",
        "声调干扰（cǎng vs cāng）",
        "形近字读音错位（如 nóng/lóng 浓/笼）",
        "「全部正确」选项作为兜底干扰"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#0 (畜 xù/chù)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#1 (挣 zhēng/zhèng)",
        "realpaper_g6_chinese_bubian_d3_kp1_001.json#0 (薄 bó/báo)",
        "realpaper_g6_chinese_bubian_zhuanxiang_zixingyin_001.json#4 (杼 zhù)",
        "realpaper_g6_chinese_bubian_zhuanxiang_zixingyin_001.json#65 (沧 cāng)"
      ],
      "ai_template": "从课文/常用字典中选多音字 N 个 → 给加点字所在词组 → 选项为 2-4 个候选读音；R1 用 2 选项 + 课内常字；R2 用 4 选项 + 形近字干扰",
      "material_type": "字音（加点字）",
      "material_excerpt": "「薄」字加点的字（薄雾）正确读音是？A. bó / B. báo",
      "common_pitfalls": [
        "二选一读音题 distractor_density 极低（0.0-0.25），对应 R1",
        "组合读音判断题（如「下列读音都相同的一组」）容易被升档为 R2，但其实是字典记忆"
      ]
    },
    {
      "pattern_id": "char_form_correction_fill",
      "pattern_name": "字形纠错·填正确字",
      "kp": "字词/字形",
      "chapter": "字词",
      "typical_form": "给一个常用四字词语含错别字（如「乌（ ）之众」），让用户填正确字（单字 fill）",
      "rounds_seen": [
        1
      ],
      "r1_features": "常用四字成语字形纠错（合/眩/济/漫/涯/议/焉），课内已学，单字答案",
      "r2_features": "（数据中未见 R2 例）",
      "r3_features": "（数据中未见）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "不适用 - 单字 fill"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#12 (乌合之众)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#13 (头昏目眩)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#14 (无济于事)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#15 (漫无人烟)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#16 (天涯海角)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#17 (不可思议)"
      ],
      "ai_template": "从课文常用四字成语库中选 N 个 → 关键字改成形近误字 → 答案 = 正确单字",
      "material_type": "成语（含错别字）",
      "material_excerpt": "乌（ ）之众 → 合 / 头昏目（ ）→ 眩 / 无（ ）于事 → 济",
      "common_pitfalls": [
        "误写为另一个同音字（如「焉」误为「嫉」）",
        "4 字成语的语义提示要明确"
      ]
    },
    {
      "pattern_id": "char_form_4group_choice",
      "pattern_name": "4 组词语字形辨识·选正确",
      "kp": "字词/字形",
      "chapter": "字词",
      "typical_form": "给 4 组词语（每组 3-4 个），选「书写都正确」或「都有错」的一组",
      "rounds_seen": [
        1,
        2
      ],
      "r1_features": "错字明显（慌草→荒草；帐蓬→帐篷；浓绸→浓稠），1 组对 3 组明显错",
      "r2_features": "错字隐蔽（书藉→书籍；匪徙→匪徒），需逐组仔细比对",
      "r3_features": "（数据中未见）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "形近字错位（藉/籍 / 徙/徒）",
        "音同字混（慌/荒 / 蓬/篷）",
        "偏旁错（绸/稠）",
        "1 组 3-4 字全对作为正确选项"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_d3_kp1_001.json#5 (耽搁/慌草...)",
        "realpaper_g6_chinese_bubian_qimo_quanzhen_001.json#1 (整理/书藉...)",
        "realpaper_g6_chinese_bubian_qizhong_002.json#6 (展览/风筝...)"
      ],
      "ai_template": "从课文词表抽 12-16 词 → 4 组每组 3-4 词 → 1 组全对 + 3 组各含 1 错字",
      "material_type": "4 组词语（每组 3-4 词）",
      "material_excerpt": "A. 整理/书藉/文件/含糊  B. 残暴/匪徙/拘留/法庭  C. 加速/齿轮/慌凉/丑恶  D. 转动/测量/善于/事例",
      "common_pitfalls": [
        "Famin 反馈类似题（chinese_r3_anchor_5 跨多项常识找一错）也可被认为 R2-R3，需看错字隐蔽度",
        "4 组同含课文词时，错字不能太隐蔽否则超出 R2"
      ]
    },
    {
      "pattern_id": "idiom_complete_fill",
      "pattern_name": "补充四字成语",
      "kp": "字词/成语运用",
      "chapter": "字词",
      "typical_form": "给四字成语挖空 1-2 字（如「（  ）思乱想 → 胡」/「万（ ）（ ）新 → 象更」），让用户填",
      "rounds_seen": [
        1,
        2
      ],
      "r1_features": "课内常考成语（万象更新/张灯结彩/截然不同/胡思乱想/全神贯注），单字或 2 字答案",
      "r2_features": "课外稍冷成语（两面三刀），或多空（万（ ）（ ）新）需独立判定",
      "r3_features": "（数据中未见）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "不适用 - fill 题"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_d1_kp1_001.json#8  (万象更新)",
        "realpaper_g6_chinese_bubian_d1_kp1_001.json#9  (截然不同)",
        "realpaper_g6_chinese_bubian_qizhong_002.json#16 (一去不返)",
        "realpaper_g6_chinese_bubian_qizhong_002.json#17 (胡思乱想)",
        "realpaper_g6_chinese_bubian_qizhong_002.json#18 (全神贯注)"
      ],
      "ai_template": "从六下成语表抽 N 个 → 挖 1-2 字 → 答案纯字（不带词性标记）",
      "material_type": "四字成语（挖字）",
      "material_excerpt": "（  ）思乱想 → 胡；万（ ）（ ）新 → 象更",
      "common_pitfalls": [
        "多空成语（万（ ）（ ）新）需注明顺序和分隔符（逗号）",
        "alt_answers 处理多种正确填法（万象更新/万象换新）"
      ]
    },
    {
      "pattern_id": "idiom_in_context_select",
      "pattern_name": "选词填空·成语在语境",
      "kp": "字词/成语运用",
      "chapter": "字词",
      "typical_form": "给候选成语池（2-4 个）+ 语境句（1-2 句），让用户选一个最贴切的成语填空",
      "rounds_seen": [
        1,
        2
      ],
      "r1_features": "成语含义直白匹配（万不得已 vs 截然不同 vs 张灯结彩），关键词触发明显",
      "r2_features": "成语近义辨析（全神贯注 vs 截然不同 在不同语境互换），需读全句捕捉语义重点",
      "r3_features": "（数据中未见）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "不适用 - fill 题, 候选池作 alt_answers"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_d1_kp1_001.json#15 (除非万不得已)",
        "realpaper_g6_chinese_bubian_d1_kp1_001.json#14 (张灯结彩,万象更新)",
        "realpaper_g6_chinese_bubian_qizhong_002.json#23 (全神贯注)",
        "realpaper_g6_chinese_bubian_qizhong_002.json#24 (截然不同)"
      ],
      "ai_template": "选 2-4 个语义相近成语池 → 设计 N 个语境句各对应一个 → 答案 = 单成语 + alt 含可换序解",
      "material_type": "成语候选池 + 语境句",
      "material_excerpt": "（全神贯注／截然不同）：八儿（    ）地看着妈妈煮制腊八粥",
      "common_pitfalls": [
        "alt_answers 必须列全所有合法填法",
        "近义辨析题难度容易被高估为 R2，其实关键词触发很明显时仍是 R1"
      ]
    },
    {
      "pattern_id": "synonym_in_context_select",
      "pattern_name": "同根近义词辨析·选词填空",
      "kp": "字词/词语搭配",
      "chapter": "字词",
      "typical_form": "用同一字（如「续」「望」）组成 4 个近义词（陆续/连续/持续/继续）→ 4 个语境句一一对应",
      "rounds_seen": [
        1,
        2
      ],
      "r1_features": "词语搭配习惯明显（「连续干 5 天」/「希望落空」），关键搭配触发即定",
      "r2_features": "搭配差异需读完整句细辨（陆续/连续/持续/继续在「搬运/干活/下雨/加固」上的细微区别）",
      "r3_features": "（数据中未见）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "不适用 - fill 题, 候选池作 alt_answers"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#19 (陆续搬运)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#20 (连续干 5 天)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#21 (持续下半月)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#22 (继续加固)",
        "realpaper_g6_chinese_bubian_d3_kp1_001.json#12 (渴望/盼望/希望/失望)"
      ],
      "ai_template": "选一个公共字 → 列 4 个常见搭配（陆/连/持/继续）→ 设计 4 个语境句 → 答案逐一",
      "material_type": "同根词候选池 + 4 语境",
      "material_excerpt": "用「续」字组成不同词语：陆续/连续/持续/继续",
      "common_pitfalls": [
        "近义词辨析在标准答案上容易出现「陆续/连续」可互换 → alt_answers 必须严格筛选",
        "题干必须明示「不重复使用」，否则 4 词可能填同一个"
      ]
    },
    {
      "pattern_id": "conjunction_fill_pair",
      "pattern_name": "关联词成对填空",
      "kp": "句式与标点/关联词运用",
      "chapter": "句式与标点",
      "typical_form": "在语境句中挖两个关联词（如「__可以买玩具，__可以放鞭炮」），让用户按顺序填一对",
      "rounds_seen": [
        1,
        2
      ],
      "r1_features": "递进/转折/并列直白（不但/而且；虽然/但是；不是/而是），逻辑连接词标志明显",
      "r2_features": "因果倒装（之所以/是因为）需识别句序，alt_answers 多",
      "r3_features": "（数据中未见）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "不适用 - fill 题, alt_answers 列同义对（不仅/还）"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_d1_kp1_001.json#18 (不但,而且)",
        "realpaper_g6_chinese_bubian_d1_kp1_001.json#19 (不是,而是)",
        "realpaper_g6_chinese_bubian_d1_kp1_001.json#20 (之所以,是因为)",
        "realpaper_g6_chinese_bubian_d1_kp1_001.json#21 (虽然,但是)"
      ],
      "ai_template": "选关联词类型（递进/转折/并列/因果/选择）→ 设计语境句 → 答案 = 一对关联词 + alt_answers 同义对",
      "material_type": "语境句（双空）",
      "material_excerpt": "过新年，小孩子(    )可以买玩意儿，(    )可以放鞭炮",
      "common_pitfalls": [
        "alt_answers 至少 2 个同义对（不但/而且；不仅/而且；不但/还）",
        "答案分隔符必须明示（用逗号分隔）"
      ]
    },
    {
      "pattern_id": "sentence_judgment_declarative",
      "pattern_name": "判断陈述句·真假",
      "kp": "句式与标点/句式转换",
      "chapter": "句式与标点",
      "typical_form": "给一个句子，让用户判断「是不是陈述句」（type=judgment 对/错）",
      "rounds_seen": [
        1
      ],
      "r1_features": "祈使句（请走出心灵的监狱）/疑问句（怎样学会处理痛苦？）vs 陈述句对比明显",
      "r2_features": "（数据中未见 R2 例）",
      "r3_features": "（数据中未见）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "不适用 - judgment 题"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#43 (请走出 → 错)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#44 (曼德拉因反对入狱 → 对)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#45 (怎样学会 → 错)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#46 (邀请起身 → 对)"
      ],
      "ai_template": "选 4 类句子（陈述/疑问/祈使/感叹）→ 出 4 题 type=judgment → 答案对/错",
      "material_type": "单句",
      "material_excerpt": "「请走出心灵的监狱。」是不是陈述句？错（祈使句）",
      "common_pitfalls": [
        "判断题答案统一「对/错」（不要用「是/否」混杂）",
        "题面必须含明显句末标点提示句式"
      ]
    },
    {
      "pattern_id": "sentence_insertion_position",
      "pattern_name": "句子插入位置·散文段落",
      "kp": "句式与标点/句子衔接",
      "chapter": "句式与标点",
      "typical_form": "给一段含 ①②③④ 标号的文字 + 一个待插入句，4 选项 ABCD 对应插入位置",
      "rounds_seen": [
        2,
        3
      ],
      "r1_features": "（数据中未见 R1 例）",
      "r2_features": "插入句与某编号位置语义直接对应（如 ① 处与「不得不干这活儿」递进衔接）",
      "r3_features": "需识别上下文逻辑断层，4 位置看似都合语流，需精准定位「承上启下」点（如《买馒头》文末插入抒情句）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "①位置：与前文递进/转折直接衔接",
        "②③位置：相邻段位语流也合理但偏题",
        "④位置：与最近上下文呼应",
        "唯一对：上下文逻辑唯一断层处"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_qimo_quanzhen_001.json#8 (「在做作业的时候他们就可以互相帮助」位置 D 处 ④)",
        "realpaper_g6_chinese_bubian_qizhong_002.json#14 (「又有的是时间」位置 A 处 ①)",
        "realpaper_g6_chinese_bubian_zhuanxiang_zixingyin_001.json#70 (《买馒头》文末插入)"
      ],
      "ai_template": "选 1 段散文（4 句以上）→ 抽出 1 句作待插入 → 标号 ①②③④ 4 个候选位置 → 答案 = 唯一逻辑衔接处",
      "material_type": "段落 + 编号位置",
      "material_excerpt": "原文 ① 有什么必要介意呢？②除了在岛上转悠，③寻找吃的以外，④那我也没有其他事可干 → 「又有的是时间」插 ①",
      "common_pitfalls": [
        "插入句的语意指向需明确（递进 vs 因果 vs 转折）",
        "选项位置必须 4 个相邻的编号，避免歧义"
      ]
    },
    {
      "pattern_id": "foreign_author_match_choice",
      "pattern_name": "外国名著作家匹配·选择",
      "kp": "文学常识/外国作家作品",
      "chapter": "文学常识",
      "typical_form": "给一部外国名著（如《鲁滨逊漂流记》），4 选项为 4 个外国作家（含丹尼尔·笛福/马克·吐温/卡罗尔/拉格洛芙等），选作者",
      "rounds_seen": [
        1
      ],
      "r1_features": "课内必读名著（鲁滨逊/汤姆/爱丽丝/骑鹅），4 作家差异明显（年代+国籍+风格），错答可瞬间排除",
      "r2_features": "（数据中未见 R2 例）",
      "r3_features": "（数据中未见）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "同期同类作家干扰（笛福/卡罗尔同英国不同时期）",
        "不同语种作家干扰（拉格洛芙瑞典 / 马克·吐温美国）",
        "正确作家作答案"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#27 (鲁滨逊→笛福)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#28 (爱丽丝→卡罗尔)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#29 (骑鹅→拉格洛芙)"
      ],
      "ai_template": "选课内必读外国名著 N 部 → 候选作家池（同年代+不同国籍 4 人）→ 答案 = 正确作家",
      "material_type": "书名 + 4 作家选项",
      "material_excerpt": "《鲁滨逊漂流记》的作者是？A. 丹尼尔·笛福 B. 刘易斯·卡罗尔 C. 塞尔玛·拉格洛芙 D. 马克·吐温",
      "common_pitfalls": [
        "作家中文译名格式（如「丹尼尔·笛福」中间是间隔号「·」非顿号）",
        "fill 类（如「《汤姆·索亚历险记》是（ ）国作家」）属同 KP 子模式，答案是国别单字"
      ]
    },
    {
      "pattern_id": "cultural_age_term_match",
      "pattern_name": "古代年龄称谓·选岁数",
      "kp": "文学常识/文化常识",
      "chapter": "文学常识",
      "typical_form": "给一个古代年龄称谓（豆蔻年华/花甲/知天命），4 选项给 4 个岁数（13/50/60/70）",
      "rounds_seen": [
        1
      ],
      "r1_features": "课内典故对应记忆（豆蔻 13 / 花甲 60 / 知天命 50 / 古稀 70），4 数字干扰简单",
      "r2_features": "（数据中未见 R2 例）",
      "r3_features": "（数据中未见）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "4 数字干扰（13/50/60/70）覆盖各称谓的常考年龄"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#30 (豆蔻 13)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#31 (花甲 60)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#32 (知天命 50)"
      ],
      "ai_template": "选课内古代年龄称谓 N 个 → 答案 = 对应岁数 → 4 数字干扰池",
      "material_type": "称谓 + 4 数字选项",
      "material_excerpt": "「豆蔻年华」指（  ）岁。A. 13 B. 50 C. 60 D. 70",
      "common_pitfalls": [
        "岁数数字必须为典籍中的标准年龄（不要混入「弱冠 20」「不惑 40」如果题目未涉及）"
      ]
    },
    {
      "pattern_id": "poem_recite_fill",
      "pattern_name": "古诗背诵默写·填上下句",
      "kp": "古诗文/古诗词背诵默写",
      "chapter": "古诗文",
      "typical_form": "给古诗的一句（上句或下句），让用户填配对的另一句（5 字或 7 字）",
      "rounds_seen": [
        1,
        2
      ],
      "r1_features": "课内必背名句（少壮不努力→老大徒伤悲；今夜月明人尽望→不知秋思落谁家），唯一指向",
      "r2_features": "课内古诗较深处的非首尾句（终日不成章→泣涕零如雨），需熟练背诵",
      "r3_features": "（数据中未见）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "不适用 - fill 题（choice 题用 4 同类古诗句作干扰）"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_d3_kp1_001.json#20 (少壮不努力 → 老大徒伤悲)",
        "realpaper_g6_chinese_bubian_d3_kp1_001.json#21 (反向：老大徒伤悲 上句)",
        "realpaper_g6_chinese_bubian_qimo_quanzhen_001.json#20 (今夜月明人尽望→不知秋思落谁家)",
        "realpaper_g6_chinese_bubian_qimo_quanzhen_001.json#22 (粉骨碎身浑不怕→要留清白在人间)",
        "realpaper_g6_chinese_bubian_qizhong_002.json#26-29 (4 道默写)"
      ],
      "ai_template": "选六下必背古诗（《长歌行》《十五夜望月》《游子吟》《竹石》《石灰吟》《九月九忆兄弟》《迢迢牵牛星》等）→ 出 N 题填上句或下句",
      "material_type": "古诗（5 字或 7 字句）",
      "material_excerpt": "「少壮不努力，____」→ 老大徒伤悲",
      "common_pitfalls": [
        "答案必须用简体（与教材一致），不要用繁体",
        "「填上句」与「填下句」要在题面明示位置（_____ 在前还是后）"
      ]
    },
    {
      "pattern_id": "kewen_content_fill_basic",
      "pattern_name": "课文基础信息填空·作者/顺序/关键词",
      "kp": "课文与名著/课文内容理解",
      "chapter": "课文与名著",
      "typical_form": "「《北京的春节》的作者是（ ）」/「按（ ）顺序」/「藏戏被称为藏文化的（ ）」类直接信息填空",
      "rounds_seen": [
        1,
        2
      ],
      "r1_features": "课内基础信息（老舍/沈从文/时间/活化石/唐东杰布），单点记忆",
      "r2_features": "（数据中未见 - 已被本次 D2 调档为 R1）",
      "r3_features": "（数据中未见）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "不适用 - fill 题"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_d1_kp1_001.json#22 (老舍)",
        "realpaper_g6_chinese_bubian_d1_kp1_001.json#23 (时间顺序)",
        "realpaper_g6_chinese_bubian_d1_kp1_001.json#24 (活化石)",
        "realpaper_g6_chinese_bubian_d1_kp1_001.json#25 (唐东杰布)",
        "realpaper_g6_chinese_bubian_d1_kp1_001.json#26 (沈从文)",
        "realpaper_g6_chinese_bubian_d3_kp1_001.json#22 (《那个星期天》时间顺序)"
      ],
      "ai_template": "从六下课文表抽 N 篇 → 出基础信息（作者/写作顺序/关键意象/人名）",
      "material_type": "课文片段或题干提示",
      "material_excerpt": "藏戏被称为藏文化的「（ ）」→ 活化石",
      "common_pitfalls": [
        "「时间顺序」「空间顺序」类答案需为标准 2 字术语",
        "Famin 锚点反馈类似题（chinese_r3_anchor_1 褒贬明显）证实此类是 R1 而非 R2"
      ]
    },
    {
      "pattern_id": "character_emotion_fill_4word",
      "pattern_name": "课文人物心情·填四字词",
      "kp": "课文与名著/课文内容理解",
      "chapter": "课文与名著",
      "typical_form": "「《那个星期天》（早晨/中段/结尾）心情是（ ）」类，让用户填 4 字词概括人物情感",
      "rounds_seen": [
        1,
        2
      ],
      "r1_features": "Famin 锚点反馈：「焦急兴奋/焦急无奈/失望委屈」可直接从课文情感线读出，但需 4 字凝练",
      "r2_features": "情感转换需理解课文 4 个时段对应的不同心情（早晨 vs 中段 vs 结尾），多空互不可换",
      "r3_features": "（数据中未见）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "不适用 - fill 题"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_d3_kp1_001.json#23 (早晨：焦急兴奋)",
        "realpaper_g6_chinese_bubian_d3_kp1_001.json#24 (中段：焦急无奈)",
        "realpaper_g6_chinese_bubian_d3_kp1_001.json#25 (结尾：失望委屈)"
      ],
      "ai_template": "选课文情感主线明显的篇目（《那个星期天》《十六年前的回忆》）→ 出 N 个时段心情填空",
      "material_type": "课文情感填空（4 字词）",
      "material_excerpt": "《那个星期天》早晨心情 → 焦急兴奋",
      "common_pitfalls": [
        "4 字词答案有多种合理填法（焦急兴奋/焦急喜悦），alt_answers 需周全",
        "Famin 反馈：此类被高估为 R2，实际课内主线明显是 R1"
      ]
    },
    {
      "pattern_id": "kewen_content_choice_attitude",
      "pattern_name": "课文人物形象/态度·选择",
      "kp": "课文与名著/课文内容理解",
      "chapter": "课文与名著",
      "typical_form": "「鲁滨逊塑造了什么形象？」/「李大钊表现什么品质？」/「山东老乡的生活态度？」4 选项性格特征",
      "rounds_seen": [
        1,
        2
      ],
      "r1_features": "Famin 锚点反馈（chinese_r3_anchor_1 褒贬明显）：人物形象褒贬鲜明（不畏艰险 vs 胆小怕事），错答可瞬排",
      "r2_features": "课文未直接概括，需读全文提炼（如《买馒头》「钱够用就好」→ 豁达开朗）",
      "r3_features": "（数据中未见 - Famin 反馈此类不应升 R3）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "正确特征：明显褒义（不畏艰险/坚毅/豁达开朗）",
        "明显反义干扰：贬义（胆小怕事/贪图享乐/自私自利）",
        "无关干扰：偏离课文（漠不关心）",
        "「全部正确」/「都不对」作兜底"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#33 (鲁滨逊：不畏艰险乐观坚强)",
        "realpaper_g6_chinese_bubian_qimo_quanzhen_001.json#7 (李大钊坚毅)",
        "realpaper_g6_chinese_bubian_zhuanxiang_zixingyin_001.json#69 (山东老乡豁达开朗)"
      ],
      "ai_template": "选课文人物 → 4 选项配 1 正 + 1 明显反义 + 2 无关 → 答案",
      "material_type": "课文片段 + 4 性格选项",
      "material_excerpt": "鲁滨逊塑造了怎样的主人公形象？A. 不畏艰险乐观坚强（对）B. 胆小怕事...",
      "common_pitfalls": [
        "Famin 反馈：人物褒贬明显时此类是 R1-R2 而非 R3",
        "不要选「漠不关心」「斤斤计较」这类与课文相关性极弱的干扰"
      ]
    },
    {
      "pattern_id": "famous_book_match_choice",
      "pattern_name": "读后感书名匹配·选择",
      "kp": "课文与名著/名著情节人物",
      "chapter": "课文与名著",
      "typical_form": "「读后感标题：『XXX——读《 》有感』，最合适的书名是？」4 选项给 4 部名著",
      "rounds_seen": [
        1
      ],
      "r1_features": "标题与名著主题对应明显（科学梦→《科学家故事 100 个》/动物情感→《狼王梦》/男孩成长→《汤姆》）",
      "r2_features": "（数据中未见）",
      "r3_features": "（数据中未见）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "正确书名：标题主题直接命中",
        "其他 3 名著作明显不匹配（鲁滨逊不是动物情感）",
        "4 部名著来源固定池（《科学家故事》《汤姆》《狼王梦》《鲁滨逊》）"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#39 (科学梦→《科学家故事 100 个》)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#40 (动物情感→《狼王梦》)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#41 (男孩成长→《汤姆》)"
      ],
      "ai_template": "选课内必读名著池 → 出读后感主题标题 → 答案 = 主题最匹配的书",
      "material_type": "标题 + 4 书名选项",
      "material_excerpt": "「科学梦·中国梦——读《 》有感」→《科学家故事 100 个》",
      "common_pitfalls": [
        "书名格式必须用书名号《》",
        "干扰名著必须是同年龄段课内必读（非随机外国名著）"
      ]
    },
    {
      "pattern_id": "writing_method_judge_choice",
      "pattern_name": "描写方法判别·选择",
      "kp": "写作/人物描写",
      "chapter": "写作",
      "typical_form": "给一个句子，4 选项 ABCD 为外貌/语言/心理/动作描写，选最准确的描写方法",
      "rounds_seen": [
        1,
        2
      ],
      "r1_features": "描写特征明显（头发/雀斑→外貌；引号/对话→语言；「他想」→心理；动词串「丢下/摸索/走过去」→动作）",
      "r2_features": "（数据中未见 R2 例 - 但本批 D2 中将外貌描写题升档作 R2）",
      "r3_features": "（数据中未见）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "外貌描写：含具体外形词（头发/雀斑/补丁）",
        "语言描写：含直接引语「」",
        "心理描写：含「他想」「心想」标志",
        "动作描写：动词串"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#23 (外貌)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#24 (语言)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#25 (心理)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#26 (动作)"
      ],
      "ai_template": "选 4 类描写方法各 1 句 → 选项固定 4 种描写名",
      "material_type": "单句 + 4 描写名选项",
      "material_excerpt": "「『这大概是一场梦』他想」→ 心理描写",
      "common_pitfalls": [
        "句子必须只含一种描写方法（不要混合外貌+动作）",
        "4 选项固定（外貌/语言/心理/动作）作 4 选 1，干扰强度低 → R1"
      ]
    },
    {
      "pattern_id": "reading_material_correspond_simple",
      "pattern_name": "阅读·原文复述对应·选择",
      "kp": "阅读理解/阅读理解",
      "chapter": "阅读理解",
      "typical_form": "给一段材料中的具体表述（如「攻击源 IP 集中省份」/「气象的定义」）→ 4 选项给 4 种表述，选与原文一致的",
      "rounds_seen": [
        1,
        2
      ],
      "r1_features": "原文有明确表述，4 选项中 1 项一字不差对应原文，3 项替换关键词（北京/广西 vs 广东；东南沿海 vs 华东沿海）",
      "r2_features": "（数据中未见 R2 例）",
      "r3_features": "（数据中未见）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "正确：与原文一致",
        "干扰 1：替换关键词（一字之差，如「广东」→「广西」）",
        "干扰 2：错改方位（「东南」→「南」）",
        "干扰 3：错改类别（「物理现象」→「化学变化」）"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_qimo_quanzhen_001.json#23 (恶意 IP 集中省份)",
        "realpaper_g6_chinese_bubian_qimo_quanzhen_001.json#24 (东南沿海受害)",
        "realpaper_g6_chinese_bubian_qimo_quanzhen_001.json#26 (气象定义)"
      ],
      "ai_template": "从材料抽具体表述 → 出 N 题 4 选项 → 1 项一致 + 3 项关键词错位",
      "material_type": "材料段 + 题干表述对照",
      "material_excerpt": "「北京、江苏、浙江、山东、广东」→ A 项一致 / B-D 各错 1 字",
      "common_pitfalls": [
        "干扰项的替换必须是材料中已出现的关键词（如同段落另一省份），不要凭空造词",
        "Famin 锚点反馈类似题（chinese_r4_anchor_2「这一过程」）：4 选项嵌套包含时容易降为 R2"
      ]
    },
    {
      "pattern_id": "reading_emotion_choice",
      "pattern_name": "阅读·人物心情/语气·选择",
      "kp": "阅读理解/阅读理解",
      "chapter": "阅读理解",
      "typical_form": "「『我』被打了此时心情是？」/「『大喝一声』应读出（ ）的语气？」4 选项给 4 类情绪",
      "rounds_seen": [
        1,
        2
      ],
      "r1_features": "原文直接点明（「我恨死外公了」→ 恨）/「大喝」「眼神猛兽」→ 愤怒，关键词触发明显",
      "r2_features": "需推理但有原文支撑（如《向日葵》女儿欢喜原因 → 孝心深重）",
      "r3_features": "（数据中未见 - Famin 反馈此类是 R1-R2，不应高升）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "正确情绪：原文直接关键词触发",
        "近义干扰：相似强度的反向情绪",
        "反义干扰：明显错的情感（喜 vs 怒）",
        "无关干扰：与情境完全脱节"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_qimo_quanzhen_001.json#28 (《记忆里的香甜》心情：恨)",
        "realpaper_g6_chinese_bubian_qimo_quanzhen_001.json#30 (《记忆里的香甜》语气：愤怒)",
        "realpaper_g6_chinese_bubian_qizhong_002.json#36 (女儿欢喜原因：孝心)"
      ],
      "ai_template": "选短文片段含明显情绪词 → 出 N 题 4 选项 → 答案 = 原文直接对应",
      "material_type": "短文 + 情绪选项",
      "material_excerpt": "「外公突然大喝一声『快回来！』」→ 应读愤怒语气",
      "common_pitfalls": [
        "Famin 反馈：心情/语气类阅读题应是 R1-R2，被高估为 R3 时需 D2 降档",
        "干扰情绪要与原文气氛相关（不能完全脱节）"
      ]
    },
    {
      "pattern_id": "reading_inference_reason",
      "pattern_name": "阅读·原因/推断·选择",
      "kp": "阅读理解/阅读理解",
      "chapter": "阅读理解",
      "typical_form": "「邻居阿姨找上门的原因？」/「桃花开得晚的原因？」4 选项给 4 个候选原因",
      "rounds_seen": [
        1,
        2
      ],
      "r1_features": "原因在原文有显式表述，4 选项 1 项命中",
      "r2_features": "需结合上下文推断（如海拔高 → 气温低 → 花期延后），跨段衔接",
      "r3_features": "（数据中未见 - Famin 反馈类似不升 R3）",
      "r4_features": "（数据中未见）",
      "distractor_design": [
        "正确：原文明确支持",
        "干扰：偷换概念（「我打了她家孩子」vs「带孩子雨中玩耍」）",
        "干扰：扩大范围（「家长不愿离开」vs「父亲坚决不离开」）",
        "干扰：偏题（「母亲心情不好」）"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_qimo_quanzhen_001.json#27 (海拔→气温低→花期晚)",
        "realpaper_g6_chinese_bubian_qimo_quanzhen_001.json#29 (院子有色彩 → 槐花)",
        "realpaper_g6_chinese_bubian_qimo_quanzhen_001.json#31 (邻居找上门 → 雨中玩耍)"
      ],
      "ai_template": "选短文中含因果链段落 → 出 N 题 4 选项 → 1 正确 + 3 偏题/扩大/偷换",
      "material_type": "短文片段 + 4 原因选项",
      "material_excerpt": "邻居阿姨找上门的原因？→ 雨中玩耍导致发烧",
      "common_pitfalls": [
        "因果推断要明确是直接原因还是远因，避免歧义",
        "Famin 反馈：直接复述型容易被高估，需 D2 校准"
      ]
    },
    {
      "pattern_id": "reading_main_idea_summarize",
      "pattern_name": "阅读·段意/主旨概括·选择",
      "kp": "阅读理解/阅读理解",
      "chapter": "阅读理解",
      "typical_form": "「概括下面这段话的大意」/「这一过程指什么」4 选项给 4 个候选概括",
      "rounds_seen": [
        2,
        3
      ],
      "r1_features": "（数据中未见 - 段意题最低 R2）",
      "r2_features": "（Famin 锚点 chinese_r3_anchor_2 反馈）：段意综合概括，3 个干扰项是「部分对」陷阱（只复述背景/偷换概念/偏题）",
      "r3_features": "全文主旨升华（如《走出心灵的监狱》→「舍弃悲痛与怨恨」），需透过事件层识别作者写作意图",
      "r4_features": "选项嵌套包含（A⊂B⊂D），需正向算才能排除「漏一半」 - 但 Famin 反馈「三短一长选最长」可降档",
      "distractor_design": [
        "选项 A：只复述背景一面（部分对）",
        "选项 B：综合概括（正确）",
        "选项 C：偷换概念（如「父亲」→「家人」）",
        "选项 D：偏题（如「母亲心情」）"
      ],
      "real_examples": [
        "realpaper_g6_chinese_bubian_qimo_quanzhen_001.json#9 (父亲坚决不离开北京)",
        "realpaper_g6_chinese_bubian_d2_kp1_001.json#47 (《走出心灵的监狱》主旨)",
        "realpaper_g6_chinese_bubian_qizhong_002.json#33 (「这一过程」嵌套指代)",
        "realpaper_g6_chinese_bubian_qizhong_002.json#34 (《向日葵》文题含义)"
      ],
      "ai_template": "选短文段落含明显主题句 → 出 4 选项 1 综合概括 + 3 部分对 → 答案 = 综合",
      "material_type": "段落或全文 + 概括选项",
      "material_excerpt": "局势严重，父亲坚决不离开北京（综合）vs 局势越来越严重（只背景）vs 父亲担心家人（偷换）",
      "common_pitfalls": [
        "Famin 锚点反馈（chinese_r3_anchor_2 段意 R2）：除非真有嵌套包含或文化升华否则不升 R3",
        "「三短一长选最长」自动指向最综合选项 → 选项无真迷惑性时降档"
      ]
    }
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
