import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
PY=sys.executable

class ScriptTests(unittest.TestCase):
    def run_script(self, name, fixture):
        return subprocess.run(
            [PY, str(ROOT/"scripts"/name), str(ROOT/"evals"/"fixtures"/fixture)],
            text=True, capture_output=True
        )

    def test_valid_case_validates(self):
        r=self.run_script("validate_design_case.py","valid-case.json")
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)

    def test_conflict_case_blocks(self):
        r=self.run_script("validate_design_case.py","conflicting-case.json")
        self.assertEqual(r.returncode,1,r.stdout+r.stderr)
        self.assertIn("OPEN_BLOCKING",r.stdout)

    def test_incomplete_pipeline_blocks_at_business(self):
        r=self.run_script("review_pipeline.py","incomplete-case.json")
        self.assertEqual(r.returncode,1,r.stdout+r.stderr)
        self.assertIn("Business Workflow",r.stdout)
        self.assertIn("blocked",r.stdout)

    def test_next_question_is_single(self):
        r=self.run_script("next_question.py","conflicting-case.json")
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)
        self.assertIn("Question:",r.stdout)
        self.assertNotIn("\nQuestion:",r.stdout.split("Question:",1)[-1])

if __name__=="__main__":
    unittest.main()
