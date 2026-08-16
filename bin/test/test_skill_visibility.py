#!/usr/bin/env python3

import importlib.util
from importlib.machinery import SourceFileLoader
import os
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


if __name__ == "__main__":
    unittest.main()
