# V3.13 立项: 申诉/争议家长审核机制

**立项时间**: 2026-05-10
**触发**: V3.12.22 Phase 3 第二批 Issue 2 — Famin 决策 C
**预期工期**: 7-10 小时（单 session 可完成）

---

## 背景与动机

V3.12.22 Phase 3 第二批 worker 扫到几道题（罗湖 Q10 / 龙岗 Q10 / 龙华期末 Q11）原卷参考答案与严格按算法推导有出入。worker 守 §1.5 没用 `|||` 兜底，标"须 Famin 复核"暴露给家长。

但当前没机制让家长在 app 内审核——只能 git 翻查 batch JSON。Famin 提出更通用的解决：

> **遇到答案问题直接推入"家长审核"中。小孩对答案有争议可以提交家长审核，AI 发现有争议也直接提交家长审核。两套逻辑并存 UI。跟小孩的争议一样，我审核后你更新答案，学习判断方式，只是不涉及更新任务和奖励。**

## 现状

V3.8.3 已有 `subjective` 主观题进家长审核机制（type=subjective 题答完直接入审核队列家长打分）。
V3.13 在此基础上**扩展两类新审核源**：
1. **AI 争议** (`_ai_dispute`)：worker 入库时发现答案算法冲突 → 自动推审核
2. **小孩申诉** (`appeal_status="pending"`)：小孩答完判错点"申诉"按钮 → 推审核

## 核心原则

1. **不影响奖励/任务**：争议/申诉中的题**冻结**学情记录（既不计对也不计错）
2. **家长决策后回写**：家长说"AI 对" → 更新题答案 + 学情重判；说"原答案对" → 不动
3. **家长决策学习**：所有决策记 `calibration_log/famin_appeal_decisions.jsonl`，未来 worker 学判断

## 数据层设计

### batch JSON schema 扩展（worker 写）

```json
{
  "id": "...",
  "content": "...",
  "answer": "19650",
  "_ai_dispute": {
    "type": "answer_algorithm_conflict",
    "reason": "原参考答案 19650 漏算 0.001% 过户费，严格按题面应为 19708.6",
    "alt_answer": "19708.6",
    "confidence": "high",
    "raised_by": "worker_afe383"
  }
}
```

**dispute type 词典**:
- `answer_algorithm_conflict`: 答案算法冲突（漏算/不严谨）
- `answer_missing`: 原卷无参考答案，worker 推导
- `answer_ambiguous`: 答案多解争议
- `question_unclear`: 题目本身有歧义

### DB schema 升级 v21 → v22

```sql
-- questions 表加列
ALTER TABLE questions ADD COLUMN ai_dispute_json TEXT;

-- 新表 appeal_records
CREATE TABLE appeal_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  question_id INTEGER NOT NULL,
  practice_record_id INTEGER,            -- 关联具体做题记录（小孩申诉时填）
  source TEXT NOT NULL,                  -- 'ai_dispute' | 'child_appeal'
  user_answer TEXT,                      -- 小孩当时答的（child_appeal 用）
  appeal_reason TEXT,                    -- 申诉理由（小孩可填或留空）
  ai_dispute_snapshot TEXT,              -- AI 争议元数据快照（JSON）
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending' | 'parent_approved' | 'parent_rejected' | 'parent_dual'
  parent_decision TEXT,                  -- 家长决策（'ai_correct' | 'original_correct' | 'both_valid'）
  parent_new_answer TEXT,                -- 家长改的新答案（如有）
  parent_note TEXT,                      -- 家长批注
  created_at TEXT NOT NULL,
  resolved_at TEXT,
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (practice_record_id) REFERENCES practice_records(id)
);

-- practice_records 表加 appeal_status 列（V3.13 起练习记录可挂申诉态）
ALTER TABLE practice_records ADD COLUMN appeal_status TEXT;
-- null = 无申诉 / 'frozen' = 冻结中 / 'resolved' = 审核完成
```

### Question / PracticeRecord / AppealRecord 模型

`lib/models/question.dart`: 加 `aiDispute` (Map<String,dynamic>?) 字段
`lib/models/practice_record.dart`: 加 `appealStatus` (String?) 字段
`lib/models/appeal_record.dart`: 新建模型

## 业务逻辑

### A. AI 争议入库流程

worker 在 4a annotate 阶段发现答案有疑问，写 `_ai_dispute` 字段：

```python
# 入库时 question_update_service 解析 _ai_dispute → 写入 ai_dispute_json 字段
```

题入库时 `appeal_records` 自动 INSERT 一条 `source='ai_dispute', status='pending'` 记录。

### B. 小孩做 AI 争议题流程

练习屏 `practice_screen.dart`:

1. 题展示时如 `q.aiDispute != null` → 顶部黄色 banner: "⚠ 这题答案被 AI 标注为'有疑问'，做完会自动提交爸爸审核"
2. 答完后 → `PracticeRecord.appealStatus = 'frozen'`，**不计学情，不发奖励**
3. 自动 INSERT `appeal_records` 关联本次做题
4. UI 提示："已提交爸爸审核，结果出来再算分。"

### C. 小孩申诉普通题流程

练习屏判错后：

1. 显示按钮 "我觉得答案有问题，申诉给爸爸看"
2. 点了 → 弹简短输入框（可选）"为什么觉得有问题"
3. 提交 → `PracticeRecord.appealStatus = 'frozen'`，回滚错题记录（学情记录回滚到之前状态）
4. INSERT `appeal_records` source=`child_appeal`

### D. 家长审核 UI

`lib/screens/parent_review_screen.dart`（已有 subjective 审核屏，扩展）：

新增 tab `争议待审` (与 `主观题待审` 并列)，子分类：

```
争议待审 (12)
  ├─ AI 标注 (5)         ← _ai_dispute 入库时自动入审核
  └─ 小孩申诉 (7)         ← 小孩点申诉按钮入审核
```

每条审核项展示：
- 题面 + 当前 answer
- AI 推的：AI 建议 alt_answer + reason
- 小孩申诉的：小孩当时答 + 申诉理由
- 三个按钮：
  - "AI/小孩对" → 改 question.answer = alt_answer / new_answer，重判该次做题，学情更新
  - "原答案对" → 不改答案，学情按原判（错）
  - "两答案都对" → answer = 原 \|\|\| alt（V3.12.22 ⊥4d 兜底）

家长决策后：
- `practice_record.appealStatus = 'resolved'`
- `appeal_record.status = 'parent_*' / parent_decision = '...'`
- 学情/奖励重新计算
- 决策事件写 `calibration_log/famin_appeal_decisions.jsonl`

### E. AI 学习机制

`calibration_log/famin_appeal_decisions.jsonl`:

```json
{"timestamp":"2026-05-10T12:00:00","question_id":1234,"source":"ai_dispute",
 "ai_proposed":{"alt_answer":"19708.6","reason":"漏算过户费"},
 "famin_decision":"original_correct","famin_note":"参考答案合理舍入到整百"}
```

未来 worker 入库前读最近 N=100 条决策学 Famin 判断风格（rubric 隐式更新）。

## UI 设计

### 练习屏 banner（AI 争议题）

```
┌─────────────────────────────────────┐
│ ⚠ 这题答案被 AI 标注疑问，做完进审核 │
└─────────────────────────────────────┘

题目内容...
```

### 练习屏申诉按钮（普通题判错后）

```
答错了 ✗

正确答案: 19650

[ 知道了 ]   [ 我觉得答案有问题，申诉给爸爸 ]
```

### 家长审核 tab

参考现有 subjective 审核屏布局（lib/screens/parent_review_screen.dart）。

## 工期估算

| 步骤 | 时间 |
|---|---|
| DB schema v21 → v22 + AppealRecord model | 30 min |
| Question.aiDispute / PracticeRecord.appealStatus 字段 | 30 min |
| AppealService 新建（业务逻辑核心）| 1.5 h |
| practice_screen 加 banner + 申诉按钮 + appealStatus 处理 | 1 h |
| parent_review_screen 加争议待审 tab | 2.5 h |
| question_update_service 解析 _ai_dispute → DB | 30 min |
| famin_appeal_decisions.jsonl 写 + worker prompt 更新 | 1 h |
| 测试 + APK build + Famin 实测一轮 | 1 h |
| 总 | **~8 h** |

## 实施顺序（单 session）

1. **schema + model** (1 h)
2. **AppealService** (1.5 h)
3. **AI 争议入库流程** (30 min)
4. **小孩练习屏 UI** (1 h)
5. **家长审核屏 UI** (2.5 h)
6. **学习机制 + APK build + 测试** (2 h)

## 触发条件

V3.13 启动需要 Famin 拍板 + 至少 1 个 session 充分 token。

启动建议时机:
- Phase 3 第三批扫完（剩 ~133 套数学 + 5 套语文重扫）后，积累更多 AI 争议样本
- 或者 Famin 觉得当前积累的 3 道争议题（罗湖 Q10/龙岗 Q10/龙华 Q11）够触发

## 与现有系统兼容性

- ✅ V3.8.3 subjective 审核机制保留不变（同 parent_review_screen 加 tab）
- ✅ DB v22 升级保后向兼容（V3.12.22 用户老题库 ai_dispute_json 列默认 NULL）
- ✅ V3.12.22 \|\|\| 兜底机制保留（"漏算明显量"边界）。V3.13 起更倾向用 AI 争议入审核而非 \|\|\|

## 待 Famin 拍板

- [ ] 启动 V3.13 实施时机（现在 / Phase 3 全扫完后 / 其他）
- [ ] schema 设计是否要调整（appeal_record 字段 / DB v22 升级方式）
- [ ] UI 是否走 parent_review_screen 加 tab vs 独立新屏
