# 物理首套 round 抽审（V3.12.20.1，2026-05-09）

> **Status: NO QUESTIONS EMITTED — paper integrally skipped at Step 1**
>
> 源 PDF: `/mnt/d/AI_Workspace/真题/初二/八年级下册物理期末真题卷/1北京市朝阳区2020-2021学年八年级（下学期）期末检测物理试题.pdf`
>
> 目标 source_id: `realpaper_g8_physics_renjiao_qimo_beijing_chaoyang_001`
>
> 跳过原因: PDFPatcher 输出的纯扫描型 PDF，0 字体，pdftotext 仅 16 字节（全 form-feed 字符），违反 §9.1 完整性优先 + Step 1.3 整卷跳过纪律 + feedback_unclear_abandon 禁 OCR/多模态抢救。
>
> 视觉确认: preview-01.png 显示页面是栅格图像（含照片、电池图、滑轮图等），文字层为空。
>
> 全源池抽样 (38 套): 全部 3-16 字节 = 全是同源 PDFPatcher 扫描，**初二物理整源池在当前规则下不可处理**。

## 待 Famin 决策（详情见 `/tmp/v3_12_20_physics_report.md`）

1. 是否给物理科目开 OCR 例外通道（与 V3.10 反例的差异在哪）
2. 是否换源（人教官方教参试卷 / 其他可文本提取的真题集）
3. 是否调整初二物理批次扩展计划（暂停 / 推迟 / 跳过年级）

## 本次抽审 markdown 不含题目

物理科目阶段 0 的 LLM 自由判 + Famin 抽审流程**未触发**——因为没有题被入库。下一套物理真题入库（不论换源或开 OCR 通道）会按本格式补齐。

## 格式参考

参考 `docs/anchor_review_math.md`，每道题块含：

```
### Q{n} — round=R{x}（reasoning: ...）

【题干】content 全文 + image_data/SVG 渲染

【选项】A. ... B. ... C. ... D. ...（如 choice）

【答案】X

【解析】explanation

【round 判定 reasoning】LLM 推理：基础概念识别题 / 多步推导 / ...

- [ ] Famin Comment: ____（接受 / 改 R___ / unsure）
```
