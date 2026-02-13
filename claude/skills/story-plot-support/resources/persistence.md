# 永続化（プロットの正本管理）ポリシー

## ゴール
- どんな粒度でも「今の正本（Source of Truth）」が一意に分かる
- 途中から入っても、既存資産を破壊せずに統合できる
- IDが安定し、伏線/タイムライン/シーンが参照切れしない

---

## 1) フォルダ構成（推奨・共通）
`plots/<project_slug>/` を作り、以下を置く。

- `plot.yml` … **唯一の正本（構造データ）**
- `intake.yml` … 初回質問の回答（後で見返す）
- `views/` … Markdownビュー（生成物。読みやすさ用）
- `sources/` … 途中からの場合の"元データをそのまま保存"（絶対に上書きしない）
- `snapshots/` … 重要マイルストーン時点の `plot.yml` スナップショット
- `decisions.md` … "決めたことログ"（後で迷子にならない）
- `notes.md` … 走り書き/TBD/方針

---

## 2) ID安定ルール（超重要）
- Event: `E001...`
- Presented event: `P001...`
- Foreshadow: `F001...`
- Chapter: `CH01...`
- Scene: `SC001...`
- Strand: `STR_A...`

**運用**
- いったん付けたIDは変えない（並べ替えても同じ）
- 削除せず `status: deprecated` で無効化（参照切れ防止）
- "置き換え"は `superseded_by: <id>` を入れる

---

## 3) 新規で作る場合（New Project Mode）
### 最小の正本（最初の完成条件）
`plot.yml` にまずこれだけ入っていれば前進できる：
- north_star.logline
- north_star.end_state_paragraph（TBDでも良いが"方向性"は書く）
- strands（STR_Aだけでも）
- mid_term.sequences（8シークエンス or TBD）

### おすすめの永続化ステップ（設計過多防止）
1. `intake.yml` 作成（チェックボックス回答）
2. `plot.yml` に反映（TBD可）
3. `views/` を生成（ログライン/8シークエンス/ステップアウトラインなど）
4. 書けないなら短期へ降りて `scenes` だけ先に増やす

**"打ち止めライン"**
- 長期：終点1段落が書けたらOK
- 中期：8シークエンスが揃ったら短期へ
- 短期：ステップアウトラインが全列挙できたら執筆へ

---

## 4) 途中から作る場合（Midstream / Import Mode）
### 原則：既存資産を壊さず「取り込み→整形→強化」
**重要**：元データは必ず `sources/` に"原文のまま"保存する。

#### Step 0: 取り込み（破壊しない）
- `sources/` に以下のどれかで保存
  - `sources/outline.md`
  - `sources/scenes.csv`
  - `sources/manuscript.md`
  - `sources/notes.md`
  - `sources/whatever_original.<ext>`
- そのファイルは以後 "参照専用" とする（上書きしない）

#### Step 1: 参照マッピング（Crosswalkを作る）
`plot.yml` 側に「どのIDが元のどこに対応するか」を残す。
- Chapter/Sceneに `source_ref` を付与する（例：行番号/見出し/URLなど）
- 例：`source_ref: "sources/outline.md#L120-L140"` のように

#### Step 2: 最低限の"正本"へ変換
- 既存アウトラインが「章」なら：`chapters[]` を先に作る
- 既存アウトラインが「シーン」なら：`scenes[]` を先に作る
- 原稿しかないなら：まず "ざっくりシーン分割" を作って `scenes[]` に起こす（TBDでも良い）

#### Step 3: 強化（索引の道具を後付け）
- B系（整合性）：タイムラインA/B → 伏線台帳を追加
- D系（テンポ）：8シークエンスへ集約して弱い塊を特定
- A系（群像）：章×筋マトリクスで放置筋を検出

---

## 5) スナップショット運用（リライト耐性）
大きな意思決定の前後で `snapshots/` に `plot.yml` をコピーする。

例：
- `snapshots/2026-02-10_baseline.yml`（取り込み直後）
- `snapshots/2026-02-10_after_sequences.yml`（8シークエンス確定後）
- `snapshots/2026-02-10_after_scene_polish.yml`（G/C/T/B整備後）

---

## 6) 決めたことログ（decisions.md）
テンプレ：
- 日付
- 何を決めたか（1行）
- 理由（2〜3行）
- 影響範囲（STR/CH/SC/伏線ID）
- 未確定（TBD）

これがあると「後で迷子にならない」。
