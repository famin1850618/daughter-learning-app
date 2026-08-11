#!/usr/bin/env python3
import hashlib
import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("review_math_g7_bootstrap.py")
SPEC = importlib.util.spec_from_file_location("review_math_g7_bootstrap", MODULE_PATH)
reviewer = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = reviewer
SPEC.loader.exec_module(reviewer)


def question() -> dict:
    return {
        "local_id": 1,
        "type": "choice",
        "chapter": "有理数及其运算",
        "knowledge_point": "有理数/正数与负数",
        "content": "若超过水位6m记作+6m，则低于水位4m记作（ ）。",
        "options": ["A. 4m", "B. -4m"],
        "answer": "B",
        "explanation": "超过记正，低于记负，所以为-4m。",
        "round": 1,
    }


def anchor(status: str) -> dict:
    return {
        "candidate_id": "g7_test_r1",
        "proposed_round": 1,
        "status": status,
        "source_ref": "sample.json#1",
        "knowledge_point": "有理数/正数与负数",
        "type": "choice",
        "content": "低于水位记作负数。",
    }


class BootstrapReviewerTest(unittest.TestCase):
    def test_unconfirmed_anchor_never_confident(self):
        result = reviewer.review_question("sample.json", question(), [anchor("requires_famin_confirmation")])
        self.assertEqual(result["proposed_round"], 1)
        self.assertEqual(result["flag"], "review")
        self.assertIn("not yet sufficiently confirmed", result["confidence_reason"])

    def test_confirmed_exact_anchor_can_support_matching_rubric(self):
        result = reviewer.review_question("sample.json", question(), [anchor("confirmed_by_famin")])
        self.assertEqual(result["proposed_round"], 1)
        self.assertEqual(result["flag"], "confident")

    def test_original_round_is_observed_but_not_used(self):
        q1 = question()
        q4 = dict(q1, round=4)
        a = [anchor("requires_famin_confirmation")]
        r1 = reviewer.review_question("sample.json", q1, a)
        r4 = reviewer.review_question("sample.json", q4, a)
        self.assertEqual(r1["proposed_round"], r4["proposed_round"])
        self.assertNotEqual(
            r1["original_round_observed_but_not_used"],
            r4["original_round_observed_but_not_used"],
        )

    def test_rejects_non_g7_batch(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "g6.json"
            path.write_text(json.dumps({"grade": 6, "subject": "math", "questions": []}), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "not a G7 math batch"):
                reviewer.load_questions([path])

    def test_cli_output_does_not_change_input(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            batch = root / "sample.json"
            anchors = root / "anchors.json"
            output = root / "report.jsonl"
            batch.write_text(
                json.dumps({"grade": 7, "subject": "math", "questions": [question()]}, ensure_ascii=False),
                encoding="utf-8",
            )
            anchors.write_text(
                json.dumps({"grade": 7, "subject": "math", "anchors": [anchor("requires_famin_confirmation")]}, ensure_ascii=False),
                encoding="utf-8",
            )
            before = hashlib.sha256(batch.read_bytes()).hexdigest()
            rc = reviewer.main([str(batch), "--anchors", str(anchors), "--output", str(output)])
            after = hashlib.sha256(batch.read_bytes()).hexdigest()
            self.assertEqual(rc, 0)
            self.assertEqual(before, after)
            self.assertTrue(output.exists())
            record = json.loads(output.read_text(encoding="utf-8").strip())
            self.assertEqual(record["flag"], "review")

    def test_source_has_no_machine_or_g6_glob_hardcode(self):
        source = MODULE_PATH.read_text(encoding="utf-8")
        self.assertNotIn("/home/faminwsl/daughter_learning_app", source)
        self.assertNotIn("realpaper_g6_math_", source)


if __name__ == "__main__":
    unittest.main()
