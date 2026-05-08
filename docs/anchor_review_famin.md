# 锚点题审核（Famin 用）— 索引

> **2026-05-08 update：** 之前的紧凑表格题面被截断，重新做成"每道题完整 detail"按学科分文件。

## 三份审核文件

| 文件 | 道数 | 重点 |
|------|------|------|
| [anchor_review_math.md](anchor_review_math.md) | 20 | 11 KP / 5 chapter / 3 题型，agent 自评无存疑 |
| [anchor_review_chinese.md](anchor_review_chinese.md) | 20 | 15 KP，**9 道 ⚠️[审]**（R3/R4 真题不足，agent 升档了，最需 Famin 判定）|
| [anchor_review_english.md](anchor_review_english.md) | 20 | 15 KP，含 4 道听力多角色（带 audio_text + speakers）|

## 标注流程（每道题最后一段）

每道题底部有：

```
**Famin 你的判断：**

- [ ] 同意 RX
- [ ] 实际是 R1
- [ ] 实际是 R2
- [ ] 实际是 R3
- [ ] 实际是 R4
- [ ] ? 拿不准

**Comment（改档/拿不准时填）：**

> 
```

**操作：**
- **同意 agent 的档** → 不动，整块留空
- **不同意** → 把对应行的 `[ ]` 改成 `[X]`，加一句 comment 说明
- **拿不准** → `[X] ?` + comment 写为啥

## 完成后

告诉我"锚点审核做完了"或"数学审完了"（按科目分批也行），我跑脚本提取你的标注：

1. 解析 markdown 中的 `[X]` 选择
2. 写入 `calibration_log/famin_feedback.jsonl`
3. 重排 `anchor_questions_g6_*.json` 的 round 字段（如果有改档）
4. 喂给后续 D2 reviewer 重审 1925 道 + 未来 difficulty skill 训练

## 打开方式

| 方式 | 链接 |
|------|------|
| GitHub Web（手机/平板）| https://github.com/famin1850618/daughter-learning-app/blob/main/docs/anchor_review_chinese.md（点 ✏️ 编辑）|
| 本地 VS Code | `code ~/daughter_learning_app/docs/anchor_review_<科目>.md` |
| Termius / 手机 WSL | `vim docs/anchor_review_<科目>.md` |

## 重点关注（语文 9 道 ⚠️[审]）

语文原 batch R3 仅 4 道、R4 是 0，agent 不得不从 R2/R3 强行升档 9 道：
- R3: 4 道 [审]（孔子态度 / 段意概括 / 心灵监狱主旨 / 文学常识不正确）
- R4: 5 道 [审]（端午"莫不"赏析 / 这一过程指代 / 向日葵情感四阶段 / 对偶工整 / 买馒头段落衔接）

这 9 道最容易判错，**优先看**。如果你判它们其实是 R2 → reviewer agent 重审 1925 道时会按你的判断回调整张语文题包。
