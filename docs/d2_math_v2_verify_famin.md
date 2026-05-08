# 数学 D2 V2 verify 抽样（Famin 用）

> **背景：** D2 V2 算法重跑后 flag_review 从 163 → 70（-57%），1 档以内对齐 86%。本次抽 10 道 verify V2 输出对 V1 修对没修对。
>
> **两组：**
> - **A 组（5 道）**：V1 flag_review (≥2 档差) → V2 confident。看 V2 是否真的修对了
> - **B 组（5 道）**：V2 自暴露 high_variance（单维拉高 max）。看是否真应升档
>
> **标法：** 同意 V2 / V1 / 原档 / 第三档 / 拿不准 + Comment
>
> 完成告诉我"V2 verify 标完了"。

---

## A 组：V1 flag_review → V2 confident（V2 是否修对了 V1 误判）

### `realpaper_g6_math_beishida_qimo_003.json#39`

**KP**: `比和比例/比的意义` | **题型**: `calculation`
**original**: R3 | **V1**: R1 (flag_review) | **V2**: R4 (confident)

**题面：**

> 甲、乙、丙三位工人共同制作了 2050 个零件。已知甲和乙制作的零件个数比是 5∶3，乙和丙是 4∶3。乙制作了多少个零件？

**答案：** `600`

**解析：** 统一比甲乙丙 = 20:12:9，总份 41；乙 = 2050$\times$12/41 = 600。

**V1 reasoning：** 步骤数 1 (R1); 陷阱密度 N/A; KP跨度 2 (R2); 数据复杂度 0.00 (R1) | 锚点 math_r3_anchor_4 (R3, kp=比和比例/比的意义, type=calculation) | 综合 R1, 原 R3, 降档 2

**V2 reasoning：** 5维: step=4(4) mental=2(3) distractor=None(None) calc=0.20(2) kp_span=1(1) | max=4, median=3, flag=confident | anchor=math_r4_anchor_4 (R4)

**V2 5 维**: `step_count=4 / mental_flexibility=2 / calculation_volume=0.2 / kp_span=1`

**Famin 你的判断：**

- [ ] 同意 V2（实际 R4）
- [ ] 同意 V1（实际 R1）
- [ ] 同意原档（实际 R3）
- [ ] 实际是 R2
- [ ] ? 拿不准

**Comment（说明判断 / 算法该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_zhouce_peiyou_002.json#11`

**KP**: `圆柱与圆锥/圆柱圆锥综合应用` | **题型**: `calculation`
**original**: R3 | **V1**: R1 (flag_review) | **V2**: R3 (confident)

**题面：**

> 打谷场上有一堆稻谷成圆锥形，底面直径是 5 m，高是 1.8 m。如果每立方米稻谷重 500 kg，稻谷的出米率为 70%，这堆稻谷能加工大米多少千克？

**答案：** `4121.25`

**解析：** 底面半径＝5$\div$2＝2.5 m。体积＝1/3$\times$3.14$\times$2.$5^{2}\times$1.8＝11.775 m³。大米＝11.775$\times$500$\times$70%＝4121.25 kg。

**V1 reasoning：** 步骤数 1 (R1); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.05 (R1) | 锚点 math_r3_anchor_1 (R3, kp=圆柱与圆锥/圆柱的表面积, type=calculation) | 综合 R1, 原 R3, 降档 2

**V2 reasoning：** 5维: step=3(3) mental=0(1) distractor=None(None) calc=0.65(3) kp_span=2(2) | max=3, median=3, flag=confident | anchor=math_r4_anchor_5 (R4)

**V2 5 维**: `step_count=3 / mental_flexibility=0 / calculation_volume=0.65 / kp_span=2`

**Famin 你的判断：**

- [ ] 同意 V2（实际 R3）
- [ ] 同意 V1（实际 R1）
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（说明判断 / 算法该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_mokuai_tongji_001.json#25`

**KP**: `总复习/解决问题策略` | **题型**: `calculation`
**original**: R3 | **V1**: R1 (flag_review) | **V2**: R3 (confident)

**题面：**

> 甲、乙两人用同样多的钱一起买了 22 瓶葡萄酒，甲拿了 12 瓶，乙拿了 10 瓶，后来甲又补给乙 26 元钱。每瓶葡萄酒多少钱？

**答案：** `26`

**解析：** 公平分配应各 11 瓶。甲多拿了 12-11=1 瓶，要补给乙 1 瓶的钱。补 26 元 = 1 瓶价 = 26 元。

**V1 reasoning：** 步骤数 1 (R1); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.00 (R1) | 锚点 math_r4_anchor_2 (R4, kp=总复习/解决问题策略, type=calculation) | 综合 R1, 原 R3, 降档 2

**V2 reasoning：** 5维: step=3(3) mental=1(2) distractor=None(None) calc=0.00(1) kp_span=1(1) | max=3, median=2, flag=confident | anchor=math_r4_anchor_2 (R4)

**V2 5 维**: `step_count=3 / mental_flexibility=1 / calculation_volume=0.0 / kp_span=1`

**Famin 你的判断：**

- [ ] 同意 V2（实际 R3）
- [ ] 同意 V1（实际 R1）
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（说明判断 / 算法该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_xshchu_shenyang_001.json#27`

**KP**: `总复习/数与代数综合` | **题型**: `calculation`
**original**: R4 | **V1**: R1 (flag_review) | **V2**: R3 (confident)

**题面：**

> 简便计算：20.18 $\times$ 1996 － 19.95 $\times$ 2018，结果是(    )。

**答案：** `20.18`

**解析：** 20.18$\times$1996=2018$\times$19.96（一个因数$\times$100，另一个$\div$100）。原式=2018$\times$19.96-19.95$\times$2018=2018$\times$（19.96-19.95）=2018$\times$0.01=20.18。

**V1 reasoning：** 步骤数 2 (R2); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.15 (R1) | 锚点 math_r4_anchor_3 (R2, kp=总复习/数与代数综合, type=calculation) | 综合 R1, 原 R4, 降档 3

**V2 reasoning：** 5维: step=2(2) mental=0(1) distractor=None(None) calc=0.65(3) kp_span=1(1) | max=3, median=2, flag=confident | anchor=math_r4_anchor_3 (R2)

**V2 5 维**: `step_count=2 / mental_flexibility=0 / calculation_volume=0.65 / kp_span=1`

**Famin 你的判断：**

- [ ] 同意 V2（实际 R3）
- [ ] 同意 V1（实际 R1）
- [ ] 同意原档（实际 R4）
- [ ] 实际是 R2
- [ ] ? 拿不准

**Comment（说明判断 / 算法该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_mokuai_yicuo_001.json#21`

**KP**: `圆柱与圆锥/圆锥的体积` | **题型**: `calculation`
**original**: R4 | **V1**: R1 (flag_review) | **V2**: R4 (confident)

**题面：**

> 一个圆锥形土堆，底面直径是 6 m，高是 2.5 m。用一辆载重 6 t 的汽车去运，每立方米土约重 1.5 t，几次可以全部运完？（$\pi$取3.14，结果向上取整）

**答案：** `6`

**解析：** 底面半径=6$\div$2=3 m，体积=(1/3)$\times\pi\times 3^{2}\times$2.5=(1/3)$\times$3.14$\times$9$\times$2.5=23.55 m³；总质量=23.55$\times$1.5=35.325 t；35.325$\div$6≈5.9，向上取整=6 次。

**V1 reasoning：** 步骤数 2 (R2); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.20 (R1) | 锚点 math_r4_anchor_5 (R4, kp=圆柱与圆锥/圆锥的体积, type=calculation) | 综合 R1, 原 R4, 降档 3

**V2 reasoning：** 5维: step=4(4) mental=2(3) distractor=None(None) calc=0.45(2) kp_span=1(1) | max=4, median=3, flag=confident | anchor=math_r4_anchor_5 (R4)

**V2 5 维**: `step_count=4 / mental_flexibility=2 / calculation_volume=0.45 / kp_span=1`

**Famin 你的判断：**

- [ ] 同意 V2（实际 R4）
- [ ] 同意 V1（实际 R1）
- [ ] 实际是 R2
- [ ] 实际是 R3
- [ ] ? 拿不准

**Comment（说明判断 / 算法该怎么改）：**

> 

---

## B 组：V2 high_variance（单维拉高，是否真应升档）

### `realpaper_g6_math_beishida_qimo_003.json#21`

**KP**: `总复习/数与代数综合` | **题型**: `choice`
**original**: R2 | **V1**: R1 (suggest_change) | **V2**: R3 (high_variance)

**题面：**

> 下列年份中，不是闰年的是(    )。

**选项：**

- A. 1988
- B. 1900
- C. 2000
- D. 2016

**答案：** `B`

**解析：** 闰年规则：能被 4 整除且不能被 100 整除，或能被 400 整除。1900 被 100 整除但不被 400 整除，平年。

**V1 reasoning：** 步骤数 1 (R1); 陷阱密度 0.35 (R2); KP跨度 1 (R1); 数据复杂度 0.00 (R1) | 锚点 math_r1_anchor_2 (R1, kp=总复习/统计与可能性, type=choice) | 综合 R1, 原 R2, 降档 1

**V2 reasoning：** 5维: step=1(1) mental=0(1) distractor=2(3) calc=0.00(1) kp_span=1(1) | max=3, median=1, flag=high_variance | anchor=math_r1_anchor_2 (R1)

**V2 5 维**: `step_count=1 / mental_flexibility=0 / distractor_realness=2 / calculation_volume=0.0 / kp_span=1`

**Famin 你的判断：**

- [ ] 同意 V2（实际 R3）
- [ ] 同意 V1（实际 R1）
- [ ] 同意原档（实际 R2）
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（说明判断 / 算法该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_mokuai_yicuo_001.json#20`

**KP**: `总复习/解决问题策略` | **题型**: `calculation`
**original**: R3 | **V1**: R1 (flag_review) | **V2**: R4 (high_variance)

**题面：**

> 在环保日活动中，六(1)班同学共收集废旧电池 280 节，比六(2)班同学收集的 1.2 倍少 8 节。六(2)班同学收集废旧电池多少节？

**答案：** `240`

**解析：** 设六(2)班收集 x 节，则 1.2x-8=280，1.2x=288，x=240 节。

**V1 reasoning：** 步骤数 2 (R2); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.10 (R1) | 锚点 math_r4_anchor_2 (R4, kp=总复习/解决问题策略, type=calculation) | 综合 R1, 原 R3, 降档 2

**V2 reasoning：** 5维: step=4(4) mental=1(2) distractor=None(None) calc=0.35(2) kp_span=2(2) | max=4, median=2, flag=high_variance | anchor=math_r4_anchor_2 (R4)

**V2 5 维**: `step_count=4 / mental_flexibility=1 / calculation_volume=0.35 / kp_span=2`

**Famin 你的判断：**

- [ ] 同意 V2（实际 R4）
- [ ] 同意 V1（实际 R1）
- [ ] 同意原档（实际 R3）
- [ ] 实际是 R2
- [ ] ? 拿不准

**Comment（说明判断 / 算法该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_mokuai_tongji_001.json#22`

**KP**: `总复习/统计与可能性` | **题型**: `choice`
**original**: R1 | **V1**: R1 (no_change) | **V2**: R3 (high_variance)

**题面：**

> 骰子的六个面上分别刻有 1 到 6 个点。同时抛掷两枚骰子，下列说法中不可能实现的是(    )。

**选项：**

- A. 点数之和是 12
- B. 点数之和小于 3
- C. 点数之和是 13
- D. 点数之和是 7

**答案：** `C`

**解析：** 两骰子最大和 = 6+6 = 12，所以 13 不可能。其他都可能（12=6+6，<3 即 1+1=2，7 多种组合）。

**V1 reasoning：** 步骤数 2 (R2); 陷阱密度 0.35 (R2); KP跨度 1 (R1); 数据复杂度 0.00 (R1) | 锚点 math_r1_anchor_2 (R1, kp=总复习/统计与可能性, type=choice)

**V2 reasoning：** 5维: step=1(1) mental=0(1) distractor=2(3) calc=0.00(1) kp_span=1(1) | max=3, median=1, flag=high_variance | anchor=math_r1_anchor_2 (R1)

**V2 5 维**: `step_count=1 / mental_flexibility=0 / distractor_realness=2 / calculation_volume=0.0 / kp_span=1`

**Famin 你的判断：**

- [ ] 同意 V2（实际 R3）
- [ ] 同意 V1（实际 R1）
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（说明判断 / 算法该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_mokuai_daishu_001.json#18`

**KP**: `比和比例/比例的基本性质` | **题型**: `choice`
**original**: R2 | **V1**: R2 (no_change) | **V2**: R3 (high_variance)

**题面：**

> 能与 0.24∶0.1 组成比例的是(    )。

**选项：**

- A. 24∶1
- B. 12∶1
- C. 12∶5
- D. 5∶12

**答案：** `C`

**解析：** 0.24:0.1=24:10=12:5。能组成比例即比值相等：12:5 的比值=12/5=2.4，与 0.24/0.1=2.4 相等。

**V1 reasoning：** 步骤数 2 (R2); 陷阱密度 0.35 (R2); KP跨度 2 (R2); 数据复杂度 0.10 (R1) | 锚点 math_r1_anchor_3 (R1, kp=比和比例/比的意义, type=choice)

**V2 reasoning：** 5维: step=1(1) mental=0(1) distractor=2(3) calc=0.15(1) kp_span=1(1) | max=3, median=1, flag=high_variance | anchor=math_r1_anchor_3 (R1)

**V2 5 维**: `step_count=1 / mental_flexibility=0 / distractor_realness=2 / calculation_volume=0.15 / kp_span=1`

**Famin 你的判断：**

- [ ] 同意 V2（实际 R3）
- [ ] 同意 V1（实际 R2）
- [ ] 实际是 R1
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（说明判断 / 算法该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_mokuai_daishu_001.json#25`

**KP**: `比和比例/化简比` | **题型**: `calculation`
**original**: R3 | **V1**: R1 (flag_review) | **V2**: R4 (high_variance)

**题面：**

> 化简比并求比值：4.5∶(4/9)。请依次填化简后的比和比值，用逗号分隔（写法如「81:8,81/8」）。

**答案：** `81:8,81/8`

**解析：** 4.5∶(4/9)=(9/2)∶(4/9)=(9/2)$\times$18∶(4/9)$\times$18=81∶8；比值=81/8。

**V1 reasoning：** 步骤数 2 (R2); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.15 (R1) | 锚点 math_r3_anchor_4 (R3, kp=比和比例/比的意义, type=calculation) | 综合 R1, 原 R3, 降档 2

**V2 reasoning：** 5维: step=4(4) mental=1(2) distractor=None(None) calc=0.30(2) kp_span=2(2) | max=4, median=2, flag=high_variance | anchor=math_r3_anchor_4 (R3)

**V2 5 维**: `step_count=4 / mental_flexibility=1 / calculation_volume=0.3 / kp_span=2`

**Famin 你的判断：**

- [ ] 同意 V2（实际 R4）
- [ ] 同意 V1（实际 R1）
- [ ] 同意原档（实际 R3）
- [ ] 实际是 R2
- [ ] ? 拿不准

**Comment（说明判断 / 算法该怎么改）：**

> 

---
