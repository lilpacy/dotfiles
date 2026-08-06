import copy
import importlib.util
import json
import subprocess
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PY = sys.executable


def load_script(name):
    script_path = ROOT / "scripts" / name
    spec = importlib.util.spec_from_file_location(script_path.stem, script_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class ScriptTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.review_pipeline = load_script("review_pipeline.py")
        cls.validate_design_case = load_script("validate_design_case.py")
        cls.valid_case = json.loads(
            (ROOT / "evals" / "fixtures" / "valid-case.json").read_text(encoding="utf-8")
        )

    def run_script(self, name, fixture):
        return subprocess.run(
            [PY, str(ROOT / "scripts" / name), str(ROOT / "evals" / "fixtures" / fixture)],
            text=True,
            capture_output=True,
        )

    def test_準正常系_単純な判断だけならデシジョンテーブルなしで通過する(self):
        case = copy.deepcopy(self.valid_case)
        for decision in case["decisions"]:
            decision["logic_type"] = "simple_rule"
        case["decision_table"] = {"conditions": [], "actions": [], "cases": []}

        blockers = self.review_pipeline.checks(case)

        self.assertEqual(blockers["decision_specification"], [])

    def test_正常系_完成ケースは構造検証を通過する(self):
        result = self.run_script("validate_design_case.py", "valid-case.json")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_正常系_質問選択は一度に一問だけ返す(self):
        result = self.run_script("next_question.py", "conflicting-case.json")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Question:", result.stdout)
        self.assertNotIn("\nQuestion:", result.stdout.split("Question:", 1)[-1])

    def test_異常系_業務理解の意味項目が空ならS1で停止する(self):
        case = copy.deepcopy(self.valid_case)
        case["project"]["success_conditions"][0]["statement"] = ""
        case["project"]["success_conditions"][0]["verification"] = ""
        case["actors"][0]["name"] = ""
        case["actors"][0]["role"] = ""
        case["actors"][0]["responsibilities"] = []
        case["business_workflow"]["start_event"] = ""
        case["business_workflow"]["end_event"] = ""
        for step in case["business_workflow"]["steps"]:
            step["action"] = ""
            step["input"] = []
            step["output"] = []

        blockers = self.review_pipeline.checks(case)
        issues = self.validate_design_case.validate(case)

        self.assertTrue(blockers["business_understanding"])
        self.assertTrue(
            any(issue["code"] in {"SUCCESS_CONDITION", "ACTOR_MEANING", "WORKFLOW_MEANING"} for issue in issues)
        )

    def test_異常系_S1がユーザー承認前ならS2へ進めない(self):
        case = copy.deepcopy(self.valid_case)
        stage = next(
            stage
            for stage in case["pipeline"]["stages"]
            if stage["id"] == "business_understanding"
        )
        stage["status"] = "ready_for_review"

        blockers = self.review_pipeline.checks(case)

        self.assertIn("ユーザー承認がない", blockers["business_understanding"])

    def test_異常系_agentの自己承認ではS2へ進めない(self):
        case = copy.deepcopy(self.valid_case)
        stage = next(
            stage
            for stage in case["pipeline"]["stages"]
            if stage["id"] == "business_understanding"
        )
        stage["status"] = "approved"
        stage["approved_by"] = "agent"
        stage["approval_evidence"] = "agentが自分で承認"

        blockers = self.review_pipeline.checks(case)
        issues = self.validate_design_case.validate(case)

        self.assertIn(
            "承認主体がユーザーまたは明示委任ではない",
            blockers["business_understanding"],
        )
        self.assertTrue(any(issue["code"] == "S1_APPROVAL" for issue in issues))

    def test_異常系_現行業務の引き渡しが繋がらなければS1で停止する(self):
        case = copy.deepcopy(self.valid_case)
        case["business_workflow"]["steps"][0]["output"] = ["次工程へ渡らない成果物"]

        issues = self.validate_design_case.validate(case)

        self.assertTrue(any(issue["code"] == "WORKFLOW_HANDOFF" for issue in issues))

    def test_異常系_複数条件の判断はデシジョンテーブルがなければ停止する(self):
        case = copy.deepcopy(self.valid_case)
        case["decisions"][0]["logic_type"] = "decision_table"
        case["decision_table"] = {"conditions": [], "actions": [], "cases": []}

        blockers = self.review_pipeline.checks(case)

        self.assertTrue(blockers["decision_specification"])

    def test_異常系_矛盾ケースはBlockingとして停止する(self):
        result = self.run_script("validate_design_case.py", "conflicting-case.json")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("OPEN_BLOCKING", result.stdout)

    def test_異常系_情報不足ケースは業務理解で停止する(self):
        result = self.run_script("review_pipeline.py", "incomplete-case.json")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("Business Understanding", result.stdout)
        self.assertIn("blocked", result.stdout)


if __name__ == "__main__":
    unittest.main()
