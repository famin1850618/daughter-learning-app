# 锚点题审核 — 英语（共 20 道）

> **如何标注**（每道题最后一段）：
> - **同意** agent 的档 → 不动，整段留空
> - **不同意** → 把 `[ ] 同意` 那行 X 在另一档（如 `[X] R2`），加一句 comment
> - **拿不准** → `[X] ?` + comment 写为啥拿不准
>
> 完成后告诉我"语文/数学/英语 锚点审核做完了"，我跑脚本提取写入 calibration_log。

## R1（5 道）

### `english_r1_anchor_1`

**KP**: `Vocabulary/Family & Relationships`  |  **chapter**: `Vocabulary`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_pet_r1.json#0`

**题面：**

> She is my mother's sister, so she is my ____.

**选项：**

- A. uncle
- B. aunt
- C. cousin
- D. niece

**答案：** `B`

**解析：** Mother's sister = aunt. Uncle is male, niece is the daughter of a sibling, cousin is a child of an aunt or uncle.

**Agent 4 维 reasoning（agent 评 R1）：**

> R1 因为：语言层级 1（单词形式直接对应家庭关系），陷阱密度 0.25（uncle 是性别错明显，cousin/niece 是不同关系等级——只有一个近义概念），KP 跨度 1（仅 family vocabulary），数据复杂度 0.2（10 词短句、CEFR A1 词汇、无听力）。

**Breakdown**: `step_count=1 / distractor_density=0.25 / kp_span=1 / data_complexity=0.2`

**Famin 你的判断：**

- [ ] 同意 R1
- [ ] 实际是 R2
- [ ] 实际是 R3
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

### `english_r1_anchor_2`

**KP**: `Grammar/Past Simple`  |  **chapter**: `Grammar`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_pet_r1.json#80`

**题面：**

> I ____ my grandmother yesterday.

**选项：**

- A. visit
- B. visits
- C. visiting
- D. visited

**答案：** `D`

**解析：** 'Yesterday' signals Past Simple; regular verb takes -ed. 'Visit' is base; 'visits' is Simple Present; 'visiting' is -ing.

**Agent 4 维 reasoning（agent 评 R1）：**

> R1 因为：语言层级 1（看 yesterday 直接选 -ed 词形），陷阱密度 0.25（4 选项是 visit/visits/visiting/visited 的纯词形变化，错答明显错），KP 跨度 1（仅一般过去时词尾），数据复杂度 0.15（5 词短句、A1 词汇、无听力）。

**Breakdown**: `step_count=1 / distractor_density=0.25 / kp_span=1 / data_complexity=0.15`

**Famin 你的判断：**

- [ ] 同意 R1
- [ ] 实际是 R2
- [ ] 实际是 R3
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

### `english_r1_anchor_3`

**KP**: `Grammar/Present Perfect (basic)`  |  **chapter**: `Grammar`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_pet_r1.json#100`

**题面：**

> I ____ already finished my homework.

**选项：**

- A. has
- B. have
- C. had
- D. having

**答案：** `B`

**解析：** 'Already' is a Present Perfect marker; 'I' takes 'have' + past participle. 'Has' is for he/she/it; 'had' is Past Perfect; 'having' is -ing.

**Agent 4 维 reasoning（agent 评 R1）：**

> R1 因为：语言层级 1（直接选助动词形式），陷阱密度 0.3（has/have 是人称错配，having 明显错），KP 跨度 1（基础现在完成时），数据复杂度 0.2（6 词、A1 词汇、无听力）。

**Breakdown**: `step_count=1 / distractor_density=0.3 / kp_span=1 / data_complexity=0.2`

**Famin 你的判断：**

- [ ] 同意 R1
- [ ] 实际是 R2
- [ ] 实际是 R3
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

### `english_r1_anchor_4`

**KP**: `Reading/Scanning for detail`  |  **chapter**: `Reading`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_pet_r1.json#150`

**题面：**

> My summer holiday in Beijing

Last summer, I went to Beijing with my mother and father. We took a fast train from Shanghai on the first of July. The trip was about five hours long. We stayed at a small hotel near the city centre for ten days.

On our first day, we visited the Forbidden City. It was very big and very hot, so we drank a lot of water. The next morning, we walked on the Great Wall. My father took more than one hundred photos of me.

My favourite day was Friday. We went to a quiet park and watched old people doing tai chi. Then we ate Beijing duck for dinner. The price was 198 yuan, but my mother said it was very tasty.

We came home on the eleventh of July. I want to go back to Beijing next year because the food and the people are wonderful.

Question 1: When did the writer go to Beijing?

**选项：**

- A. Last winter
- B. Last spring
- C. Last summer
- D. Last autumn

**答案：** `C`

**解析：** The first sentence says 'Last summer, I went to Beijing with my mother and father.'

**Agent 4 维 reasoning（agent 评 R1）：**

> R1 因为：语言层级 1（首句关键词原文匹配），陷阱密度 0.0（4 个季节中只有 1 个对，其他 3 个文中完全未出现），KP 跨度 1（纯 scanning 抓显性时间状语），数据复杂度 0.5（约 130 词中等长度文章但题目本身定位极易、A2 词汇）。

**Breakdown**: `step_count=1 / distractor_density=0.0 / kp_span=1 / data_complexity=0.5`

**Famin 你的判断：**

- [ ] 同意 R1
- [ ] 实际是 R2
- [ ] 实际是 R3
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

### `english_r1_anchor_5`

**KP**: `Listening/Listening for gist`  |  **chapter**: `Listening`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_pet_r1.json#180`

**题面：**

> Listen and choose the correct answer.

What is the conversation mainly about?

**听力原文（audio_text）：**

```
A: So, what are you doing this weekend?
B: I think I will go to the beach on Saturday with my sister. The weather is going to be sunny and warm.
A: That sounds nice. On Sunday, my family is having a small picnic in the park. Would you like to come?
B: Yes, I would love to. I will bring some sandwiches and orange juice.
A: Great, see you on Sunday at noon.
```

**Speakers**: `{"A": {"gender": "female", "age": "child"}, "B": {"gender": "male", "age": "child"}}`

**选项：**

- A. Their weekend plans
- B. A new movie
- C. A school exam
- D. A birthday gift

**答案：** `A`

**解析：** The speakers discuss going to the beach on Saturday and a picnic on Sunday, so the topic is weekend plans. The other options are not mentioned.

**Agent 4 维 reasoning（agent 评 R1）：**

> R1 因为：语言层级 2（听短对话抓主旨需理解 1 层句型），陷阱密度 0.25（其余 3 个选项在对话中完全无相关词，唯独 weekend plans 直接命中 Saturday/Sunday 关键词），KP 跨度 1（gist 单一技能），数据复杂度 0.45（5 turn 对话、2 speakers child voice、A2 词汇）。听力锚点：单话题、词面提示明显，是 R1 听力 baseline。

**Breakdown**: `step_count=2 / distractor_density=0.25 / kp_span=1 / data_complexity=0.45`

**Famin 你的判断：**

- [ ] 同意 R1
- [ ] 实际是 R2
- [ ] 实际是 R3
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

## R2（5 道）

### `english_r2_anchor_1`

**KP**: `Grammar/Past Continuous`  |  **chapter**: `Grammar`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_pet_r1.json#99`

**题面：**

> Mary ____ to music while she did her homework.

**选项：**

- A. listens
- B. listened
- C. is listening
- D. was listening

**答案：** `D`

**解析：** Past Continuous shows a parallel ongoing past activity. The other options do not fit a past background context.

**Agent 4 维 reasoning（agent 评 R2）：**

> R2 因为：语言层级 2（句型转换：while 引出过去背景动作要 was+ing），陷阱密度 0.5（4 选项中 listened 是过去式很有迷惑——孩子可能选过去一般时；is listening 是现在进行时），KP 跨度 2（一般过去时 vs 过去进行时对比），数据复杂度 0.35（9 词单句、A2 词汇）。

**Breakdown**: `step_count=2 / distractor_density=0.5 / kp_span=2 / data_complexity=0.35`

**Famin 你的判断：**

- [ ] 同意 R2
- [ ] 实际是 R1
- [ ] 实际是 R3
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

### `english_r2_anchor_2`

**KP**: `Grammar/Modals (can/could/should/might/must)`  |  **chapter**: `Grammar`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_pet_r1.json#129`

**题面：**

> I'm not sure, but she ____ be at home now.

**选项：**

- A. must
- B. might
- C. should
- D. can

**答案：** `B`

**解析：** 'Might' shows uncertain possibility. 'Must' = strong certainty; 'should' = expectation; 'can' = ability — only 'might' fits 'not sure'.

**Agent 4 维 reasoning（agent 评 R2）：**

> R2 因为：语言层级 2（要识别 'not sure' 与情态动词的语义对应），陷阱密度 0.6（must/should/can 都语法对但语义偏差，must 是 R3 才能精确排除的强反义陷阱），KP 跨度 1（情态动词单一 KP 但需 4 个细分语义对比），数据复杂度 0.3（10 词、A2 词汇）。

**Breakdown**: `step_count=2 / distractor_density=0.6 / kp_span=1 / data_complexity=0.3`

**Famin 你的判断：**

- [ ] 同意 R2
- [ ] 实际是 R1
- [ ] 实际是 R3
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

### `english_r2_anchor_3`

**KP**: `Grammar/Comparatives & Superlatives`  |  **chapter**: `Grammar`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_pet_r1.json#139`

**题面：**

> This box is ____ than that one.

**选项：**

- A. heavy
- B. heaviest
- C. heavier
- D. more heavy

**答案：** `C`

**解析：** Adjectives ending in consonant + y change y to i and add -er: heavier. 'Heavy' is base; 'heaviest' is superlative; 'more heavy' is incorrect.

**Agent 4 维 reasoning（agent 评 R2）：**

> R2 因为：语言层级 2（变形规则：辅音+y 改 i 加 er，比简单加 er 多 1 步），陷阱密度 0.5（heaviest 是最高级形式陷阱、more heavy 是合规则的 'more+adj' 但对 heavy 不适用），KP 跨度 2（比较级形式 + 不规则变化），数据复杂度 0.2（8 词、A1 词汇）。

**Breakdown**: `step_count=2 / distractor_density=0.5 / kp_span=2 / data_complexity=0.2`

**Famin 你的判断：**

- [ ] 同意 R2
- [ ] 实际是 R1
- [ ] 实际是 R3
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

### `english_r2_anchor_4`

**KP**: `Grammar/Conditionals 0 & 1`  |  **chapter**: `Grammar`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_pet_r1.json#149`

**题面：**

> If you press this button, the door ____ .

**选项：**

- A. open
- B. opens
- C. opened
- D. will opening

**答案：** `B`

**解析：** Zero conditional describes general results; both clauses use Present Simple, third-person singular 'door' takes -s. The others break the rule.

**Agent 4 维 reasoning（agent 评 R2）：**

> R2 因为：语言层级 2（条件句 0 型：两边都用一般现在时；'door' 第三人称单数加 s），陷阱密度 0.5（will opening 明显错，但 open vs opens 是人称数陷阱、opened 是过去时陷阱），KP 跨度 2（零条件句结构 + 第三人称单数变形），数据复杂度 0.3（9 词、A2 词汇）。

**Breakdown**: `step_count=2 / distractor_density=0.5 / kp_span=2 / data_complexity=0.3`

**Famin 你的判断：**

- [ ] 同意 R2
- [ ] 实际是 R1
- [ ] 实际是 R3
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

### `english_r2_anchor_5`

**KP**: `Listening/Listening for detail`  |  **chapter**: `Listening`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_pet_r1.json#198`

**题面：**

> Listen and choose the correct answer.

What is the name of the girl's pet?

**听力原文（audio_text）：**

```
A: Do you have a pet, Mia?
B: Yes, I have a small white cat. Her name is Coco.
A: That is a sweet name. How old is she?
B: She is two years old. My friend Anna also has a cat called Bella, and my cousin has a dog named Max.
A: And Luna?
B: Oh, Luna is my neighbour's rabbit. But my own pet is just Coco.
A: She must be lovely.
B: Yes, Coco is the best cat in the world.
```

**Speakers**: `{"A": {"gender": "female", "age": "child"}, "B": {"gender": "female", "age": "child"}}`

**选项：**

- A. Bella
- B. Coco
- C. Max
- D. Luna

**答案：** `B`

**解析：** The girl says her cat's name is Coco. Bella, Max, and Luna are her friends' pets.

**Agent 4 维 reasoning（agent 评 R2）：**

> R2 因为：语言层级 2（细节抓取需排除 4 个名字干扰），陷阱密度 0.75（4 个名字全部出现在录音中，必须全程跟踪 'her name'/'my own pet' 才能排除朋友/邻居的宠物），KP 跨度 1（listening detail），数据复杂度 0.55（8 turns 较长对话、2 speakers child、A2 词汇）。听力锚点：多干扰名字、'但是'转折句决定答案——是典型 R2 多陷阱听力。

**Breakdown**: `step_count=2 / distractor_density=0.75 / kp_span=1 / data_complexity=0.55`

**Famin 你的判断：**

- [ ] 同意 R2
- [ ] 实际是 R1
- [ ] 实际是 R3
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

## R3（5 道）

### `english_r3_anchor_1`

**KP**: `Reading/Inferring meaning from context`  |  **chapter**: `Reading`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_pet_r1.json#168`

**题面：**

> Mary lost her keys this morning, so she could not ______ the door of her flat.

What is the best word for the blank?

**选项：**

- A. paint
- B. open
- C. clean
- D. count

**答案：** `B`

**解析：** Without keys, you cannot open the door, so 'open' fits the context best.

**Agent 4 维 reasoning（agent 评 R3）：**

> R3 因为：语言层级 3（语境推断：从'丢了钥匙'隐含'打不开'的因果链），陷阱密度 0.5（paint/clean/count 都是常见可对'door'操作的动词，但只有 open 与 keys 因果对应——孩子若忽略 'lost keys' 易选 paint/clean），KP 跨度 2（词义辨析 + 因果推断），数据复杂度 0.4（17 词复合句、A2 词汇）。

**Breakdown**: `step_count=3 / distractor_density=0.5 / kp_span=2 / data_complexity=0.4`

**Famin 你的判断：**

- [ ] 同意 R3
- [ ] 实际是 R1
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

### `english_r3_anchor_2`

**KP**: `Reading/Skimming for gist`  |  **chapter**: `Reading`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_pet_r1.json#159`

**题面：**

> Question 5: What is the main message of the last paragraph?

**选项：**

- A. The shop is open at certain times and has plans for children.
- B. The shop will close next month.
- C. Mrs Wang is going to write a new book.
- D. The shop is too small for families.

**答案：** `A`

**解析：** The last paragraph gives the opening hours and announces a free story time for young children every Sunday, so it is about the times and the new plan for children.

**Agent 4 维 reasoning（agent 评 R3）：**

> R3 因为：语言层级 3（段落主旨综合：要把'营业时间'+'儿童计划'两个信息块归纳为一个主旨），陷阱密度 0.6（B/D 看似合理但与原文矛盾、C 是文中提到的人物名做的混淆），KP 跨度 2（skimming 找主旨 + 信息归纳），数据复杂度 0.55（基于约 200 词的整篇 bookshop 文章、A2-B1 词汇）。

**Breakdown**: `step_count=3 / distractor_density=0.6 / kp_span=2 / data_complexity=0.55`

**Famin 你的判断：**

- [ ] 同意 R3
- [ ] 实际是 R1
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

### `english_r3_anchor_3`

**KP**: `句型/一般疑问句`  |  **chapter**: `简单句与句型转换`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_r3.json#108`

**题面：**

> Make a yes/no question of: 'They went to the park yesterday.'

**选项：**

- A. Do they go to the park yesterday?
- B. Did they went to the park yesterday?
- C. Did they go to the park yesterday?
- D. Were they go to the park yesterday?

**答案：** `C`

**解析：** 过去一般疑问：Did + 主语 + 动词原形。

**Agent 4 维 reasoning（agent 评 R3）：**

> R3 因为：语言层级 2（句型转换 1 步），陷阱密度 0.75（B 'Did + 过去式 went' 是孩子最常犯的过去时双重错误，A 时态错但语法形式对，D 用 were 替代 did 是助动词错配——3 个错答都符合中级学习者实际错误模式），KP 跨度 2（一般疑问句结构 + 过去时助动词 + 动词原形规则），数据复杂度 0.3（9 词、A2 词汇）。

**Breakdown**: `step_count=2 / distractor_density=0.75 / kp_span=2 / data_complexity=0.3`

**Famin 你的判断：**

- [ ] 同意 R3
- [ ] 实际是 R1
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

### `english_r3_anchor_4`

**KP**: `句型/否定句转换`  |  **chapter**: `简单句与句型转换`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_r3.json#122`

**题面：**

> Make negative: 'There were some apples on the table.'

**选项：**

- A. There weren't any apples on the table.
- B. There weren't some apples on the table.
- C. There wasn't some apples on the table.
- D. There aren't any apples on the table.

**答案：** `A`

**解析：** 否定句 some → any，weren't 保持复数过去。

**Agent 4 维 reasoning（agent 评 R3）：**

> R3 因为：语言层级 2-3（否定句转换需 2 个同时变化：be 否定 + some→any），陷阱密度 0.75（B 是 some 没改 any 的常见错、C 是 some 没改+主谓一致也错的双错、D 是时态错），KP 跨度 3（there be 句型 + 否定式 + some/any 单复数对应），数据复杂度 0.35（9 词、A1 词汇但语法点密集）。

**Breakdown**: `step_count=3 / distractor_density=0.75 / kp_span=3 / data_complexity=0.35`

**Famin 你的判断：**

- [ ] 同意 R3
- [ ] 实际是 R1
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

### `english_r3_anchor_5`

**KP**: `Listening/Listening for gist`  |  **chapter**: `Listening`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_pet_r1.json#188`

**题面：**

> Listen and choose the correct answer.

What is the boy's main reason for the call?

**听力原文（audio_text）：**

```
A: Hello, is that Daniel?
B: Yes, speaking.
A: Hi Daniel, it is Mark. I am calling to invite you to my birthday party this Saturday.
B: Oh, how nice. What time does it start?
A: It begins at three in the afternoon. We will have cake, games, and music in the garden.
B: Sounds wonderful. I will be there for sure.
A: Great, see you on Saturday. Do not forget to bring your camera.
```

**Speakers**: `{"A": {"gender": "male", "age": "child"}, "B": {"gender": "male", "age": "child"}}`

**选项：**

- A. To invite his friend to a party
- B. To ask about homework
- C. To order a pizza
- D. To book a cinema ticket

**答案：** `A`

**解析：** The boy invites his friend to come to his birthday party on Saturday. Homework, pizza, and cinema are not the reason for the call.

**Agent 4 维 reasoning（agent 评 R3）：**

> R3 因为：语言层级 3（电话场景需理解'I am calling to invite' 这种交际功能短语+排除 cake/games/music 等场景词带来的'pizza'/'cinema' 联想干扰），陷阱密度 0.6（4 选项均是儿童电话常见用途，pizza 是 cake/garden 派对场景的近距离干扰），KP 跨度 2（主旨 + 交际功能识别），数据复杂度 0.6（7 turn 中长对话、2 speakers male child、A2 词汇）。听力锚点：场景词干扰强、交际功能识别——R3 baseline。

**Breakdown**: `step_count=3 / distractor_density=0.6 / kp_span=2 / data_complexity=0.6`

**Famin 你的判断：**

- [ ] 同意 R3
- [ ] 实际是 R1
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

## R4（5 道）

### `english_r4_anchor_1`

**KP**: `阅读理解/阅读理解`  |  **chapter**: `基础阅读理解`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_r3.json#167`

**题面：**

> Reading Passage 1:

My name is Tom and I am twelve years old. I live in a small town with my parents and my sister Lily. Last Saturday was a wonderful day for our family. We got up early and drove to the countryside. The weather was sunny and warm. My father took us to a farm owned by Uncle Bill. There were many animals on the farm: cows, sheep, ducks and chickens. Lily was very excited because she had never seen so many animals before. We helped Uncle Bill feed the chickens and pick fresh apples from the trees. At noon, Aunt Mary cooked a big lunch for us. We had vegetable soup, bread, eggs and apple pie. After lunch, we played football on the green field with Uncle Bill's children. In the afternoon, we went fishing in the small river behind the farm. I caught two fish and Lily caught one. We came back home in the evening, tired but very happy. I will never forget that wonderful day on the farm.

Question 3: Who cooked lunch for Tom's family?

**选项：**

- A. Tom's mother
- B. Aunt Mary
- C. Uncle Bill
- D. Lily

**答案：** `B`

**解析：** 原文 'Aunt Mary cooked a big lunch for us'，需在长篇中定位非主要人物。

**Agent 4 维 reasoning（agent 评 R4）：**

> R4 因为：语言层级 4（长篇阅读+人物定位：6 个家人/亲戚名字穿插全文，要在 ~180 词中精准定位'cook lunch' 的执行者），陷阱密度 0.75（Tom's mother 是默认家庭印象的强陷阱、Uncle Bill 是文中主导人物、Lily 是参与者——3 个错答都是文中实有人物且都干预了那一天的事件），KP 跨度 3（长篇定位 + 多人物追踪 + 'father took us'/'helped Uncle Bill'/'Aunt Mary cooked' 多动作动词分辨），数据复杂度 0.7（180 词长篇、6 人物、多动作时序、B1 词汇）。R4 因长篇人物定位是 PET R4 经典题型，超过 R3 单段 inferring 难度。

**Breakdown**: `step_count=4 / distractor_density=0.75 / kp_span=3 / data_complexity=0.7`

**Famin 你的判断：**

- [ ] 同意 R4
- [ ] 实际是 R1
- [ ] 实际是 R2
- [ ] 实际是 R3
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

### `english_r4_anchor_2`

**KP**: `Listening/Listening for gist`  |  **chapter**: `Listening`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_pet_r1.json#189`

**题面：**

> Listen and choose the correct answer.

What is the woman's attitude toward the weather today?

**听力原文（audio_text）：**

```
A: What a horrible day.
B: I know, it has been raining since this morning.
A: I really do not like rainy days. My shoes are wet and my hair is a mess.
B: Did you bring an umbrella?
A: Yes, but the wind is so strong that the umbrella is almost broken.
B: That is bad luck.
A: I just hate this kind of weather. I hope tomorrow will be sunny so we can go outside again.
```

**Speakers**: `{"A": {"gender": "female", "age": "adult"}, "B": {"gender": "male", "age": "adult"}}`

**选项：**

- A. She does not like it
- B. She loves it
- C. She does not care
- D. She is afraid of it

**答案：** `A`

**解析：** The woman complains about the rain and says she hates it, showing she does not like the weather. The other options do not match her words.

**Agent 4 维 reasoning（agent 评 R4）：**

> R4 因为：语言层级 4（attitude inference：要从'horrible'/'do not like'/'a mess'/'almost broken'/'hate' 多 turn 累积语气得出'不喜欢'，且区分'不喜欢'与'害怕'的强度细微差），陷阱密度 0.85（D 'afraid' 是看到 'wind so strong'/'almost broken' 易误选的强陷阱、C 'does not care' 是'不喜欢'的近义降阶陷阱、B 'loves' 是反向陷阱），KP 跨度 3（多 turn 综合 + 形容词强度辨析 + 态度推断），数据复杂度 0.75（7 turns 长对话、2 adult speakers、B1 词汇 horrible/hate/mess/almost broken）。R4 因 attitude inference 在 PET 中是高阶听力技能。

**Breakdown**: `step_count=4 / distractor_density=0.85 / kp_span=3 / data_complexity=0.75`

**Famin 你的判断：**

- [ ] 同意 R4
- [ ] 实际是 R1
- [ ] 实际是 R2
- [ ] 实际是 R3
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

### `english_r4_anchor_3`

**KP**: `阅读理解/阅读理解`  |  **chapter**: `基础阅读理解`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_r3.json#170`

**题面：**

> Reading Passage 2:

The giant panda is one of the most famous animals in the world. It is also the symbol of China. Pandas live mainly in the bamboo forests of southwest China, especially in Sichuan, Shaanxi and Gansu. A grown-up panda is about 1.5 metres long and weighs about 100 kilograms. It has a round face, black ears and big black eye patches. Its body is white, but its arms and legs are black. Pandas eat bamboo for almost the whole day. They may spend twelve hours a day eating, and they need more than ten kilograms of bamboo to stay healthy. Although pandas look heavy, they can climb trees very well. Sometimes they also eat small animals or fish, but bamboo is their main food. Pandas are an endangered species. There are not many wild pandas left, so the Chinese government and many scientists work hard to protect them. Every year, more and more baby pandas are born in the panda research centres. People around the world love pandas because they are cute, lovely and very friendly.

Question 1: Which province is NOT mentioned as a home of pandas?

**选项：**

- A. Sichuan
- B. Shaanxi
- C. Gansu
- D. Yunnan

**答案：** `D`

**解析：** 原文只列 Sichuan, Shaanxi and Gansu，Yunnan 未提及。'NOT mentioned' 题型需逐一比对。

**Agent 4 维 reasoning（agent 评 R4）：**

> R4 因为：语言层级 4（信息说明文+'NOT mentioned' 反向定位：要把 4 个省名逐一与原文比对，比'选出 mentioned 的'多 1 步反向逻辑），陷阱密度 0.75（4 个都是中国西南省份，孩子按一般地理知识可能误选熊猫确实有的省份），KP 跨度 2（细节定位 + 反向逻辑），数据复杂度 0.75（200 词说明文、专有名词 Sichuan/Shaanxi/Gansu/Yunnan 拼写易混、B1 词汇 endangered/species）。R4 因'NOT 题型' 是 PET 高阶题型，反向比对加重认知负担。

**Breakdown**: `step_count=4 / distractor_density=0.75 / kp_span=2 / data_complexity=0.75`

**Famin 你的判断：**

- [ ] 同意 R4
- [ ] 实际是 R1
- [ ] 实际是 R2
- [ ] 实际是 R3
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

### `english_r4_anchor_4`

**KP**: `阅读理解/阅读理解`  |  **chapter**: `基础阅读理解`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_r3.json#178`

**题面：**

> Reading Passage 3:

Lucy is a sixth-grade student at Sunshine Primary School. Every weekday she gets up at six thirty and has breakfast with her family at seven. Her mother always makes warm milk and bread for her. After breakfast, Lucy walks to school with her best friend Emma. The school is only ten minutes away from her home. Classes start at eight in the morning. Lucy has six classes every day: Chinese, Maths, English, Science, Art and PE. Her favourite subject is English because the teacher tells funny stories and plays games with the students. At noon Lucy has lunch in the school dining hall. The lunch usually has rice, vegetables and meat or fish. After school, Lucy stays at the library to finish her homework. She also borrows books about animals because she wants to be a scientist when she grows up. At five o'clock she goes home and helps her mother in the kitchen. After dinner she practises the piano for half an hour and then reads stories for fun. She goes to bed at nine thirty. Lucy thinks her school life is busy but full of fun.

Question 4: Why does Lucy borrow books about animals?

**选项：**

- A. Her mother asks her to.
- B. She wants to be a scientist.
- C. She wants to be a teacher.
- D. Her teacher tells her to.

**答案：** `B`

**解析：** 原文 'because she wants to be a scientist when she grows up'。需识别 because 引导的因果状语并定位真正动机。

**Agent 4 维 reasoning（agent 评 R4）：**

> R4 因为：语言层级 4（长篇 because 因果定位 + 动机辨析），陷阱密度 0.85（mother/teacher/teaching 都是文中或文化常见的'被动原因'、scientist 是真因——3 个错答全部利用孩子文中读到的人物或职业相关词造混淆），KP 跨度 3（长篇定位 + because 因果识别 + 主语指代'she'/'her' 跨句追踪），数据复杂度 0.7（约 200 词、多职业/科目词汇、B1 词汇）。R4 因主动原因 vs 被动安排的辨析超过纯定位题难度。

**Breakdown**: `step_count=4 / distractor_density=0.85 / kp_span=3 / data_complexity=0.7`

**Famin 你的判断：**

- [ ] 同意 R4
- [ ] 实际是 R1
- [ ] 实际是 R2
- [ ] 实际是 R3
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---

### `english_r4_anchor_5`

**KP**: `句型/否定句转换`  |  **chapter**: `简单句与句型转换`  |  **题型**: `choice`
**来源卷**: `batch_2026_05_07_g6_english_r3.json#120`

**题面：**

> Choose the WRONG negative sentence.

**选项：**

- A. He doesn't like fish.
- B. They aren't at home.
- C. We don't go there last week.
- D. She didn't go to school yesterday.

**答案：** `C`

**解析：** C 含 'last week' 应用过去时 didn't go，'don't go' 是现在时，时态与时间状语冲突。其余三句语法均正确。

**Agent 4 维 reasoning（agent 评 R4）：**

> R4 因为：语言层级 4（找错题 = 反向辨析：4 选项都'看似合理'，要逐句校对时态/助动词/be 动词/主谓一致），陷阱密度 0.85（C 错处仅在 last week 与现在时冲突——隐性错；A/B/D 全对，迷惑性最强），KP 跨度 4（一般现在时否定 + be 否定 + 一般过去时否定 + 时态-状语对应），数据复杂度 0.55（短句 4 个但跨 4 种否定结构、A1-A2 词汇）。R4 因找错题型是 PET 顶级技巧，需要否定结构全谱系熟练度。

**Breakdown**: `step_count=4 / distractor_density=0.85 / kp_span=4 / data_complexity=0.55`

**Famin 你的判断：**

- [ ] 同意 R4
- [ ] 实际是 R1
- [ ] 实际是 R2
- [ ] 实际是 R3
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 

---
