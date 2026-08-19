"""失敗時にログへ切り分け情報が残ることだけを確認する自己チェック。
実行: python test_sync_worker.py
"""
import json
import os
import tempfile

LOG = os.path.join(tempfile.mkdtemp(), "sync.log")
os.environ["SYNC_WORKER_LOG"] = LOG

import sync_worker


def test_失敗したレコードとカーソルがログに残る():
    pages = [
        {"orders": [{"id": "ok-1", "items": [{"price": 100, "qty": 2}],
                     "shipping": {"address": {"region": "JP"}}}],
         "next_cursor": "c2"},
        # shipping.address が欠けた壊れたレコード = 本番でしか見られない類の入力
        {"orders": [{"id": "bad-9", "items": [{"price": 1, "qty": 1}], "shipping": {}}],
         "next_cursor": None},
    ]
    sync_worker.fetch_orders = lambda cursor: pages[0] if cursor == "" else pages[1]
    sync_worker.upload = lambda row: None

    try:
        sync_worker.main()
    except SystemExit as e:
        assert e.code == 1, f"exit 1 で終わるはず, got {e.code}"
    else:
        raise AssertionError("壊れたレコードで異常終了するはず")

    with open(LOG) as f:
        text = f.read()

    # 切り分けに必要な4点
    assert "bad-9" in text, "失敗したレコードの id がログに無い"
    assert "c2" in text, "失敗時点の cursor がログに無い"
    assert "KeyError" in text, "例外の型/スタックがログに無い"
    assert "aborted after 1 orders" in text, "どこまで進んだかがログに無い"
    # 成功済みレコードの生データを全部吐くとログが膨れるので、失敗分だけであること
    assert text.count("raw=") == 1, "raw ダンプは失敗レコードのみのはず"
    print("OK\n---- log ----\n" + text)


if __name__ == "__main__":
    test_失敗したレコードとカーソルがログに残る()
