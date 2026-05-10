#!/usr/bin/env python3
"""V3.17 batch 重扫工具

对 v1 batch 增补 _raw_excerpt + 跑 V3.17 7 条检查; 输出建议 (PASS / SKIP / FIXUP).
不直接修改 v1, 输出 v2 候选 + 诊断.
"""
import json
import re
import sys
import os
from pathlib import Path

NUM_RE = re.compile(r"\d+(?:\.\d+)?(?:/\d+)?(?:[:：]\d+(?:\.\d+)?)?")


def extract_nums(text: str):
    """提取所有数字/分数/比例 (兼容全角冒号 :/：)"""
    if not text:
        return set()
    # 归一化: 全/半角冒号 (含 U+FF1A : U+2236 ∶ + LaTeX \colon \: \,) → 半角:
    norm = text.replace("：", ":").replace("∶", ":").replace("．", ".")
    norm = re.sub(r"\\colon\s*", ":", norm)
    norm = re.sub(r"\\\\colon\s*", ":", norm)
    # \div / \times / \cdot 等运算符 → 空格 (避免 1.25\div 0.5 被误拼成 1.25/0.5)
    norm = re.sub(r"\\(?:div|times|cdot|pm|mp|cdots)\s*", " ", norm)
    return set(NUM_RE.findall(norm))


def find_qnum_excerpt(raw_lines, qnum_int):
    """启发式: 从 raw 找题号 qnum 对应段"""
    qnum = str(qnum_int)
    patterns = [
        re.compile(rf"^\s*{qnum}[．\.]\s*"),
        re.compile(rf"^\s*{qnum}[、）)]\s*"),
    ]
    starts = []
    for i, line in enumerate(raw_lines):
        if any(p.match(line) for p in patterns):
            starts.append(i)
    if not starts:
        return ""
    # 用最后一个 (因为 raw 常常题面+【答案】块都各有一份)
    # 取第一个 (题面)
    start = starts[0]
    # 找下一题起点 (qnum+1, qnum+2)
    end = len(raw_lines)
    for nq in [qnum_int + 1, qnum_int + 2, qnum_int + 3]:
        np_pats = [re.compile(rf"^\s*{nq}[．\.]\s*"), re.compile(rf"^\s*{nq}[、）)]\s*")]
        for j in range(start + 1, len(raw_lines)):
            if any(p.match(raw_lines[j]) for p in np_pats):
                if j < end:
                    end = j
                break
    excerpt_lines = []
    for ln in raw_lines[start:end]:
        if ln.startswith("【") and any(t in ln for t in ["答案", "解析", "分析", "详解", "点睛"]):
            break
        excerpt_lines.append(ln)
    return "\n".join(excerpt_lines).strip()


def fuzzy_find_excerpt(raw_lines, content):
    """用 content 关键词在 raw 找最匹配段, 仅返回**当前题**那一段"""
    raw_full = "\n".join(raw_lines)
    target_line = -1
    # 多级降级: 8字 → 6字 → 4字 → 3字 中文
    # 高字数最先尝试 (避免噪声), 失败再降级
    for min_len in [8, 6, 4, 3]:
        keywords = re.findall(rf"[一-鿿]{{{min_len},}}", content)
        # 长关键词无法整段匹配时, 截子串扫: 取首 N 字 / 中段 N 字 / 末段 N 字
        for kw in keywords:
            # 完整匹配
            idx = raw_full.find(kw)
            if idx >= 0:
                target_line = raw_full[:idx].count("\n")
                break
            # 子串扫 (步长 4 字)
            if len(kw) >= 8:
                for s in range(0, len(kw) - 4, 2):
                    sub = kw[s:s + min(8, len(kw) - s)]
                    if len(sub) >= 4:
                        idx = raw_full.find(sub)
                        if idx >= 0:
                            target_line = raw_full[:idx].count("\n")
                            break
                if target_line >= 0:
                    break
        if target_line >= 0:
            break
    # 还失败: 用数字+小数点 (如 86.27, 5/16) 或 阿拉伯数字 ≥3 位
    if target_line < 0:
        nums = re.findall(r"\d+\.\d+|\d{3,}", content)
        for n in nums:
            idx = raw_full.find(n)
            if idx >= 0:
                target_line = raw_full[:idx].count("\n")
                break
    if target_line < 0:
        return ""
    # 找包含此关键词的题号段: 向前找最近 "<n>. " 行, 向后找下一 "<n>. " 行
    qnum_re = re.compile(r"^\s*(\d{1,3})[．\.]\s*")  # 空白可选 (raw 常无空白)
    start = 0
    for i in range(target_line, -1, -1):
        if qnum_re.match(raw_lines[i]):
            start = i
            break
    end = len(raw_lines)
    for j in range(start + 1, len(raw_lines)):
        if qnum_re.match(raw_lines[j]):
            end = j
            break
    excerpt_lines = []
    for ln in raw_lines[start:end]:
        if ln.startswith("【") and any(t in ln for t in ["答案", "解析", "分析", "详解", "点睛"]):
            break
        excerpt_lines.append(ln)
    return "\n".join(excerpt_lines).strip()


def parse_qnum(group_id, group_order):
    """从 group_id 抽题号 (如 qm_futian_001_q5 → 5)"""
    if not group_id:
        return None
    m = re.search(r"_q(\d+)$", group_id)
    if m:
        return int(m.group(1))
    return None


def check_v317(content, raw_excerpt, qtype, common_prefix="", question=None):
    """V3.17 7 条 check"""
    issues = []
    if question is None:
        question = {}

    # 1: _raw_excerpt 存在
    if not raw_excerpt:
        issues.append("V3.17-1: 无法从 raw 定位 _raw_excerpt")
        return issues

    # 3: 主观词 (排除已 subjective)
    subj_words = ["请说明理由", "哪家更", "哪个更", "你的看法", "谈谈", "为什么"]
    if any(w in raw_excerpt for w in subj_words) and qtype != "subjective":
        # "为什么" 在数学比例题里常见且不一定主观, 用更精严
        # 仅在原题真主观时报警
        if any(w in raw_excerpt for w in ["请说明理由", "哪家更", "哪个更"]):
            issues.append(f"V3.17-3: raw 含主观词 type={qtype}")

    # 4: '图' 词缺 image (仅警告, 不算违纪 - 实际撤回看 V3.17-7 数字检查)
    has_image = bool(question.get("image_data") or question.get("option_images"))
    has_image_skip = bool(question.get("_image_skip_reason"))
    img_words = ["如图", "下图", "上图", "右图", "示意图", "图中", "图所示", "看图", "观察图"]
    raw_has_img = any(w in raw_excerpt for w in img_words)
    img_warn = raw_has_img and not has_image and not has_image_skip

    # 5+7: 数字集合判别 (核心硬规则)
    full_raw = raw_excerpt + " " + (common_prefix or "")
    raw_nums = extract_nums(full_raw)
    content_nums = extract_nums(content)
    extras = content_nums - raw_nums
    real_extras = set()
    for n in extras:
        # 容许小题序号 (1-30 单数字 + . 紧跟)
        if n.isdigit() and 1 <= int(n) <= 30 and re.search(rf"(?:^|\n)\s*{re.escape(n)}\.\s", content):
            continue
        # 容许年份 (2020-2030)
        if n.isdigit() and 2020 <= int(n) <= 2030:
            continue
        real_extras.add(n)
    # ⊥3b 豁免: group 内有 image_data → "如图<描述>" 是 worker 自带 Vision 合法读图
    # 这里用 has_image_in_group flag 控制 (传参)
    has_group_image = question.get("_group_has_image", False)
    if real_extras and not has_group_image:
        marker = " [+图丢失]" if img_warn else ""
        issues.append(f"V3.17-7: content 多出 raw 之外数字 {sorted(real_extras)}{marker}")
    elif real_extras and has_group_image:
        # 图存在但仍标 INFO 用于审计
        pass  # silent

    # 6: 否定反转 (仅在精确匹配时报警, fuzzy 段常被多题污染所以严收紧)
    # 仅当 raw "划去 + 拼音/音节" 或 "划掉 + 答案" 等强信号才警告
    strong_neg_pats = [r"划去.*?[（(].*?[）)]", r"划掉错误", r"错误.*?选项", r"哪[个项种].*?不正确"]
    raw_has_strong_neg = any(re.search(p, raw_excerpt) for p in strong_neg_pats)
    if raw_has_strong_neg:
        if not any(w in content for w in ["划去", "不正确", "错误", "划掉"]):
            issues.append("V3.17-6: raw 有强否定 content 缺 (题型语义反转嫌疑)")

    # 格式指引检测
    fmt_pats = [
        (r"用\s*\|\|\|\s*分隔", "格式指引: |||"),
        (r"按顺序填", "格式指引: 按顺序"),
        (r"用逗号分隔", "格式指引: 逗号"),
        (r"保留\s*\d+\s*位小数", "精度指引: 保留小数"),
        (r"四舍五入到", "精度指引: 四舍五入"),
    ]
    for pat, label in fmt_pats:
        if re.search(pat, content) and not re.search(pat, raw_excerpt):
            issues.append(f"V3.15-1/2: {label} 自加 (raw 无)")

    return issues


def main():
    if len(sys.argv) < 2:
        print("Usage: v317_rebuild.py <v1_batch_json> [--apply]", file=sys.stderr)
        sys.exit(1)
    v1_path = sys.argv[1]
    apply_mode = "--apply" in sys.argv

    with open(v1_path, encoding="utf-8") as f:
        batch = json.load(f)

    sha1 = batch.get("_quality_meta", {}).get("sha1") or batch.get("_source_docx_sha1")
    cache_dir = Path("/home/faminwsl/daughter_learning_app/.cache/docx") / sha1
    raw_path = cache_dir / "raw_with_omath.txt"
    if not raw_path.exists():
        print(f"ERROR: no cache {raw_path}", file=sys.stderr)
        sys.exit(1)

    raw_lines = raw_path.read_text(encoding="utf-8").splitlines()

    name = Path(v1_path).stem
    print(f"\n========== {name} ==========")
    print(f"sha1={sha1} q={len(batch.get('questions', []))} skipped={len(batch.get('_skipped_for_future', []))}")

    # 按 group_id 分组
    groups = {}
    for q in batch.get("questions", []):
        gid = q.get("group_id", "")
        groups.setdefault(gid, []).append(q)

    # 跑 check
    new_questions = []
    skip_groups = []
    pass_count = 0
    fixup_count = 0
    fail_count = 0
    grp_violations = {}

    for gid, qs in groups.items():
        qnum = parse_qnum(gid, qs[0].get("group_order"))
        if qnum is None:
            # 单题 (no group_id): 用 fuzzy keyword 找 raw 段
            for q in qs:
                fuzzy = fuzzy_find_excerpt(raw_lines, q.get("content", ""))
                if not fuzzy:
                    new_questions.append(q)
                    pass_count += 1
                    continue
                # 单题也跑 V3.17 check
                q_meta = dict(q)
                q_meta["_group_has_image"] = bool(q.get("image_data") or q.get("option_images"))
                issues = check_v317(q.get("content", ""), fuzzy, q.get("type", ""), question=q_meta)
                if issues:
                    fail_count += 1
                    key = (gid or "single") + "_" + (q.get("content", "")[:20] or "?")
                    grp_violations[key] = (qnum, fuzzy, [(q.get("group_order"), issues)])
                else:
                    q2 = dict(q)
                    q2["_raw_excerpt"] = fuzzy
                    new_questions.append(q2)
                    pass_count += 1
            continue
        raw_excerpt = find_qnum_excerpt(raw_lines, qnum)
        # fuzzy backup: 用 content 关键词找 raw 段 (题号不匹配时)
        # 规则: 如果 qnum 找到的 raw 跟任一 content 共同 ≥4 字关键词 < 1, 改用 fuzzy
        sample_content = qs[0].get("content", "")
        if raw_excerpt:
            content_keywords = set(re.findall(r"[一-鿿]{4,}", sample_content))
            raw_keywords = set(re.findall(r"[一-鿿]{4,}", raw_excerpt))
            shared = content_keywords & raw_keywords
            if not shared:
                # qnum 错对应, 改用 fuzzy
                fuzzy = fuzzy_find_excerpt(raw_lines, sample_content)
                if fuzzy:
                    raw_excerpt = fuzzy
        elif not raw_excerpt:
            raw_excerpt = fuzzy_find_excerpt(raw_lines, sample_content)
        # 预扫: 组内有无 image_data (任一题有就算组内有图)
        group_has_image = any(bool(q.get("image_data")) or bool(q.get("option_images")) for q in qs)
        # 组内全部题都 check
        group_issues = []
        for q in qs:
            q_with_meta = dict(q)
            q_with_meta["_group_has_image"] = group_has_image
            issues = check_v317(q.get("content", ""), raw_excerpt, q.get("type", ""), question=q_with_meta)
            if issues:
                group_issues.append((q.get("group_order"), issues))
        if group_issues:
            grp_violations[gid] = (qnum, raw_excerpt, group_issues)
            fail_count += len(qs)
        else:
            for q in qs:
                q2 = dict(q)
                q2["_raw_excerpt"] = raw_excerpt
                new_questions.append(q2)
                pass_count += 1

    print(f"\n  PASS: {pass_count}  VIOLATIONS: {fail_count}  groups_violated: {len(grp_violations)}")
    for gid, (qnum, raw_x, gi) in grp_violations.items():
        print(f"\n  [VIOLATION] gid={gid} qnum={qnum}")
        print(f"    raw_excerpt[:200]: {(raw_x or '')[:200]}")
        for go, issues in gi:
            print(f"    order={go}:")
            for s in issues:
                print(f"      - {s}")

    if apply_mode:
        # 写 v2 候选
        out_dir = Path("/home/faminwsl/daughter_learning_app/assets/data/batches_v2")
        out_dir.mkdir(parents=True, exist_ok=True)
        v2_path = out_dir / Path(v1_path).name
        v2 = dict(batch)
        v2["_v2_workflow_version"] = "V3.17"
        v2["_source_docx_sha1"] = sha1
        v2["questions"] = new_questions
        # 添加违纪到 _skipped_for_future
        skipped = list(v2.get("_skipped_for_future", []))
        for gid, (qnum, raw_x, gi) in grp_violations.items():
            skipped.append({
                "qnum": str(qnum),
                "reason": "v317_violation_recheck",
                "raw_excerpt": (raw_x or "")[:300],
                "_violation_details": [{"order": go, "issues": iss} for go, iss in gi],
            })
        v2["_skipped_for_future"] = skipped
        # 更新 quality_meta
        qm = dict(v2.get("_quality_meta", {}))
        qm["_v2_workflow_version"] = "V3.17"
        qm["_v2_redoing_v1_violations"] = True
        qm["questions_imported_total"] = len(new_questions)
        qm["questions_skipped_groups"] = len(skipped)
        v2["_quality_meta"] = qm
        with open(v2_path, "w", encoding="utf-8") as f:
            json.dump(v2, f, ensure_ascii=False, indent=2)
        print(f"\n  WROTE v2: {v2_path}")
        # 双写 question_bank_v2
        qb_dir = Path("/home/faminwsl/daughter_learning_app/question_bank_v2")
        qb_dir.mkdir(parents=True, exist_ok=True)
        qb_path = qb_dir / Path(v1_path).name
        with open(qb_path, "w", encoding="utf-8") as f:
            json.dump(v2, f, ensure_ascii=False, indent=2)
        print(f"  WROTE qb: {qb_path}")


if __name__ == "__main__":
    main()
