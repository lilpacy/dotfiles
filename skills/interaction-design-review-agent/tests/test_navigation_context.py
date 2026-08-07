import json
import subprocess
import sys
import unittest
from pathlib import Path


SKILL_ROOT = Path(__file__).resolve().parents[1]
PY = sys.executable


class NavigationContextTests(unittest.TestCase):
    def test_正常系_質問と一緒に直前と現在のステージと全体進捗を確認できる(self):
        result = subprocess.run(
            [
                PY,
                str(SKILL_ROOT / "scripts" / "next_question.py"),
                str(SKILL_ROOT / "evals" / "fixtures" / "conflicting-case.json"),
                "--json",
            ],
            text=True,
            capture_output=True,
        )
        payload = json.loads(result.stdout)

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(
            payload["navigation"]["previous_stage"],
            {"id": "design_principles", "label": "Design Principles", "position": 5},
        )
        self.assertEqual(
            payload["navigation"]["current_stage"],
            {"id": "contradiction_check", "label": "Contradiction Check", "position": 6},
        )
        self.assertEqual(
            payload["navigation"]["progress"],
            {"current": 6, "total": 9, "label": "6/9"},
        )


if __name__ == "__main__":
    unittest.main()
