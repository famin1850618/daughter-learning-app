# G7 语文难度路由 bootstrap 审计

日期：2026-08-11

## 结论

七年级语文目前没有经 Famin 确认的专用 anchors，因此不能沿用“语文已 Stage 1”的全科表述直接落正式 round。本次将 G7 单独置于 Stage 0，只产出候选 rubric、12 道抽审题和只读检查工具；没有回填任何 batch。

## 样本范围

| 范围 | 批次 / 题数 | type | round / 候选现状 |
|---|---:|---|---|
| 已生产 | 2 / 46 | fill 14、choice 8、subjective 24 | R1 24、R2 10、R3 12、R4 0 |
| 新候选 | 2 / 48 | fill 9、choice 3、subjective 36 | 正式 round 全为 null；worker 候选仅作信号 |

四批输入 SHA-256 已写入 `g7_chinese_anchor_candidates.json`，只读 reviewer 会在运行前后再次核对。

## G6 与 G7 的关键差异

- G6 anchor 池主动排除了主观题、作文和阅读 cluster；本次 94 道 G7 样本中 subjective 达 60 道，若直接套 G6，会让最主要题型没有标尺。
- G7 大量采用主题化综合实践、整篇现代文、两文比较、材料群、名著整本书和 600 字以上写作。难度核心从“选项干扰”扩展到证据组织和持续表达。
- G7 组合题是实际抽题单位，必须先逐子题判断再组内统一；G6 旧 anchors 基本无法提供这一维度。
- 年级相对性不同：七上课内名句、字词和固定常识仍可是 R1，不能因为内容比六年级陌生就自动升档。

## G6 资产不可直接继承的风险

- `docs/anchor_questions_g6_chinese.json` 含 disabled、unsure 和 Famin 改档条目；部分 `anchor_id` 名称仍写 R3/R4，但实际 `round` 已被改成 R1/R2。按名字引用会误路由。
- G6 rubric 的 R4 例子部分曾被 Famin 降档，说明“长材料、长选项、全文依赖”不是稳定的高档充分条件。
- 现行 `docs/rubric_chinese.md` 仍以 G6 anchors 为配套；它可以提供降档/升档历史信号，但不能证明 G7 已完成首轮 verify。

## 生产 G7 round 可能的偏差

- 两批生产题均无 R4，存在明显的天花板缺失风险。
- 完整作文均被标 R1；如果 round 衡量独立完成的认知与表达负荷，这很可能低估了构思、结构和持续表达。究竟校准为 R3 还是 R4，应由本轮写作边界题确认。
- 深圳 48 中学现代文组合组 5 题的历史 round 为 `[3,1,3,3,1]`，违反现行组内统一规则。
- 罗湖生产组 5 题全部 R1，但题目覆盖修辞赏析、跨文本比较、文化评价与开放表达，可能存在批量压低，而非逐题证据判断。
- 多空默写和直接识记有时被标 R2，有时 R1；需明确“重复同类操作不自动升档”的口径。

以上均为审计信号，不是改档结论；本次没有更改生产数据。

## 候选集设计

- R1：拼音写字、主题归类、跨篇直接默写。
- R2：词性判断、病句修改、敬辞谦辞。
- R3：现代文整组、文言比较整组、名著情节作用。
- R4：多文本多空一致性、整本书精神抽象、完整半命题作文。

R4 三题均是边界候选，尤其“一个字概括名著”和常规完整作文可能被 Famin 调回 R3。保留这种不确定性比虚构稳定 R4 更符合 bootstrap 目标。

## 可复现流程

```bash
python3 tools/difficulty/review_chinese_g7_bootstrap.py \
  question_bank/realpaper_g7_chinese_renjiao_qz_shenzhen48_001.json \
  question_bank/realpaper_g7_chinese_renjiao_qm_luohu_001.json \
  /home/faminwsl/worktrees/dla_scan_cn_luohu/question_bank/realpaper_g7_chinese_renjiao_qm_luohu_002.json \
  /home/faminwsl/worktrees/dla_scan_cn_yantian/question_bank/realpaper_g7_chinese_renjiao_qm_yantianwaiyu_001.json \
  --check
```

重新生成抽审稿时显式提供 `--verify-output docs/difficulty/g7_chinese_anchor_verify_famin.md --force`。工具只写所指定的报告文件，不写 batch、index 或 status。

## 尚未完成

- 12 道候选尚未获 Famin 确认。
- 没有对未参与选锚题做独立一致率评估。
- 没有把 G7 提升到 Stage 1，更没有达到 Stage 2。
- 没有回填、注册、提交或发布任何正式 round。
