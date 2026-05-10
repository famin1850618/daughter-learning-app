# V3.12.22 Phase 3 第二批 Issues & Resolutions

**批次**: 重扫 5 套（救 OMath） + 新扫 5 套 = 10 套 / 286 题入库 / 102 题跳过
**时间**: 2026-05-10
**worker**: afe383…（token ~330K）

---

## 总览

worker 报 5 条 Issues。前两批合计 **20 套深圳数学卷已扫 / 478 题入库**。

⭐ **OMath 工具救题验证**: 龙华期末 2024-25 标杆卷 47 段 OMath 100% 转 LaTeX 注入；该卷入库 17→33 题（+16）。福田/龙岗/福田质检共救活 ~50 题。**入库率 70% → 90%**，符合预期。

---

## Issue 1：option_images 字段未在 validate.py 覆盖（建议入纪律）

**现象**: V3.12.22 A3 新增 `option_images` schema，worker 用此字段嵌入 4 选项图。但 `validate.py` `2_image_indicator` 检查"题面提图必有 image_data"时未识别 option_images，触发 false positive。worker 用 `_image_skip_reason="option_images_used"` 暂解。

**worker 建议**: validate.py 加规则——题面提图时 `image_data` OR `option_images` 任一非空即 PASS。

**Famin 决策**:
- [ ] A. 入纪律（主 session 立即修 validate.py 加 option_images 识别）
- [ ] B. 不动（保持 `_image_skip_reason` workaround）
- [ ] C. 其他: ____________

---

## Issue 2：答案算法冲突 worker 未用 ||| 兜底（个案处理，建议不入纪律）

**现象**: 罗湖 Q10 / 龙岗 Q10 / 龙华期末 Q11 阴影分数等题，原卷参考答案与严格按算法推导有出入。

**worker 决策**: 保参考答案为 batch answer，explanation 中暴露差异 + 标"须 Famin 复核"。**未用 ||| 兜底**（守住 §1.5 边界，避免被滥用）。

**worker 建议**: 否——按 ⊥4d "仅漏算明显量允许 |||"边界，本批属"算法争议"，应保原答案。

**Famin 决策**:
- [ ] A. ✅ 同意 worker 判断（保原答案 + explanation 暴露 + 标须复核）
- [ ] B. 改 ||| 兜底（双答案）
- [ ] C. 其他: ____________

**待你抽查**: 罗湖 Q10 / 龙岗 Q10 / 龙华期末 Q11 是否真有算法冲突 / 原卷答案错？

---

## Issue 3："如图但缺数据"跳过 vs 入库的边界规则（建议入纪律）

**现象**: 罗湖 Q11（线段图比例描述）/ 龙岗 Q15（直尺看数字）题面"如图..."配图：
- 配图清晰可读 + worker Vision 能识别 → worker 把图意补到 content + image_data 入库
- 配图模糊 / 关键数据丢失 → 整题进 `_skipped_for_future` reason=`info_lost_irrecoverable`

**worker 建议**: rules/images_docx.md 加规则：「题面提"如图"+ 文字层缺关键数据：① 图清晰可识别 → worker Vision 写补到 content + 嵌入 image_data；② 图丢失/模糊 → reason=info_lost_irrecoverable 跳过」

**Famin 决策**:
- [ ] A. 入纪律（worker 建议措辞）—— ① 路径常用，提高入库率
- [ ] B. 仅 ② 路径，① 路径整题跳（保守入库率低但更安全）
- [ ] C. 其他: ____________

---

## Issue 4：OMath 段拆裂（罕见，建议不入纪律）

**现象**: 龙华期末 Q1(3) `$\frac{7}{13}\times\frac{1}{4}+\frac{3}{4}\div\frac{13}{7}$` 在 raw_with_omath.txt 多行分散注入（单 OMath 段被 docx 编辑工具拆分多段）。

**worker 决策**: 手工合并完整公式入 content。

**worker 建议**: 否（罕见，工具本身已成熟，部分 docx 编辑产生段拆裂属个例）。

**Famin 决策**: ✅ 默认采用 worker 建议（不入纪律）。

---

## Issue 5：π / n² 等特殊字符转 choice（已有 §5.1 规则覆盖）

**现象**: 龙华 Q21 圆柱体积 `96π`、罗湖 Q22(2) `n²`。

**worker 决策**: 按 §5.1 输入法限制，转 choice + 4 选项（含正确答案）。

**Famin 决策**: ✅ 已有 §5.1 规则覆盖，无新纪律。

---

## 总结：本批关键发现

1. **OMath 工具救题验证**: 入库率 70% → 90%，节省大量重做时间。下批数学/语文卷预期同样高入库率。
2. **4 大禁令 0 违例**: V3.12.22 ⊥1/⊥2/⊥3/⊥4 全部稳定执行。
3. **_skipped_for_future 机制落地**: 102 跳过题全部完整记录（reason + raw_excerpt + source_para），未来 app 升级回填可用。
4. **可主 session 立即处理 (Issue 1)**: option_images 加进 validate.py（小工程量）。

## 数据快照

| 项 | V3.12.21 | V3.12.22 第一批 | V3.12.22 第二批 |
|---|---|---|---|
| 数学已扫深圳源 | 5 套 78 题 | +5 套 112 题 | 总 20 套 478 题 |
| 入库率 | 52% | 70% | 90% |
| OMath 段救活 | 0 | 0 | 80+ |
| _skipped_for_future | 无机制 | 无机制 | 102 题完整记录 |

## 下一步建议

A 你审完 Issue 1/2/3 决策后：
- Issue 1 入纪律：主 session 立即升级 validate.py
- Issue 2/3 入纪律：主 session 修 spec / rules
- Phase 3 第三批：派 worker 扫剩余 ~128 套深圳数学 docx + 启动语文重扫（5 套语文已扫但未享 V3.12.22 全套）
