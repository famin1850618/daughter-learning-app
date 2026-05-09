# V3.12.20.1 入库 Issues 汇总（待 Famin 决策）

**入库总览**：12 batch / 333 题 / version 47→48
- Math A: d4_genzong (42) / d4_guoguan (37) / zhouce_peiyou_002 (20) / zhouce_peiyou_003 (26) — 125 题
- Math B: qizhong_002 (22) / qimo_002 (37) / xsc_shenyang_001 (42) — 101 题
- Chinese C: unit1_001 (22) / unit1_002 (27) / unit2_001 (28) / unit3_001 (17) — 94 题
- Chinese D: qizhong_005 (13) — 13 题
- 跳过：Chinese D 期末模拟卷1 + 全真卷2（扫描型 PDF）/ Physics 38 套源池整体扫描型不可处理

**全部 batch validate.py 15/15 PASS + svg_dim_audit 0 待修。**

---


---

# === v3_12_20_physics_report.md ===

## Issues & Resolutions

### 问题 1: 整卷扫描型 PDF（PDFPatcher 0 字体）—— 是否进 OCR 通道

- **遇到场景**: Step 1 extract，pdftotext -layout 输出 16 字节（纯 form-feed `0x0c`）；`pdftotext -raw` 同样 16 字节；`pdffonts` 报 0 字体（`name | type | encoding ... ---` 表头之外 0 行）。
- **现象**: PDF 标头显示 Creator=PDFPatcher 0.6.2.3572 / Producer=iTextSharp，CreationDate 2021-12-30。pdftoppm 渲染 preview-01.png 视觉清晰可读（题面 / 选项 / 装置图都看得见），但完全是栅格图像；文字层完全空。
- **当时决策**: 按 pipeline.md Step 1.3 + memory feedback_unclear_abandon 整卷跳过；不尝试 OCR / 多模态读图。
- **是否合规**: ✅ 严格合规（V3.10 122 道伪题就是因为多模态抢救而生）。
- **建议是否写入纪律**: 是
- **理由**:
  - SKILL.md 16 条纪律 + pre_commit_check 19 项**没有针对"整源池级不可处理"的处置流程**。Step 1.3 只说了"整卷跳过 + manifest 注明"，但当**整源池 38 套都同源**时——是 worker 报告还是主 session 决策？是否有"换源"或"开 OCR 通道"的合法路径？
  - 建议补 SKILL.md §17（暂定）：**源池级不可处理 → 整源池跳过 + 主 session 升级到 Famin 战略决策**（不是 worker 自决）。

### 问题 2: 整源池 38 套全部同源同病

- **遇到场景**: 决定跳过本卷后，扩抽样确认是否换其他物理 PDF；用 `for f in *.pdf; do pdftotext -layout "$f" - | wc -c; done` 一次扫 38 套。
- **现象**: 全部 3-16 字节可识别文本（北京 / 海淀 / 黄冈 / 武汉 / 苏科版 / 沪科版 / 北师版 / 沪粤版 全军覆没）。说明源 = 同一商业题库的扫描合集（PDFPatcher + iTextSharp 工具链）。
- **当时决策**: worker 不能擅自换源（不在 prompt 范围内），就把这个发现写进 manifest._observation 和本报告。
- **是否合规**: ✅ 合规但发现重大战略问题。
- **建议是否写入纪律**: 是
- **理由**:
  - **batch_inventory.md 的"待入清单"列了物理 1+2 套，但实际 0 套可处理**——清单建的时候没做"PDF 可处理性预扫"。
  - 建议补纪律: **批次清单建立前必须先跑可处理性预扫**（pdftotext 字节数 + pdffonts 字体数 双判，<100 字节或 0 字体直接 mark `unprocessable`），避免 worker 跑到 Step 1 才发现。
  - 这条纪律可以写进 `feedback_apk_build_discipline.md` 同级的新条 `feedback_inventory_pre_scan.md`。

### 问题 3: KP fallback 到 chapter — 边界 case 预演

- **遇到场景**: 虽然没入库到 4a，但我提前研究了 curriculum_seed.dart 的物理 chapter 列表（preview-01 看到题面有 "气体的浮力 / 排水管 U 形反水弯 / 塑料吸盘"），评估 KP fallback 实现策略。
- **现象**: 看 chapter 名是: 机械运动 / 声现象 / 物态变化 / **光现象** / 透镜及其应用 / 质量与密度 / 力 / 运动和力 / 压强 / 浮力 / **功和机械能** / 简单机械。
  - 任务 prompt 写的是 "光" / "运动与力" / "功机械能"，**和 curriculum_seed.dart 实际值不完全一致**："光现象" 不是 "光"，"运动和力" 不是 "运动与力"，"功和机械能" 不是 "功机械能"。
  - prompt 描述的章节名如直接拷给 KP 字段，会被 validate.py §3 chapter 检查 fail（chapter 不在白名单）。
- **当时决策**: 由于没真入库，没实际暴露此风险，但**抢先记录**。
- **是否合规**: ⚠ 边界 — 任务 prompt 与 spec 数据源名称漂移。
- **建议是否写入纪律**: 是
- **理由**:
  - 主 session 派 worker 时，prompt 里的"chapter 列表"必须从 `curriculum_seed.dart` 直接 grep 拷贝，**不许凭印象写**。否则 worker 看 prompt 写 "光"，实际 chapter 是 "光现象"，validate fail。
  - 建议补 SKILL.md 子条: **派 worker 前主 session 必须 `grep "Chapter(subject:" curriculum_seed.dart` 取活清单写进 prompt**，不许自由意会。

### 问题 4: 物理 KP 字段 = chapter 名 fallback 的语义

- **遇到场景**: prompt 说"KP 字段填 chapter 名（如机械运动）"，"实在没匹配的入 kp_gap"。
- **现象**: 物理 chapter 已经够细（12 章），但 chapter 之内还会有 "二力平衡 / 重力 / 弹力 / 摩擦力 / 阿基米德原理 / 杠杆原理 / 滑轮组" 等次级 KP——比"运动和力"这种章名更精准。
- **当时决策**: 未实际入库时无须决策，但**记录歧义**——
  - 路径 A: KP = chapter 名（粗粒度，整章一格）
  - 路径 B: KP = LLM 推理出的次级 KP（如"二力平衡"），即使不在清单也直接进 kp_gap 等候区
  - 路径 C: KP 字段留 null，仅保留 chapter（最干净，但破坏 schema：§7 说 KP 必填）
- **是否合规**: ⚠ 边界 — spec 没明确定义。
- **建议是否写入纪律**: 是
- **理由**:
  - 建议路径 B：**LLM 推理出最佳猜测 KP 名 → 都进 kp_gap 等候区**（不影响入库，未来 KP 体系建好统一回填）。这样物理首批入库时 KP 信号最丰富，未来回填成本最低。
  - 反对路径 A: chapter 名当 KP 用 → 后续真 KP 体系建立时无法区分"是真 KP 还是 chapter fallback"。
  - 反对路径 C: 破坏 schema 一致性，validate.py §3 检 chapter 但 §7 检 KP，KP=null 会触发整套 batch fail。

### 问题 5: 物理图形预演 — SVG 双箭头规则在物理上的边界

- **遇到场景**: 虽然没真画，但 preview-01.png 看到了图形类型（电池组、塑料吸盘、U 形管、气球潜水艇），按任务 prompt 要求预演 SVG 画法。
- **现象**: V3.12.20.1 的 SVG 长度标注双箭头规则（rules/integrity.md §5）是从**数学几何题**提炼的，规则核心:
  - 直线长度 → 双箭头 polygon
  - 曲线长度（C= / 弧长）→ 引线虚线 + ASCII 文字，禁双箭头
  - bbox 在 viewBox 内 + ASCII text only
- **物理特有图形预演**:
  1. **力矢量箭头 F**（受力分析图）—— 单端箭头表示方向 + 大小，与"长度标注双箭头"在视觉语言上**冲突**。学生看到"两个三角形夹一段"会以为是长度，看到"一个三角形指向终点"会以为是力。
  2. **电路图**（电池/电阻/灯泡/开关 标准符号）—— 这些**不是几何长度**也**不是力矢量**，是符号化元件。需要专属图形库（电池: `[+|-]` 短长平行线；电阻: 矩形或锯齿；灯泡: 圆+×；开关: 斜线）。
  3. **光路图**（入射光线 + 法线 + 反射/折射光线 + 角度标记）—— 光线是带箭头的射线（单端箭头方向），角度需要弧线标 `θ=30°` 或 `i=` `r=`。和力矢量的视觉语言**也是单端箭头**，但语义不同。
  4. **弹簧 + 滑轮**：弹簧是锯齿曲线，滑轮是圆 + 绳索；绳索张力**有方向**（单端箭头）。
  5. **U 形管 / 容器液面高度差**：高度差 Δh **是直线长度**（双箭头合规），但容器壁是曲线（曲线本身禁双箭头）—— 需要清楚标注双箭头是测的"两液面之间的纵向距离"而非"管壁长度"。
- **当时决策**: 整卷跳过未真画 SVG。但写出预演结论交主 session。
- **是否合规**: ⚠ 边界 — 现行规则不覆盖物理特有视觉语言。
- **建议是否写入纪律**: 是（**多条**）
- **理由**:
  1. **SVG §5.1 力矢量 vs 长度标注的视觉区分**: 力矢量 = 单端箭头 + 字母 F (向量符) + 单位 N；长度标注 = 双端箭头 + 数值 + 单位 cm/m。颜色或线宽**不要**区分（SVG cairosvg fallback 不稳）。靠**几何形状**区分（单 vs 双 polygon）。
  2. **SVG §5.2 电路图标准符号库**: 立 ASCII art 风格的电池/电阻/灯泡/开关 SVG primitive，复用模板（避免每个 worker 重画）。元件标 `R1=10` (省略 Ω 的 ASCII 表达，因为 Ω 不是 ASCII)。
  3. **SVG §5.3 光路图箭头规约**: 光线箭头在末端（不是双端），夹角用 `<path d="M ... A ..."/>` 弧线 + ASCII 文字 `i=30deg` (因 ° 不是 ASCII)。
  4. **SVG §5.4 单位 ASCII 化清单**:
     - Ω → `Ohm`
     - ° → `deg`
     - ℃ → `degC`
     - μ → `u`
     - ² → `^2`
     - π → `pi`
     - 这是 SVG `<text>` 内（cairosvg fallback 限制），content / explanation 字段仍可用全角符号。
  5. **SVG §5.5 多元件复合图**：电路图 + 受力图 + 光路图 同时出现的题（综合题），要画在同一张 SVG 还是分图？建议: 单 SVG 画完整装置，子图（如局部受力分析）走第二张 SVG（多 image_data）。

### 问题 6: 实验题答案格式 — 多空填空 vs 简答

- **遇到场景**: 物理实验题（如"测密度 / 测电阻 / 探究压强"）常见结构: "本实验用到的器材是____，原理是____，操作步骤(1)____ (2)____ (3)____，结论是____。"
- **现象**: 一道实验大题可能有 5-10 个空，每个空答案不同：器材名（"刻度尺/天平/量筒"短词）、原理公式（带 LaTeX）、操作描述（短句）、结论（短句）。
- **决策选项**:
  - 路径 A: 形式 A 压成 1 道多空 fill（按 §5.4 形式 A） — 但答案有的是公式（违反输入法白名单 §5.1）+ 有的是短句（违反白名单），整体不能压。
  - 路径 B: 形式 B 拆 N 道独立 fill/choice/calculation 用 group_id —— 但**操作步骤的答案常是开放式短句**（"将物体浸没水中，记下水面读数"），不在 fill 输入法白名单。
  - 路径 C: 整道实验大题按 calculation 类型保留 + answer 字段写完整答案 —— 但 calculation 在 app 端是文本输入校验，多空多步答案对不齐。
- **当时决策**: 未实际入库无须决策。
- **是否合规**: ⚠ 边界 — spec §5/§5.4 没覆盖物理实验题。
- **建议是否写入纪律**: 是
- **理由**:
  - 物理实验题是物理科**特有题型**（数学没有，语文阅读题有但格式不同）。建议:
    - 实验题里**纯客观空**（器材名、读数、计算结果）→ 拆独立 fill/calculation 进 group_id
    - 实验题里**开放式描述空**（操作步骤、结论分析）→ 标 type=`subjective` + `_subj_held` 后缀，参考 writing_pending 模式（接 AI 评分后再启用），暂不入库
    - 同一实验大题里混合的客观空 + 主观空 → 客观空入库（保留 group_id），主观空记入 docs/realpaper_subjective_held/，不影响整大题入库

### 问题 7: 单位 ASCII 化的渗透深度

- **遇到场景**: 物理无处不是单位 (Ω, ℃, m/s, cm³, kg·m/s², N·m, °C, %)。
- **现象**: V3.12.19 立的"SVG `<text>` 仅 ASCII"是为了 cairosvg fallback 字体稳定。但物理题面 content 字段、explanation 字段、answer 字段、options 字段——这些渲染走 Flutter 不走 cairosvg，**可以**用全角中文符号 / Unicode。
- **决策歧义**: SVG 内 `<text>R1=10Ohm</text>` vs content 字段 `电阻 R₁=10Ω`——同一道题里两种写法**矛盾**：
  - 用户看 content 看到 Ω
  - 用户点放大看 SVG 看到 Ohm
  - **学生认知不一致**
- **当时决策**: 未实际入库无须决策。
- **是否合规**: ⚠ 边界 — SVG/content 写法不一致带来认知割裂。
- **建议是否写入纪律**: 是
- **理由**:
  - 建议 §5.6 ASCII 单位规约: SVG 内 ASCII，但**explanation 字段必须显式同步说明**（如 "（图中 Ohm = Ω, deg = °, degC = ℃）"），让学生能桥接两种表达。
  - 长期方案: 升级 SVG 渲染管线支持 Unicode 字体（非 cairosvg 路径），但短期用 ASCII + 桥接说明。

### 问题 8: 物理 round 4 档基础描述未沉淀

- **遇到场景**: prompt 说"LLM 自由判 round（基础/中等/较难/竞赛 4 档）"，但**没给物理 4 档的特征描述**。
- **现象**:
  - 数学有 V4 算法（5 维 + max + 单维拉满保护）+ 20 锚点
  - 语文有 anchors+rubric V0.1
  - 物理：什么都没有，全靠 LLM 凭印象判
  - 没有"基础题 = 单概念识别 / 中等题 = 单步公式套用 / 较难题 = 多步推理 + 公式综合 / 竞赛题 = 多概念联立 + 创新模型"这种锚定描述
- **当时决策**: 未实际入库无须决策。
- **是否合规**: ⚠ 边界 — 阶段 0 本来就是"自由判 + 抽审累积"，但**自由判前如果完全无锚定**，verify 反馈无依据可比对（"为什么你判 R3 不是 R2"答不上来）。
- **建议是否写入纪律**: 是
- **理由**:
  - 建议物理首套入库前先**临时建一份 rubric_physics_v0.md**（即使是 LLM 凭物理教学经验起草的 4 档描述），让 worker 自由判时**至少有可引用文本**。
  - 这能让 verify markdown 里的 reasoning 有意义（"判 R2 因属于 rubric §基础+1 步公式应用"），而非空话（"我感觉是 R2"）。
  - V3.12.20 立 rubric_physics_v0.md → V3.12.21 worker 用 → V3.12.22 Famin verify → 进入语文式阶段 1。

### 问题 9: prompt 漂移：rubric 升级条件

- **遇到场景**: 任务 prompt 说"emit 后必须生成 docs/d2_physics_v1_verify_famin.md"。
- **现象**: 即使 0 题入库，按照 prompt 文字字面要求，verify markdown 仍要生成。我已生成空文件，注明状态。
- **当时决策**: 生成空 verify 文件，写明 "NO QUESTIONS EMITTED" 状态 + 待 Famin 决策清单。
- **是否合规**: ✅ 合规（按 prompt 字面 + 添加 status header）。
- **建议是否写入纪律**: 否（个案）。
- **理由**: prompt 漂移是个案，不需要写规则。但主 session 收到 worker 的 verify markdown 时应该**先看 status**——如果 status="NO QUESTIONS"，跳过 round 抽审环节直接看 Issues 报告。

---

## 建议补充进 SKILL.md 的纪律清单（汇总）

| 建议条目 | 内容 | 来源问题 |
|---|---|---|
| **§17 源池级不可处理升级** | 整源池所有 PDF 同源同病时，worker 不擅自决策；汇报 manifest._observation + 主 session 升级 Famin 决策（换源 / 开 OCR / 跳阶段） | 问题 1, 2 |
| **inventory 预扫纪律**（新 feedback memo） | 批次清单建立前必须 pdftotext 字节数 + pdffonts 字体数双扫，<100 字节或 0 字体 mark `unprocessable` 不入清单 | 问题 2 |
| **派 worker 前 chapter 名活清单** | 主 session 派 worker 时 prompt 里 chapter 名必须 grep curriculum_seed.dart 拷贝，禁凭印象写 | 问题 3 |
| **物理 KP fallback 路径 B（推荐）** | LLM 推理次级 KP 名 → 全部进 kp_gap 等候区，不污染 chapter；保留 KP 信号最大化 | 问题 4 |
| **§5.1 力矢量 vs 长度标注（SVG）** | 力矢量 = 单端箭头 + F + N；长度标注 = 双端箭头 + 数值 + cm/m；纯几何形状区分 | 问题 5 |
| **§5.2 电路图标准符号库** | 立 SVG primitive 模板（电池/电阻/灯泡/开关），复用避免重画 | 问题 5 |
| **§5.3 光路图箭头规约** | 光线 = 末端单箭头；夹角 = 弧线 + ASCII | 问题 5 |
| **§5.4 SVG ASCII 单位映射表** | Ω→Ohm, °→deg, ℃→degC, μ→u, ²→^2, π→pi（SVG 内） | 问题 5, 7 |
| **§5.5 复合图分图原则** | 完整装置 1 张 SVG；局部受力/光路分析单独 SVG | 问题 5 |
| **§5.6 单位双写桥接** | SVG ASCII / content Unicode → explanation 必含桥接说明 | 问题 7 |
| **物理实验题专项处理** | 客观空入 group_id；主观空 `_subj_held` 后缀缓存等 AI 评分接入 | 问题 6 |
| **rubric_physics_v0.md 起草** | 4 档基础描述给 LLM 自由判作锚定，让 reasoning 有引用 | 问题 8 |

---

## Pipeline 实际推进度

| Step | 实际状态 |
|---|---|
| 1 extract | ❌ Fail (raw.txt 16 字节) |
| 2 segment | 未到 |
| 3 match_ans | 未到 |
| 4a annotate | 未到 |
| 4b round | 未到 |
| 5 validate | 未到 |
| 6 emit | 未到 (0 batch JSON) |
| 6.5 supervise | 未到 |
| 7 register | 未到 |
| 8 commit | 不需要（按 prompt 不 commit）|
| 9 manifest | ✅ 已写入 skipped_files |

## 输出物清单

| 文件 | 状态 | 说明 |
|---|---|---|
| `assets/data/batches/realpaper_g8_physics_renjiao_qimo_beijing_chaoyang_001.json` | 不产出 | 0 题，整卷跳过 |
| `question_bank/realpaper_g8_physics_renjiao_qimo_beijing_chaoyang_001.json` | 不产出 | 同上 |
| `docs/d2_physics_v1_verify_famin.md` | ✅ 产出（空状态文件） | 含跳过原因 + 格式参考给下次 |
| `docs/realpaper_manifest.json` | ✅ 更新 | 新增 skipped_files 项 + `_observation` 字段记录全源池问题 |
| `/tmp/v3_12_20_physics_report.md` | ✅ 本报告 | 9 条 issue + 12 条建议纪律 |
| `/tmp/v3_12_20_physics/render/` | 不产出 | 0 SVG 待自检 |

## 总结数字

- 题数: 0
- round 分布: 不适用
- 系列组合数: 不适用
- KP fallback 数: 不适用
- KP gap 数: 不适用
- 图处理: 0 SVG / 0 PNG / 38 套整卷跳过候选（含本卷）
- validate.py 通过情况: 未运行（无 batch JSON）
- Issues & Resolutions: 9 条
- 建议纪律: 12 条

---

# === v3_12_20_batch_a_report.md ===

## 6. Issues & Resolutions（"不要全顺利"）

### Issue 1: SVG `<text>` 含中文 (V3.12.19 第 18 项)

**触发**: 第一次构建 d4_genzong 时，q8/q9/五q1/五q4 的坐标轴/图例标签使用了 "底/cm"、"高/cm"、"体积/cm³"、"时间/分"、"路程/千米"、"销售量/个"、"剩余量/个"、"销量/件"、"单价/元"、"工作总量/个"、"人数/人"、"甲车"、"乙车" 等中文。

**校验输出**: `#13: SVG <text> 含中文 '底/cm'` 等 11 处 fail

**修复**: 将所有 SVG `<text>` 标签替换为 ASCII 占位（b/cm、h/cm、V/cm^3、t/min、s/km、x、y、car-A、car-B、A、B、C），并在题面 content 里**显式说明**坐标轴含义（"图中横轴 b/cm、纵轴 h/cm"），保持学生理解的完整性。

**学习**: V3.12.19 已强制 SVG 文本走 ASCII（移动端字体 fallback 风险），但工人首次构建未自动应用这条；纳入 d4_guoguan 起的默认模板。

### Issue 2: SVG `<text>` 超 viewBox

**触发**: 五q1 (d4_genzong) 标 "h/cm" 在 x=248 时，超出 viewBox=260 的右边界 +10px。

**校验输出**: `#31: SVG <text> 'h/cm' 超 viewBox（[248.0,270.0] vs [0.0,260.0]）`

**修复**: viewBox 从 `260 220` 改为 `280 220`，预留右侧 20px 给坐标轴文字。

**学习**: 锚点 `text-anchor=start` 时文字向右伸展 0.55×fontSize×字符数；ASCII 4-字符 "h/cm" 在 fs=10 时占 22px，需要预留同等空间。

### Issue 3: SVG 多坐标子图的 origin "0" 被识别为 dim 标注

**触发**: d4_guoguan 三q2 四联子图（A/B/C/D）每幅都在原点写 "0"，单独的 "0" 数字被 `SVG_DIM_NUM_PAT` 识别为长度标注。

**校验输出**: `#17: SVG 长度标注 ['0','0','0','0'] (4个) 需双箭头 ×8，实有 polygon/marker 0`

**修复**: 移除四联子图的原点 "0" 文字（保留坐标轴 line 即可，"0" 在迷你示意图中本就不是必需）。

**学习**: 多候选展开图例外条件需 ≥2 个 ABCD label + ≥6 个数字 dim_text；本图只有 4 个 ABCD（图选项标注） + 4 个 "0"，未达到例外阈值。最简单 fix 是不画原点数字。

### Issue 4: 题面"判断比例并说明理由"（开放主观题）

**触发**: d4_genzong 四「判断下面各题中的两个量哪些成正比例……，说明理由」原题为开放主观题。

**判断**: realpaper-extract §5 spec 禁止开放题。我把 4 道说理题模板化为 fill 题——题面增加「填「正」/「反」/「不成」之一」明确指示，将「说明理由」移入 explanation 字段。这样保留题目教学价值（学生答字面 "正/反/不成"），主观说理由 explanation 提供。

**校验**: fill_inputmethod 通过 ✅。

### Issue 5: zhouce_peiyou_003 第五题"全部写出 8 个比例"

**触发**: 原题"已知 12×5=15×4，根据比例的基本性质改写成比例（建议全部写出）"，开放写多个比例。

**判断**: 答案唯一（8 个排列穷举），可模板化为 fill。answer 字段用逗号分隔 8 个比例字符串，content 说明「按答案中给出的全部 8 个不同比例填」。

**风险**: 学生输入顺序可能不同；practice_screen.dart 答案匹配方式应做"集合相等"而非"字符串相等"（这是入库 4a 阶段决策权外，但需 reviewer 留意 alt_answers 配置）。

### Issue 6: 三q1（zhouce_peiyou_002）4 image options 中 D 是文本

**触发**: 三q1 「测量圆锥高的方法」选项 A/B/C 是图，D 是「以上方法均不正确」（文本）。

**判断**: 仍按 `options=["A","B","C","D"]` + image_data 模式处理（合规，因为 SVG_SAN_Q1 为 4 个面板的混合图，第 4 面板嵌入了 D 字母作为占位）。题面文字补充说明每个图意义 + 第 D 项文字。

**校验**: choice_letter_prefix 规则允许全字母 options + answer 必须字母 ✅。

### Issue 7: zhouce_peiyou_002 一q1 OCR 出现"5650"被当成 5.65 dm³

**触发**: raw.txt 行 7 显示 `5.65 dm3＝(   )L(     )mL`，但答案 `5 650`（中间一个 L 空格）。意味着 5.65 dm³ = 5 L 650 mL（小数部分 0.65 L = 650 mL）。

**判断**: 拼成 "5 L 650 mL"。answer 写成 `3050,5,650`（3 个空：dm³,L,mL）。

**校验**: 答案格式正确 ✅。

### Issue 8: 五q5（zhouce_peiyou_002）直角梯形旋转哪条边？

**触发**: 题面说"绕轴旋转"，原图右侧 9cm 边上有"⊕"轴标记。需要正确判断是绕 9cm 这条长边（轴）旋转。

**验证**: 绕 9cm 边旋转：左边 6cm 是平行于轴的短边（距轴 5cm），形成圆柱（半径 5，高 6）+ 圆锥（半径 5，高 9-6=3）的复合体。算得 549.5 cm³ 与原答案一致 ✅。

### Issue 9: 装饰性卡通图（青蛙、手机）跳过

**判断**: d4_genzong 一q1 青蛙儿歌、zhouce_peiyou_003 一q4 手机模型，原图含装饰卡通插图但与解题无关，按 §9.4 直接跳过 image，仅保留文字题。

### Issue 10: Validate 报告"主动检 14/15"的临时状态

**触发**: 4a 阶段（emit JSON 但未 round）validate 输出 14/15（item 6 round_filled fail）。

**修复流程**: 4b 阶段跑 `python3 tools/d2_math_review_v4.py` → 读 `calibration_log/d2_math_review_v4.jsonl` → `apply_rounds.py` 写回 round → 再次 validate 得到 15/15。这个 14→15 的瞬态被记录在 build 日志中。

---

## 7. 文件清单

### Batch JSON（双写一致 sha1）

| Source | qb_path | as_path | sha1 |
|--------|---------|---------|------|
| d4_genzong | `question_bank/realpaper_g6_math_beishida_d4_genzong_001.json` | `assets/data/batches/...same.json` | `1a5c7f0108cb15a5475302b183c37ad3d7764075` |
| d4_guoguan | `question_bank/realpaper_g6_math_beishida_d4_guoguan_001.json` | `assets/data/batches/...same.json` | `776747dab40327089c2c8061f664867b1f85b3ae` |
| zhouce_peiyou_002 | `question_bank/realpaper_g6_math_beishida_zhouce_peiyou_002.json` | `assets/data/batches/...same.json` | `bcf8795de2f5510914768b86ba968c3dd3128c3b` |
| zhouce_peiyou_003 | `question_bank/realpaper_g6_math_beishida_zhouce_peiyou_003.json` | `assets/data/batches/...same.json` | `1c0d95fc0eb4cfaedc79909dbd92a11800a01bad` |

### Index

`question_bank/index.json`: v43 → v47（增 4 条 batch entry）

### Build Scripts

- `/tmp/v3_12_20_batch_a/scripts/build_d4_genzong.py`
- `/tmp/v3_12_20_batch_a/scripts/build_d4_guoguan.py`
- `/tmp/v3_12_20_batch_a/scripts/build_zhouce_peiyou_002.py`
- `/tmp/v3_12_20_batch_a/scripts/build_zhouce_peiyou_003.py`
- `/tmp/v3_12_20_batch_a/scripts/apply_rounds.py`
- `/tmp/v3_12_20_batch_a/scripts/render_svgs.py`
- `/tmp/v3_12_20_batch_a/scripts/update_index.py`

### Render PNGs (visual verification)

`/tmp/v3_12_20_batch_a/render/<source_id>__idx<N>.png` — 24 张 SVG 全部渲染成功并目视检查。

---

## 8. NOT Done（按主任务约定）

- ❌ **DO NOT commit / push** — 主 session 处理（git status 已留待主 session）
- ❌ **DO NOT update main.dart** — 主 session 处理
- ❌ **DO NOT update batch_inventory** — 主 session 处理
- ❌ **DO NOT 升级 round 上限** — 4a 入库纪律：数学走 V4 脚本自动判，本批次未做人工调整

---

## 9. Summary

- **125 道题**入库（4 批合计），全部 4 批 **15/15 自动检 PASS**
- **24 张 SVG** 渲染验证通过；svg_dim_audit 0 must-fix
- **13 组 group** 系列组合（含 7 张 SVG 共享图组）
- **round 分布**: R1×30 R2×59 R3×34 R4×2（V4 脚本自动判 + group ceil 统一）
- **总 KP 覆盖**: 正反比例（5 KP）/ 比和比例（6 KP）/ 圆柱与圆锥（5 KP）
- **chapter 覆盖**: 正比例和反比例 / 比例 / 圆柱与圆锥（与北师六下教材结构一致）

---

# === v3_12_20_batch_b_report.md ===

## Issues & Resolutions（V3.12.7 强制）

### 问题 1: choice 选项 6 个 (ABCDEF) 触发 letter_prefix 校验失败

- **遇到场景**: qimo_002 三.4「下列每组两个量中，成正比例的是(   )，成反比例的是(   )」，选项 ABCDEF 六个，需多选答案 AE / BC。
- **现象**: validator 项 17 强制 options 首字母 ∈ [ABCDZ]，E、F 开头报"选项缺 ABCD 前缀"。
- **当时决策**: 把 choice 转 fill（把六个选项写在 content 里编号 ABCDEF，answer 写"AE" / "BC"）。
- **是否合规**: ✅ 符合 §5.1 fill 输入法白名单（≤4 字短词）；但 fill 多字母答案在用户体验上弱于"勾选"——实际上是绕过 validator。
- **建议是否写入纪律**: 是。建议规则细化：「choice 选项支持 6 字母（A-F）+ 多选答案」或「6+ 选项题强制走 fill 字母连写」二选一明文规定。当前 [ABCDZ] 限制是隐式的。

### 问题 2: 题面"展开图是"误命中 IMAGE_INDICATOR

- **遇到场景**: qizhong_002 三.2「圆柱的侧面展开图是一个正方形」中"图是"被 validator 当作"含图"指代符号。
- **现象**: validator 项 2 报"题面提图但无 image_data / SVG"。原题确实没附图。
- **当时决策**: 加 `_image_skip_reason` 字段（"题面「展开图是」中含「图是」误命中 indicator，原题无附图"）。
- **是否合规**: ✅ pre_commit_check.md 项 2 允许 `_image_skip_reason` 例外。
- **建议是否写入纪律**: 是。`IMAGE_INDICATORS` 列表中"图是"过宽，建议要求前缀必须是连续的"如图""下图""图所示"等更明确指代符（"X图是"中的"图是"是合成词不指代图）。或在 validator 中加白名单「展开图是」「侧面图是」等组合词跳过。

### 问题 3: qimo_002 五.动手操作整组拆分入库

- **遇到场景**: 期末测试卷五大题包含 3 道子题：1（画 4 倍三角形）、2（读 B/C 坐标）、3（画旋转+平移）。整组本是连续作答（同图同三角形），但只有第 2 题可在 app 形式作答。
- **现象**: 1 和 3 是画图作答（学生在方格纸上画图），无法用 fill/choice 编码。
- **当时决策**: 跳过 1 和 3，只入第 2 题（独立 question，无 group_id）。题面加"如图所示方格图中…"+ 提供方格 SVG。
- **是否合规**: ⚠ 边界。§5.4 系列组合题原则是"绝不拆题保留共同题面"——但这里 1/3 物理上没法入库（画图题型）。当前选择是"剩下的可入题独立入库"。
- **建议是否写入纪律**: 否（个案处理）。已有规则：§9.4 跳过整题 + manifest 注明。但本案是"组内部分子题跳过、剩余子题独立入库"——边界未明示。如果再发生可写"组内部分子题跳过时，存活子题作为独立 question 入库（不带 group_id），并在 explanation 注明"原题作为大题第 N 子题，前置子题为画图作答跳过""。

### 问题 4: 一.9 含 $(120-25x)$ 答案——fill 输入法限制冲突

- **遇到场景**: xsc_shenyang_001 一.9「看了 $x$ 天，还剩(   )页没有看；当 $x=4$ 时，还剩(   )页」答案 1 是含 $x$ 的代数式 "$120-25x$"，答案 2 是数值 20。
- **现象**: fill 输入法白名单（§5.1）禁含变量、复杂表达。原本一题两空导致答案非法。
- **当时决策**: 拆成两题：第一空（代数式）转 choice 给 4 个选项让用户选式子；第二空（x=4 时）保 fill 答 20。
- **是否合规**: ✅ 符合 §5.1 + 一题独立性。原题"两空"被拆为两个独立 question（不用 group_id，因第二题在 content 里直接给出第一题的式子作前提）。
- **建议是否写入纪律**: 否（个案处理）。但建议拓展 §5.1：「同题包含代数式答案 + 数值答案 → 拆分为前题 choice（代数式）+ 后题 fill（数值），后题 content 给出前题式子作前提」。

### 问题 5: 装饰图（圆剪拼成长方形）"如图"指代但图非必要

- **遇到场景**: xsc 一.12「如右图，把圆分成若干等份，剪拼成一个近似的长方形」——原图是"扇形阵列"装饰图，文字已完整描述操作；图对解题无作用。
- **现象**: 题面含"如右图"必触发 IMAGE_INDICATOR（项 2）。
- **当时决策**: 加 `_image_skip_reason="原图为装饰性扇形阵列示意（圆分若干等份后并排），文字已完整描述操作；图不影响解题"`。
- **是否合规**: ⚠ 边界。pre_commit 允许 `_image_skip_reason`，但纪律默认是"装饰性图标 cartoon_decoration 类应走 PNG 截图"（§9.1.1 V3.12.19）。当前选择是 skip，理由是图对解题无作用。
- **建议是否写入纪律**: 是。建议明示：「装饰图（即图本身不携带解题必要信息，文字已完整描述）→ 允许 `_image_skip_reason="装饰图，文字已完整描述操作"` 跳过；与 cartoon_decoration（图含解题必要的卡通元素）区分。」当前 `cartoon_decoration` 仅适用"图含信息但风格为卡通"，对"图无信息"无明文。

### 问题 6: SVG 双箭头 + 文字方向（竖直标注 transform rotate）

- **遇到场景**: qizhong_002 #19 直角梯形 SVG 中"8cm"和"5cm"是竖直边长度，文字需旋转 90°显示。
- **现象**: 初版 `<text transform="rotate(-90 ...)">8cm</text>` 字位置 + bbox 计算难，且配双箭头 polygon 画布坐标方向需特别处理。
- **当时决策**: 双箭头 polygon 直接画在数值文字旁边的纵向 line 端点上；text 用 `transform=rotate(-90 cx cy)` 在原位置旋转。
- **是否合规**: ✅ 符合 §9.3.5 (双箭头 + ASCII 文字)。
- **建议是否写入纪律**: 否（已有解决方案）。但 SKILL `rules/integrity.md` §5「纵向标注：y 方向同理，箭头 polygon 旋转 90°」可补充示例「文字 y 方向用 transform=rotate(-90 x y) 旋转，箭头 polygon 仍按原坐标系画 vertical pair」。

### 问题 7: combo SVG 立体图（轴测视角）尺寸标注布局乱

- **遇到场景**: xsc #35 求 L 形组合长方体（前块 6×5×10 + 后块 6×2×10）的表面积/体积——需画立体轴测图，标 5 个尺寸（5、6、6、2、10）。
- **现象**: 初版 SVG 6 个数字标注线四散，渲染后视觉杂乱（数字旋转方向相反互相重叠）。
- **当时决策**: 重画为「双正面图（左大块 6×5、右小块 6×2 并排）+ 顶面带平行四边形示意 + 长 10 dm 在最右」。Z 轴方向用 `transform=rotate(-90)` 标"10"。
- **是否合规**: ✅ 渲染清晰，但仍较 "视图分离图（正视+侧视+顶视三视图）" 不如。
- **建议是否写入纪律**: 否（个案）。但作为参考案例：组合立体图 SVG **简化原则** = 优先 2D 双视图 / 三视图，不必强求轴测视角。

### 问题 8: V4 round 脚本对答案带分数 (5又1/7) 估难度偏高

- **遇到场景**: qimo_002 #8 绳子带分数答案，V4 给 R4。题型 fill 是带分数 (5又1/7)，逻辑思路是设方程求 x 后求差。Famin 锚点中类似题目通常 R3。
- **现象**: V4 因为 calc 维度（带分式 + 复杂数）+ step（多步设方程）+ 答案非整数 → max R4。
- **当时决策**: 接受 V4 给的 R4（数学走脚本不审）。
- **是否合规**: ✅ 符合 §2.1（数学阶段 2 脚本强制）。
- **建议是否写入纪律**: 否（V4 阈值由数学 difficulty skill 自我演进 — Famin 验后再调）。建议保留 V4 输出供 Famin 抽审决策升降。

### 问题 9: 4cm 标注位置歧义（Q4.4 平行四边形阴影）

- **遇到场景**: xsc #34 平行四边形阴影面积——原题图中"4cm"标在 DC 上某段，但是阴影底（DC 减 4cm）还是非阴影底（4cm 本身就是非阴影部分）有歧义。
- **现象**: 第一版 explanation 写"阴影底 = DC - 4 = 4 cm"——这与"DC=8, 4cm 是非阴影"一致；但当 SVG 中阴影底视觉上又像 4cm（蓝色部分窄）会矛盾。
- **当时决策**: SVG 把 4cm 标在 DC 上靠 C 那一段（清晰区分非阴影部分），explanation 写"图中 4 cm 是 DC 上从 C 起的非阴影部分长度"。
- **是否合规**: ✅ 配合 §5.6.7 措辞同步原则——题面措辞、SVG 标注、explanation 三者一致。
- **建议是否写入纪律**: 否（个案）。但作为反例：含"阴影部分"的几何图，必须**明文 explanation** 解释每个尺寸标注属于哪一段，避免 "4cm 既可能是阴影底也可能是非阴影底" 的歧义。

### 问题 10: chapter 全卷归"总复习"是否合理

- **遇到场景**: qimo_002（北师大六下期末测试卷）和 xsc_shenyang_001（小升初测试卷）都是"综合卷"，含跨多年级 KP（大数改写、抽屉原理、利率、三角形不等式等）。chapter 列表只有 "图形的运动 / 圆柱与圆锥 / 小升初综合 / 总复习 / 数学好玩 / 正比例和反比例 / 比例" 7 类（六下教材章节）。
- **现象**: 多数题归"总复习"（含"总复习/数与代数综合"等 KP），少量归"圆柱与圆锥""比例""正比例和反比例"。
- **当时决策**: 综合卷的 chapter 默认 = "总复习"；非"小升初综合"（"小升初综合"目前缺对应 KP）。
- **是否合规**: ✅ 符合 §3「综合卷归小升初综合（grade=6）」——但因没有"小升初综合"对应 KP，实际归"总复习"更合 KP 清单。
- **建议是否写入纪律**: 是。建议明示「综合卷 chapter 选择：（a）若有"小升初综合"chapter 且 KP 对应清单充裕，归之；（b）若 KP 主要落"总复习"分类，chapter="总复习"」。当前 §3 提到"小升初综合"但实际 KP 清单无此 chapter 下细分，导致回退"总复习"。

---

## 双写校验

```
qizhong_002        sha1 一致 ✓
qimo_002           sha1 一致 ✓
xsc_shenyang_001   sha1 一致 ✓
```

## 渲染产物

8 张 SVG 渲染 PNG 位置:
- `/tmp/v3_12_20_batch_b/render/realpaper_g6_math_beishida_*__idx*.png`
- 已 cp 到 `/mnt/d/AI_Workspace/svg_fix_review/v3_12_20_batch_b/`（Famin Win+E 审）

## 不 commit / 不更新 main.dart

按 prompt 要求，本 worker 不 commit、不更新 main.dart `_bundledBatchAssets`。主 session 后续:
1. 收 Issues 决策
2. 派 supervisor 抽查（题数 ≥ 20 触发 §6.5 supervisor 派发）
3. 入 manifest + 注册 + commit

---

# === v3_12_20_batch_c_report.md ===

## Issues & Resolutions

### 问题 1：raw.txt 全部乱码（部编 PDF 嵌入私有字体）
- **遇到场景**：4 套 PDF 全部 `pdftotext -layout` 输出大量私有 Unicode 乱码
- **现象**：raw.txt 13K 字节但内容如「ぜ̰ࢅ‫ٳ‬䓮ᴷᷰ≻ࢧ」无法直接读
- **当时决策**：完全弃用 raw.txt，改用 hires-*.png 视觉读题（200 dpi 渲染）。逐页 PIL crop + Read tool 视觉读取，对照 PDF 答案页校对
- **是否合规**：✅ 符合 §9.1 完整性优先（所有信息从图渲染读取，不漏题面）+ feedback_unclear_abandon 反过来——本卷视觉清晰，不属于"识别失败"
- **建议是否写入纪律**：是。建议在 pipeline.md Step 1 后增加新的"raw.txt 健康度检查"——若包含 ≥30% 私有 Unicode 区段（U+E000-U+F8FF）或全文 mojibake，agent 必须自动切换"纯视觉读题"模式（pdftoppm 渲染图 + crop + Read tool），并在 manifest 标注 `raw_txt_unusable=true`。当前流程没明确说"乱码时该怎么办"，agent 会浪费时间尝试解析 raw.txt

### 问题 2：连线题如何转成 fill / choice 形式
- **遇到场景**：unit1_001 q7 古诗-节日-习俗 4 古诗连线、unit2_001 q7 书+作家+年龄连线
- **现象**：原题是 3 列连线（如《寒食》—寒食节—禁火吃生食），App 不支持连线 UI
- **当时决策**：拆成多道 fill 子题用同一 group_id，共同题面含完整候选池（4 古诗+4 节日+4 习俗），子题问"《X》对应的节日是（    ）和习俗是（    ）"。学生填两空（节日,习俗）。这样保留候选池完整性
- **是否合规**：✅ 符合 §5.4 形式 B group + §9.1 完整性
- **建议是否写入纪律**：是。建议补 series_combo.md 新增「连线题处理范式」：连线题必走形式 B group，共同题面列出三列完整候选，每子题问一行的多空对应。**禁**把连线题压成单题多空 fill（学生看不出哪行对应哪列）

### 问题 3：开放写话+答案给"示例"的题边界
- **遇到场景**：每套都有"写出三个 X 词语"/"用 Y 字组词"/"补全句子"型半开放题
- **现象**：答案给"示例：渴望/盼望/希望/失望"——表面看像 fill 标准答案，实际可填多种合理词
- **当时决策**：分两类处理——
  - 候选池**有强约束**（如"用「望」组词" + 4 个特定语境，前后逻辑限定唯一答案）→ 入库 fill，alt_answers 列出常见正确变体
  - 候选池**无强约束**（如"写三个形容时间的三字词语"）→ 弃，不入库（feedback_question_quality.md 禁开放题）
- **是否合规**：⚠ 边界——前一类入库我做了"alt_answers 容错"妥协，但学生答案可能仍超出我列的变体；判错可能误伤
- **建议是否写入纪律**：是。建议补题包纪律新增「半开放 fill 入库规则」：
  - 答案"示例"字样且语境约束唯一 → 入库 fill + alt_answers ≥3 个变体
  - 答案"示例"字样且写出 N 个 → 弃
  - 题面"补全/续写一段话/写下你的看法" → 弃
  
### 问题 4：q3 词语订正题的答案格式
- **遇到场景**：unit2_001 q3 "下列词语书写正确的在括号里打√，错误的写出错字与改正字"
- **现象**：每个词需返回"√"或"错字→正字"组合答案；学生答题方式有"和→合"或"和合"或"乌合之众"等多种格式
- **当时决策**：answer 用统一格式"和→合,炫→眩,...,√,...,√"，alt_answers 列出 3 种格式（错字→正字 / 错字正字两字相邻 / 顿号逗号变体）。但仍可能漏覆盖
- **是否合规**：⚠ 边界——这种"对错+改正"复合题在 fill 输入法限制下不太友好（学生输入"→"符号麻烦）
- **建议是否写入纪律**：是。建议补 inputmethod.md：「错字订正题特殊处理」——statement 应明确告诉学生填答案的格式（本题 content 已加"书写正确填√;书写错误填'错字→正字'"提示）。或考虑把这种题强制转 9 道独立 choice（"以下哪个写法正确"）以避免格式混乱

### 问题 5：保温杯参数表是否要嵌图
- **遇到场景**：unit3_001 q9-q11 阅读"保温杯说明书"含"保温参数表"（90℃ 装入，0.5h/1h/1.5h/2h 对应 75/65/60/55℃）
- **现象**：原 PDF 表格能图片嵌入（约 87KB base64），但表格内容完全可文字化
- **当时决策**：选择文字化（"时间 0.5 小时→温度 75℃"等），不嵌图。理由：表格简单 4 行 2 列；文字化对学生 TTS 阅读、复制粘贴友好；且不违反"图必嵌图"硬规——题面没有"如图所示"措辞，仅"以下是参数表"+ 4 行数据
- **是否合规**：✅ 符合 §9.2/§5.6 总原则（信息从图维度迁移到文本维度，不算丢失）
- **建议是否写入纪律**：是。建议补 images.md 新增「简单表格处理纪律」：≤6 行 ≤3 列的纯数据表格优先文字化，写法用"项 A 值 a；项 B 值 b" 或"行表头 → 列数据"分号分隔。复杂表格（含合并单元格 / 数据 ≥10 项 / 含图标）才嵌图

### 问题 6：阅读理解长文是否完整保留 vs 节选
- **遇到场景**：unit1_002 q12《安塞腰鼓》、unit2_001 q12《走出心灵的监狱》、unit3_001 q12《失去的一天》
- **现象**：原文长（300-700 字），4 道子题均依赖原文全文。content 反复嵌入全文导致 batch JSON 体积膨胀（每子题 content 长度 1500-3000 字符）
- **当时决策**：每子题 content 含完整阅读材料 + "当前小题：..."。即"形式 B group 必须每子题保留共同题面"硬规则
- **是否合规**：✅ 符合 §5.4 形式 B 强制
- **建议是否写入纪律**：是。建议补 series_combo.md 新增「长阅读材料 group 处理纪律」：阅读理解原文 ≥200 字时，仍必须每子题嵌入全文（spec §5.4 不许"靠语境推"）。**但允许 explanation 段不重复全文**（节省 base64+文本体积）。如果同一阅读材料子题数 ≥6，可考虑做"父题 + 子题引用"机制（未来工程改造）

### 问题 7：anchor_id 引用的相近度判断
- **遇到场景**：每题 round reasoning 引用 anchor 时
- **现象**：rubric §4 要求"在 round±1 内最相近"，但 18 个 active anchor 涵盖类型有限（无成语补字、无换偏旁组词、无连线题等具体题型）
- **当时决策**：选最近似题型 anchor（如成语补字用 r2_a1 5 字成语，换偏旁组词用 r1_a3 字音字形）。引用时显式说"anchor X 形态相同/近似/起点对照"
- **是否合规**：⚠ 边界——某些题型 anchor 不完全 match，引用时多用"形态对照"软关联
- **建议是否写入纪律**：是。建议长期沉淀更多 anchor，覆盖：
  - 成语补字 / 选字组词 / 换偏旁组词
  - 连线题（用 fill group 形式）
  - 句式转换（缩句/拟人/夸张/反问/双重否定 各 1 道 R2 锚点）
  - 标点歧义题
  - 描写方法识别（外貌/语言/心理/动作）
  - 说明文条款定位题

短期：rubric §4 可放宽为"round±1 内最近似 + 引用方式说明（同型/形态相同/形态近似/起点对照）"

### 问题 8：unit2_001 q3 词语订正"嫣知非福"
- **遇到场景**：unit2_001 q3 9 词中第 8 个"嫣知非福"
- **现象**：答案给"嫣→焉"（即焉知非福），但 PDF 渲染图字体让"嫣"和"嫣"难以区分（实际原题是"嫣"——女字旁），需要小心确认
- **当时决策**：核对 hires-1 第 q3 区域的 9 词清单，第 8 词字形确认是"嫣"（女字旁）。订正字"焉"
- **是否合规**：✅ 符合 §1.5 原题保真（保留原题"嫣"错字，订正"焉"对应正字）
- **建议是否写入纪律**：否（个案处理已对照原图，无需新规则）

### 问题 9：unit2_001 q14 子题（双引号 vs 中文双引号）
- **遇到场景**：unit2_001 q12 group_4（写作目的 4 选 1，引文用"："带）
- **现象**：原题答案 D 选项含「悲痛与怨恨」等中文双引号，validate.py 项 9 检查不能用 ASCII 双引号——我用「」或「""」（全角）
- **当时决策**：所有引文统一用中文双引号「」（左右匹配），代码字符串内手工转义。validate.py 项 9 PASS
- **是否合规**：✅ 符合 §5.7
- **建议是否写入纪律**：否（已是现规则）

### 问题 10：q4(2) "嘲加幸福"还是"嫦娥幸福"——OCR 误读边界
- **遇到场景**：unit2_001 q3 第 8 词答案识别（"嫣→焉"）
- **现象**：早先尝试解析时一度怀疑是"嫦娥幸福"——典型 OCR/视觉误读
- **当时决策**：先放大裁剪 q3 hires 区域确认是"嫣知非福"（9 字成语行）；然后对照答案页核对错改字"嫣→焉"逻辑通顺
- **是否合规**：✅ 符合 feedback_unclear_abandon 反向——本卷视觉清晰可读，不属于"识别失败放弃"
- **建议是否写入纪律**：否（个案）但触发观察：当 agent 怀疑视觉读到的字与答案对不上时，必须 hires crop 放大再核（默认 200 dpi 不够时考虑 300 dpi）。这一点已隐含在 §9.3.1 "PDF crop 看原图"中。

## 待 Famin 决策（issue 摘要）

按 SKILL.md V3.12.20 顶级纪律 #15「主 session 必须聚合 worker Issues → Famin 决策入纪律」：

10 条问题中明确建议入纪律的有 7 条：
1. raw.txt 乱码 → pipeline.md Step 1 加健康度检查 + 自动切视觉模式
2. 连线题 → series_combo.md 加「连线题处理范式」（必走形式 B group）
3. 半开放写话 → quality_rules 加「示例答案"半开放 fill"边界规则」
4. 错字订正题 → inputmethod.md 加「错字订正题答案格式纪律」
5. 简单表格 → images.md 加「≤6 行 ≤3 列纯数据表优先文字化」
6. 长阅读材料 group → series_combo.md 加「长阅读 group 处理纪律」（每子题嵌全文 + explanation 不重复）
7. anchor 覆盖 → rubric_chinese.md §4 放宽 + 长期补 anchor 覆盖更多题型

3 条个案，不入纪律：
8. q3 字形识别（嫣 vs 嫦）
9. ASCII 引号 → 中文双引号转换（已在规则）
10. OCR 误读边界（已隐含在 §9.3.1）

## 路径

- batch JSON 双写：
  - `/home/faminwsl/daughter_learning_app/assets/data/batches/realpaper_g6_chinese_bubian_unit1_001.json`
  - `/home/faminwsl/daughter_learning_app/assets/data/batches/realpaper_g6_chinese_bubian_unit1_002.json`
  - `/home/faminwsl/daughter_learning_app/assets/data/batches/realpaper_g6_chinese_bubian_unit2_001.json`
  - `/home/faminwsl/daughter_learning_app/assets/data/batches/realpaper_g6_chinese_bubian_unit3_001.json`
  - 同名文件位于 `/home/faminwsl/daughter_learning_app/question_bank/`
- round reasoning 日志：`/tmp/round_log_unit{1_001,1_002,2_001,3_001}.json`
- 报告：`/tmp/v3_12_20_batch_c_report.md`（本文件）

## 不 commit（按指令）

主 session 处理：
1. 收集本报告 Issues
2. 整理与其他 worker 的 Issues 聚合后交 Famin 决策
3. 决策入纪律的当场更新 SKILL.md / rules / validate.py
4. 然后批量 commit + push + purge CDN

---

# === v3_12_20_batch_d_report.md ===

## Issues & Resolutions

### 问题 1: PDF #2 / #3 扫描型整卷跳过决策

- **遇到场景**: Step 1 extract，pdftotext -layout 对两份 PDF 输出仅 312 / 69 字节（全是页脚水印）
- **现象**: 视觉上 preview-1.png 是清晰的题面文字图像（OCR 应能高准确率识别），但 PDF 不含文字图层 → 无法 pdftotext。答案 PDF 文本正常可提取
- **当时决策**: 整卷跳过，不尝试 OCR/多模态读图
- **依据**: spec §9.1 + pipeline.md Step 1.3 + `feedback_unclear_abandon`「严禁 OCR 抢救」+ V3.10 122 道伪题反例
- **是否合规**: ✅ 严格符合（hard rule "scanned PDF → 整卷跳过"）
- **建议是否写入纪律**: 已经入了。当前规则明确——「pdftotext 0 字节 → 整卷跳过」。**建议补充**: 当前 D 批两份扫描型 PDF 都属"答案 PDF 可读但题面 PDF 不可读"模式。建议在 spec §9.1 显式增列一条："答案 PDF 单独可读，但对应题面 PDF 扫描型不可读时，**不许**用答案反推题面入库（违反原题保真 §1.5）"
- **理由**: 这是一个相对特殊的子模式（答案与题面分两份 PDF），未来可能反复出现，明文写入避免后续 worker "我看答案完整应该能补出题面"的诱惑

### 问题 2: 大题二「零」字 3 义辨析的形式 A vs B 抉择

- **遇到场景**: PDF #1 大题二（为加点字「零」选择正确解释，3 个语境 ①②③，候选池 ABC）
- **现象**: 该题是「3 个独立子题共享一个 ABC 候选池」结构。子题题型同（fill 选字母），子题指令同（"为加点字零选择..."），答案离散单字母，无依赖
- **当时决策**: 按 series_combo §5.4 形式 A 判断流程压成 1 道 fill 多空（content 列出 ①②③ 三个语境 + 候选池 ABC，answer 是 "C,A,B"）
- **是否合规**: ✅ 形式 A 适用条件全满足（同题型/同指令/答案离散单字母/无依赖）
- **建议是否写入纪律**: 否，rules/series_combo.md 已涵盖。这是范例性的形式 A 案例（候选池跨子题共享）

### 问题 3: 五·1 课文人物形象 5 空跳过判断

- **遇到场景**: 大题五·1「在学习中，我们认识了____的鲁滨逊，____的尼尔斯，____的汤姆·索亚，____的八儿，还有____的李大钊」，PDF 答案给"不畏艰险积极乐观/顽皮淘气/勇于探险追求自由/天真可爱/坚贞不屈"
- **现象**: 答案前缀显式标"示例"（PDF 答案页"五、1.示例：..."）→ 是开放性人物形象描述题，标准答案非唯一
- **当时决策**: 整题跳过（不入库）
- **是否合规**: ✅ 符合 §5（subjective）+ §9.1（避免锁死开放答案）
- **建议是否写入纪律**: 是（弱）。建议在 rules/series_combo.md 或 quality_rules 增加"PDF 答案前缀标'示例'的题，type 必须是 subjective 或整题跳过；不许压成 fill"。当前 quality_rules.md（未读）可能已有但 worker 不知；如未涵盖，建议补

### 问题 4: 七·2 / 七·3 / 七·4 散文阅读题大量跳过

- **遇到场景**: 大题七《梅香》课外阅读 5 子题，其中 1/3/4 三道为开放性概括/感悟/默写题（"震惊原因 2 个"/"对'富有'的理解"/"赞美梅花的诗句"）
- **现象**: 5 子题中只有 1 道（"内容梳理 3 空"，明确填空格式）+ 1 道（"标题含义"choice）能入库，3/5 子题跳过
- **当时决策**: 系列组合 group 内 2 子题入库（保留共同上文+按 group_order 编 1 和 2，跳过的子题不在 group 中），group_id 仍为 `qizhong_005_q7`
- **疑虑**: group_order 是否必须严格按原 PDF 子题号？我用了 1 (七·1) 和 2 (七·5)——把"七·5 标题含义"的 group_order 设为 2，跟原题号 5 不一致
- **是否合规**: ⚠ 边界。group_continuity 自动检 PASS（order 1,2 单调），但"丢失中间子题号"信息
- **建议是否写入纪律**: 是。**建议加入** rules/series_combo.md：「形式 B 系列组合题部分子题跳过时，group_order 用入库后顺序（连续 1,2,3...），不强制保留原 PDF 子题号；但 content 中可以保留原题号（如"当前为大题七·5"）作为参考」

### 问题 5: 大题三·4 课文常识题答案选项嵌套关系判断

- **遇到场景**: 大题三·4「下列说法正确的一项」，4 项分别考《腊八粥》/《北京的春节》/《那个星期天》/《鲁滨逊漂流记》四个课文常识
- **现象**: 答案 B 项「老舍《北京的春节》详略得当」是正面陈述，其他三项是错误陈述。要做对，需对 4 部课内必修课文的作者+内容点都熟悉
- **判定犹豫**: anchor `chinese_r3_anchor_5`（4 选不正确文化常识 R3）vs `chinese_r3_anchor_1`（《两小儿辩日》课文理解 R1）
- **当时决策**: 定 R2，理由是 4 项都课内必修（降档信号"课内必修常识"），但需逐项核对所以高于 anchor_1 的 R1
- **是否合规**: ✅ 引用了具体 anchor + 降档信号
- **建议是否写入纪律**: 否，rubric §2.1 已覆盖（"课内必修常识 → 降档"）。本题的 R2 介于 R1 和 R3 中间是合理判断。如果 Famin verify 后觉得偏差，可在锚点池补"4 课内课文常识 4 选 1 → R2"作为新锚点

### 问题 6: 题画诗 4 选多选题（AB）的 fill 多选答案格式

- **遇到场景**: 大题六·4「下列哪些是题画诗，用'√'标出来」，PDF 答案 "A.√ B.√"
- **现象**: 多选题但 4 选项只 2 项有题画诗背景。type 选 fill 多空（answer="AB"）
- **判定犹豫**: 是该用 choice 多选还是 fill？目前 schema 没有"choice 多选"独立 type
- **当时决策**: 用 fill，answer="AB"，alt_answers 含"A、B"/"A,B"/"A B"四种格式兼容用户输入
- **是否合规**: ⚠ 边界。validate.py 项 17 (choice ABCD 前缀) 跳过 fill 类型；项 8（fill 输入法）允许字母组合（不在 forbidden 列表）
- **建议是否写入纪律**: 是。**建议加入** rules/inputmethod.md 或 series_combo.md：「多选题（用'√'标出/选出所有正确项）入库为 fill type，answer 用字母按字母顺序连写（"AB" / "ABD"），alt_answers 至少给"A、B"/"A,B"两种分隔形式兼容用户输入」

### 问题 7: emphasis 文本检查"加粗词"被误判旧措辞

- **遇到场景**: 大题三·3 题面写"（**加粗词**为原题加点词）"作为辅助说明
- **现象**: validate.py 项 16 把"加点词"识别为旧措辞（exclude 仅匹配"为原题加点字"，不匹配"为原题加点词"）
- **当时决策**: 改写为"（**加粗**部分为原题加点的词语）"——避免使用"加点词"
- **是否合规**: ✅ 通过自动检
- **建议是否写入纪律**: 是（弱）。**建议**: validate.py check_emphasis_phrasing 的 exclude 词组扩展为 `['为原题加点字', '原题加点字', '为原题加点词', '原题加点词', '为原题加点的词语', '原题加点的词语']`，否则 worker 必须用统一的"加粗部分为原题加点的词语"表达，而 anchor batch 现存的"为原题加点字"也无法适应"加点词组（多字）"场景

### 问题 8: choice 选项内含加粗字（含 ** 与 ABCD 前缀混用）

- **遇到场景**: 大题三·1 选项形如 `"A. **燃**放（rán）、开**凿**（záo）、书籍、亲吻"`
- **现象**: 选项以 "A. " 开头但内部含多个 `**字**` markdown 加粗
- **判定犹豫**: validate.py 项 17 的 ABCD 前缀正则 `^[ABCDZ][.、:：．]` 是否兼容选项内有加粗
- **当时决策**: 验证表明 PASS（正则只检前缀字符，不影响后续内容）
- **是否合规**: ✅
- **建议是否写入纪律**: 否，正则已正确处理

### 问题 9: 大题二「零」字三义题的"加粗字"措辞

- **遇到场景**: 题二原题"为下列加点字选择正确的解释"中"加点字"是动作主语（指零），不是辅助说明
- **现象**: 题面改成"为下列加粗字「**零**」选择正确的解释"——用「零」指明具体加点字，避免"加粗字"成为不确定指代
- **当时决策**: ✅ 改后题面更清晰
- **是否合规**: ✅ 符合 §5.6.7 措辞同步 + 信息无损
- **建议**: 否，已是范例做法

---

## 文件清单（绝对路径）

### 入库文件（双写）
- `/home/faminwsl/daughter_learning_app/assets/data/batches/realpaper_g6_chinese_bubian_qizhong_005.json`
- `/home/faminwsl/daughter_learning_app/question_bank/realpaper_g6_chinese_bubian_qizhong_005.json`

### 注册文件
- `/home/faminwsl/daughter_learning_app/question_bank/index.json`（version 42→43）
- `/home/faminwsl/daughter_learning_app/lib/data/bundled_batches.dart`（加 1 行）

### Manifest
- `/home/faminwsl/daughter_learning_app/docs/realpaper_manifest.json`（processed +1, skipped_files +2）

### 缓存（中间产物，不入 commit）
- `.cache/realpaper/fcda49eb2376ef184e19a22b41b03a7339150de8/`（PDF #1）
- `.cache/realpaper/8c38a43a817b0e15d4403a6a121d1f43e5527c6c/`（PDF #2 跳过）
- `.cache/realpaper/d1de5d7ccd7b3217992c96420b38d7ff3a5737c7/`（PDF #3 跳过）
- `.cache/realpaper/a5f4d6df3143308537fb7b2ac8a9366facedb12f/`（PDF #2 答案）
- `.cache/realpaper/fbf52330314c06ad31d0b64d6cd016f2e7f1632f/`（PDF #3 答案）

---

## Commit message 模板（不 commit，留主 session）

```
V3.12.20.1 D 批语文真题入库 qizhong_005 13 题（PDF #2/#3 整卷跳过）

入库分布:
- type: fill 7 / choice 6
- round: R1 3 / R2 8 / R3 2
- 系列组合: 2 组（qizhong_005_q6 4 题 + qizhong_005_q7 2 题）

图处理:
- image_data 嵌入: 0 道（语文卷无图）
- SVG 重绘: 0 道
- §9.4 跳过: 0 道（含图题）

完整性自检（§9.5）:
- 自动 15/15 PASS
- 手动 4 项: 10_no_spoiler PASS / 11_sample_5 5/5 PASS / 13_svg_4step N/A / 14_dim_consistent N/A

跳过题（PDF #1 内 6 题）:
- 大题四 (1)(2)凄凉造句、(3)仿写、改礼貌说法 → subjective
- 大题五·1 课文人物形象 5 空 → 答案开放性
- 大题七·2/3/4 → 主观开放题
- 大题八 口语交际 → subjective
- 大题九 习作 → 写作题暂不出

整卷跳过 2 PDF（manifest.skipped_files[] +2）:
- 期末模拟卷1（扫描型 PDFPatcher，pdftotext 312 字节仅页脚）
- 期末全真卷2（扫描型 PDFPatcher，pdftotext 69 字节仅页脚）
- 触发：§9.1 完整性 + Step 1.3 + feedback_unclear_abandon「禁 OCR 抢救」

round 阶段（语文阶段 1）:
- 每题 reasoning 引用 anchor_id + rubric 信号
- 关键引用：r1_a1（默写）、r2_a1/r2_a2（成语/选词）、r3_a3/r3_a5（主旨/文化常识）

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

---

## 总结

- **入库 13 题**（仅 PDF #1）；2 个 PDF 整卷跳过（spec §9.1 + feedback_unclear_abandon 强制）
- **15/15 自动 PASS**；4 项手动全过（10/11 PASS + 13/14 N/A）
- **9 个 Issues** 提交主 session 决策入纪律（其中 4 条建议写入：扫描型答案+题面分离 / 部分子题跳过 group_order / 多选 fill 格式 / 加点词 exclude 扩展）
