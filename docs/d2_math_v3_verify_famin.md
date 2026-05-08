# 数学 V3 verify 抽样（Famin 用，第 3 轮）

> **背景：** V3 算法 4 改动 + 17 道剧透题已修。本次抽 10 道 verify
>
> **三组：**
> - **A 组（4 道）**：V2→V3 round 变化的题（验 V3 改动起作用）
> - **B 组（3 道）**：V3 仍 high_variance（看是否真该升档）
> - **C 组（3 道）**：剧透修过的题（验修后 round 是否合理）
>
> **标法：** 同意 V3 / 同意 V2 / 同意原档 / 实际 R<N> / 拿不准 + Comment
>
> 完成后告诉我"V3 verify 标完了"。

---

## A 组：V2→V3 变化（验 V3 改动）

### `realpaper_g6_math_beishida_kaodian_guoguan_008.json#10`

**KP**: `总复习/解决问题策略` | **题型**: `choice`
**original**: R2 | **V2**: R3 (high_variance) | **V3**: R2 (confident)

**题面：**

> 某客运列车行驶于北京、济南、南京这 3 个城市之间，火车站应准备(    )种不同的车票。

**选项：**

- A. 3
- B. 4
- C. 6
- D. 8

**答案：** `C`

**解析：** n 个城市需要 n$\times$(n-1) 种车票（往返不同方向）：3$\times$2 = 6 种。

**V3 reasoning：** 5维: step=1(1) mental=0(1) distractor=2(3) calc=0.00(1) kp_span=1(1) | max=2, median=1, flag=confident | anchor=math_r1_anchor_2 (R1)

**V3 5 维**: `step_count=1 / mental_flexibility=0 / distractor_realness=2 / calculation_volume=0.0 / kp_span=1`

**Famin 你的判断：**

- [ ] 同意 V3（实际 R2）
- [ ] 同意 V2（实际 R3）
- [ ] 同意原档（实际 R2）
- [ ] 实际是 R1
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment：**

> 

---

### `realpaper_g6_math_beishida_mokuai_jisuan_001.json#17`

**KP**: `总复习/数与代数综合` | **题型**: `choice`
**original**: R2 | **V2**: R3 (high_variance) | **V3**: R2 (confident)

**题面：**

> 下列分数中，不能化成有限小数的是(    )。

**选项：**

- A. 7/20
- B. 8/25
- C. 7/12
- D. 2/5

**答案：** `C`

**解析：** 最简分数能化成有限小数的条件：分母分解质因数后只含 2 和 5。20=$2^{2}\times$5、25=$5^{2}$、5=5 都满足；12=$2^{2}\times$3 含质因数 3，所以 7/12 不能化成有限小数。

**V3 reasoning：** 5维: step=1(1) mental=0(1) distractor=2(3) calc=0.15(1) kp_span=1(1) | max=2, median=1, flag=confident | anchor=math_r1_anchor_2 (R1)

**V3 5 维**: `step_count=1 / mental_flexibility=0 / distractor_realness=2 / calculation_volume=0.15 / kp_span=1`

**Famin 你的判断：**

- [ ] 同意 V3（实际 R2）
- [ ] 同意 V2（实际 R3）
- [ ] 同意原档（实际 R2）
- [ ] 实际是 R1
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment：**

> 

---

### `realpaper_g6_math_beishida_d2_guoguan_001.json#15`

**KP**: `比和比例/比例的基本性质` | **题型**: `choice`
**original**: R2 | **V2**: R3 (anchor_disagree) | **V3**: R2 (confident)

**题面：**

> 在下面的数中，只有选择(    )，才可以与 4，5，6 组成一个比例。

**选项：**

- A. 8
- B. 10
- C. 7.5
- D. 12

**答案：** `C`

**解析：** 组比例需 a$\times$d = b$\times$c。试 7.5：4$\times$7.5 = 30 = 5$\times$6 ✓，所以 4:5 = 6:7.5。

**V3 reasoning：** 5维: step=2(2) mental=0(1) distractor=2(3) calc=0.30(2) kp_span=1(1) | max=2, median=2, flag=confident | anchor=math_r1_anchor_3 (R1)

**V3 5 维**: `step_count=2 / mental_flexibility=0 / distractor_realness=2 / calculation_volume=0.3 / kp_span=1`

**Famin 你的判断：**

- [ ] 同意 V3（实际 R2）
- [ ] 同意 V2（实际 R3）
- [ ] 同意原档（实际 R2）
- [ ] 实际是 R1
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment：**

> 

---

### `realpaper_g6_math_beishida_shudaishu_001.json#28`

**KP**: `比和比例/化简比` | **题型**: `choice`
**original**: R2 | **V2**: R3 (high_variance) | **V3**: R2 (confident)

**题面：**

> 修一条路，甲队单独修 15 天完成，乙队单独修 12 天完成。甲队的工作效率与乙队的工作效率的最简整数比是(    )。

**选项：**

- A. 15∶12
- B. 12∶15
- C. 5∶4
- D. 4∶5

**答案：** `D`

**解析：** 甲效率 = 1/15，乙效率 = 1/12。1/15∶1/12 = 12∶15 = 4∶5。

**V3 reasoning：** 5维: step=1(1) mental=0(1) distractor=2(3) calc=0.00(1) kp_span=1(1) | max=2, median=1, flag=confident | anchor=math_r1_anchor_3 (R1)

**V3 5 维**: `step_count=1 / mental_flexibility=0 / distractor_realness=2 / calculation_volume=0.0 / kp_span=1`

**Famin 你的判断：**

- [ ] 同意 V3（实际 R2）
- [ ] 同意 V2（实际 R3）
- [ ] 同意原档（实际 R2）
- [ ] 实际是 R1
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment：**

> 

---

## B 组：V3 仍 high_variance（是否真升档）

### `realpaper_g6_math_beishida_xshchu_xian_001.json#9`

**KP**: `正反比例/正比例的意义` | **题型**: `fill`
**original**: R2 | **V2**: R4 (high_variance) | **V3**: R4 (high_variance)

**题面：**

> 一辆汽车在公路上行驶，2 时行驶 200 km，3 时行驶 300 km，4 时行驶 400 km。这辆汽车行驶的时间与路程成(    )比例。照这样计算，该汽车 5.5 时行驶(    ) km。请依次填「正」或「反」、数，用逗号分隔。

**答案：** `正,550`

**解析：** 路程$\div$时间=100（一定），所以时间与路程成正比例。该车每小时行 100 km，5.5 时行 5.5$\times$100=550 km。

**V3 reasoning：** 5维: step=4(4) mental=1(2) distractor=None(None) calc=0.35(2) kp_span=1(1) | max=4, median=2, flag=high_variance | anchor=math_r3_anchor_2 (R3)

**V3 5 维**: `step_count=4 / mental_flexibility=1 / calculation_volume=0.35 / kp_span=1`

**Famin 你的判断：**

- [ ] 同意 V3（实际 R4）
- [ ] 同意原档（实际 R2）
- [ ] 实际是 R1
- [ ] 实际是 R3
- [ ] ? 拿不准

**Comment：**

> 

---

### `realpaper_g6_math_beishida_mokuai_tongji_001.json#23`

**KP**: `总复习/统计与可能性` | **题型**: `choice`
**original**: R3 | **V2**: R3 (high_variance) | **V3**: R3 (high_variance)

**题面：**

> 盒子里有 8 个球，分别标有 2、3、4、5、6、7、8、9。这些球除标的数不同外其他都相同。下面规则中对双方公平的是(    )。

**选项：**

- A. 任意摸一球，摸到质数甲胜，摸到合数乙胜
- B. 任意摸一球，摸到的数小于 5 甲胜，摸到的数大于 5 乙胜
- C. 任意摸一球，摸到 2 的倍数甲胜，摸到 5 的倍数乙胜
- D. 任意摸一球，摸到奇数甲胜，摸到 4 的倍数乙胜

**答案：** `A`

**解析：** 质数：2、3、5、7（4 个），合数：4、6、8、9（4 个），双方各占一半，公平。其余选项概率不等。

**V3 reasoning：** 5维: step=4(4) mental=0(1) distractor=0(1) calc=0.00(1) kp_span=1(1) | max=3, median=1, flag=high_variance | anchor=math_r1_anchor_2 (R1)

**V3 5 维**: `step_count=4 / mental_flexibility=0 / distractor_realness=0 / calculation_volume=0.0 / kp_span=1`

**Famin 你的判断：**

- [ ] 同意 V3（实际 R3）
- [ ] 同意原档（实际 R3）
- [ ] 实际是 R1
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment：**

> 

---

### `realpaper_g6_math_beishida_shudaishu_001.json#3`

**KP**: `总复习/数与代数综合` | **题型**: `fill`
**original**: R2 | **V2**: R4 (high_variance) | **V3**: R4 (high_variance)

**题面：**

> 20 以内既是奇数又是合数的数（9 和 15），它们的最大公因数是(    )，最小公倍数是(    )。请按顺序填两个答案，逗号分隔。

**答案：** `3,45`

**解析：** 9=$3^{2}$，15=3$\times$5。最大公因数=3，最小公倍数=$3^{2}\times$5=45。

**V3 reasoning：** 5维: step=2(2) mental=3(4) distractor=None(None) calc=0.00(1) kp_span=2(2) | max=4, median=2, flag=high_variance | anchor=math_r3_anchor_5 (R4)

**V3 5 维**: `step_count=2 / mental_flexibility=3 / calculation_volume=0.0 / kp_span=2`

**Famin 你的判断：**

- [ ] 同意 V3（实际 R4）
- [ ] 同意原档（实际 R2）
- [ ] 实际是 R1
- [ ] 实际是 R3
- [ ] ? 拿不准

**Comment：**

> 

---

## C 组：剧透修过（验修后 round）

### `realpaper_g6_math_beishida_qimo_002.json#9`

**KP**: `总复习/解决问题策略` | **题型**: `calculation`
**original**: R3 | **V2**: R2 (anchor_disagree) | **V3**: R3 (confident)

🔧 **此题题干剧透已修**（content 改了 example，但 answer/explanation 未变）

**题面：**

> 一块土地，让小华单独平整需要 5 时，让陈老师单独平整需要 3 时。如果两人合作，几时能平整完这块土地？请填分数答案（写成 a/b 或带分数 a又b/c 形式，如「3/4」或「1又3/4」）。

**答案：** `15/8`

**解析：** 两人合作的工作效率＝1/5+1/3＝3/15+5/15＝8/15。合作时间＝1$\div$8/15＝15/8 时（即 1 又 7/8 时）。

**V3 reasoning：** 5维: step=4(4) mental=0(1) distractor=None(None) calc=0.15(1) kp_span=2(2) | max=3, median=2, flag=confident | anchor=math_r4_anchor_2 (R4)

**V3 5 维**: `step_count=4 / mental_flexibility=0 / calculation_volume=0.15 / kp_span=2`

**Famin 你的判断：**

- [ ] 同意 V3（实际 R3）
- [ ] 同意 V2（实际 R2）
- [ ] 同意原档（实际 R3）
- [ ] 实际是 R1
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment：**

> 

---

### `realpaper_g6_math_beishida_xshchu_xian_001.json#27`

**KP**: `总复习/数与代数综合` | **题型**: `calculation`
**original**: R1 | **V2**: R2 (confident) | **V3**: R2 (confident)

🔧 **此题题干剧透已修**（content 改了 example，但 answer/explanation 未变）

**题面：**

> 直接写出得数：3/2 $\div$ 3/5 =(    )。（填分数，如「3/4」）

**答案：** `5/2`

**解析：** 除以一个数等于乘其倒数：3/2$\times$5/3=15/6=5/2。

**V3 reasoning：** 5维: step=2(2) mental=0(1) distractor=None(None) calc=0.15(1) kp_span=2(2) | max=2, median=2, flag=confident | anchor=math_r4_anchor_3 (R2)

**V3 5 维**: `step_count=2 / mental_flexibility=0 / calculation_volume=0.15 / kp_span=2`

**Famin 你的判断：**

- [ ] 同意 V3（实际 R2）
- [ ] 同意原档（实际 R1）
- [ ] 实际是 R3
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment：**

> 

---

### `realpaper_g6_math_beishida_xshchu_shenyang_001.json#32`

**KP**: `比和比例/比的意义` | **题型**: `calculation`
**original**: R3 | **V2**: R4 (confident) | **V3**: R4 (confident)

🔧 **此题题干剧透已修**（content 改了 example，但 answer/explanation 未变）

**题面：**

> 王大爷家的果园有 6400 m²，他准备用 3/8 的地栽苹果树，剩下的地按 2:3 栽梨树和桃树。三种果树的面积分别是多少平方米？请依次填苹果树、梨树、桃树面积，用逗号分隔（如「100,200,300」）。

**答案：** `2400,1600,2400`

**解析：** 苹果树=6400$\times$3/8=2400 m²。剩下=6400-2400=4000 m²。梨树=4000$\times$2/(2+3)=1600 m²，桃树=4000$\times$3/(2+3)=2400 m²。

**V3 reasoning：** 5维: step=4(4) mental=1(2) distractor=None(None) calc=0.65(3) kp_span=2(2) | max=4, median=3, flag=confident | anchor=math_r3_anchor_4 (R3)

**V3 5 维**: `step_count=4 / mental_flexibility=1 / calculation_volume=0.65 / kp_span=2`

**Famin 你的判断：**

- [ ] 同意 V3（实际 R4）
- [ ] 同意原档（实际 R3）
- [ ] 实际是 R1
- [ ] 实际是 R2
- [ ] ? 拿不准

**Comment：**

> 

---
