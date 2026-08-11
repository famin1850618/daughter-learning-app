#!/usr/bin/env python3
"""Read-only Grade-7 Chinese difficulty bootstrap reviewer.

This tool validates candidate anchors and exposes candidate-only routing
evidence. It deliberately has no batch/index write-back path. Existing
production ``round`` values are reported for bias auditing, never reused as a
proposal. Until Famin confirms Grade-7 anchors, every result remains
``review``.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_ANCHORS = REPO_ROOT / "docs/difficulty/g7_chinese_anchor_candidates.json"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_anchors(path: Path) -> list[dict[str, Any]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("grade") != 7 or data.get("subject") != "chinese":
        raise ValueError("anchor file must declare grade=7 and subject=chinese")
    anchors = list(data.get("anchors") or [])
    if not anchors:
        raise ValueError("anchor file has no candidates")
    for anchor in anchors:
        if anchor.get("status") != "requires_famin_confirmation":
            raise ValueError(
                f"bootstrap anchor is not candidate-only: {anchor.get('candidate_id')}"
            )
        if anchor.get("proposed_round") not in (1, 2, 3, 4):
            raise ValueError(f"invalid proposed_round: {anchor.get('candidate_id')}")
    return anchors


def load_batches(paths: list[Path]) -> tuple[dict[str, dict[str, Any]], dict[str, str]]:
    batches: dict[str, dict[str, Any]] = {}
    hashes: dict[str, str] = {}
    for path in paths:
        resolved = path.resolve()
        raw = resolved.read_bytes()
        batch = json.loads(raw)
        if batch.get("grade") != 7 or batch.get("subject") != "chinese":
            raise ValueError(f"not a G7 Chinese batch: {resolved}")
        if path.name in batches:
            raise ValueError(f"duplicate batch filename: {path.name}")
        batches[path.name] = batch
        hashes[str(resolved)] = hashlib.sha256(raw).hexdigest()
    return batches, hashes


def assert_unchanged(hashes: dict[str, str]) -> None:
    for raw_path, before in hashes.items():
        after = sha256(Path(raw_path))
        if before != after:
            raise RuntimeError(f"input batch changed unexpectedly: {raw_path}")


def parse_ref(source_ref: str) -> tuple[str, int]:
    filename, marker, local_id = source_ref.rpartition("#")
    if not marker or not filename:
        raise ValueError(f"invalid source_ref: {source_ref}")
    return filename, int(local_id)


def question_lookup(batches: dict[str, dict[str, Any]]) -> dict[str, dict[str, Any]]:
    lookup: dict[str, dict[str, Any]] = {}
    for filename, batch in batches.items():
        for question in batch.get("questions") or []:
            ref = f"{filename}#{question.get('local_id')}"
            if ref in lookup:
                raise ValueError(f"duplicate question ref: {ref}")
            lookup[ref] = question
    return lookup


def top_level_candidate_map(batch: dict[str, Any]) -> dict[int, int]:
    result: dict[int, int] = {}
    for row in batch.get("_round_candidate_review") or []:
        local_id = row.get("local_id")
        candidate_round = row.get("candidate_round")
        if isinstance(local_id, int) and candidate_round in (1, 2, 3, 4):
            result[local_id] = candidate_round
    return result


def observed_worker_candidate(batch: dict[str, Any], question: dict[str, Any]) -> int | None:
    direct = question.get("_round_candidate")
    if direct in (1, 2, 3, 4):
        return int(direct)
    return top_level_candidate_map(batch).get(question.get("local_id"))


def validate_group_anchor(
    anchor: dict[str, Any], batches: dict[str, dict[str, Any]], lookup: dict[str, dict[str, Any]]
) -> list[str]:
    issues: list[str] = []
    member_refs = anchor.get("group_member_refs") or []
    if anchor.get("candidate_kind") != "group":
        if member_refs:
            issues.append("single candidate unexpectedly declares group_member_refs")
        return issues
    if len(member_refs) < 2:
        issues.append("group candidate must contain at least two member refs")
        return issues

    group_ids: set[str] = set()
    worker_rounds: set[int] = set()
    for ref in member_refs:
        question = lookup.get(ref)
        if question is None:
            issues.append(f"missing group member: {ref}")
            continue
        group_id = question.get("group_id")
        if not group_id:
            issues.append(f"member has no group_id: {ref}")
        else:
            group_ids.add(str(group_id))
        filename, _ = parse_ref(ref)
        candidate = observed_worker_candidate(batches[filename], question)
        if candidate is not None:
            worker_rounds.add(candidate)
    if len(group_ids) != 1:
        issues.append(f"group members do not share exactly one group_id: {sorted(group_ids)}")
    if len(worker_rounds) > 1:
        issues.append(f"worker candidates are not group-unified: {sorted(worker_rounds)}")
    if worker_rounds and anchor.get("proposed_round") not in worker_rounds:
        issues.append(
            "anchor proposed_round differs from the already unified worker candidate: "
            f"anchor={anchor.get('proposed_round')} worker={sorted(worker_rounds)}"
        )
    return issues


def validate_anchor(
    anchor: dict[str, Any], batches: dict[str, dict[str, Any]], lookup: dict[str, dict[str, Any]]
) -> dict[str, Any]:
    ref = str(anchor.get("source_ref") or "")
    question = lookup.get(ref)
    issues: list[str] = []
    if question is None:
        issues.append(f"missing source question: {ref}")
        return {"candidate_id": anchor.get("candidate_id"), "valid": False, "issues": issues}

    filename, _ = parse_ref(ref)
    batch = batches[filename]
    for field in ("type", "chapter", "knowledge_point", "content", "answer"):
        if anchor.get(field) != question.get(field):
            issues.append(f"anchor field drift: {field}")
    if anchor.get("options") != question.get("options"):
        issues.append("anchor field drift: options")

    issues.extend(validate_group_anchor(anchor, batches, lookup))
    return {
        "candidate_id": anchor.get("candidate_id"),
        "source_ref": ref,
        "valid": not issues,
        "issues": issues,
        "proposed_round": anchor.get("proposed_round"),
        "status": "review",
        "worker_candidate_round_observed": observed_worker_candidate(batch, question),
        "production_round_observed_but_not_used": question.get("round"),
    }


def review_questions(
    batches: dict[str, dict[str, Any]], anchors: list[dict[str, Any]]
) -> list[dict[str, Any]]:
    """Expose only explicit candidate evidence; never infer from production round."""
    by_ref = {a["source_ref"]: a for a in anchors}
    group_anchor_by_ref: dict[str, dict[str, Any]] = {}
    for anchor in anchors:
        for ref in anchor.get("group_member_refs") or []:
            group_anchor_by_ref[ref] = anchor

    rows: list[dict[str, Any]] = []
    for filename, batch in batches.items():
        questions = list(batch.get("questions") or [])
        groups: dict[str, list[dict[str, Any]]] = defaultdict(list)
        for question in questions:
            if question.get("group_id"):
                groups[str(question["group_id"])].append(question)

        for question in questions:
            ref = f"{filename}#{question.get('local_id')}"
            anchor = by_ref.get(ref) or group_anchor_by_ref.get(ref)
            worker_candidate = observed_worker_candidate(batch, question)
            proposed = anchor.get("proposed_round") if anchor else worker_candidate
            route_status = "candidate_for_famin_review" if proposed else "no_g7_candidate"
            group_id = question.get("group_id")
            if group_id:
                member_rounds = {
                    observed_worker_candidate(batch, member)
                    for member in groups[str(group_id)]
                    if observed_worker_candidate(batch, member) is not None
                }
                if len(member_rounds) > 1:
                    route_status = "blocked_group_not_unified"
                if anchor and anchor.get("candidate_kind") == "group":
                    expected = set(anchor.get("group_member_refs") or [])
                    actual = {
                        f"{filename}#{member.get('local_id')}" for member in groups[str(group_id)]
                    }
                    if expected != actual:
                        route_status = "blocked_group_membership_drift"
            rows.append(
                {
                    "question_ref": ref,
                    "grade": 7,
                    "subject": "chinese",
                    "type": question.get("type"),
                    "chapter": question.get("chapter"),
                    "knowledge_point": question.get("knowledge_point"),
                    "group_id": group_id,
                    "candidate_id": anchor.get("candidate_id") if anchor else None,
                    "proposed_round": proposed,
                    "flag": "review",
                    "route_status": route_status,
                    "method": "g7_chinese_stage0_explicit_candidate_only",
                    "worker_candidate_round_observed": worker_candidate,
                    "production_round_observed_but_not_used": question.get("round"),
                }
            )
    return rows


def format_value(value: Any) -> str:
    if value is None:
        return "（无）"
    if isinstance(value, list):
        return "\n".join(f"- {item}" for item in value)
    return str(value)


def verify_markdown(anchors: list[dict[str, Any]]) -> str:
    lines = [
        "# G7 语文难度候选锚点：Famin 最小抽审稿",
        "",
        "> 状态：Stage 0 bootstrap。12 道均为候选，全部需要 Famin 确认；不得据此回填正式 round。",
        "> 组合题以整组为路由单位，本文显示代表题面并列出全部组员；确认档位将应用于整组。",
        "",
        "## 抽审规则",
        "",
        "每档 3 题，共 12 题。若某档有 2 题及以上改档，该档应补充候选后再审；R4 当前是边界池，允许整体下移，不能为了凑齐档位强留。",
        "",
    ]
    for round_no in range(1, 5):
        lines.extend([f"## R{round_no} 候选", ""])
        for anchor in [a for a in anchors if a["proposed_round"] == round_no]:
            lines.extend(
                [
                    f"### `{anchor['candidate_id']}`",
                    "",
                    f"- 来源：`{anchor['source_ref']}`",
                    f"- 类型 / KP：`{anchor['type']}` / `{anchor['knowledge_point']}`",
                    f"- 候选单位：`{anchor.get('candidate_kind', 'single')}`",
                    f"- 历史生产 round（仅审计，不作证据）：`{anchor.get('production_round_observed')}`",
                    f"- worker 初判（仅候选）：`{anchor.get('worker_candidate_round_observed')}`",
                ]
            )
            if anchor.get("group_member_refs"):
                lines.append("- 组员：" + "、".join(f"`{x}`" for x in anchor["group_member_refs"]))
                lines.append(f"- 组统一检查：`{anchor.get('group_unification_status')}`")
            lines.extend(
                [
                    "",
                    "题面：",
                    "",
                    str(anchor["content"]),
                    "",
                    "选项：",
                    "",
                    format_value(anchor.get("options")),
                    "",
                    f"官方答案：{format_value(anchor.get('answer'))}",
                    "",
                    f"候选理由：{anchor['reasoning']}",
                    "",
                    f"可改档位置：{anchor['adjustment_guidance']}",
                    "",
                    f"- [ ] 同意 R{round_no}",
                ]
            )
            for other in range(1, 5):
                if other != round_no:
                    lines.append(f"- [ ] 改为 R{other}")
            lines.extend(
                [
                    "- [ ] 暂不作为锚点（题面、答案或区分度证据不足）",
                    "- Famin comment：",
                    "",
                ]
            )
    return "\n".join(lines).rstrip() + "\n"


def write_text(path: Path, text: str, force: bool) -> None:
    if path.exists() and not force:
        raise FileExistsError(f"refusing to overwrite {path}; pass --force")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("batches", nargs="+", type=Path)
    parser.add_argument("--anchors", type=Path, default=DEFAULT_ANCHORS)
    parser.add_argument("--output", type=Path, help="optional JSONL candidate review output")
    parser.add_argument("--verify-output", type=Path, help="optional Markdown generated from anchors")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--check", action="store_true", help="fail if anchor/source/group checks fail")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    anchors = load_anchors(args.anchors)
    batches, hashes = load_batches(args.batches)
    lookup = question_lookup(batches)
    anchor_checks = [validate_anchor(a, batches, lookup) for a in anchors]
    records = review_questions(batches, anchors)

    if args.output:
        payload = "".join(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n" for row in records)
        write_text(args.output, payload, args.force)
    if args.verify_output:
        write_text(args.verify_output, verify_markdown(anchors), args.force)

    assert_unchanged(hashes)
    invalid = [row for row in anchor_checks if not row["valid"]]
    distribution = Counter(a["proposed_round"] for a in anchors)
    print(
        json.dumps(
            {
                "batches": len(batches),
                "questions": len(records),
                "anchors": len(anchors),
                "anchor_round_distribution": dict(sorted(distribution.items())),
                "invalid_anchors": invalid,
                "all_results_review_only": all(r["flag"] == "review" for r in records),
                "input_sha256_unchanged": True,
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 1 if args.check and invalid else 0


if __name__ == "__main__":
    raise SystemExit(main())
