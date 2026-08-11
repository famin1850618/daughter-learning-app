#!/usr/bin/env python3
import hashlib
import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("review_chinese_g7_bootstrap.py")
SPEC = importlib.util.spec_from_file_location("review_chinese_g7_bootstrap", MODULE_PATH)
reviewer = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = reviewer
SPEC.loader.exec_module(reviewer)


def question(local_id: int, *, round_value: int | None = 4, candidate: int | None = None) -> dict:
    q = {
        "local_id": local_id,
        "type": "choice",
        "chapter": "字词",
        "knowledge_point": "字词/词语理解",
        "content": "选择使用恰当的词语。",
        "options": ["A. 甲", "B. 乙"],
        "answer": "A",
        "round": round_value,
    }
    if candidate is not None:
        q["_round_candidate"] = candidate
    return q


def batch(questions: list[dict]) -> dict:
    return {"grade": 7, "subject": "chinese", "questions": questions}


class ChineseG7BootstrapReviewerTest(unittest.TestCase):
    def test_production_round_is_never_used_as_candidate(self):
        batches = {"sample.json": batch([question(1, round_value=4)])}
        row = reviewer.review_questions(batches, [])[0]
        self.assertIsNone(row["proposed_round"])
        self.assertEqual(row["production_round_observed_but_not_used"], 4)
        self.assertEqual(row["route_status"], "no_g7_candidate")

    def test_explicit_worker_candidate_stays_review_only(self):
        batches = {"sample.json": batch([question(1, candidate=2)])}
        row = reviewer.review_questions(batches, [])[0]
        self.assertEqual(row["proposed_round"], 2)
        self.assertEqual(row["flag"], "review")

    def test_top_level_candidate_is_visible(self):
        data = batch([question(1, candidate=None)])
        data["_round_candidate_review"] = [{"local_id": 1, "candidate_round": 3}]
        self.assertEqual(reviewer.observed_worker_candidate(data, data["questions"][0]), 3)

    def test_mixed_group_candidates_are_blocked(self):
        q1, q2 = question(1, candidate=2), question(2, candidate=3)
        for order, q in enumerate((q1, q2), 1):
            q["group_id"] = "group_1"
            q["group_order"] = order
        rows = reviewer.review_questions({"sample.json": batch([q1, q2])}, [])
        self.assertTrue(all(r["route_status"] == "blocked_group_not_unified" for r in rows))

    def test_input_hash_unchanged(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "sample.json"
            path.write_text(json.dumps(batch([question(1, candidate=1)]), ensure_ascii=False), encoding="utf-8")
            _, hashes = reviewer.load_batches([path])
            before = hashlib.sha256(path.read_bytes()).hexdigest()
            reviewer.assert_unchanged(hashes)
            after = hashlib.sha256(path.read_bytes()).hexdigest()
            self.assertEqual(before, after)

    def test_source_has_no_batch_or_index_writeback(self):
        source = MODULE_PATH.read_text(encoding="utf-8")
        self.assertNotIn('index.json', source)
        self.assertNotIn('["round"] =', source)
        self.assertNotIn("['round'] =", source)


if __name__ == "__main__":
    unittest.main()
