# incident memo (this morning)

- 今朝の nightly sync が途中で死んでいた。cron のメールには
  `sync_worker.py failed (exit 1)` としか残っていない
- stdout/stderr は cron が捨てていて手元にない
- 本番環境にしか実データがなく、ローカルでは再現できない
- デプロイは CI 経由で 40 分かかる。次の実行は今夜 2:00 のみ
