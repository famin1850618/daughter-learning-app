# 数学 D2 Flag Review 抽样复核（Famin 用）

> **背景：** D2 reviewer agent 在 1010 道数学题中标 163 道 ≥ 2 档差异 flag_review（疑似入库 agent 严重打错）。
> 从中按 shift × KP 分层抽 15 道复核，反馈用于调整 difficulty skill 算法（不是直接调 round 字段）。
>
> **如何标注**（每道题最后一段）：
> - **同意算法 suggested_round** → `[x] 同意算法`（说明入库 agent 当时打错）
> - **同意原 original_round** → `[x] 同意原档`（算法误判，下面 Comment 说明算法漏看了什么）
> - **第三档** → `[x] 实际 R<N>`
> - **拿不准** → `[x] ?`
>
> 完成后告诉我"数学 flag_review 复核完了"，我跑脚本写入 calibration_log + 推 difficulty skill 算法调整建议。

---

## Shift: R1->R3（升档，抽 2 道）

### `realpaper_g6_math_beishida_kaodian_zonghe_001.json#15`

**KP**: `总复习/数与代数综合`  |  **题型**: `fill`
**入库 (original)**: **R1** → **算法建议 (suggested)**: **R3**

**题面：**

> 直接写出得数。请依次计算并填 6 个数，用逗号分隔（分数写成「分子/分母」格式）：4/7$\times$5.6=(    )；5/7-5/7$\times$0=(    )；10-2/3-1/3=(    )；0.$3^{2}$=(    )；3.5-2.45=(    )；3/4$\div$0.25=(    )。

**答案：** `3.2,5/7,9,0.09,1.05,3`

**解析：** 4/7$\times$5.6=22.4/7=3.2；先算 5/7$\times$0=0，再算 5/7-0=5/7；10-(2/3+1/3)=9；0.$3^{2}$=0.09；3.5-2.45=1.05；3/4$\div$0.25=0.75$\div$0.25=3。

**算法 reasoning：** 步骤数 3 (R3); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.30 (R2) | 锚点 math_r3_anchor_5 (R4, kp=总复习/数与代数综合, type=fill) | 综合 R3, 原 R1, 升档 2

**Breakdown**: `step_count=3 / kp_span=1 / data_complexity=0.30000000000000004 / round_per_dim={'step': 3, 'distractor': None, 'kp_span': 1, 'data_complexity': 2}`

**Famin 你的判断：**

- [ ] 同意算法（实际 R3）
- [ ] 同意原档（实际 R1，算法误判）
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（说明算法漏看了什么 / 该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_kaodian_zonghe_002.json#10`

**KP**: `总复习/数与代数综合`  |  **题型**: `fill`
**入库 (original)**: **R1** → **算法建议 (suggested)**: **R3**

**题面：**

> 口算（结果用「≈」时取近似值，依次填 6 个结果，用逗号分隔）：$259+398\approx$；$8.8-0.88=$；$2.4\div\frac{3}{4}=$；$0.125^2=$；$50\times 800=$；$1000-403\approx$。

**答案：** `660,7.92,3.2,1/64,40000,600`

**解析：** $259+398\approx 260+400=660$；$8.8-0.88=7.92$；$2.4\div 0.75=3.2$；$0.125^2=\frac{1}{64}$；$50\times 800=40000$；$1000-403\approx 1000-400=600$。

**算法 reasoning：** 步骤数 2 (R2); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.30 (R2) | 锚点 math_r3_anchor_5 (R4, kp=总复习/数与代数综合, type=fill) | 综合 R3, 原 R1, 升档 2

**Breakdown**: `step_count=2 / kp_span=1 / data_complexity=0.30000000000000004 / round_per_dim={'step': 2, 'distractor': None, 'kp_span': 1, 'data_complexity': 2}`

**Famin 你的判断：**

- [ ] 同意算法（实际 R3）
- [ ] 同意原档（实际 R1，算法误判）
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（说明算法漏看了什么 / 该怎么改）：**

> 

---

## Shift: R3->R1（降档，抽 8 道）

### `realpaper_g6_math_beishida_mokuai_jisuan_001.json#39`

**KP**: `总复习/解决问题策略`  |  **题型**: `fill`
**入库 (original)**: **R3** → **算法建议 (suggested)**: **R1**

**题面：**

> 现有长 45 厘米、宽 30 厘米的长方形纸若干张，要拼成一个正方形。正方形的边长最短是(    )厘米，至少要用(    )张这样的长方形纸。请依次填 2 个数，用逗号分隔。

**答案：** `90,6`

**解析：** 正方形边长须同时是 45 和 30 的倍数，最短为最小公倍数 90 厘米。所需张数=(90$\div$45)$\times$(90$\div$30)=2$\times$3=6 张。

**算法 reasoning：** 步骤数 1 (R1); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.00 (R1) | 锚点 math_r3_anchor_5 (R4, kp=总复习/数与代数综合, type=fill) | 综合 R1, 原 R3, 降档 2

**Breakdown**: `step_count=1 / kp_span=1 / data_complexity=0.0 / round_per_dim={'step': 1, 'distractor': None, 'kp_span': 1, 'data_complexity': 1}`

**Famin 你的判断：**

- [ ] 同意算法（实际 R1）
- [ ] 同意原档（实际 R3，算法误判）
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（说明算法漏看了什么 / 该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_xingjitongji_001.json#15`

**KP**: `圆柱与圆锥/圆柱的体积`  |  **题型**: `fill`
**入库 (original)**: **R3** → **算法建议 (suggested)**: **R1**

**题面：**

> 把一段长 2 m 的圆柱形木料锯成 4 个小圆柱，表面积正好增加了 36 dm²。这段木料的体积是(    )m³。

**答案：** `0.12`

**解析：** 锯成 4 段需 3 刀，每刀 2 个面，共 6 个新底面。每底面 = 36$\div$6 = 6 dm²。体积 = 底$\times$高 = 6$\times$20 = 120 dm³ = 0.12 m³（高 2m=20dm）。

**算法 reasoning：** 步骤数 2 (R2); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.15 (R1) | 锚点 math_r2_anchor_4 (R2, kp=圆柱与圆锥/圆柱的体积, type=choice) | 综合 R1, 原 R3, 降档 2

**Breakdown**: `step_count=2 / kp_span=1 / data_complexity=0.15000000000000002 / round_per_dim={'step': 2, 'distractor': None, 'kp_span': 1, 'data_complexity': 1}`

**Famin 你的判断：**

- [ ] 同意算法（实际 R1）
- [ ] 同意原档（实际 R3，算法误判）
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（说明算法漏看了什么 / 该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_zhouce_peiyou_004.json#18`

**KP**: `正反比例/反比例的意义`  |  **题型**: `fill`
**入库 (original)**: **R3** → **算法建议 (suggested)**: **R1**

**题面：**

> 一辆汽车从甲地开往乙地，平均每时行驶 80 km，4 时到达。返回时，平均每时比原来快 1/4，返回时用了多少时？（用比例知识解）

**答案：** `3.2`

**解析：** 总路程一定，速度与时间成反比例。返回速度 = 80$\times$(1+1/4) = 100 km/h；80$\times$4 = 100$\times$x，解得 x = 3.2 时。

**算法 reasoning：** 步骤数 2 (R2); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.15 (R1) | 锚点 math_r1_anchor_5 (R1, kp=正反比例/比例尺, type=fill) | 综合 R1, 原 R3, 降档 2

**Breakdown**: `step_count=2 / kp_span=1 / data_complexity=0.15000000000000002 / round_per_dim={'step': 2, 'distractor': None, 'kp_span': 1, 'data_complexity': 1}`

**Famin 你的判断：**

- [ ] 同意算法（实际 R1）
- [ ] 同意原档（实际 R3，算法误判）
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（说明算法漏看了什么 / 该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_xshchu_xian_001.json#14`

**KP**: `总复习/图形与几何综合`  |  **题型**: `judgment`
**入库 (original)**: **R3** → **算法建议 (suggested)**: **R1**

**题面：**

> 钟面 15:30 时，时针和分针所形成的角是直角。

**答案：** `错`

**解析：** 15:30 时分针指向 6，时针在 3 与 4 之间偏向 4 一半的位置，时针与分针夹角=75°，不是直角。

**算法 reasoning：** 步骤数 1 (R1); 陷阱密度 0.15 (R1); KP跨度 2 (R2); 数据复杂度 0.00 (R1) | 锚点 math_r1_anchor_2 (R1, kp=总复习/统计与可能性, type=choice) | 综合 R1, 原 R3, 降档 2

**Breakdown**: `step_count=1 / distractor_density=0.15 / kp_span=2 / data_complexity=0.0 / round_per_dim={'step': 1, 'distractor': 1, 'kp_span': 2, 'data_complexity': 1}`

**Famin 你的判断：**

- [ ] 同意算法（实际 R1）
- [ ] 同意原档（实际 R3，算法误判）
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（说明算法漏看了什么 / 该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_zhouce_peiyou_003.json#16`

**KP**: `比和比例/解比例`  |  **题型**: `fill`
**入库 (original)**: **R3** → **算法建议 (suggested)**: **R1**

**题面：**

> 解比例：1.24 : x = 2.48 : 0.4。x = (    )

**答案：** `0.2`

**解析：** 2.48x = 1.24$\times$0.4 = 0.496，x = 0.2。

**算法 reasoning：** 步骤数 1 (R1); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.15 (R1) | 锚点 math_r1_anchor_3 (R1, kp=比和比例/比的意义, type=choice) | 综合 R1, 原 R3, 降档 2

**Breakdown**: `step_count=1 / kp_span=1 / data_complexity=0.15000000000000002 / round_per_dim={'step': 1, 'distractor': None, 'kp_span': 1, 'data_complexity': 1}`

**Famin 你的判断：**

- [ ] 同意算法（实际 R1）
- [ ] 同意原档（实际 R3，算法误判）
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（说明算法漏看了什么 / 该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_qizhong_003.json#16`

**KP**: `圆柱与圆锥/圆锥的体积`  |  **题型**: `calculation`
**入库 (original)**: **R3** → **算法建议 (suggested)**: **R1**

**题面：**

> 有一个底面直径是 20 厘米装有一部分水的圆柱形玻璃杯，水中浸没着一个底面直径是 6 厘米、高 20 厘米的圆锥形铅锤。当把铅锤从水中取出时，杯子中的水面下降多少厘米？

**答案：** `0.6`

**解析：** 铅锤体积 = (1/3)$\times$3.14$\times 3^{2}\times$20 = 188.4 cm³；下降水柱体积也是 188.4 cm³；杯底面积 = 3.14$\times$1$0^{2}$ = 314 cm²；下降高 = 188.4$\div$314 = 0.6 cm。

**算法 reasoning：** 步骤数 2 (R2); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.15 (R1) | 锚点 math_r4_anchor_5 (R4, kp=圆柱与圆锥/圆锥的体积, type=calculation) | 综合 R1, 原 R3, 降档 2

**Breakdown**: `step_count=2 / kp_span=1 / data_complexity=0.15000000000000002 / round_per_dim={'step': 2, 'distractor': None, 'kp_span': 1, 'data_complexity': 1}`

**Famin 你的判断：**

- [ ] 同意算法（实际 R1）
- [ ] 同意原档（实际 R3，算法误判）
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（说明算法漏看了什么 / 该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_qimo_003.json#40`

**KP**: `比和比例/比的意义`  |  **题型**: `calculation`
**入库 (original)**: **R3** → **算法建议 (suggested)**: **R1**

**题面：**

> 甲、乙、丙三位工人共同制作了 2050 个零件。已知甲和乙制作的零件个数比是 5∶3，乙和丙是 4∶3。丙制作了多少个零件？

**答案：** `450`

**解析：** 丙 = 2050$\times$9/41 = 450。

**算法 reasoning：** 步骤数 1 (R1); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.00 (R1) | 锚点 math_r3_anchor_4 (R3, kp=比和比例/比的意义, type=calculation) | 综合 R1, 原 R3, 降档 2

**Breakdown**: `step_count=1 / kp_span=1 / data_complexity=0.0 / round_per_dim={'step': 1, 'distractor': None, 'kp_span': 1, 'data_complexity': 1}`

**Famin 你的判断：**

- [ ] 同意算法（实际 R1）
- [ ] 同意原档（实际 R3，算法误判）
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（说明算法漏看了什么 / 该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_qimo_003.json#36`

**KP**: `圆柱与圆锥/圆柱的表面积`  |  **题型**: `calculation`
**入库 (original)**: **R3** → **算法建议 (suggested)**: **R1**

**题面：**

> 一个圆柱形水池，水池的内壁和底面要抹水泥。从内部量得底面周长是 50.24 m，池深 1.2 m。抹水泥的面积是多少 m²？

**答案：** `261.248`

**解析：** 半径 = 8 m；底面积 = 3.14$\times$64 = 200.96 m²；侧面积（内壁） = 50.24$\times$1.2 = 60.288 m²；总 = 200.96+60.288 = 261.248 m²。

**算法 reasoning：** 步骤数 2 (R2); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.15 (R1) | 锚点 math_r3_anchor_1 (R3, kp=圆柱与圆锥/圆柱的表面积, type=calculation) | 综合 R1, 原 R3, 降档 2

**Breakdown**: `step_count=2 / kp_span=1 / data_complexity=0.15000000000000002 / round_per_dim={'step': 2, 'distractor': None, 'kp_span': 1, 'data_complexity': 1}`

**Famin 你的判断：**

- [ ] 同意算法（实际 R1）
- [ ] 同意原档（实际 R3，算法误判）
- [ ] 实际是 R2
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（说明算法漏看了什么 / 该怎么改）：**

> 

---

## Shift: R4->R1（降档，抽 3 道）

### `realpaper_g6_math_beishida_mokuai_daishu_001.json#34`

**KP**: `总复习/解决问题策略`  |  **题型**: `calculation`
**入库 (original)**: **R4** → **算法建议 (suggested)**: **R1**

**题面：**

> 婷婷有一本故事书，已看的页数与剩下页数的比是 3∶5，如果再看 65 页，正好看完了全书的 11/12，这本故事书共有多少页？（写整数）

**答案：** `120`

**解析：** 已看占全书 3/(3+5)=3/8；65 页对应 11/12-3/8=22/24-9/24=13/24；总页数=65$\div$(13/24)=65$\times$24/13=120 页。

**算法 reasoning：** 步骤数 2 (R2); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.20 (R1) | 锚点 math_r4_anchor_2 (R4, kp=总复习/解决问题策略, type=calculation) | 综合 R1, 原 R4, 降档 3

**Breakdown**: `step_count=2 / kp_span=1 / data_complexity=0.2 / round_per_dim={'step': 2, 'distractor': None, 'kp_span': 1, 'data_complexity': 1}`

**Famin 你的判断：**

- [ ] 同意算法（实际 R1）
- [ ] 同意原档（实际 R4，算法误判）
- [ ] 实际是 R2
- [ ] 实际是 R3
- [ ] ? 拿不准

**Comment（说明算法漏看了什么 / 该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_xshchu_beijing_001.json#28`

**KP**: `总复习/数与代数综合`  |  **题型**: `calculation`
**入库 (original)**: **R4** → **算法建议 (suggested)**: **R1**

**题面：**

> 为迎接文明城市创建，城东新区拓宽一条公路，第一天修了 15%，第二天比第一天少修 300 米，还剩 75%，这条公路全长多少米？（填米数）

**答案：** `6000`

**解析：** 第二天修了 1-15%-75%=10%。第二天比第一天少修 15%-10%=5% 对应 300 米，全长=300$\div$5%=6000 米。

**算法 reasoning：** 步骤数 2 (R2); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.00 (R1) | 锚点 math_r4_anchor_3 (R2, kp=总复习/数与代数综合, type=calculation) | 综合 R1, 原 R4, 降档 3

**Breakdown**: `step_count=2 / kp_span=1 / data_complexity=0.0 / round_per_dim={'step': 2, 'distractor': None, 'kp_span': 1, 'data_complexity': 1}`

**Famin 你的判断：**

- [ ] 同意算法（实际 R1）
- [ ] 同意原档（实际 R4，算法误判）
- [ ] 实际是 R2
- [ ] 实际是 R3
- [ ] ? 拿不准

**Comment（说明算法漏看了什么 / 该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_xshchu_xian_001.json#7`

**KP**: `圆柱与圆锥/圆柱圆锥综合应用`  |  **题型**: `fill`
**入库 (original)**: **R4** → **算法建议 (suggested)**: **R1**

**题面：**

> 一个蛋糕盒（圆柱形），盒上扎了一条漂亮的丝带，丝带从盒底十字交叉绕到盒顶，共绕过 8 条直径与 8 条高，再加上接头处用去的部分。已知蛋糕盒底面周长是 94.2 cm，高是 11 cm，接头处用去 20 cm，这条丝带长(    ) cm。

**答案：** `348`

**解析：** 底面直径=94.2$\div$3.14=30 cm。丝带长=8 条直径+8 条高+接头=8$\times$30+8$\times$11+20=240+88+20=348 cm。

**算法 reasoning：** 步骤数 2 (R2); 陷阱密度 N/A; KP跨度 1 (R1); 数据复杂度 0.10 (R1) | 锚点 math_r3_anchor_3 (R2, kp=圆柱与圆锥/圆柱圆锥综合应用, type=fill) | 综合 R1, 原 R4, 降档 3

**Breakdown**: `step_count=2 / kp_span=1 / data_complexity=0.1 / round_per_dim={'step': 2, 'distractor': None, 'kp_span': 1, 'data_complexity': 1}`

**Famin 你的判断：**

- [ ] 同意算法（实际 R1）
- [ ] 同意原档（实际 R4，算法误判）
- [ ] 实际是 R2
- [ ] 实际是 R3
- [ ] ? 拿不准

**Comment（说明算法漏看了什么 / 该怎么改）：**

> 

---

## Shift: R4->R2（降档，抽 2 道）

### `realpaper_g6_math_beishida_xshchu_xian_001.json#36`

**KP**: `总复习/解决问题策略`  |  **题型**: `calculation`
**入库 (original)**: **R4** → **算法建议 (suggested)**: **R2**

**题面：**

> A、B 两个仓库存化肥的质量比是 12:11，后来 B 仓库又运进 24 吨，这时 A 仓库存化肥比 B 仓库少 1/9。B 仓库原来存化肥(    )吨。

**答案：** `105.6`

**解析：** 原 A:B=12:11，设原 A=12k、原 B=11k。运进 24 吨后 B 变 11k+24，A 比新 B 少 1/9，即 12k=(11k+24)$\times$8/9。解得 108k=88k+192，20k=192，k=9.6。原 B=11$\times$9.6=105.6 吨。

**算法 reasoning：** 步骤数 2 (R2); 陷阱密度 N/A; KP跨度 3 (R3); 数据复杂度 0.35 (R2) | 锚点 math_r4_anchor_2 (R4, kp=总复习/解决问题策略, type=calculation) | 综合 R2, 原 R4, 降档 2

**Breakdown**: `step_count=2 / kp_span=3 / data_complexity=0.35 / round_per_dim={'step': 2, 'distractor': None, 'kp_span': 3, 'data_complexity': 2}`

**Famin 你的判断：**

- [ ] 同意算法（实际 R2）
- [ ] 同意原档（实际 R4，算法误判）
- [ ] 实际是 R1
- [ ] 实际是 R3
- [ ] ? 拿不准

**Comment（说明算法漏看了什么 / 该怎么改）：**

> 

---

### `realpaper_g6_math_beishida_xshchu_xian_001.json#35`

**KP**: `比和比例/比的意义`  |  **题型**: `calculation`
**入库 (original)**: **R4** → **算法建议 (suggested)**: **R2**

**题面：**

> 客车和货车同时从甲、乙两地的中点处向相反方向行驶，3 时后，客车到达甲地，货车离乙地还有 42 千米。已知货车和客车的速度比是 5:7。甲、乙两地相距(    )千米。

**答案：** `294`

**解析：** 时间相同时路程比=速度比 5:7。设货车 3 时行 5k 千米，客车行 7k 千米。客车走完一半全程=7k；货车走 5k=7k-42，即 2k=42，k=21。全程=2$\times$7k=2$\times$147=294 千米。

**算法 reasoning：** 步骤数 2 (R2); 陷阱密度 N/A; KP跨度 3 (R3); 数据复杂度 0.20 (R1) | 锚点 math_r3_anchor_4 (R3, kp=比和比例/比的意义, type=calculation) | 综合 R2, 原 R4, 降档 2

**Breakdown**: `step_count=2 / kp_span=3 / data_complexity=0.2 / round_per_dim={'step': 2, 'distractor': None, 'kp_span': 3, 'data_complexity': 1}`

**Famin 你的判断：**

- [ ] 同意算法（实际 R2）
- [ ] 同意原档（实际 R4，算法误判）
- [ ] 实际是 R1
- [ ] 实际是 R3
- [ ] ? 拿不准

**Comment（说明算法漏看了什么 / 该怎么改）：**

> 

---
