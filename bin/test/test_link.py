#!/usr/bin/env python3

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


LINK_SCRIPT = Path(__file__).parents[2] / "link.sh"


class LinkTest(unittest.TestCase):
    def test_正常系_全Skill公開をruntime専用配置へ安全に移行できる(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            dotfiles = root / "dotfiles"
            home = root / "home"
            scripts = dotfiles / "skills/agmsg/scripts"
            scripts.mkdir(parents=True)
            (dotfiles / "bin").mkdir()
            (home / ".agents").mkdir(parents=True)
            shutil.copy2(LINK_SCRIPT, dotfiles / "link.sh")
            (dotfiles / "links.conf").write_text(
                "skills/agmsg/scripts\t~/.agents/skills/agmsg/scripts\n",
                encoding="utf-8",
            )
            link_skills = dotfiles / "link-skills.sh"
            link_skills.write_text("#!/usr/bin/env bash\n", encoding="utf-8")
            link_skills.chmod(0o755)
            (home / ".agents/skills").symlink_to(dotfiles / "skills")
            subprocess.run(["git", "init", "-q"], cwd=dotfiles, check=True)

            environment = os.environ.copy()
            environment.update(
                HOME=str(home), DOTFILES=str(dotfiles), SKIP_SUDO_LINKS="1"
            )
            subprocess.run(
                [str(dotfiles / "link.sh")], env=environment, check=True
            )

            runtime_root = home / ".agents/skills"
            self.assertTrue(runtime_root.is_dir())
            self.assertFalse(runtime_root.is_symlink())
            self.assertTrue((runtime_root / "agmsg/scripts").is_symlink())
            self.assertFalse((runtime_root / "agmsg/SKILL.md").exists())


if __name__ == "__main__":
    unittest.main()
