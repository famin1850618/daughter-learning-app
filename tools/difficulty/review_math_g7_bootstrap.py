#!/usr/bin/env python3
"""Grade-7 math round bootstrap reviewer (read-only candidate generator).

This tool is intentionally conservative:

* it accepts batch paths/directories through CLI arguments;
* it never edits a batch or the index;
* unconfirmed candidate anchors can explain a comparison, but cannot make a
  result ``confident`` or override the rubric score;
* it emits JSONL/Markdown only when an explicit output path is supplied.

It is a Stage-0 bootstrap aid, not a calibrated production router.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any, Iterable


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_ANCHORS = REPO_ROOT / "docs/difficulty/g7_math_anchor_candidates.json"

NOVELTY_TERMS = (
    "定义", "新定义", "规律", "递推", "取整", "存在", "任意", "分类讨论",
    "动点", "探究", "综合与实践", "项目式", "最大值", "最小值", "折叠",
)
REPRESENTATION_TERMS = (
    "如图", "数轴", "统计图", "表格", "流程图", "展开图", "函数关系",
    "图象", "图像", "尺规作图",
)
DIRECT_TERMS = (
    "相反数", "系数是", "次数是", "用科学记数法表示", "比较大小",
    "正数与负数", "直接写出", "根据定义",
)
BRANCH_TERMS = (
    "两种情况", "三种情况", "所有可能", "任意", "是否存在", "至少", "至多",
    "分类讨论", "答案不唯一",
)
METHOD_TERMS = (
    "所以", "因此", "进而", "再", "然后", "由此", "可得", "解得",
    "代入", "化简", "分类", "情况",
)
OP_RE = re.compile(r"(?:\\times|\\div|[+\-×÷=]|\\frac|\^\{|平方|立方)")
NUMBER_RE = re.compile(r"(?<![A-Za-z])\d+(?:\.\d+)?")
CHINESE_TOKEN_RE = re.compile(r"[\u3400-\u9fff]{1,6}|[A-Za-z]+")


@dataclass(frozen=True)
class Signals:
    steps: int
    novelty: int
    representations: int
    branching: int
    kp_span: int
    calculation: int
    directness: int


def _clamp(value: int, low: int, high: int) -> int:
    return max(low, min(high, value))


def _count_distinct_terms(text: str, terms: Iterable[str]) -> int:
    return sum(1 for term in terms if term in text)


def estimate_signals(question: dict[str, Any]) -> Signals:
    """Extract explainable, grade-7-specific signals without using old round."""
    content = str(question.get("content") or "")
    explanation = str(question.get("explanation") or "")
    combined = f"{content}\n{explanation}"

    method_hits = _count_distinct_terms(explanation, METHOD_TERMS)
    equation_lines = sum(1 for line in explanation.splitlines() if "=" in line)
    subparts = len(re.findall(r"(?:^|[；;。\n])\s*[（(][1-9][)）]", content))
    steps = _clamp(max(1, method_hits // 2 + 1, equation_lines, subparts), 1, 4)

    novelty = _clamp(_count_distinct_terms(combined, NOVELTY_TERMS), 0, 3)
    representations = _clamp(_count_distinct_terms(content, REPRESENTATION_TERMS), 0, 3)
    branching = _clamp(_count_distinct_terms(content, BRANCH_TERMS) + subparts, 0, 3)

    kp = str(question.get("knowledge_point") or "")
    chapter = str(question.get("chapter") or "")
    explicit_cross = 0
    families = {
        "equation": ("方程", "未知数", "设"),
        "geometry": ("角", "线段", "三角形", "正方体", "折叠", "平行"),
        "algebra": ("代数式", "整式", "同类项", "字母"),
        "number": ("有理数", "绝对值", "数轴", "正负"),
        "statistics": ("统计", "频数", "调查", "概率"),
        "function": ("函数", "变量", "图象", "图像"),
    }
    primary = next((name for name, words in families.items() if any(w in kp + chapter for w in words)), None)
    for name, words in families.items():
        if name != primary and any(w in combined for w in words):
            explicit_cross += 1
    kp_span = _clamp(1 + explicit_cross, 1, 4)

    op_count = len(OP_RE.findall(combined))
    numbers = [float(x) for x in NUMBER_RE.findall(content)]
    has_fraction = "\\frac" in combined or bool(re.search(r"\d+\s*/\s*\d+", combined))
    has_large = any(abs(n) >= 1000 for n in numbers)
    calculation = _clamp((op_count >= 3) + (op_count >= 7) + has_fraction + has_large, 0, 3)

    directness = _clamp(_count_distinct_terms(content, DIRECT_TERMS), 0, 2)
    return Signals(steps, novelty, representations, branching, kp_span, calculation, directness)


def rubric_round(signals: Signals) -> tuple[int, int, list[str]]:
    """Return proposed round, transparent score and active rubric reasons."""
    score = 0
    reasons: list[str] = []

    if signals.steps >= 4:
        score += 3
        reasons.append("解题链估计为4步或以上")
    elif signals.steps == 3:
        score += 2
        reasons.append("解题链估计为3步")
    elif signals.steps == 2:
        score += 1
        reasons.append("解题链估计为2步")
    else:
        reasons.append("解题链估计为1步")

    if signals.novelty >= 2:
        score += 2
        reasons.append("含两个以上新定义/规律/动态探究信号")
    elif signals.novelty == 1:
        score += 1
        reasons.append("含一个新定义、规律或动态信号")

    if signals.representations >= 2:
        score += 1
        reasons.append("需联合两种以上图表/几何表征")
    if signals.branching >= 2:
        score += 2
        reasons.append("存在明显分支或多情形")
    elif signals.branching == 1:
        score += 1
        reasons.append("存在一个条件分支")
    if signals.kp_span >= 3:
        score += 2
        reasons.append("解题路径疑似跨3个以上知识族")
    elif signals.kp_span == 2:
        score += 1
        reasons.append("解题路径疑似跨2个知识族")
    if signals.calculation >= 3:
        score += 2
        reasons.append("计算表达负荷较高")
    elif signals.calculation == 2:
        score += 1
        reasons.append("计算表达负荷中等")
    if signals.directness:
        score -= 2 * signals.directness
        reasons.append("题面含直接定义/识记信号，执行降档保护")

    if score <= 0:
        proposed = 1
    elif score <= 2:
        proposed = 2
    elif score <= 4:
        proposed = 3
    else:
        proposed = 4
    return proposed, score, reasons


def _tokens(text: str) -> set[str]:
    return {t.lower() for t in CHINESE_TOKEN_RE.findall(text)}


def anchor_similarity(question: dict[str, Any], anchor: dict[str, Any]) -> float:
    qkp = str(question.get("knowledge_point") or "")
    akp = str(anchor.get("knowledge_point") or "")
    kp_score = 1.0 if qkp == akp else (0.5 if qkp.split("/")[0] == akp.split("/")[0] else 0.0)
    type_score = 1.0 if question.get("type") == anchor.get("type") else 0.0
    qt, at = _tokens(str(question.get("content") or "")), _tokens(str(anchor.get("content") or ""))
    lexical = len(qt & at) / max(len(qt | at), 1)
    return round(0.55 * kp_score + 0.20 * type_score + 0.25 * lexical, 4)


def load_anchors(path: Path) -> list[dict[str, Any]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("grade") != 7 or data.get("subject") != "math":
        raise ValueError("anchor file must declare grade=7 and subject=math")
    return list(data.get("anchors") or [])


def nearest_anchor(question: dict[str, Any], anchors: list[dict[str, Any]]) -> tuple[dict[str, Any] | None, float]:
    if not anchors:
        return None, 0.0
    ranked = sorted(((anchor_similarity(question, a), a) for a in anchors), key=lambda x: x[0], reverse=True)
    return ranked[0][1], ranked[0][0]


def review_question(batch_name: str, question: dict[str, Any], anchors: list[dict[str, Any]]) -> dict[str, Any]:
    signals = estimate_signals(question)
    proposed, score, reasons = rubric_round(signals)
    anchor, similarity = nearest_anchor(question, anchors)
    anchor_status = anchor.get("status") if anchor else None
    anchor_round = anchor.get("proposed_round") if anchor else None
    exact_confirmed = bool(
        anchor
        and anchor_status == "confirmed_by_famin"
        and anchor.get("source_ref") == f"{batch_name}#{question.get('local_id')}"
    )

    # Candidate anchors are explanatory only. Confirmed anchors may support the
    # result but never silently override a rubric disagreement.
    if exact_confirmed and anchor_round == proposed:
        flag = "confident"
        confidence_reason = "Famin-confirmed exact anchor agrees with rubric"
    elif anchor_status == "confirmed_by_famin" and similarity >= 0.72 and anchor_round == proposed:
        flag = "confident"
        confidence_reason = "close Famin-confirmed anchor agrees with rubric"
    else:
        flag = "review"
        confidence_reason = "G7 rubric/anchors are not yet sufficiently confirmed"
    if anchor_status == "confirmed_by_famin" and anchor_round is not None and abs(anchor_round - proposed) >= 2:
        flag = "review"
        confidence_reason = "rubric and confirmed anchor differ by at least two rounds"

    subpart_count = len(re.findall(r"(?:^|[；;。\n])\s*[（(][1-9][)）]", str(question.get("content") or "")))
    route_status = "blocked_structure_reconstruction" if subpart_count >= 2 else "eligible_for_round_review"
    if route_status != "eligible_for_round_review":
        flag = "review"
        confidence_reason = "multipart source must be reconstructed before final round routing"

    return {
        "question_ref": f"{batch_name}#{question.get('local_id')}",
        "grade": 7,
        "subject": "math",
        "chapter": question.get("chapter"),
        "knowledge_point": question.get("knowledge_point"),
        "type": question.get("type"),
        "content_preview": str(question.get("content") or "")[:180],
        "proposed_round": proposed,
        "flag": flag,
        "method": "g7_math_stage0_bootstrap_rubric",
        "route_status": route_status,
        "detected_subpart_count": subpart_count,
        "rubric_score": score,
        "signals": asdict(signals),
        "reasoning": reasons,
        "nearest_anchor": {
            "candidate_id": anchor.get("candidate_id") if anchor else None,
            "status": anchor_status,
            "proposed_round": anchor_round,
            "similarity": similarity,
        },
        "confidence_reason": confidence_reason,
        "original_round_observed_but_not_used": question.get("round"),
    }


def discover_batches(paths: list[str], batch_dir: str | None, pattern: str) -> list[Path]:
    found = [Path(p).resolve() for p in paths]
    if batch_dir:
        found.extend(sorted(Path(batch_dir).resolve().glob(pattern)))
    unique: list[Path] = []
    seen: set[Path] = set()
    for path in found:
        if path not in seen:
            unique.append(path)
            seen.add(path)
    if not unique:
        raise ValueError("provide batch paths or --batch-dir")
    return unique


def load_questions(paths: list[Path]) -> tuple[list[tuple[str, dict[str, Any]]], dict[str, str]]:
    rows: list[tuple[str, dict[str, Any]]] = []
    hashes: dict[str, str] = {}
    for path in paths:
        raw = path.read_bytes()
        hashes[str(path)] = hashlib.sha256(raw).hexdigest()
        batch = json.loads(raw)
        if batch.get("grade") != 7 or batch.get("subject") != "math":
            raise ValueError(f"not a G7 math batch: {path}")
        for question in batch.get("questions") or []:
            rows.append((path.name, question))
    return rows, hashes


def assert_unchanged(hashes: dict[str, str]) -> None:
    for raw_path, before in hashes.items():
        after = hashlib.sha256(Path(raw_path).read_bytes()).hexdigest()
        if before != after:
            raise RuntimeError(f"input batch changed unexpectedly: {raw_path}")


def write_jsonl(path: Path, records: list[dict[str, Any]], force: bool) -> None:
    if path.exists() and not force:
        raise FileExistsError(f"refusing to overwrite {path}; pass --force")
    path.parent.mkdir(parents=True, exist_ok=True)
    text = "".join(json.dumps(r, ensure_ascii=False, sort_keys=True) + "\n" for r in records)
    path.write_text(text, encoding="utf-8")


def write_verify_markdown(path: Path, anchors: list[dict[str, Any]], force: bool) -> None:
    if path.exists() and not force:
        raise FileExistsError(f"refusing to overwrite {path}; pass --force")
    lines = [
        "# G7 数学难度候选锚点：Famin 抽审稿",
        "",
        "> 状态：Stage 0 bootstrap 候选。本文中的档位均未获 Famin 确认，不能写回题库，不能称为已校准锚点。",
        "> 工具局限：当前 reviewer 是可解释启发式；图片题必须结合原图审定；旧题只有答案字母时，不能据此验证完整推理链。",
        "",
        "## 最小审定方式",
        "",
        "每档先审 3 题（标有 `minimum_review: true`），共 12 题。若某档有 2 题以上被改档，该档剩余候选全部复审。",
        "",
    ]
    grouped: dict[int, list[dict[str, Any]]] = defaultdict(list)
    for anchor in anchors:
        grouped[int(anchor["proposed_round"])].append(anchor)
    for round_no in range(1, 5):
        lines.extend([f"## R{round_no} 候选", ""])
        for anchor in grouped.get(round_no, []):
            block = [
                f"### `{anchor['candidate_id']}`",
                "",
                f"- 来源：`{anchor['source_ref']}`",
                f"- 范围：`{anchor['source_scope']}`",
                f"- 题型 / KP：`{anchor['type']}` / `{anchor['knowledge_point']}`",
                f"- 最小审定清单：{'是' if anchor.get('minimum_review') else '否'}",
                "",
                f"题面：{anchor['content']}",
                "",
                f"官方答案：`{anchor['answer']}`",
                "",
                f"候选理由：{anchor['reasoning']}",
                "",
                f"- [ ] 同意 R{round_no}",
            ]
            block.extend(f"- [ ] 改为 R{alternative}" for alternative in range(1, 5) if alternative != round_no)
            block.extend([
                "- [ ] 暂不作为锚点（题面/图片/答案证据不足）",
                "- Famin comment：",
                "",
            ])
            lines.extend(block)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("batches", nargs="*", help="explicit G7 math batch JSON paths")
    parser.add_argument("--batch-dir", help="directory to scan; no repository path is hardcoded")
    parser.add_argument("--glob", default="realpaper_g7_math_*.json", help="glob used with --batch-dir")
    parser.add_argument("--anchors", default=str(DEFAULT_ANCHORS), help="candidate/confirmed G7 anchor JSON")
    parser.add_argument("--output", help="optional JSONL candidate report path")
    parser.add_argument("--verify-output", help="optional Famin anchor-review Markdown path")
    parser.add_argument("--force", action="store_true", help="replace explicit report outputs")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        paths = discover_batches(args.batches, args.batch_dir, args.glob)
        questions, hashes = load_questions(paths)
        anchors = load_anchors(Path(args.anchors))
        records = [review_question(name, q, anchors) for name, q in questions]
        if args.output:
            write_jsonl(Path(args.output), records, args.force)
        if args.verify_output:
            write_verify_markdown(Path(args.verify_output), anchors, args.force)
        assert_unchanged(hashes)
    except (OSError, ValueError, RuntimeError, json.JSONDecodeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    eligible = [r for r in records if r["route_status"] == "eligible_for_round_review"]
    blocked = len(records) - len(eligible)
    rounds = Counter(r["proposed_round"] for r in eligible)
    flags = Counter(r["flag"] for r in records)
    print(f"reviewed={len(records)} batches={len(paths)} read_only=true")
    print(f"eligible={len(eligible)} blocked_structure={blocked}")
    print("round_distribution_eligible=" + json.dumps(dict(sorted(rounds.items())), ensure_ascii=False))
    print("flag_distribution=" + json.dumps(dict(sorted(flags.items())), ensure_ascii=False))
    if not args.output:
        print("no JSONL written (use --output explicitly)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
