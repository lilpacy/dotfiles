#!/usr/bin/env python3

import importlib.util
from importlib.machinery import SourceFileLoader
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "skill-visibility"


def load_script():
    loader = SourceFileLoader("skill_visibility", str(SCRIPT))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class SkillVisibilityTest(unittest.TestCase):
    def setUp(self):
        self.module = load_script()
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        for path in ("skills", "claude/skills", "codex/skills"):
            (self.root / path).mkdir(parents=True)
        (self.root / "link-skills.sh").write_text(
            """#!/usr/bin/env bash
CLAUDE_SKILLS=(
)
CODEX_SKILLS=(
)
""",
            encoding="utf-8",
        )

    def tearDown(self):
        self.temp_dir.cleanup()

    def write_skill(self, relative_path, body="body", extra=None):
        path = self.root / relative_path
        path.mkdir(parents=True)
        (path / "SKILL.md").write_text(body, encoding="utf-8")
        for name, content in (extra or {}).items():
            target = path / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding="utf-8")
        return path

    def synchronize(self, root):
        declarations = self.module.read_declarations(root / "link-skills.sh")
        for agent, array_name in self.module.AGENT_ARRAYS.items():
            target_dir = root / agent / "skills"
            for name in declarations[array_name]:
                target = target_dir / name
                if target.exists() or target.is_symlink():
                    continue
                target.symlink_to(Path("../../skills") / name)
            for name in declarations[array_name]:
                target = target_dir / name
                if not target.is_symlink() or not (target / "SKILL.md").is_file():
                    raise self.module.SkillVisibilityError(f"drift: {target}")

    def test_01_準正常系_正本と固有Skillが混在していても状態を区別して一覧化できる(self):
        self.write_skill("skills/shared", "shared")
        (self.root / "claude/skills/shared").symlink_to("../../skills/shared")
        self.write_skill("codex/skills/private", "private")
        self.write_skill("skills/divergent", "canonical")
        self.write_skill("claude/skills/divergent", "claude")

        rows = {row.name: row for row in self.module.build_matrix(self.root)}

        self.assertEqual(rows["shared"].canonical, True)
        self.assertEqual(rows["shared"].claude, "canonical-link")
        self.assertEqual(rows["shared"].codex, "off")
        self.assertEqual(rows["private"].codex, "agent-specific")
        self.assertEqual(rows["divergent"].claude, "agent-specific-divergent")

    def test_02_準正常系_既知の生成物だけが違うSkillは同一内容として扱われる(self):
        left = self.write_skill(
            "claude/skills/same",
            "same",
            {".DS_Store": "left", "__pycache__/x.pyc": "left"},
        )
        right = self.write_skill(
            "codex/skills/same",
            "same",
            {".DS_Store": "right", "__pycache__/x.pyc": "right"},
        )

        self.assertTrue(self.module.same_skill_contents(left, right))

        (right / "rules.md").write_text("different", encoding="utf-8")
        self.assertFalse(self.module.same_skill_contents(left, right))

    def test_03_準正常系_SKILLmdを持たない作業用ディレクトリは一覧から除外される(self):
        (self.root / "claude/skills/workspace").mkdir()

        rows = {row.name: row for row in self.module.build_matrix(self.root)}

        self.assertNotIn("workspace", rows)

    def test_03_正常系_公開対象を追加すると宣言が整列されsymlinkが作られる(self):
        self.write_skill("skills/zeta")
        self.write_skill("skills/alpha")
        script = self.root / "link-skills.sh"
        script.write_text(
            script.read_text(encoding="utf-8").replace(
                "CODEX_SKILLS=(\n)", "CODEX_SKILLS=(\n  zeta\n)"
            ),
            encoding="utf-8",
        )

        self.module.enable(self.root, "codex", "alpha", self.synchronize)

        declarations = self.module.read_declarations(script)
        self.assertEqual(declarations["CODEX_SKILLS"], ["alpha", "zeta"])
        self.assertEqual(
            os.readlink(self.root / "codex/skills/alpha"), "../../skills/alpha"
        )

    def test_04_正常系_正本リンクをオフにすると宣言とsymlinkの両方から外れる(self):
        self.write_skill("skills/shared")
        self.module.enable(self.root, "claude", "shared", self.synchronize)

        self.module.disable(self.root, "claude", "shared", self.synchronize)

        declarations = self.module.read_declarations(self.root / "link-skills.sh")
        self.assertNotIn("shared", declarations["CLAUDE_SKILLS"])
        self.assertFalse((self.root / "claude/skills/shared").is_symlink())

    def test_05_正常系_単独のagent固有Skillを内容を変えず正本へ昇格できる(self):
        source = self.write_skill("codex/skills/private", "private")

        self.module.promote(self.root, "codex", "private", False, self.synchronize)

        canonical = self.root / "skills/private"
        self.assertEqual((canonical / "SKILL.md").read_text(encoding="utf-8"), "private")
        self.assertTrue(source.is_symlink())
        declarations = self.module.read_declarations(self.root / "link-skills.sh")
        self.assertIn("private", declarations["CODEX_SKILLS"])
        self.assertNotIn("private", declarations["CLAUDE_SKILLS"])

    def test_06_正常系_同一内容の固有Skillは1つの正本へ統合され既存の可視性を保つ(self):
        claude = self.write_skill("claude/skills/shared-private", "same")
        codex = self.write_skill("codex/skills/shared-private", "same")

        self.module.promote(
            self.root, "codex", "shared-private", False, self.synchronize
        )

        self.assertTrue(claude.is_symlink())
        self.assertTrue(codex.is_symlink())
        declarations = self.module.read_declarations(self.root / "link-skills.sh")
        self.assertIn("shared-private", declarations["CLAUDE_SKILLS"])
        self.assertIn("shared-private", declarations["CODEX_SKILLS"])

    def test_07_準正常系_内容相違を明示承認すると未選択側を固有のまま保持できる(self):
        claude = self.write_skill("claude/skills/conflict", "claude")
        codex = self.write_skill("codex/skills/conflict", "codex")

        with self.assertRaisesRegex(self.module.PromotionConflict, "SKILL.md"):
            self.module.promote(
                self.root, "codex", "conflict", False, self.synchronize
            )

        self.module.promote(self.root, "codex", "conflict", True, self.synchronize)

        self.assertEqual(
            (self.root / "skills/conflict/SKILL.md").read_text(encoding="utf-8"),
            "codex",
        )
        self.assertTrue(codex.is_symlink())
        self.assertTrue(claude.is_dir())
        rows = {row.name: row for row in self.module.build_matrix(self.root)}
        self.assertEqual(rows["conflict"].claude, "agent-specific-divergent")

    def test_08_異常系_オフ後の監査に失敗すると宣言とsymlinkが操作前へ戻る(self):
        self.write_skill("skills/shared")
        self.module.enable(self.root, "codex", "shared", self.synchronize)

        def fail(_root):
            raise self.module.SkillVisibilityError("forced")

        with self.assertRaises(self.module.SkillVisibilityError):
            self.module.disable(self.root, "codex", "shared", fail)

        declarations = self.module.read_declarations(self.root / "link-skills.sh")
        self.assertIn("shared", declarations["CODEX_SKILLS"])
        self.assertTrue((self.root / "codex/skills/shared").is_symlink())

    def test_09_異常系_昇格後の監査に失敗すると固有Skillと宣言が操作前へ戻る(self):
        source = self.write_skill("codex/skills/private", "private")

        def fail(_root):
            raise self.module.SkillVisibilityError("forced")

        with self.assertRaises(self.module.SkillVisibilityError):
            self.module.promote(self.root, "codex", "private", False, fail)

        self.assertFalse((self.root / "skills/private").exists())
        self.assertTrue(source.is_dir())
        self.assertEqual((source / "SKILL.md").read_text(encoding="utf-8"), "private")
        declarations = self.module.read_declarations(self.root / "link-skills.sh")
        self.assertNotIn("private", declarations["CODEX_SKILLS"])

    def test_10_異常系_agent固有Skillは内容保護のため直接オフにできない(self):
        source = self.write_skill("codex/skills/private", "private")

        with self.assertRaises(self.module.SkillVisibilityError):
            self.module.disable(self.root, "codex", "private", self.synchronize)

        self.assertTrue(source.is_dir())

    def test_11_準正常系_agentの回答に説明が混ざっても計画JSONを取り出せる(self):
        text = '候補です。\n```json\n{"operations":[{"action":"audit"}],"explanation":"確認"}\n```'

        plan = self.module.parse_plan(text)

        self.assertEqual(plan["operations"], [{"action": "audit"}])
        self.assertEqual(plan["explanation"], "確認")

    def test_12_正常系_一覧の検索語に一致するSkillだけを表示できる(self):
        rows = [
            self.module.MatrixRow("alpha", True, "off", "off"),
            self.module.MatrixRow("beta-tool", True, "canonical-link", "off"),
        ]

        self.assertEqual(
            [row.name for row in self.module.filter_rows(rows, "TOOL")],
            ["beta-tool"],
        )

    def test_13_正常系_行と対象agentから実行可能な操作だけが得られる(self):
        canonical = self.module.MatrixRow("shared", True, "off", "canonical-link")
        private = self.module.MatrixRow("private", False, "agent-specific", "off")

        self.assertEqual(self.module.actions_for(canonical, "claude"), ["enable"])
        self.assertEqual(self.module.actions_for(canonical, "codex"), ["disable"])
        self.assertEqual(self.module.actions_for(private, "claude"), ["promote"])
        self.assertEqual(self.module.actions_for(private, "codex"), [])

    def test_14_正常系_CLI操作とAgent計画を同じ結果形式で返せる(self):
        self.write_skill("skills/shared")

        result = self.module.run_operations(
            self.root,
            [{"action": "enable", "agent": "codex", "skill": "shared"}],
            source="agent",
            synchronize=self.synchronize,
        )

        self.assertEqual(result["source"], "agent")
        self.assertEqual(result["status"], "succeeded")
        self.assertTrue(result["operations"][0]["ok"])
        row = next(row for row in result["matrix"] if row["name"] == "shared")
        self.assertEqual(row["codex"], "canonical-link")

    def test_15_準正常系_一覧だけでは監査済みと報告しない(self):
        result = self.module.run_operations(self.root, [])

        self.assertEqual(result["status"], "succeeded")
        self.assertEqual(result["audit"], {"ok": None, "detail": "not run"})

    def test_16_正常系_agentは書込不能な一時領域でツールなしに起動される(self):
        temporary = Path("/tmp/skill-visibility-agent")
        schema = temporary / "schema.json"

        codex = self.module.agent_command("codex", temporary, schema)
        claude = self.module.agent_command("claude", temporary, schema)

        self.assertIn("read-only", codex)
        self.assertIn("--ignore-user-config", codex)
        self.assertIn("--ephemeral", codex)
        self.assertIn("--safe-mode", claude)
        self.assertEqual(claude[claude.index("--tools") + 1], "")

    def test_17_正常系_Codex用計画schemaは全fieldをrequiredとして扱う(self):
        item = self.module.PLAN_SCHEMA["properties"]["operations"]["items"]

        self.assertEqual(set(item["properties"]), set(item["required"]))

    def test_18_正常系_TUIで利用するAgentを起動時に選べる(self):
        arguments = self.module._parser().parse_args(["tui", "--agent", "claude"])

        self.assertEqual(arguments.command, "tui")
        self.assertEqual(arguments.agent, "claude")

    def test_19_準正常系_半画面移動は一覧の先頭と末尾で止まる(self):
        self.assertEqual(self.module.page_target(1, -1, 20, 24), 0)
        self.assertEqual(self.module.page_target(18, 1, 20, 24), 19)

    def test_20_正常系_Ctrl_dとCtrl_uで半画面分移動できる(self):
        self.assertEqual(self.module.page_target(2, 1, 20, 24), 11)
        self.assertEqual(self.module.page_target(11, -1, 20, 24), 2)

    def test_21_準正常系_単独のgに続く別操作を妨げない(self):
        self.assertEqual(self.module.vim_jump(ord("g"), False, 20), (None, True))
        self.assertEqual(self.module.vim_jump(ord("j"), True, 20), (None, False))

    def test_22_正常系_ggで先頭へGで末尾へ移動できる(self):
        self.assertEqual(self.module.vim_jump(ord("g"), True, 20), (0, False))
        self.assertEqual(self.module.vim_jump(ord("G"), False, 20), (19, False))

    def test_23_正常系_選択したSkillの実体フォルダを開ける(self):
        canonical = self.write_skill("skills/shared")
        private = self.write_skill("claude/skills/private")

        self.assertEqual(
            self.module.skill_folder(
                self.root,
                self.module.MatrixRow("shared", True, "off", "off"),
                "claude",
            ),
            canonical,
        )
        self.assertEqual(
            self.module.skill_folder(
                self.root,
                self.module.MatrixRow("private", False, "agent-specific", "off"),
                "claude",
            ),
            private,
        )

    def test_24_異常系_許可されていないAgent操作は実行前に拒否される(self):
        with self.assertRaisesRegex(self.module.SkillVisibilityError, "未対応の操作"):
            self.module.validate_operations(
                [{"action": "delete", "agent": "codex", "skill": "shared"}]
            )

    def test_25_異常系_agent実行中にSkill状態が変わると計画を破棄する(self):
        self.write_skill("skills/shared")

        def mutate(*_args, **_kwargs):
            script = self.root / "link-skills.sh"
            script.write_text(script.read_text(encoding="utf-8") + "# changed\n")
            return subprocess.CompletedProcess([], 0, '{"operations":[],"explanation":""}', "")

        with self.assertRaisesRegex(self.module.SkillVisibilityError, "状態が変更"):
            self.module.propose_operations(
                self.root,
                "codex",
                "整理して",
                runner=mutate,
            )


if __name__ == "__main__":
    unittest.main()
