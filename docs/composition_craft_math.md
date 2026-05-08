# 命题艺术 — 数学（Composition Craft）

> **状态：** V3.12 立项 O9 task（2026-05-08）。本文件是 Layer 2 命题艺术的结构化沉淀，用于未来 AI 出题（错题变体 / 冷门章节补题 / cron 重启）。
>
> **当前：** schema + 字段说明 + 留空 patterns 数组（**待 O10 reviewer agent 从 1383 道真题逆向提炼填充**）
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
    // ===== 待 O10 reviewer agent 提炼填充 =====
    // 估计提炼出 30-50 个 pattern_id（数学 1383 道真题）
    // 每 pattern 至少有 3 道真题样例才入库（孤例不留）
    //
    // 已知雏形（来自 realpaper_observations_math.md）：
    //
    // {
    //   "pattern_id": "cylinder_surface_packaging",
    //   "pattern_name": "圆柱表面积应用·包装/油漆类",
    //   "kp": "圆柱与圆锥/表面积",
    //   "chapter": "圆柱与圆锥",
    //   "typical_form": "给定圆柱底面半径 r 和高 h，问需要多少 m² 包装纸 / 多少升油漆（每升涂 N m²）",
    //   "rounds_seen": [1, 2, 3],
    //   "r1_features": "整数 r/h，纯表面积；选项明显错（忘 ×2 / 忘 +底面）",
    //   "r2_features": "加单位换算（cm² ↔ m²）；近似值干扰",
    //   "r3_features": "隐藏'开口圆柱'提示（无底/无盖）；选项有'忘开口'陷阱",
    //   "r4_features": "跨章节（圆柱 + 比例 + 利润）；选项需正向算才能排除",
    //   "distractor_design": [
    //     "忘 ×2（只算单底）",
    //     "忘 +底面（只算侧面）",
    //     "单位换算错（保留 cm² 没转 m²）",
    //     "开口圆柱减底面但减成俩"
    //   ],
    //   "real_examples": [
    //     "realpaper_g6_math_beishida_d1_guoguan_001#5",
    //     "realpaper_g6_math_beishida_kaodian_guoguan_002#12"
    //   ],
    //   "ai_template": "r ∈ {2,3,5,10}, h ∈ {6,8,10,15}, 情境 ∈ {油漆/包装/标签}, 单位陷阱 ∈ {cm/m}",
    //   "latex_pattern": "$S=2\\pi r^{2}+2\\pi rh$",
    //   "common_pitfalls": ["忘 ×2", "忘 +底面", "单位换算错", "开口圆柱处理错"]
    // }
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
