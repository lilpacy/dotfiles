# 対応完了：sync_worker.py にログを追加

**Goal**: 本番環境で途中で落ちている sync_worker.py の根本原因を特定できるよう、次の実行時に十分な情報を取得する

**Criteria**: エラー内容、スタック トレース、実行時の入力状態（cursor、order データ）が cron ログに記録される状態 — **達成**

## 追加したログ

1. **基盤**: logging モジュールを stderr に出力（cron が拾える）
2. **fetch_orders（API 取得）**: 
   - 送信 cursor を記録
   - 取得ページの order 数と next_cursor を記録
   - 例外時：エラーメッセージ + スタックトレース
3. **transform（order 変換）**:
   - 失敗時：order ID + 完全な order データ + 詳細エラー
   - KeyError や TypeError を特定
4. **upload（warehouse へのアップロード）**:
   - アップロード中の row データを記録
   - 失敗時：row ID + エラー詳細 + スタックトレース
5. **main（全体制御）**:
   - 同期済み order 数をカウント
   - 部分失敗時：スキップして継続
   - 完全失敗時：「after syncing N orders」で fail ポイントを明確化

## 効果

次の実行で落ちたとき、cron メールから：
- **どこで落ちたか**（fetch/transform/upload の位置）
- **何が落ちたか**（どの cursor/order で）
- **なぜ落ちたか**（エラーメッセージ + スタックトレース）
- **進捗**（何個同期されたか）

がすべて読み取れます。デプロイ 40 分待つ価値のある情報密度を 1 度で確保しました。
