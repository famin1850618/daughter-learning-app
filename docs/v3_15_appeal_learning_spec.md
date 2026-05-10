# V3.15 立项: 申诉评语 worker 学习机制

**立项时间**: 2026-05-10
**触发**: Famin 反馈"判断申诉我的评语你是否能看到？要把申诉成功的评语当成修改答案和判断标准的依据"

---

## 现状盘点

### 已就位（V3.7.7 + V3.13）

1. **数据已采集**: `LearningExportService.buildJson()` 已含 `review_feedback` 段
   - 字段: `request_type / status / question_id / subject / grade / knowledge_point / content / user_answer / standard_answer / child_note / parent_note / parent_score / reviewed_at`
2. **同步通道**: `LearningSyncService` 每 6h 自动 PUT 到 `daughter-learning-data` 私有 repo
3. **PAT 在用户设备**: 配在 SharedPreferences，主 session/worker 无法直接拿

### 缺什么

- 主 session 派 worker 前**没拉过** `daughter-learning-data` 数据
- worker prompt 没要求"读 review_feedback 学习 Famin 判断风格"
- 申诉 approved 后**没回写题包源**（batch JSON 答案不变，下次重扫又得家长再审）

## 需求拆解

### 用例 1: 题级答案修正（直接落地）

家长 approve appeal/aiDispute → 隐式说"标准答案应改"或"小孩答的也算对"

**机制**:
- 手机端: `ReviewRequestService.approve` 时 UPDATE `questions.answer`（追加 `|||user_answer` 兜底）
- 学情同步: 答案变更已含在下次 buildJson 里（reviewed_at 时间戳）
- 主 session: git pull daughter-learning-data → 拿到答案变更 → patch batch JSON 源 → push

### 用例 2: 判题规则学习（结构化沉淀）

家长多次 approve "同义词" 申诉 → AnswerMatcher 应加更宽容同义词
家长多次 reject "声调" 申诉 → 拼音类题保持严格判

**机制**:
- 主 session 定期分析 `daughter-learning-data` 的 review_feedback
- 提取 pattern → 写到 `~/.claude/skills/realpaper-extract/rules/answer_matcher_calibration.md`
- worker 派工 prompt 必读

### 用例 3: 入库纪律学习

家长申诉评语暴露 worker 入库错误（如题面剧透 / 加点字漏标）

**机制**:
- 主 session 把 review_feedback 中"评语含纪律词"（如"剧透"/"应当"/"原题不该"）提取
- 沉淀到 SKILL.md ⊥0/⊥4 反例库
- 已有 D-9 / D-7 / 大丰收三反例就是这个机制的人工版

## 实施路径（3 阶段）

### 阶段 A（V3.15.0 最小闭环，~3 h）

**目标**: 主 session 能拉到家长决策 + worker prompt 加纪律

1. 主 session 加脚本 `tools/sync_appeal_decisions.sh`:
   - `git clone https://${PAT}@github.com/famin1850618/daughter-learning-data ~/AI_Workspace/learning_data/`
   - 每次派 worker 前先 `git pull`
2. PAT 处理: Famin 在主 session 启动时 `export GITHUB_PAT=...` 环境变量（或写到 ~/.claude/secrets）
3. worker prompt template 加纪律:
   ```
   入库前必检 ~/AI_Workspace/learning_data/<device>.json 的 review_feedback 段:
   - 同 source 题如有 status=approved → 该题答案以 user_answer 优先（worker 不重判）
   - parent_note 含"剧透"/"加点字"等关键词 → 触发 SKILL.md ⊥0 二次自查
   ```

### 阶段 B（V3.15.1 题级答案回写，~2 h）

**目标**: 家长 approve → 答案永久回写题包源

1. `ReviewRequestService.approve` (appeal 类型):
   - 调用 `_qDao.updateQuestionAnswer(qid, newAnswer)`
   - newAnswer = `original|||user_answer` (用 ||| 兜底，跟 V3.12.22 Issue 9 同款)
2. 主 session 周期性同步:
   - 拉 daughter-learning-data → 找 status=approved 且 reviewed_at > last_sync 的 record
   - 回写到 `~/daughter_learning_app/assets/data/batches/<source>.json` 对应题
   - commit + push + CDN purge

### 阶段 C（V3.15.2 规则学习，~3-4 h，可选）

**目标**: 评语 pattern 自动沉淀为纪律

1. 主 session 加分析脚本 `tools/analyze_appeal_decisions.py`:
   - 聚类 parent_note 关键词
   - 输出 markdown 报告给 Famin 审 → 入 SKILL.md
2. 季度性手工运行（不自动化避免错杀）

## 数据脱敏 / 隐私

- `daughter-learning-data` 是 Famin 私有 repo（PAT 控制）
- review_feedback 含小孩答题原文，敏感
- main session 拉到本地 `~/AI_Workspace/learning_data/` 不入项目 git
- worker 派工时只看 review_feedback 段（不看 child 完整答题历史）

## 触发条件

- 阶段 A 实施前提: Famin 配 GITHUB_PAT 到 ~/.claude/secrets 或环境变量
- 阶段 B 实施前提: 阶段 A 完成 + Famin 已用过申诉/审核机制（积累审核数据）

## 待决策

- [ ] PAT 配置方式（环境变量 / secrets 文件 / 一次性 git config credential helper）
- [ ] 阶段 A/B/C 启动时机
- [ ] daughter-learning-data 是否合并到 daughter-learning-app 同 repo（简化拉取链路）
