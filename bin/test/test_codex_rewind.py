#!/usr/bin/env python3

import importlib.util
from importlib.machinery import SourceFileLoader
import json
import sqlite3
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "codex-rewind"


def load_script():
    loader = SourceFileLoader("codex_rewind", str(SCRIPT))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class CodexRewindTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.db_path = Path(self.temp_dir.name) / "thread_history.sqlite"
        self.state_db_path = Path(self.temp_dir.name) / "state.sqlite"
        with sqlite3.connect(self.db_path) as db:
            db.executescript(
                """
                CREATE TABLE thread_turns (
                    thread_id TEXT NOT NULL,
                    turn_id TEXT NOT NULL,
                    rollout_ordinal INTEGER NOT NULL,
                    status TEXT NOT NULL,
                    first_user_item_id TEXT,
                    PRIMARY KEY (thread_id, turn_id)
                );
                CREATE TABLE thread_items (
                    thread_id TEXT NOT NULL,
                    turn_id TEXT NOT NULL,
                    item_id TEXT NOT NULL,
                    rollout_ordinal INTEGER NOT NULL,
                    created_at_ms INTEGER NOT NULL,
                    item_json TEXT NOT NULL,
                    item_type TEXT NOT NULL
                );
                """
            )
        with sqlite3.connect(self.state_db_path) as db:
            db.execute(
                """
                CREATE TABLE threads (
                    id TEXT PRIMARY KEY,
                    cwd TEXT NOT NULL,
                    source TEXT NOT NULL,
                    thread_source TEXT,
                    archived INTEGER NOT NULL,
                    recency_at_ms INTEGER NOT NULL
                )
                """
            )

    def tearDown(self):
        self.temp_dir.cleanup()

    def add_turn(self, turn_id, ordinal, status, text):
        item = {
            "type": "userMessage",
            "id": f"item-{turn_id}",
            "content": [{"type": "text", "text": text}],
        }
        with sqlite3.connect(self.db_path) as db:
            db.execute(
                "INSERT INTO thread_turns VALUES (?, ?, ?, ?, ?)",
                ("thread-1", turn_id, ordinal, status, f"item-{turn_id}"),
            )
            db.execute(
                "INSERT INTO thread_items VALUES (?, ?, ?, ?, ?, ?, ?)",
                (
                    "thread-1",
                    turn_id,
                    f"item-{turn_id}",
                    ordinal + 1,
                    ordinal * 1000,
                    json.dumps(item),
                    "userMessage",
                ),
            )

    def test_1_準正常系_最初の依頼を選ぶと新しい会話として扱われる(self):
        self.add_turn("turn-1", 1, "completed", "最初の依頼")

        prompt = load_script().load_prompts(self.db_path, "thread-1")[0]

        self.assertIsNone(prompt.previous_turn_id)

    def test_2_正常系_過去の依頼を選ぶと直前の会話位置が得られる(self):
        self.add_turn("turn-1", 1, "completed", "最初の依頼")
        self.add_turn("turn-2", 10, "completed", "次の依頼")

        prompts = load_script().load_prompts(self.db_path, "thread-1")

        self.assertEqual(prompts[1].text, "次の依頼")
        self.assertEqual(prompts[1].previous_turn_id, "turn-1")

    def test_3_正常系_VS_Codeの会話より直近の巻き戻し先を継続できる(self):
        rows = [
            ("cli", "/repo", "cli", "user", 0, 1),
            ("rewind", "/repo", "vscode", "codex-rewind", 0, 2),
            ("vscode", "/repo", "vscode", "user", 0, 3),
        ]
        with sqlite3.connect(self.state_db_path) as db:
            db.executemany("INSERT INTO threads VALUES (?, ?, ?, ?, ?, ?)", rows)

        thread = load_script().find_thread(self.state_db_path, None, "/repo")

        self.assertEqual(thread.id, "rewind")

    def test_4_異常系_処理中の依頼は巻き戻し候補に表示されない(self):
        self.add_turn("turn-1", 1, "completed", "完了した依頼")
        self.add_turn("turn-2", 10, "inProgress", "処理中の依頼")

        prompts = load_script().load_prompts(self.db_path, "thread-1")

        self.assertEqual([prompt.text for prompt in prompts], ["完了した依頼"])


if __name__ == "__main__":
    unittest.main()
