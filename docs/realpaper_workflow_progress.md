# 真题工作流 Stage 0/1 进度跟踪

**用途：** 防止 token 中断后下次会话能续上。每完成一个 task 立即更新本文件 + commit + push。

**最近更新：** 2026-05-08

## Stage 0 任务进度

| Task | 状态 | 完成时间 | 备注 |
|---|---|---|---|
| T22 清理真题目录 | ✅ completed | 2026-05-08 | 9.6→8.8GB / 7239→6971 文件；删 6 一级英语 + 1 全国生物 + 35 嵌入式非主科目录；保留"综合笔试"+"物理+化学"待 Famin 处理 |
| T23 装工具栈 | ⏳ in_progress（卡 Famin sudo）| - | libreoffice 未装，pip 未装。Famin 需手动 sudo apt install libreoffice python3-pip tesseract-ocr tesseract-ocr-chi-sim |
| T24 question_dao.dart 加 source 过滤 | ✅ completed | 2026-05-08 | 加 `_activeSourceFilter` 常量；6 个抽题方法（getRandom / getRandomByRound / getQuestionsForKnowledgePoint / getQuestionsForAssessmentUnit / getQuestionsForKpByRound / getQuestionsForKpExcludingWrong）都加了过滤；错题集查询不加（保留显示历史）|
| T25 DB v14 迁移：12 batch + 新 chapter | pending | - | database_helper.dart 升 v14；UPDATE 12 个 cron AI batch source 加 _deprecated；不动 chapter/type/KP |
| T26 curriculum_seed.dart 加 22 chapter | pending | - | 英语 16 (V/G/R/L × 4 grade) + 数学/语文 各 2 (小升初/中考综合) + 物理/化学 各 1 (中考综合) |
| T27 PET R1 200 题 chapter 重映射 | pending | - | 脚本：每题 chapter 从 "PET" 改为 KP fullPath 第一段。双写 batch JSON |
| T28 写 .realpaper-spec.md | pending | - | 8 步 pipeline + 命名规则 + 题型/难度/KP/主观题/图片纪律 + 失败回滚 |
| T29 写 tools/realpaper/*.py | pending | - | extract.py + segment.py + match_ans.py + validate.py + process.sh |
| T30 初始化 docs 文件骨架 | pending | - | manifest.json + kp_pending.json + 6 份 observations.md |
| T31 Stage 1 扫六下真题 | pending | - | ~/AI_Workspace/真题/六下/ 数学/语文 卷 |
| T32 build APK + push | pending | - | flutter build apk --debug → planning_v3_9_x.apk → push |

## 关键决策点（plan 已批准 2026-05-08）

1. 真题范围：**仅数学/语文/物理/化学**（英语走 Cambridge AI）
2. 转换工具：**libreoffice 一锅端**（Famin 选）
3. KP 缺口：**等候区机制**（每科 10 卷 review）
4. 主观题：**保留区**（source 加 `_subj_held`，等 AI 评分 API 后启用）
5. 难度：我主观判（按试卷类型 + 卷内位置 + KP 复杂度）
6. 跨年级综合题 KP：取**最高年级**
7. chapter 设计：数理化按教材章节 / 语文/英语按 KP 一级 category
8. 老题处理：12 个 cron AI batch 全部 source 加 `_deprecated`，不动其他字段
9. 部署窗口期：Stage 0 + Stage 1 合并连续做，避免"老题 deprecated 但新真题没入库"空窗
10. 图片纪律：图/文字不清晰直接放弃；清晰图直接截图嵌；需重绘则重绘
11. 自动扫机制：本机 Linux cron + Claude Code headless（错峰：凌晨 4 ticks × 20 卷 + 白天 2 ticks × 5 卷）

## 当前 commit 链

- `99ccb92` V3.8.3: 家长审核机制 + subjective + cron 停（V3.8.3 deprecated 过滤是 plan 时漏改 bug）
- `5b73855` V3.8.4: Cambridge KP seed 入库 + .cambridge-spec.md
- `696a250` V3.9 Stage 1: PET R1 200 题
- **下次 commit（V3.9.1）**：T24-T30 + Stage 0 完整 + Stage 1 第一批六下真题入库

## Stage 1 起跑信息

**六下目录**：~/AI_Workspace/真题/六下/（430MB，已同步完）
- 六下/数学/...
- 六下/语文/...

**起跑卷推荐**：从最简单的卷（先看哪些是数学，单卷较小）开始端到端验证。

## 跨会话恢复指南

如 token 用完中断，下次会话开始时：
1. `git log --oneline -10` 看 commit 进度
2. 读本文件看 task 进度
3. `cd /home/faminwsl/daughter_learning_app`
4. 检查 `docs/realpaper_manifest.json` 看已处理的卷
5. 检查 `docs/realpaper_kp_pending.json` 看 KP 等候区是否有待 review
6. 继续未完成的 task
