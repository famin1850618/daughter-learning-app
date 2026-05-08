# 锚点题审核（Famin 用）

> **如何标注：** 默认 `round_famin` 留空 = 同意 agent 的档；不同意填新档 + `comment`
> 
> 完成后告诉我"锚点审核做完了"，我跑脚本提取反馈写入 calibration_log。

---

## 数学（共 20 道）

| ID | agent档 | KP | 题面 | round_famin | comment |
|----|--------|-----|------|-------------|---------|
| `math_r1_anchor_1` | **R1** | 圆柱与圆锥/圆柱的表面积 | 做一个无盖的圆柱形水桶，求至少需要多少铁皮，就是求水桶的( )。 → A. 底面积 / B. 侧面积 / C. 侧面积＋两个底面积 / D. 侧面积＋… 答:D | | |
| `math_r1_anchor_2` | **R1** | 总复习/统计与可能性 | 要统计学校各社团人数，应绘制( )统计图。 → A. 折线 / B. 扇形 / C. 条形 / D. 都可以 答:C | | |
| `math_r1_anchor_3` | **R1** | 比和比例/比的意义 | 把 2 千克盐加入 15 千克水中，盐与盐水的质量比是( )。 → A. 2∶15 / B. 15∶17 / C. 2∶17 答:C | | |
| `math_r1_anchor_4` | **R1** | 正反比例/正比例的意义 | 成正比例的两个量在变化时的规律是它们的( )不变。 → A. 和 / B. 差 / C. 积 / D. 比值 答:D | | |
| `math_r1_anchor_5` | **R1** | 正反比例/比例尺 | 在比例尺是 1∶1000000 的地图上，图上距离 5 cm 表示实际距离( )km。 答:50 | | |
| `math_r2_anchor_1` | **R2** | 圆柱与圆锥/圆柱的表面积 | 一个圆柱的底面半径是 5 dm，若高增加 2 dm，则侧面积增加( )dm²。（$\pi$取3.14… → A. 10 / B. 20 / C. 31.4 / D. 62.8 答:D | | |
| `math_r2_anchor_2` | **R2** | 圆柱与圆锥/圆柱的表面积 | 制作一个底面直径是 10 cm、长 4 m 的通风管，至少需要( )m² 的铁皮。（通风管两端无底面… → A. 1.256 / B. 12.56 / C. 125.6 / D. 1256 答:A | | |
| `math_r2_anchor_3` | **R2** | 正反比例/比例尺 | 一种长 4 mm 的精密零件在图纸上长 8 cm，这张图纸的比例尺是( )。 → A. 1∶2 / B. 1∶20 / C. 20∶1 答:C | | |
| `math_r2_anchor_4` | **R2** | 圆柱与圆锥/圆柱的体积 | 把一个棱长是 4 分米的正方体木块削成一个最大的圆柱，圆柱的体积是( )立方分米。 → A. 50.24 / B. 100.48 / C. 64 答:A | | |
| `math_r2_anchor_5` | **R2** | 正反比例/反比例的意义 | 乐乐把 1000 mL 水倒入不同的圆柱形容器中，容器中水的高度与容器的底面积( )。 → A. 成正比例 / B. 成反比例 / C. 不成比例 / D. 无法判断 答:B | | |
| `math_r3_anchor_1` | **R3** | 圆柱与圆锥/圆柱的表面积 | 一个圆柱的高为 8 cm，如果把它的高截掉 2 cm，表面积就会减少 12.56 cm²。它的体积是多少 cm³？ 答:25.12 | | |
| `math_r3_anchor_2` | **R3** | 圆柱与圆锥/圆柱的表面积 | 把一个底面直径是 4 厘米、高 8 厘米的圆柱沿底面直径竖直切割成两个半圆柱，表面积一共增加了( )平方厘米。 答:64 | | |
| `math_r3_anchor_3` | **R3** | 圆柱与圆锥/圆柱圆锥综合应用 | 一个长方体、一个圆柱和一个圆锥的底面积和体积分别相等。如果长方体的高是 9 厘米，那么圆柱的高是( )厘米，圆锥的高是(… 答:9,27 | | |
| `math_r3_anchor_4` | **R3** | 比和比例/比的意义 | 在比例尺是 1∶5000000 的地图上，量得 A、B 两地的距离是 6 cm。甲、乙两车同时从 A、B 两地相向开出，… 答:60 | | |
| `math_r3_anchor_5` | **R3** | 总复习/数与代数综合 | 用棱长是 1 cm 的小正方体，依次摆出长方体（1$\times$1$\times$n 形状）。由 2 个小正方体摆出的… 答:402 | | |
| `math_r4_anchor_1` | **R4** | 圆柱与圆锥/圆柱圆锥综合应用 | 一个圆柱和一个圆锥，底面周长的比是 2∶3，它们的高的比是 9∶5。圆锥和圆柱体积的最简整数比是( … → A. 8∶5 / B. 12∶5 / C. 5∶12 / D. 5∶8 答:C | | |
| `math_r4_anchor_2` | **R4** | 总复习/解决问题策略 | A、B 两个仓库存化肥的质量比是 12:11，后来 B 仓库又运进 24 吨，这时 A 仓库存化肥比 B 仓库少 1/9… 答:105.6 | | |
| `math_r4_anchor_3` | **R4** | 总复习/数与代数综合 | 简便计算：20.18 $\times$ 1996 － 19.95 $\times$ 2018，结果是( )。 答:20.18 | | |
| `math_r4_anchor_4` | **R4** | 比和比例/比的意义 | 客车和货车同时从甲、乙两地的中点处向相反方向行驶，3 时后，客车到达甲地，货车离乙地还有 42 千米。已知货车和客车的速… 答:294 | | |
| `math_r4_anchor_5` | **R4** | 圆柱与圆锥/圆锥的体积 | 一个圆锥形土堆，底面直径是 6 m，高是 2.5 m。用一辆载重 6 t 的汽车去运，每立方米土约重 1.5 t，几次可… 答:6 | | |

## 语文（共 20 道）

| ID | agent档 | KP | 题面 | round_famin | comment |
|----|--------|-----|------|-------------|---------|
| `chinese_r1_anchor_1` | **R1** | 古诗文/古诗词背诵默写 | 默写：「少壮不努力，________」（出自汉乐府《长歌行》）。横线处应填的诗句是？ 答:老大徒伤悲 | | |
| `chinese_r1_anchor_2` | **R1** | 文学常识/外国作家作品 | 《汤姆·索亚历险记》是（ ）国作家的代表作品。 答:美 | | |
| `chinese_r1_anchor_3` | **R1** | 字词/字音 | 「薄」字加点的字（薄雾）正确读音是（ ）。 → A. bó / B. báo 答:A | | |
| `chinese_r1_anchor_4` | **R1** | 文学常识/外国作家作品 | 《鲁滨逊漂流记》的作者是（ ）。 → A. 丹尼尔·笛福 / B. 刘易斯·卡罗尔 / C. 塞尔玛·拉格洛芙 / D… 答:A | | |
| `chinese_r1_anchor_5` | **R1** | 修辞/反问 | 「世界上还有几个剧种一部戏可以演出三五天还没有结束的呢？」这句话运用了哪种修辞手法？ → A. 夸张 / B. 比喻 / C. 设问 / D. 反问 答:D | | |
| `chinese_r2_anchor_1` | **R2** | 字词/成语运用 | 选择合适的成语填空：比喻老师教育的学生众多、各地都有的成语是「（ ）」（填 5 字成语）。 答:桃李满天下 | | |
| `chinese_r2_anchor_2` | **R2** | 字词/词语理解 | 选词填空（严肃／严格／严厉／严峻）：我们必须（ ）地面对当前的形势。横线处应填的词语是？ 答:严肃 | | |
| `chinese_r2_anchor_3` | **R2** | 句式与标点/病句修改 | 下列句子中，有语病的一项是？ → A. 在逃去如飞的日子里，在千门万户的世界里的我能做什么呢？ / B. 灯一悬起… 答:C | | |
| `chinese_r2_anchor_4` | **R2** | 句式与标点/句式转换 | 把直接引语「『这是我的妻子。』他指着母亲说。」改为转述句，正确的是？ → A. 那是他的妻子，他指着母亲说。 / B. 这是我的妻子，他指着母亲说。 / … 答:A | | |
| `chinese_r2_anchor_5` | **R2** | 句式与标点/标点符号 | 下列四个句子中，标点符号使用正确的是？ → A. 腊月二十三过小年，差不多就是过春节的彩排。 / B. 张思德同志是为人民利… 答:B | | |
| `chinese_r3_anchor_1` | **R3** ⚠️[审] | 课文与名著/课文内容理解 | 《两小儿辩日》中「孔子不能决也」反映出孔子对知识持怎样的态度？ → A. 不懂装懂 / B. 实事求是 / C. 妄自尊大 / D. 漠不关心 答:B | | |
| `chinese_r3_anchor_2` | **R3** ⚠️[审] | 阅读理解/阅读理解 | 概括下面这段话的大意，最恰当的一句是？ 局势越来越严重，父亲的工作也越来越紧张。他的朋友劝他离开北京… → A. 局势越来越严重，父亲的工作也越来越紧张。 / B. 在局势严重时，父亲坚决… 答:B | | |
| `chinese_r3_anchor_3` | **R3** ⚠️[审] | 现代文阅读/主旨概括 | 《走出心灵的监狱》一文最能说明作者写作目的的一项是（ ）。 → A. 谴责白人统治者对年事已高的曼德拉进行残酷的虐待。 / B. 赞扬曼德拉在就… 答:D | | |
| `chinese_r3_anchor_4` | **R3** | 阅读理解/阅读理解 | 阅读《人类能在地球上生活多久》：文中画波浪线的句子「人类面临的真正威胁，却是来自人类自身」中「来自人… → A. 人类对大自然的破坏 / B. 人类不懂得保护水资源 / C. 人类的总人口… 答:D | | |
| `chinese_r3_anchor_5` | **R3** ⚠️[审] | 文学常识/文化常识 | 下列说法不正确的一项是？ → A. 《学弈》通过两个人跟从同一个老师学下棋因学习态度大不相同导致最终结果也不同… 答:D | | |
| `chinese_r4_anchor_1` | **R4** ⚠️[审] | 现代文阅读/词句赏析 | 沈从文《端午日》文中加点的三个「莫不」的作用：从程度上渲染观看龙舟竞赛的人之( )，涉及面之( )，具体写出了「全茶峒人… 答:多,广,盛况 | | |
| `chinese_r4_anchor_2` | **R4** ⚠️[审] | 阅读理解/阅读理解 | 阅读《人类能在地球上生活多久》：「这一过程还将至少持续 40 亿年」中「这一过程」指什么？ → A. 太阳将持续而稳定地向地球提供光和热。 / B. 太阳将持续而稳定地向地球提… 答:B | | |
| `chinese_r4_anchor_3` | **R4** ⚠️[审] | 阅读理解/阅读理解 | 阅读《向日葵》：对「我」情感态度变化（ ）→ 冷淡心痛 →（ ）→（ ）的概括，正确的一项是？ → A. 生气抱怨／惊讶诧异／高兴感动 / B. 生气抱怨／惴惴不安／高兴感动 / … 答:A | | |
| `chinese_r4_anchor_4` | **R4** ⚠️[审] | 修辞/对偶 | 下列诗句中，具有对仗工整特点的一项是？ → A. 春城无处不飞花，寒食东风御柳斜。 / B. 千锤万凿出深山，烈火焚烧若等闲… 答:C | | |
| `chinese_r4_anchor_5` | **R4** ⚠️[审] | 阅读理解/阅读理解 | 《买馒头》中，将文末「但不论如何，生活的本身是值得庆喜的吧！」插入原文，最恰当的位置是？ → A. ⑩⑪段之间 / B. ⑪⑫段之间 / C. ⑫⑬段之间 / D. ⑬⑭段之… 答:C | | |

## 英语（共 20 道）

| ID | agent档 | KP | 题面 | round_famin | comment |
|----|--------|-----|------|-------------|---------|
| `english_r1_anchor_1` | **R1** | Vocabulary/Family & Relationships | She is my mother's sister, so she is my ____. → A. uncle / B. aunt / C. cousin / D. niec… 答:B | | |
| `english_r1_anchor_2` | **R1** | Grammar/Past Simple | I ____ my grandmother yesterday. → A. visit / B. visits / C. visiting / D. … 答:D | | |
| `english_r1_anchor_3` | **R1** | Grammar/Present Perfect (basic) | I ____ already finished my homework. → A. has / B. have / C. had / D. having 答:B | | |
| `english_r1_anchor_4` | **R1** | Reading/Scanning for detail | My summer holiday in Beijing Last summer, I went t… → A. Last winter / B. Last spring / C. Las… 答:C | | |
| `english_r1_anchor_5` | **R1** | Listening/Listening for gist | Listen and choose the correct answer. What is the … → A. Their weekend plans / B. A new movie … 答:A | | |
| `english_r2_anchor_1` | **R2** | Grammar/Past Continuous | Mary ____ to music while she did her homework. → A. listens / B. listened / C. is listeni… 答:D | | |
| `english_r2_anchor_2` | **R2** | Grammar/Modals (can/could/should/might/must) | I'm not sure, but she ____ be at home now. → A. must / B. might / C. should / D. can 答:B | | |
| `english_r2_anchor_3` | **R2** | Grammar/Comparatives & Superlatives | This box is ____ than that one. → A. heavy / B. heaviest / C. heavier / D.… 答:C | | |
| `english_r2_anchor_4` | **R2** | Grammar/Conditionals 0 & 1 | If you press this button, the door ____ . → A. open / B. opens / C. opened / D. will… 答:B | | |
| `english_r2_anchor_5` | **R2** | Listening/Listening for detail | Listen and choose the correct answer. What is the … → A. Bella / B. Coco / C. Max / D. Luna 答:B | | |
| `english_r3_anchor_1` | **R3** | Reading/Inferring meaning from context | Mary lost her keys this morning, so she could not … → A. paint / B. open / C. clean / D. count 答:B | | |
| `english_r3_anchor_2` | **R3** | Reading/Skimming for gist | Question 5: What is the main message of the last p… → A. The shop is open at certain times and… 答:A | | |
| `english_r3_anchor_3` | **R3** | 句型/一般疑问句 | Make a yes/no question of: 'They went to the park … → A. Do they go to the park yesterday? / B… 答:C | | |
| `english_r3_anchor_4` | **R3** | 句型/否定句转换 | Make negative: 'There were some apples on the tabl… → A. There weren't any apples on the table… 答:A | | |
| `english_r3_anchor_5` | **R3** | Listening/Listening for gist | Listen and choose the correct answer. What is the … → A. To invite his friend to a party / B. … 答:A | | |
| `english_r4_anchor_1` | **R4** | 阅读理解/阅读理解 | Reading Passage 1: My name is Tom and I am twelve … → A. Tom's mother / B. Aunt Mary / C. Uncl… 答:B | | |
| `english_r4_anchor_2` | **R4** | Listening/Listening for gist | Listen and choose the correct answer. What is the … → A. She does not like it / B. She loves i… 答:A | | |
| `english_r4_anchor_3` | **R4** | 阅读理解/阅读理解 | Reading Passage 2: The giant panda is one of the m… → A. Sichuan / B. Shaanxi / C. Gansu / D. … 答:D | | |
| `english_r4_anchor_4` | **R4** | 阅读理解/阅读理解 | Reading Passage 3: Lucy is a sixth-grade student a… → A. Her mother asks her to. / B. She want… 答:B | | |
| `english_r4_anchor_5` | **R4** | 句型/否定句转换 | Choose the WRONG negative sentence. → A. He doesn't like fish. / B. They aren'… 答:C | | |
