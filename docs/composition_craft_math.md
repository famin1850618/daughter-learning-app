# 命题艺术 — 数学（Composition Craft）

> **状态：** V3.12 立项 O9 task（2026-05-08）。本文件是 Layer 2 命题艺术的结构化沉淀，用于未来 AI 出题（错题变体 / 冷门章节补题 / cron 重启）。
>
> **当前（V3.12 D2+O10 合并 reviewer 完成 2026-05-08）：** patterns 数组已填充 37 个 pattern_id（数学 1010 道真题逆向提炼；每 pattern ≥ 3 道真题样例。详见 `calibration_log/d2_math_review.jsonl`）
>
> **协同文档：** `realpaper_observations_math.md`（工程坑层）/ `skill_composition_template.md`（schema）/ `realpaper_quality_rules.md`（质量原则）

## 用途与读者

本文件的读者：**未来 AI 出题 agent**（错题反馈生成同 KP 变体 / 冷门章节补题 / cron 重启时出题）。
- **必读时机**：任何数学出题 agent 启动前 cat 本文件
- **不读后果**：AI 生成题质量崩溃（V3.7 cron 时代教训）
- **应用方式**：按 `kp` 找匹配 `pattern_id` → 用 `ai_template` 参数随机生成 → 套 `distractor_design` 做选项 → self-check `r{N}_features` 描述

## Schema 说明

每个 pattern 是一个题型范式（"圆柱表面积·包装类"、"比例尺与实际距离"），包含：

| 字段 | 类型 | 说明 |
|------|------|------|
| `pattern_id` | string | 唯一 ID（蛇形小写英文）|
| `pattern_name` | string | 中文短名 |
| `kp` | string | KP 路径（严格匹配 knowledge_points_seed.dart）|
| `chapter` | string | 章节归属 |
| `typical_form` | string | 典型形态描述（一句话）|
| `rounds_seen` | int[] | 已观察到的 round 档位 |
| `r1_features` | string | R1 档此模式的特征（数据简单 / 1 步 / 选项明显错）|
| `r2_features` | string | R2 档特征（多 1 步 / 单位换算 / 近似值干扰）|
| `r3_features` | string | R3 档特征（隐藏条件 / 跨概念 / 部分对陷阱）|
| `r4_features` | string | R4 档特征（思维拓展 / 反证 / 跨章节）|
| `distractor_design` | string[] | 干扰项策略列表（按真题逆向提炼）|
| `real_examples` | string[] | 真题样例引用（"realpaper_g6_math_*#index"）|
| `ai_template` | string | AI 生成参数空间 + 公式骨架 |
| `latex_pattern` | string | 关键公式 LaTeX（双反斜杠 JSON 形式）|
| `common_pitfalls` | string[] | 出题陷阱（如"忘 ×2 / 忘 +底面"）|

## 与难度系统协同

`r{N}_features` 段是 **difficulty-math skill 的 anchors.json reasoning 段**的雏形：
- D1（锚点题）的 reasoning 段 = 本 craft 的 r{N}_features 升级版
- O10 提炼 pattern 时，可借 D1 锚点题的 reasoning 作为种子

## Patterns 数组（待 O10 填充）

```json
{
  "subject": "math",
  "grade": 6,
  "schema_version": "0.1.0",
  "patterns": [
    {
      "pattern_id": "cylinder_cut_surface_change",
      "pattern_name": "圆柱锯/截·表面积变化",
      "kp": "圆柱与圆锥/圆柱的表面积",
      "chapter": "圆柱与圆锥",
      "typical_form": "把圆柱形木料锯/截成 N 段（沿底面），表面积增加多少；或截短一段表面积/体积减少多少",
      "rounds_seen": [2, 3],
      "r1_features": "整数 N 段、整数底面积，直接套'增加=2(N-1)·底面积'",
      "r2_features": "反求底面积/底面半径（已知增加表面积反推 r 或 S底）；含 π=3.14 整数运算",
      "r3_features": "同时求多个量（表面积减少 + 体积减少），双输出且需识别'减侧面积=2πr·Δh'",
      "r4_features": "结合切割方向变化（沿轴竖切产生矩形截面 vs 沿底面横锯）多步推理",
      "distractor_design": [
        "锯成 N 段忘记是 (N-1) 个新切口（多算 1 个）",
        "每个切口忘乘 2（只算 1 个新底面）",
        "把'表面积增加'与'侧面积增加'混淆",
        "底面积反求时忘除以新切面数"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_d1_guoguan_001#9",
        "realpaper_g6_math_beishida_kaodian_guoguan_003#7",
        "realpaper_g6_math_beishida_kaodian_guoguan_003#20",
        "realpaper_g6_math_beishida_kaodian_guoguan_004#7"
      ],
      "ai_template": "r ∈ {1,2,3,5}, h ∈ {6,8,10,15} dm/cm, N段 ∈ {2,3,4,5}, 情境 ∈ {木料/金属棒/水管}, 单位 ∈ {cm,dm,m}, 输出形态 ∈ {求增加面积|反求底面积|减少体积+减少表面积双填}",
      "latex_pattern": "$\\Delta S = 2(N-1)\\pi r^{2}$",
      "common_pitfalls": [
        "切口数 N-1 而非 N",
        "忘乘 2",
        "侧面积/表面积混淆",
        "单位 cm² ↔ dm² 换算"
      ]
    },
    {
      "pattern_id": "cylinder_open_surface",
      "pattern_name": "无盖/通风管圆柱·表面积",
      "kp": "圆柱与圆锥/圆柱的表面积",
      "chapter": "圆柱与圆锥",
      "typical_form": "做无盖水桶 / 通风管 / 滚动一周，求需多少铁皮 / 滚过面积",
      "rounds_seen": [1, 2, 3],
      "r1_features": "概念辨析（'无盖=侧面+1底' vs '通风管=只侧面'），无运算",
      "r2_features": "代入数值算面积；含 cm↔m 单位换算",
      "r3_features": "情境隐藏'开口'信息，需要从应用场景推断（如'做笔筒'隐含上面开口）",
      "r4_features": "结合材料损耗率 / 接缝预留等真实工程参数",
      "distractor_design": [
        "选项给'侧面积+2底面积'（当成封闭圆柱）",
        "选项给'只侧面积'（适用于通风管而非水桶）",
        "单位换算错（cm² 没转 m²）",
        "忽略'至少需要'的最优含义"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_d1_genzong_001#3",
        "realpaper_g6_math_beishida_d1_genzong_001#12",
        "realpaper_g6_math_beishida_d1_genzong_001#20",
        "realpaper_g6_math_beishida_d1_guoguan_001#17"
      ],
      "ai_template": "r 或 d ∈ {0.1,5,10,20} (m或cm), h ∈ {0.5,4,8,50}, 情境 ∈ {无盖水桶/通风管/铁皮笔筒/烟囱/滚筒}, 单位陷阱开关 ∈ {true|false}",
      "latex_pattern": "$S_{无盖}=2\\pi rh+\\pi r^{2}$ ; $S_{通风管}=2\\pi rh$",
      "common_pitfalls": [
        "把无盖当封闭",
        "单位换算 cm↔m",
        "滚动一周面积=侧面积易当表面积"
      ]
    },
    {
      "pattern_id": "cylinder_packaging_choice",
      "pattern_name": "圆柱包装/油漆/铁皮·选择题",
      "kp": "圆柱与圆锥/圆柱的表面积",
      "chapter": "圆柱与圆锥",
      "typical_form": "选择题：做某物件至少需要多少铁皮/油漆/包装纸",
      "rounds_seen": [1, 2, 3],
      "r1_features": "纯概念辨析（求底+侧面积配置）",
      "r2_features": "数值代入 + 含单位换算的计算",
      "r3_features": "选项中含 4 个数量级（1.256/12.56/125.6/1256）逼考生算清楚",
      "r4_features": "复合需求（圆柱+圆锥+长方体一起包装），计算 + 比较选项策略",
      "distractor_design": [
        "选项含完全相同数字但不同小数位（单位换算陷阱）",
        "选项有'侧面积+2底面积'数值（当成封闭）",
        "选项给'只侧面积'数值（通风管误用为水桶）",
        "选项给'πr²+πrh'（漏×2）"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_d1_genzong_001#12",
        "realpaper_g6_math_beishida_d1_guoguan_001#17",
        "realpaper_g6_math_beishida_d1_guoguan_001#26",
        "realpaper_g6_math_beishida_zhouce_peiyou_001#16"
      ],
      "ai_template": "r ∈ {2,5,10}, h ∈ {4,8,15}, 单位组 ∈ {(cm,m),(dm,m)}, 选项数量级 ∈ {4 个差 10 倍}",
      "latex_pattern": "$S=2\\pi r^{2}+2\\pi rh$",
      "common_pitfalls": [
        "单位换算",
        "底面计入次数",
        "通风管/无盖识别"
      ]
    },
    {
      "pattern_id": "cylinder_water_displacement",
      "pattern_name": "圆柱容器·浸入物体水位上升",
      "kp": "圆柱与圆锥/圆柱的体积",
      "chapter": "圆柱与圆锥",
      "typical_form": "在装水圆柱形容器里放入石头/铁块，水面上升 h cm，求物体体积",
      "rounds_seen": [2],
      "r1_features": "直接套 V物 = πr²·Δh，整数易算",
      "r2_features": "需要 d↔r 换算 + π=3.14 计算",
      "r3_features": "结合'物体露出水面'或'部分浸入'情境（实际体积≠水位变化）",
      "r4_features": "结合密度/质量计算物体重量",
      "distractor_design": [
        "用容器整体体积代替 Δ高×底面积",
        "忘记 d→r 减半",
        "把'上升'当成'最终水位'"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_d1_genzong_001#21",
        "realpaper_g6_math_beishida_d1_guoguan_001#29",
        "realpaper_g6_math_beishida_kaodian_guoguan_003#8"
      ],
      "ai_template": "d ∈ {10,16,20} cm, Δh ∈ {0.5,1,3} cm, 物体 ∈ {石头/铁块/铜块}, 输出 ∈ {V物 | V物+m=ρV}",
      "latex_pattern": "$V_{物}=\\pi r^{2}\\cdot\\Delta h$",
      "common_pitfalls": [
        "d/r 混淆",
        "上升量 vs 最终高",
        "单位 cm³↔mL"
      ]
    },
    {
      "pattern_id": "cylinder_max_in_box",
      "pattern_name": "长方体/正方体内最大圆柱·体积",
      "kp": "圆柱与圆锥/圆柱的体积",
      "chapter": "圆柱与圆锥",
      "typical_form": "把棱长/长宽 a 的长方体（正方体）削成最大圆柱，求体积",
      "rounds_seen": [1, 2, 3],
      "r1_features": "正方体棱长直接给，d=棱长, h=棱长",
      "r2_features": "识别'底面 d=正方形边'隐藏几何关系，计算 πr²h",
      "r3_features": "长方体多组边长（按比给）需选哪两个作底直径/高",
      "r4_features": "比较两种围法（横/竖）哪种圆柱体积更大",
      "distractor_design": [
        "选项 = 正方体本身体积（没削）",
        "把直径当半径算（V 多 4 倍）",
        "把比例边长用错对应"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_mokuai_kongjian_001#20",
        "realpaper_g6_math_beishida_qizhong_001#14",
        "realpaper_g6_math_beishida_qizhong_002#17"
      ],
      "ai_template": "形状 ∈ {正方体棱长 4|长方体 4∶3∶2 比例}, 棱长 ∈ {4,6,8,12}",
      "latex_pattern": "$V=\\pi r^{2}h, r=\\frac{a}{2}$",
      "common_pitfalls": [
        "d↔r 混淆",
        "底面/高对应错",
        "比例边长选错"
      ]
    },
    {
      "pattern_id": "cylinder_container_height",
      "pattern_name": "圆柱容器·已知体积/容积反算高",
      "kp": "圆柱与圆锥/圆柱的体积",
      "chapter": "圆柱与圆锥",
      "typical_form": "圆柱形容器底面 r 已知，体积/容积 V 已知，求高",
      "rounds_seen": [2, 3],
      "r1_features": "直接 h = V/(πr²)，整数易算",
      "r2_features": "含单位 mL↔cm³↔L 换算",
      "r3_features": "情境复杂（油桶装油 + 装满判断 + 厚度等扰动）",
      "r4_features": "组合（多容器倒水 + 容积比较）",
      "distractor_design": [
        "忘记开口/封口对容积影响（题面给厚度时 V内 ≠ V外）",
        "单位 mL = cm³ 直接当 L"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_d1_guoguan_001#18",
        "realpaper_g6_math_beishida_d1_guoguan_001#29",
        "realpaper_g6_math_beishida_kaodian_guoguan_005#11",
        "realpaper_g6_math_beishida_qimo_003#35"
      ],
      "ai_template": "r ∈ {3,5,10}, V ∈ {942,1500,3140} cm³ 或 mL, 单位陷阱开关",
      "latex_pattern": "$h=V/(\\pi r^{2})$",
      "common_pitfalls": [
        "容积 vs 体积（厚度）",
        "mL/cm³/L 换算"
      ]
    },
    {
      "pattern_id": "cone_volume_pile",
      "pattern_name": "圆锥沙堆/谷堆/土堆·体积及重量",
      "kp": "圆柱与圆锥/圆锥的体积",
      "chapter": "圆柱与圆锥",
      "typical_form": "圆锥形堆体，给底面周长/直径+高，求体积或所装重量+车次",
      "rounds_seen": [2, 4],
      "r1_features": "已知 r、h，直接套 V=πr²h/3",
      "r2_features": "已知周长反求 r 后再算 V",
      "r3_features": "增加密度计算质量",
      "r4_features": "增加运输车载重 + 向上取整决策",
      "distractor_design": [
        "忘 1/3 系数",
        "周长 vs 直径混淆",
        "向上取整 vs 四舍五入"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_guoguan_004#17",
        "realpaper_g6_math_beishida_mokuai_yicuo_001#21",
        "realpaper_g6_math_beishida_qizhong_003#17",
        "realpaper_g6_math_beishida_qizhong_003#18"
      ],
      "ai_template": "C 或 d ∈ {18.84,12.56,6.28} m, h ∈ {1.2,1.5,2.5} m, 情境 ∈ {沙堆/谷堆/土堆}, 增项 ∈ {密度+车次}",
      "latex_pattern": "$V=\\frac{1}{3}\\pi r^{2}h$",
      "common_pitfalls": [
        "丢 1/3",
        "周长↔半径",
        "向上取整决策"
      ]
    },
    {
      "pattern_id": "cone_equal_dim_with_cylinder",
      "pattern_name": "圆锥与圆柱等底等高·体积关系",
      "kp": "圆柱与圆锥/圆锥的体积",
      "chapter": "圆柱与圆锥",
      "typical_form": "已知圆柱（或圆锥）的体积/高，等底等高的圆锥（或圆柱）的体积/水位高是多少",
      "rounds_seen": [1, 2, 3],
      "r1_features": "判断'圆锥=1/3 圆柱'，无运算",
      "r2_features": "代入数值（V锥=15→V柱=45）或反算（圆锥水倒入圆柱中水位=h/3）",
      "r3_features": "结合体积差（V柱-V锥=ΔV）解 V柱、V锥",
      "r4_features": "三种关系组合（等底等高 vs 等底等积 vs 等高等积）混合判断",
      "distractor_design": [
        "用 1/3 反方向",
        "把'多 2/3'当成'比为 2:3'",
        "等积时高的关系记反"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_d1_guoguan_001#11",
        "realpaper_g6_math_beishida_kaodian_guoguan_005#10",
        "realpaper_g6_math_beishida_kaodian_zonghe_003#7",
        "realpaper_g6_math_beishida_qimo_003#15"
      ],
      "ai_template": "已知量 ∈ {V柱|V锥|高|体积差}, 关系 ∈ {等底等高|等底等积|等高等积}",
      "latex_pattern": "$V_{锥}=\\frac{1}{3}V_{柱}$ (等底等高)",
      "common_pitfalls": [
        "1/3 系数方向",
        "水位 = h/3 而非 h",
        "三种关系混淆"
      ]
    },
    {
      "pattern_id": "cyl_cone_volume_diff",
      "pattern_name": "圆柱-圆锥等底等高·体积差填空",
      "kp": "圆柱与圆锥/圆柱圆锥综合应用",
      "chapter": "圆柱与圆锥",
      "typical_form": "圆柱比圆锥多 X dm³，求两者体积（多空填空）",
      "rounds_seen": [1, 2, 3],
      "r1_features": "判断'圆锥比等底等高圆柱体积少 2/3'（概念）",
      "r2_features": "已知差/和算 V 柱 V 锥（双填空）；削去部分=圆柱-圆锥",
      "r3_features": "结合周长底面反求半径再算",
      "r4_features": "等积关系下高比、底面比叠加",
      "distractor_design": [
        "用'1/3'代替'2/3'差",
        "把双填空一空填错另一空也错",
        "等底等高条件被忽略"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_d1_genzong_001#6",
        "realpaper_g6_math_beishida_d1_guoguan_001#5",
        "realpaper_g6_math_beishida_d1_guoguan_001#13",
        "realpaper_g6_math_beishida_kaodian_guoguan_004#8"
      ],
      "ai_template": "ΔV ∈ {8.4,42,120} dm³, 已知 ∈ {V柱-V锥|V柱+V锥|V柱-V锥的削去 V}",
      "latex_pattern": "$V_{柱}-V_{锥}=\\frac{2}{3}V_{柱}$",
      "common_pitfalls": [
        "2/3 vs 1/3",
        "削去 = V柱 - V锥"
      ]
    },
    {
      "pattern_id": "cylinder_to_cone_carve",
      "pattern_name": "圆柱削成最大圆锥·体积",
      "kp": "圆柱与圆锥/圆柱圆锥综合应用",
      "chapter": "圆柱与圆锥",
      "typical_form": "把圆柱削成等底等高最大圆锥，求圆锥体积或削去体积",
      "rounds_seen": [2, 3],
      "r1_features": "已知 V柱→V锥=V柱/3 直接（一步）",
      "r2_features": "已知周长+高反求 V，再 ÷3；或已知削去体积反求",
      "r3_features": "削去后剩余物联合体积（如圆锥+剩余圆柱）",
      "r4_features": "削成圆锥+其他几何组合体",
      "distractor_design": [
        "V锥 = V柱·2/3（实际是 1/3）",
        "底面周长 vs 直径混淆",
        "等底等高 vs 等底等积混淆"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_d1_guoguan_001#5",
        "realpaper_g6_math_beishida_kaodian_guoguan_004#6",
        "realpaper_g6_math_beishida_mokuai_kongjian_001#8",
        "realpaper_g6_math_beishida_qizhong_001#28"
      ],
      "ai_template": "C或d ∈ {18.84,12.56} dm, h ∈ {7,10,15}, 题型 ∈ {V锥求|V柱-V锥求|削去 ratio}",
      "latex_pattern": "$V_{锥}=\\frac{1}{3}V_{柱}$",
      "common_pitfalls": [
        "1/3 系数方向",
        "周长↔半径换算"
      ]
    },
    {
      "pattern_id": "cylinder_cut_axial_section",
      "pattern_name": "圆柱沿底面直径竖切·矩形截面",
      "kp": "圆柱与圆锥/圆柱圆锥综合应用",
      "chapter": "圆柱与圆锥",
      "typical_form": "把圆柱沿底面直径竖直切成两个半圆柱，表面积增加多少",
      "rounds_seen": [2, 3],
      "r1_features": "概念辨析'切了几个新面'",
      "r2_features": "代入算（2 个矩形截面，面积=d×h，共 2 个）",
      "r3_features": "需要识别'矩形长=高、宽=直径'（隐藏几何）",
      "r4_features": "切多次或斜切（变种）",
      "distractor_design": [
        "只算 1 个矩形（忘 ×2）",
        "把矩形长当成 r 而非 d",
        "横切 vs 竖切混淆"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_d1_genzong_001#13",
        "realpaper_g6_math_beishida_d1_guoguan_001#4",
        "realpaper_g6_math_beishida_mokuai_yingyong_001#11",
        "realpaper_g6_math_beishida_qizhong_001#3"
      ],
      "ai_template": "d ∈ {4,6,10}, h ∈ {6,8,10,15}, 切方向 ∈ {竖直切|横切}",
      "latex_pattern": "$\\Delta S=2dh$ (竖切)",
      "common_pitfalls": [
        "截面长=高、宽=d",
        "切几次=切了 N 个 1 面"
      ]
    },
    {
      "pattern_id": "scale_distance_basic",
      "pattern_name": "比例尺·图距↔实距换算",
      "kp": "正反比例/比例尺",
      "chapter": "正比例和反比例",
      "typical_form": "已知比例尺 1:N + 图上距离/实际距离，求另一个",
      "rounds_seen": [1, 2, 3],
      "r1_features": "图距×N→实距，cm→km 标准换算",
      "r2_features": "需要 cm↔km 双换算 + 实距→图距反向",
      "r3_features": "结合速度时间路程综合（比例尺+相遇问题）",
      "r4_features": "放大图比例尺（前项大）方向问题",
      "distractor_design": [
        "cm/km 换算错（缺 100000 倍）",
        "比例尺方向（前后项混淆）",
        "实距/图距搞反"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_d2_genzong_001#12",
        "realpaper_g6_math_beishida_d2_genzong_001#25",
        "realpaper_g6_math_beishida_d2_guoguan_001#5",
        "realpaper_g6_math_beishida_d2_guoguan_001#7"
      ],
      "ai_template": "比例尺 ∈ {1:1000000, 1:5000000, 1:300000, 20:1}, 已知 ∈ {图距 cm|实距 km}, 输出 ∈ {另一量|比例尺}",
      "latex_pattern": "$\\text{比例尺}=\\frac{\\text{图距}}{\\text{实距}}$",
      "common_pitfalls": [
        "cm↔km 换算",
        "比例尺方向",
        "放大图前项>后项"
      ]
    },
    {
      "pattern_id": "proportion_judge_table_or_relation",
      "pattern_name": "判断两量是否成正反比例",
      "kp": "正反比例/正反比例的判断",
      "chapter": "正比例和反比例",
      "typical_form": "判断/选择：给出关系（如圆面积与半径、总钱数与单价×数量），是否成正反比例",
      "rounds_seen": [1, 2, 3],
      "r1_features": "经典正/反比例例（路程时间/工效工时）的直观判断",
      "r2_features": "包含'有些情况下成、有些情况下不成'，需明确条件（'相关联'/'积一定'/'比值一定'）",
      "r3_features": "传递关系（a~b 正比，b~c 反比 → a~c?）",
      "r4_features": "复杂关系（含平方、立方、组合）",
      "distractor_design": [
        "把'相加=定值'当作正/反比例",
        "把'比值=积'混淆判定标准",
        "传递结果方向反"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_d4_genzong_001#14",
        "realpaper_g6_math_beishida_d4_guoguan_001#7",
        "realpaper_g6_math_beishida_d4_guoguan_001#8",
        "realpaper_g6_math_beishida_d4_guoguan_001#11"
      ],
      "ai_template": "关系组 ∈ {圆C/r, 圆S/r, sb/h, 总钱数=单价×数量}, round 1-3",
      "latex_pattern": "$\\text{正比例: }\\frac{y}{x}=k$ ; $\\text{反比例: }xy=k$",
      "common_pitfalls": [
        "相加定值≠正反比例",
        "圆面积/r² 是平方关系不是正比例"
      ]
    },
    {
      "pattern_id": "inverse_proportion_meaning",
      "pattern_name": "反比例的意义·概念辨析",
      "kp": "正反比例/反比例的意义",
      "chapter": "正比例和反比例",
      "typical_form": "给出两量关系，判断是否反比例并说明依据（积一定）",
      "rounds_seen": [1, 2, 3],
      "r1_features": "经典反比例例（速度时间路程定）",
      "r2_features": "情境隐藏'乘积一定'（如固定水量倒不同容器）",
      "r3_features": "结合表格判断 + 多组数据验证乘积",
      "r4_features": "复合关系（容器形状变化下半径与高的反比关系）",
      "distractor_design": [
        "把和一定当成反比例",
        "比值一定误识为反比例"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_d4_genzong_001#6",
        "realpaper_g6_math_beishida_d4_genzong_001#7",
        "realpaper_g6_math_beishida_d4_genzong_001#9",
        "realpaper_g6_math_beishida_d4_genzong_001#13"
      ],
      "ai_template": "情境 ∈ {速度时间|工效工时|固定水量倒容器}, 输出形态 ∈ {选/判}",
      "latex_pattern": "$xy=k$ (k 一定)",
      "common_pitfalls": [
        "和定 vs 积定",
        "判断'乘积是否一定'"
      ]
    },
    {
      "pattern_id": "direct_proportion_meaning",
      "pattern_name": "正比例的意义·概念辨析",
      "kp": "正反比例/正比例的意义",
      "chapter": "正比例和反比例",
      "typical_form": "给出关系判断是否正比例并说理（比值一定）",
      "rounds_seen": [1, 2],
      "r1_features": "教材定义直背（'比值一定'即正比例）",
      "r2_features": "需要计算多组比值确认是否一致",
      "r3_features": "情境含'平方/立方关系'误导",
      "r4_features": "图象判断（直线过原点 → 正比例）",
      "distractor_design": [
        "把'差一定'当成正比例",
        "把'积一定'当成正比例（实际是反）",
        "圆面积/半径不是正比例（平方关系）"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_d4_genzong_001#8",
        "realpaper_g6_math_beishida_d4_genzong_001#10",
        "realpaper_g6_math_beishida_d4_genzong_001#11",
        "realpaper_g6_math_beishida_d4_guoguan_001#10"
      ],
      "ai_template": "关系 ∈ {y/x=k|x²=ky|x+y=k}, 含图 ∈ {true|false}",
      "latex_pattern": "$y/x=k$ (k 一定)",
      "common_pitfalls": [
        "差一定 vs 比值一定",
        "平方关系不是正比例"
      ]
    },
    {
      "pattern_id": "solve_proportion_basic",
      "pattern_name": "解比例·基本型",
      "kp": "比和比例/解比例",
      "chapter": "比和比例",
      "typical_form": "解形如 a:b = c:x 的比例方程",
      "rounds_seen": [1, 2, 3],
      "r1_features": "整数小数 + 单位简单（如 x:0.4=0.3:0.8）",
      "r2_features": "含分数（如 20:x=2/3:4/5）需通分或交叉相乘",
      "r3_features": "含百分数 / 多次方 / 嵌套 (1/3:0.6=4/5:x)",
      "r4_features": "复杂带分式 + 应用情境",
      "distractor_design": [
        "前后项位置错（外项乘外项 vs 错位）",
        "分数运算未通分",
        "百分数没换成小数"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_d2_genzong_001#20",
        "realpaper_g6_math_beishida_d2_genzong_001#21",
        "realpaper_g6_math_beishida_d2_genzong_001#22",
        "realpaper_g6_math_beishida_d2_genzong_001#23"
      ],
      "ai_template": "数据类型 ∈ {整数|小数|分数|百分数}, 未知项位置 ∈ {内项|外项}",
      "latex_pattern": "$\\frac{a}{b}=\\frac{c}{x} \\Rightarrow ax=bc$",
      "common_pitfalls": [
        "内外项区分",
        "分数乘除",
        "百分数转换"
      ]
    },
    {
      "pattern_id": "simplify_ratio_with_units",
      "pattern_name": "化简比并求比值·含单位换算",
      "kp": "比和比例/化简比",
      "chapter": "比和比例",
      "typical_form": "化简 a:b 为最简整数比并求比值（含小数/分数/单位）",
      "rounds_seen": [1, 2, 3],
      "r1_features": "纯整数 / 简单小数（0.51:0.68）",
      "r2_features": "含单位需统一（2.5 时:25 分；3 米:30 厘米）",
      "r3_features": "含分数 + 小数混合（0.125:7/8）",
      "r4_features": "三量比化简（a:b:c）",
      "distractor_design": [
        "单位不统一直接化简",
        "化简到约分但非最简（公因数还能除）",
        "比值与最简比混淆"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_guoguan_002#14",
        "realpaper_g6_math_beishida_kaodian_guoguan_002#15",
        "realpaper_g6_math_beishida_kaodian_guoguan_002#16",
        "realpaper_g6_math_beishida_kaodian_guoguan_002#17"
      ],
      "ai_template": "含单位 ∈ {时:分|米:厘米|kg:g}, 数值类型 ∈ {小数|分数|混合}",
      "latex_pattern": "$\\frac{a}{b}=\\frac{a/g}{b/g}$ (g=gcd)",
      "common_pitfalls": [
        "单位先统一",
        "最简检查",
        "比/比值区分"
      ]
    },
    {
      "pattern_id": "pigeonhole_principle",
      "pattern_name": "抽屉原理·至少抽多少保证",
      "kp": "总复习/解决问题策略",
      "chapter": "总复习",
      "typical_form": "袋中 N 种 K 个球（牌）至少抽出几个保证有 M 同色（同类）",
      "rounds_seen": [2, 3],
      "r1_features": "经典 3 色球至少抽 4 保证 2 同色（最简）",
      "r2_features": "保证 M 个目标 + 多种类（不规整数量）",
      "r3_features": "扑克牌 / 学生抽签 / 抽屉放书的反向求'最少有几本'",
      "r4_features": "结合多重条件（颜色+花色双约束）",
      "distractor_design": [
        "抽 N 而非 N+1",
        "把'保证'当成'可能'（最少 vs 最多）",
        "考虑顺序（误用排列）"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_guoguan_007#13",
        "realpaper_g6_math_beishida_kaodian_zonghe_001#5",
        "realpaper_g6_math_beishida_kaodian_zonghe_003#16",
        "realpaper_g6_math_beishida_mokuai_shuxing_001#2"
      ],
      "ai_template": "种类数 N ∈ {3,4}, 每种数量 K ∈ {5,10}, 目标 M ∈ {2,3}, 是否反向求 ∈ {true|false}",
      "latex_pattern": "$\\lceil\\frac{m\\cdot k}{n}+1\\rceil$ (取上整)",
      "common_pitfalls": [
        "+1 而非 +0",
        "保证 vs 可能",
        "反向最小值"
      ]
    },
    {
      "pattern_id": "work_problem_partial_combo",
      "pattern_name": "工程问题·部分单独+合作",
      "kp": "总复习/解决问题策略",
      "chapter": "总复习",
      "typical_form": "甲单独 N 天/乙单独 M 天，先甲做 X 天，剩下两人合作还需多久",
      "rounds_seen": [2, 3],
      "r1_features": "纯合作（1/N+1/M）求时间",
      "r2_features": "判断对错型（合作 vs 单独效率）",
      "r3_features": "分阶段（先单独后合作 / 中途换人）",
      "r4_features": "三人合作 + 部分轮换",
      "distractor_design": [
        "效率相加 vs 时间相加（混淆）",
        "把'剩下'当成'全部'",
        "把工作量当成具体单位（漏'设全工作=1'）"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_guoguan_002#29",
        "realpaper_g6_math_beishida_kaodian_zonghe_001#22",
        "realpaper_g6_math_beishida_mokuai_yingyong_001#15",
        "realpaper_g6_math_beishida_qimo_002#9"
      ],
      "ai_template": "甲天数 ∈ {5,12}, 乙天数 ∈ {4,9}, 阶段 ∈ {纯合作|先单独 X 天再合作|中途换人}",
      "latex_pattern": "$t_{\\text{合作}}=\\frac{1-X/N}{1/N+1/M}$",
      "common_pitfalls": [
        "效率 vs 时间",
        "工作总量 = 1",
        "分阶段计算"
      ]
    },
    {
      "pattern_id": "chicken_rabbit_problem",
      "pattern_name": "鸡兔同笼·头脚条件",
      "kp": "总复习/解决问题策略",
      "chapter": "总复习",
      "typical_form": "已知头数+脚数（或脚数差）求鸡兔各几只",
      "rounds_seen": [2, 3],
      "r1_features": "标准头脚（8 头 22 腿）",
      "r2_features": "脚数差（鸡比兔少 X 只）变形",
      "r3_features": "三种动物或脚数为代数式",
      "r4_features": "增加未知（如还有龟）",
      "distractor_design": [
        "把'差'当成'和'",
        "假设法假设错（假设全鸡时多算腿）"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_guoguan_008#15",
        "realpaper_g6_math_beishida_kaodian_guoguan_008#16",
        "realpaper_g6_math_beishida_mokuai_yingyong_001#0"
      ],
      "ai_template": "总头 ∈ {8,53,100}, 条件类型 ∈ {脚和|脚差}, 题型 ∈ {算鸡|算兔|双填}",
      "latex_pattern": "$\\text{鸡}+\\text{兔}=N, 2\\text{鸡}+4\\text{兔}=L$",
      "common_pitfalls": [
        "和 vs 差条件",
        "假设法方向"
      ]
    },
    {
      "pattern_id": "percentage_application_practical",
      "pattern_name": "百分数应用·折扣/利息/出勤率",
      "kp": "总复习/解决问题策略",
      "chapter": "总复习",
      "typical_form": "已知折扣/利率/超额完成等百分比 + 数量，反求原值或差额",
      "rounds_seen": [2, 3, 4],
      "r1_features": "直接套（原价×折扣率）",
      "r2_features": "需反向求（已知折扣后金额求原价）",
      "r3_features": "多重百分比（先涨后降，超额完成多少）",
      "r4_features": "复合（增长率+利息+折扣同时）",
      "distractor_design": [
        "直接 ÷ 折扣率（应该 ×）",
        "把多重百分比简单相加",
        "超额计算基数错"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_zonghe_001#23",
        "realpaper_g6_math_beishida_kaodian_zonghe_003#26",
        "realpaper_g6_math_beishida_mokuai_daishu_001#35",
        "realpaper_g6_math_beishida_mokuai_jisuan_001#36"
      ],
      "ai_template": "情境 ∈ {折扣|利息|出勤率|完成率|超额}, 输出 ∈ {终值|原值|差额|百分比}",
      "latex_pattern": "$\\text{终值}=\\text{原值}\\times(1\\pm p\\%)$",
      "common_pitfalls": [
        "反向用错乘除",
        "多重百分比基数",
        "超额 vs 完成"
      ]
    },
    {
      "pattern_id": "percentage_basic_calculation",
      "pattern_name": "百分数基础·命中率/出勤率/折",
      "kp": "总复习/数与代数综合",
      "chapter": "总复习",
      "typical_form": "已知百分率+总数，求部分量；或已知部分量+总数，求百分率",
      "rounds_seen": [1, 2, 3, 4],
      "r1_features": "直接 N×p% 一步计算",
      "r2_features": "出勤率与缺勤数比的转换",
      "r3_features": "结合分数（如七五折=75%=3/4）多形式互化",
      "r4_features": "百分数应用题（多重情境）",
      "distractor_design": [
        "%没去除 100",
        "比和百分数搞混",
        "折扣理解错（七五折 ≠ 七成五）"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_guoguan_002#0",
        "realpaper_g6_math_beishida_kaodian_guoguan_002#2",
        "realpaper_g6_math_beishida_kaodian_guoguan_002#19",
        "realpaper_g6_math_beishida_kaodian_guoguan_008#13"
      ],
      "ai_template": "百分率 ∈ {97%, 95%, 75%, 60%}, 总数 ∈ {200, 100, 36}",
      "latex_pattern": "$\\text{部分}=\\text{总}\\times p\\%$",
      "common_pitfalls": [
        "七五折=75%",
        "出勤+缺勤=100%",
        "百分比 vs 比"
      ]
    },
    {
      "pattern_id": "direct_calc_oral_arith",
      "pattern_name": "口算/直接写得数",
      "kp": "总复习/数与代数综合",
      "chapter": "总复习",
      "typical_form": "6-8 个简单计算题打包，要求依次填答案",
      "rounds_seen": [1, 2],
      "r1_features": "纯整数小数分数四则运算（无应用）",
      "r2_features": "含百分数转换 + 估算（≈）",
      "r3_features": "复杂分数运算 + 简便算法识别",
      "r4_features": "（罕见）",
      "distractor_design": [
        "（fill 题无干扰项）"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_zonghe_001#15",
        "realpaper_g6_math_beishida_kaodian_zonghe_002#10",
        "realpaper_g6_math_beishida_kaodian_zonghe_003#18",
        "realpaper_g6_math_beishida_kaodian_zonghe_003#19"
      ],
      "ai_template": "题数 ∈ {4,6,8}, 类型 ∈ {分数四则|小数四则|百分数|估算}, 一般 R1",
      "latex_pattern": "（多种小公式串联）",
      "common_pitfalls": [
        "分数运算通分",
        "估算精度",
        "符号优先级"
      ]
    },
    {
      "pattern_id": "solve_equation_basic",
      "pattern_name": "解方程·一元一次",
      "kp": "总复习/数与代数综合",
      "chapter": "总复习",
      "typical_form": "求 x 使方程成立（含括号、系数小数、百分数）",
      "rounds_seen": [1, 2],
      "r1_features": "纯整数系数（如 5(x-1.2)=140）",
      "r2_features": "含百分数系数（62%x+3.5=3.81）",
      "r3_features": "需要先合并/移项再解",
      "r4_features": "代数综合应用题（设方程）",
      "distractor_design": [
        "（fill 题无）"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_guoguan_002#6",
        "realpaper_g6_math_beishida_kaodian_guoguan_002#18",
        "realpaper_g6_math_beishida_kaodian_guoguan_002#19",
        "realpaper_g6_math_beishida_kaodian_guoguan_002#22"
      ],
      "ai_template": "形式 ∈ {a(x+b)=c|ax±b=cx±d|p%x+b=c}, R1-R3",
      "latex_pattern": "$ax+b=c \\Rightarrow x=(c-b)/a$",
      "common_pitfalls": [
        "移项符号",
        "百分数转小数",
        "括号展开"
      ]
    },
    {
      "pattern_id": "simplify_calc_distributive",
      "pattern_name": "简便计算·分配律/结合律",
      "kp": "总复习/数与代数综合",
      "chapter": "总复习",
      "typical_form": "用分配律/结合律快速算如 12×(1/4+1/6-1/3)",
      "rounds_seen": [2, 4],
      "r1_features": "（罕见）",
      "r2_features": "分配律展开后约简（最常见）",
      "r3_features": "需要构造公因数 / 拆项",
      "r4_features": "竞赛级·识别隐藏数字关系（如 20.18×1996 - 19.95×2018）",
      "distractor_design": [
        "（calc 题无干扰项）"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_mokuai_yingyong_001#22",
        "realpaper_g6_math_beishida_mokuai_yingyong_001#23",
        "realpaper_g6_math_beishida_mokuai_yingyong_001#24",
        "realpaper_g6_math_beishida_qimo_001#22"
      ],
      "ai_template": "类型 ∈ {分配律|结合律|提公因数|拆项}, R2-R4",
      "latex_pattern": "$a(b+c)=ab+ac$",
      "common_pitfalls": [
        "反方向用律",
        "拆项后符号"
      ]
    },
    {
      "pattern_id": "stats_chart_selection",
      "pattern_name": "选择合适统计图",
      "kp": "总复习/统计与可能性",
      "chapter": "总复习",
      "typical_form": "为某情境选最合适统计图（条形/折线/扇形）",
      "rounds_seen": [1, 2],
      "r1_features": "经典对应（变化趋势→折线，比较→条形，占比→扇形）",
      "r2_features": "情境含多个适合（'看变化趋势又比较'）需选最优",
      "r3_features": "选项含'都可以'类陷阱",
      "r4_features": "（罕见）",
      "distractor_design": [
        "选'都可以'（实际有最优）",
        "占比情境选条形（应该扇形）",
        "比较绝对量选折线"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_guoguan_006#0",
        "realpaper_g6_math_beishida_kaodian_guoguan_006#1",
        "realpaper_g6_math_beishida_kaodian_guoguan_006#2",
        "realpaper_g6_math_beishida_kaodian_guoguan_006#3"
      ],
      "ai_template": "情境 ∈ {长度比较|身高变化|占比|社团人数}, 选项 ∈ {条形|折线|扇形|都可}",
      "latex_pattern": "(无)",
      "common_pitfalls": [
        "条形/折线/扇形匹配",
        "都可以陷阱"
      ]
    },
    {
      "pattern_id": "probability_basic_prediction",
      "pattern_name": "可能性大小判断·摸球抽牌",
      "kp": "总复习/统计与可能性",
      "chapter": "总复习",
      "typical_form": "袋中各色球若干，摸出某色可能性大小判断/计算",
      "rounds_seen": [1, 2, 3],
      "r1_features": "等可能（一定/可能/不可能 区分）",
      "r2_features": "不等可能比较（哪种最大/最小）",
      "r3_features": "结合奇偶/质合复合判断",
      "r4_features": "条件概率前哨",
      "distractor_design": [
        "认为'连续 9 次正面后第 10 次必反'（独立性陷阱）",
        "数字奇偶质合记错（1 不是质数）"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_guoguan_006#5",
        "realpaper_g6_math_beishida_kaodian_guoguan_006#6",
        "realpaper_g6_math_beishida_kaodian_guoguan_006#9",
        "realpaper_g6_math_beishida_kaodian_guoguan_006#10"
      ],
      "ai_template": "情境 ∈ {摸球|抽牌|抛硬币}, 数 ∈ {3,5,9 张牌}",
      "latex_pattern": "$P=\\frac{\\text{有利}}{\\text{总}}$",
      "common_pitfalls": [
        "独立性误判",
        "1 非质数",
        "可能性 vs 概率值"
      ]
    },
    {
      "pattern_id": "cuboid_combine_or_split",
      "pattern_name": "长方体拼/拆·表面积体积变化",
      "kp": "总复习/图形与几何综合",
      "chapter": "总复习",
      "typical_form": "把 N 个正方体拼成长方体，表面积/体积变化",
      "rounds_seen": [1, 2, 3],
      "r1_features": "基础概念判断（拼后体积不变、表面积减少）",
      "r2_features": "代入算（2 个 4cm 正方体拼后表面积/体积）",
      "r3_features": "棱长和→棱长（连续自然数）反推表面积",
      "r4_features": "组合体（2 个长方体不规则拼）",
      "distractor_design": [
        "拼时忘减重叠面",
        "棱长和当周长",
        "正方体 6 个面 vs 长方体 6 个面差异"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_guoguan_003#11",
        "realpaper_g6_math_beishida_kaodian_guoguan_004#19",
        "realpaper_g6_math_beishida_mokuai_kongjian_001#6",
        "realpaper_g6_math_beishida_qimo_001#6"
      ],
      "ai_template": "形态 ∈ {拼接|分割|从顶点拿走小正方体}, 个数 ∈ {2,8}",
      "latex_pattern": "$S_{长方体}=2(lw+lh+wh)$",
      "common_pitfalls": [
        "拼接重叠面",
        "棱长和 = 12×棱长",
        "拿走小正方体表面积变化"
      ]
    },
    {
      "pattern_id": "cube_edge_to_surface",
      "pattern_name": "正方体·棱长↔表面积/体积",
      "kp": "总复习/图形与几何综合",
      "chapter": "总复习",
      "typical_form": "已知棱长和或单棱求表面积/体积",
      "rounds_seen": [1, 2],
      "r1_features": "棱长直接给（直接 6a²、a³）",
      "r2_features": "棱长和÷12 反求棱长",
      "r3_features": "结合拼接/分割",
      "r4_features": "（罕见）",
      "distractor_design": [
        "棱长和 ÷ 4 当作棱长（混淆周长）",
        "把 a² 当 a³"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_guoguan_003#11",
        "realpaper_g6_math_beishida_kaodian_guoguan_004#4",
        "realpaper_g6_math_beishida_kaodian_guoguan_004#10",
        "realpaper_g6_math_beishida_kaodian_zonghe_002#7"
      ],
      "ai_template": "已知 ∈ {棱长|棱长和}, 求 ∈ {表面积|体积|两者}",
      "latex_pattern": "$S=6a^{2}, V=a^{3}$",
      "common_pitfalls": [
        "棱长和 = 12a",
        "面积 vs 体积公式"
      ]
    },
    {
      "pattern_id": "trapezoid_area_practical",
      "pattern_name": "梯形面积·篱笆/菜地应用",
      "kp": "总复习/图形与几何综合",
      "chapter": "总复习",
      "typical_form": "靠墙篱笆围梯形菜地，已知篱笆长+高，求面积",
      "rounds_seen": [1, 2, 3],
      "r1_features": "概念辨析（高 = S÷[(a+b)/2]）",
      "r2_features": "代入算（标准上底+下底+高）",
      "r3_features": "篱笆只围三边反推下底",
      "r4_features": "结合长方形 / 圆截面综合",
      "distractor_design": [
        "梯形面积公式（a+b）h/2 漏 1/2",
        "三边篱笆和 ≠ 周长"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_guoguan_004#11",
        "realpaper_g6_math_beishida_mokuai_kongjian_001#16",
        "realpaper_g6_math_beishida_xingjitongji_001#7",
        "realpaper_g6_math_beishida_xingjitongji_001#8"
      ],
      "ai_template": "情境 ∈ {靠墙篱笆|两边夹河|普通梯形}, 已知 ∈ {上底+下底+高|篱笆长+高}",
      "latex_pattern": "$S=\\frac{(a+b)h}{2}$",
      "common_pitfalls": [
        "÷2 漏掉",
        "三边 vs 四边"
      ]
    },
    {
      "pattern_id": "triangle_area_calculation",
      "pattern_name": "三角形面积·应用计算",
      "kp": "总复习/图形与几何综合",
      "chapter": "总复习",
      "typical_form": "已知底/高求面积，或反求底高",
      "rounds_seen": [1, 2, 3],
      "r1_features": "直接套 1/2·b·h",
      "r2_features": "需要找对应'底-高'配对",
      "r3_features": "结合等腰/等边讨论",
      "r4_features": "结合三角形不等式判断哪条做底",
      "distractor_design": [
        "底高错配",
        "÷2 漏掉",
        "等腰底/腰理解错"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_guoguan_003#0",
        "realpaper_g6_math_beishida_mokuai_daishu_001#19",
        "realpaper_g6_math_beishida_xingjitongji_001#8",
        "realpaper_g6_math_beishida_xshchu_beijing_001#6"
      ],
      "ai_template": "形态 ∈ {直角|等腰|普通}, 已知 ∈ {底+高|两边+夹角}",
      "latex_pattern": "$S=\\frac{1}{2}bh$",
      "common_pitfalls": [
        "÷2",
        "底高对应"
      ]
    },
    {
      "pattern_id": "parallelogram_area_choice",
      "pattern_name": "平行四边形·邻边+高·面积选择",
      "kp": "总复习/图形与几何综合",
      "chapter": "总复习",
      "typical_form": "给两邻边+其中一条边对应的高，求面积",
      "rounds_seen": [1, 2, 3],
      "r1_features": "标准底高直接给",
      "r2_features": "需识别'高对应哪条底'",
      "r3_features": "选项给出多个候选（哪条底配哪条高）",
      "r4_features": "结合斜高/外切矩形",
      "distractor_design": [
        "把不对应的边和高相乘",
        "高/斜边混淆"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_guoguan_003#0",
        "realpaper_g6_math_beishida_kaodian_guoguan_003#12",
        "realpaper_g6_math_beishida_xingjitongji_001#7"
      ],
      "ai_template": "邻边 ∈ {(8,12),(5,7)}, 高 ∈ {对应短边|对应长边}",
      "latex_pattern": "$S=bh$ (b 与 h 配对)",
      "common_pitfalls": [
        "底高对应",
        "高 vs 邻边"
      ]
    },
    {
      "pattern_id": "coord_pair_navigation",
      "pattern_name": "数对·定位与方向",
      "kp": "总复习/图形与几何综合",
      "chapter": "总复习",
      "typical_form": "给数对/方向位置确定坐标或反推",
      "rounds_seen": [1, 2],
      "r1_features": "标准 (列, 行) 直接读",
      "r2_features": "结合方向（向东 N 米向北 M 米）",
      "r3_features": "复合（多次移动后的位置）",
      "r4_features": "（罕见）",
      "distractor_design": [
        "列行顺序反",
        "正向 vs 反向（西 = 负）"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_guoguan_005#1",
        "realpaper_g6_math_beishida_kaodian_guoguan_005#7",
        "realpaper_g6_math_beishida_qizhong_001#7",
        "realpaper_g6_math_beishida_qizhong_001#13"
      ],
      "ai_template": "形态 ∈ {直接读数对|方向距离|多步移动}",
      "latex_pattern": "(无)",
      "common_pitfalls": [
        "列行顺序",
        "方向正负"
      ]
    },
    {
      "pattern_id": "shape_scale_factor",
      "pattern_name": "图形按比放大/缩小·边长面积",
      "kp": "图形的运动/图形放大缩小",
      "chapter": "图形的运动",
      "typical_form": "正方形/长方形按 N:1 放大或缩小，求新边长/面积/周长",
      "rounds_seen": [1, 2],
      "r1_features": "直接套'按 N:1 放大边长×N'，再算 N²·原面积",
      "r2_features": "判断'周长×N，面积×N²'对错",
      "r3_features": "三角形/梯形等含高的图形",
      "r4_features": "（罕见）",
      "distractor_design": [
        "'面积×N'（应该 ×N²）",
        "'周长×N²'（应该 ×N）"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_d2_genzong_001#14",
        "realpaper_g6_math_beishida_d2_guoguan_001#4",
        "realpaper_g6_math_beishida_d2_guoguan_001#12",
        "realpaper_g6_math_beishida_mokuai_yingyong_001#12"
      ],
      "ai_template": "形状 ∈ {正方形|长方形|三角形}, 比 ∈ {2:1, 4:1, 3:1}",
      "latex_pattern": "$S'=k^{2}S, C'=kC$",
      "common_pitfalls": [
        "面积是平方关系",
        "周长是一次"
      ]
    },
    {
      "pattern_id": "rotation_clock_angle",
      "pattern_name": "旋转·时钟分针时针",
      "kp": "图形的运动/旋转",
      "chapter": "图形的运动",
      "typical_form": "时针/分针从某点旋转 N° 到某点",
      "rounds_seen": [1, 2, 3],
      "r1_features": "标准 90° / 180° / 360° 计算",
      "r2_features": "顺时针 vs 逆时针方向区分",
      "r3_features": "结合多次旋转 / 反向旋转",
      "r4_features": "（罕见）",
      "distractor_design": [
        "顺/逆方向反",
        "30°/格 vs 6°/格 混淆（时针 vs 分针）"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_kaodian_guoguan_005#3",
        "realpaper_g6_math_beishida_kaodian_guoguan_005#4",
        "realpaper_g6_math_beishida_zhouce_peiyou_005#2",
        "realpaper_g6_math_beishida_zhouce_peiyou_005#3"
      ],
      "ai_template": "针类 ∈ {时针|分针}, 起点 ∈ {12, 3, 6}, 方向 ∈ {顺|逆}, 度数 ∈ {30,60,90,120,150,180}",
      "latex_pattern": "时针 30°/格, 分针 6°/格",
      "common_pitfalls": [
        "顺逆方向",
        "时针/分针每格度数"
      ]
    },
    {
      "pattern_id": "ratio_distribution_application",
      "pattern_name": "按比分配·实际应用",
      "kp": "比和比例/比的意义",
      "chapter": "比和比例",
      "typical_form": "已知总量+比，按比分配各部分量",
      "rounds_seen": [1, 2],
      "r1_features": "总量÷比和=每份量",
      "r2_features": "比含三项（甲乙丙）按比分配",
      "r3_features": "结合百分数（占总数百分比转比）",
      "r4_features": "（罕见）",
      "distractor_design": [
        "总量除以比之一项（不是比和）",
        "比转换错"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_qizhong_001#26",
        "realpaper_g6_math_beishida_qizhong_002#30",
        "realpaper_g6_math_beishida_qizhong_002#31",
        "realpaper_g6_math_beishida_xshchu_shenyang_001#6"
      ],
      "ai_template": "总量 ∈ {120, 360}, 比 ∈ {3:5, 2:3:5}",
      "latex_pattern": "$\\text{部分}_{i}=\\text{总}\\cdot\\frac{a_{i}}{\\sum a}$",
      "common_pitfalls": [
        "分母用比和而非单项",
        "三项比"
      ]
    },
    {
      "pattern_id": "scale_basic_definition",
      "pattern_name": "比例尺·概念辨析+基础换算",
      "kp": "正反比例/比例尺",
      "chapter": "正比例和反比例",
      "typical_form": "判断比例尺定义 / 单位比例尺含义",
      "rounds_seen": [1, 2],
      "r1_features": "直接读取定义",
      "r2_features": "图距:实距 比的方向（缩小/放大图）",
      "r3_features": "复合应用（含面积比例尺）",
      "r4_features": "（罕见）",
      "distractor_design": [
        "比例尺方向（前后项）",
        "数值比例尺与线段比例尺",
        "面积比 = 边长比²"
      ],
      "real_examples": [
        "realpaper_g6_math_beishida_d2_genzong_001#4",
        "realpaper_g6_math_beishida_d2_genzong_001#6",
        "realpaper_g6_math_beishida_d2_genzong_001#9",
        "realpaper_g6_math_beishida_d2_genzong_001#12"
      ],
      "ai_template": "题型 ∈ {判断|填空|选择}, 关注点 ∈ {方向|换算|定义}",
      "latex_pattern": "$\\text{比例尺}=\\frac{\\text{图距}}{\\text{实距}}$",
      "common_pitfalls": [
        "前后项方向",
        "面积比 = 边长比的平方"
      ]
    }
  ]
}
```

## O10 提炼 task 启动 checklist（下次 session）

- [ ] reviewer agent 输入：1383 道数学真题（全 41 卷）+ realpaper_observations_math.md + 本文件 schema
- [ ] 按 KP 维度 cluster 真题
- [ ] 每 KP 提炼 1-3 个高频 pattern（同模式 ≥ 3 道才入库）
- [ ] 每 pattern 严格按本 schema 输出
- [ ] reasoning 段引用真题样例 + 显式 r{N}_features 描述
- [ ] 输出 patterns 数组到本文件 + commit

**预期产出（O10 完成时）：** 30-50 个 pattern，覆盖六下数学全部主要题型范式。

## 数学命题艺术粗分类（待 O10 细化）

按已观察的 KP 大类列出预期 pattern 群：

### 圆柱与圆锥
- cylinder_surface_packaging（表面积应用·包装/油漆类）
- cylinder_volume_container（体积应用·容器/水位类）
- cylinder_cone_relation（圆柱圆锥关系·等底等高/等积）
- cylinder_cut_surface_increase（"锯成 N 段·表面积增加多少"）
- cone_volume_sand_pile（圆锥体积·沙堆/谷堆）

### 比和比例
- proportion_simplify（化简比·分数/小数/带单位）
- proportion_distribution（按比分配·实际应用）
- proportion_scale_distance（比例尺与实际距离）
- proportion_inverse_application（反比例·工人/工时）
- proportion_direct_application（正比例·路程/速度/时间）

### 数与代数综合（六下总复习）
- algebra_solve_one_var（解一元一次方程·应用题）
- mixed_operations_priority（混合运算·括号/优先级）
- decimal_fraction_conversion（小数分数互化）

### 图形与几何（总复习）
- geometry_area_combined（组合图形面积·三角形+扇形等）
- geometry_solid_three_view（立体图形·三视图）
- geometry_axis_symmetry（轴对称·画图与判断）

### 统计与概率
- statistics_chart_judgment（统计图判断·选项陷阱）
- probability_basic（基础概率·一定/可能/不可能）

### 思想方法 / 数形 / 解决问题
- methods_inverse_thinking（逆向思维·从结果反推）
- methods_classification_discussion（分类讨论·多解题）
- problem_strategy_drawing（画图法·应用题）
- problem_strategy_table（列表法·相遇追及）

**注：** 这是 O10 启动时的初步分类参考，不强制完全对齐。reviewer agent 可根据真题实际分布调整。

---

**生成时间：** 2026-05-08
**对应 task：** O9（V3.12 observation_loop Layer 2）
