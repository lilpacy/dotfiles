# `scripts/pi_synthesis_candidates.rb` の役割

## 一言でいうと

これは **Concept Synthesis 用の「候補検索フェーズ」を支える2つの小さな決定的ツール**です。単体では何も判断しません。LLM（pi-coding-agent）に「今回の新着 Delta と組み合わせる価値のある過去の Delta はどれか」を選ばせるための入力を作り（`catalog`）、その回答を検証して次の工程が使える形に固める（`merge`）。**LLM を挟んだ2ステップの前後を固めるサンドイッチの、パンの部分**です。

## なぜこれが必要なのか（背景）

vault のパイプラインは 48 時間ごとに「新しく追加された Knowledge Delta から Concept（複数 source を横断した理解）を創発する」ジョブを回しています（`.github/workflows/pi-concept-synthesis.yml`）。

ここに構造的な問題があります。Concept は定義上「**2つ以上の独立した source lineage を横断して初めて見える理解**」です（`lilpacy/CLAUDE.md`）。ということは、今回の新着 Delta だけを読んでも Concept は作れません。過去の Delta と突き合わせる必要があります。

一方で、Delta は現在 92 件あり、全部の本文を LLM の context に入れることはできません。しかも Delta の本文には Raw source からの引用（`evidence:`）が丸ごと入っています。

そこで **2段構えの検索**にしています。

1. まず極めて軽い「目次」だけを LLM に見せて、関連しそうな過去 Delta を選ばせる ← このスクリプトの `catalog`
2. 選ばれたものだけ full context を組んで、本当の Concept 判断をさせる ← 別スクリプト `build_pi_synthesis_context.rb`

workflow のプロンプトがこの分業を明示しています。「Hintは検索手掛かりであってConcept claimの根拠ではなく、Conceptの最終判断は後続のfull contextで行います」。つまり **このスクリプトが作る catalog は「当たりをつける」ためだけのもので、根拠として信用されていない**。ここが設計の勘所です。

## `catalog` サブコマンド — 検索用の目次を作る

`PiSynthesisCandidateCatalog` が `lilpacy/deltas/*.md` を全件走査し、各 Delta から次の3つだけを抜き出した Markdown を生成します。

- `source:` と `summary:` の wikilink（frontmatter から）
- `## Concept impact hints` セクションの箇条書き
- 今回の新着 Delta には `[new]` マーカー

実際に走らせた出力の一部です。

```
## lilpacy/deltas/2026-08-02 DGX Spark複数台連結の目的と帯域制約--8c9eb13082c5.md

source: [[queries/2026-08-02 DGX Spark複数台連結の目的と帯域制約]]
summary: [[summaries/DGX Spark複数台連結の目的と帯域制約]]
- ローカルLLMハードウェア選定に、ノード単体帯域とモデル分割後のシステム総帯域を分ける判断軸を追加候補とする
- ...
```

この hint は ingest 時に書き込まれたものです（`lilpacy/CLAUDE.md`「ingestは`concepts/`を変更しない。Concept候補の非決定的ヒントはDeltaへ残し」）。**ingest が「これは Concept になりそう」というメモを Delta に残しておき、synthesis がそれを検索インデックスとして使う**、という時間差の受け渡しになっています。

意図的に**除外している**ものが重要です。

- Delta の `## Changes` セクション全体（＝ Raw からの引用 evidence）
- Raw source と query transcript の本文

テストがこれを明示的に守っています（`test/pi_synthesis_candidates_test.rb`）。fixture が Raw に `OLD_RAW_SECRET` という文字列を埋め込み、`refute_includes catalog, "OLD_RAW_SECRET"` で漏れていないことを検証する。ファイル冒頭の警告文もこの契約を宣言しています。

### 注目すべき2つの判断

**`hints.empty?` なら Delta をスキップする（29-32行目）** — hint が無い、または `none` だけの Delta は catalog に載りません。検索の手掛かりが無いものは載せても LLM の判断材料にならず context を食うだけ、という割り切りです。

**予算超過は切り捨てではなく失敗（46行目）** — 160,000 bytes を超えたら `ArgumentError` で落ちます。「入るところまで入れる」ではなく「入らないなら止まる」。これは workflow プロンプトの「件数で切り捨てません」という方針と対応しています。**候補を静かに落とすと、その Delta は永久に Concept 化のチャンスを失う**ので、黙って劣化するより壊れて気づく方を選んでいます。

現状の余裕を実測しました。Delta 92 件で **64,825 bytes（予算の約 41%）**。Delta が今の 2.4 倍あたりでこのジョブが落ち始めます。まだ余裕はありますが、無限ではありません。

## `merge` サブコマンド — LLM の回答を検証して固める

`PiSynthesisCandidateSelection` は LLM が返した JSON（`{"schema_version":1,"selected_delta_paths":[...]}`）を読み、次を行います。

1. `schema_version == 1` を確認
2. 各 path を検証（後述）
3. **新着 Delta と結合して** `\0` 区切りのバイナリリストへ書き出す

3 番目が要点です。`@new_delta_paths + selected` の順で結合し `uniq`。つまり **LLM が空配列を返しても、新着 Delta は必ず入力に残る**。テスト名がそのまま意図を語っています（`test_準正常系_関連候補がない場合も新着知識だけで合成を続行できる`）。LLM が候補検索をサボっても、あるいは何も見つけられなくても、パイプラインは今回の新着分だけで先へ進める。**LLM の失敗がトリガーの取りこぼしにならない**設計です。

`\0` 区切りにしているのは、vault のファイル名に日本語・空白・記号が普通に入るからです。workflow 側も `mapfile -d ''` で読み、改行区切りの `.txt` は診断アーティファクト用にしか作っていません。

## path 検証 — 意図的に重複しているガード

`validate_delta_path` は両クラスに**ほぼ同一のコードで重複**しています（53-59 行目と 112-118 行目）。DRY 違反に見えますが、これは信頼境界がそれぞれ別だからです。

```ruby
unless path.start_with?("lilpacy/deltas/") && path.end_with?(".md") &&
       !path.include?("..") && @repo_root.join(path).file?
  raise ArgumentError, "invalid Delta path: #{value}"
end
```

`merge` 側が受け取るのは **LLM が生成した文字列**です。つまり信頼できない入力。ここで `lilpacy/deltas/` 配下に閉じ込めることで、LLM が `lilpacy/Raw Old.md` や `../../etc/passwd` のようなものを返しても弾かれる。これも異常系テストで固定されています（`test_異常系_delta以外の候補pathは拒否される`）。

**なぜこれが効くのか**: `merge` の出力はそのまま `build_pi_synthesis_context.rb` の入力になり、そこで読まれたファイルが LLM の context に入ります。ここのガードが緩いと、Raw を意図的に除外した設計（`inputs` に Raw を含めない、という vault の規約）が LLM 自身の出力経由で迂回できてしまう。**「Raw を context に入れない」を LLM の善意ではなくコードで担保している**箇所です。

frontmatter の欠落・不正、`source`/`summary` リンクの欠落もすべて例外にしています（`required_link`、63-68 行目）。このスクリプト全体が「静かに劣化するより落ちる」方針で貫かれています。

## workflow の中での位置

```
[cursor 以降に追加された Delta を git diff で検出]
        ↓ delta-inputs.zlist（新着のみ）
  catalog ← このスクリプト
        ↓ synthesis-candidate-catalog.md（hint と link だけ、Raw なし）
  [pi-coding-agent --tools read] ← 過去 Delta を選ぶ
        ↓ synthesis-candidate-result.json
  merge ← このスクリプト（検証 + 新着と結合）
        ↓ synthesis-delta-inputs.zlist（確定入力集合）
  build_pi_synthesis_context.rb ← full context を組む
        ↓
  [pi-coding-agent] ← 本番の Concept 判断
        ↓
  pi_synthesis_apply.rb → Concept のみの PR
```

新着検知の境界となる cursor は `synthesis_ledger.rb` が管理します。`lilpacy/CLAUDE.md` に補足があります。「cursorは新着検知の境界であり、過去のConcept候補の有効期限にはしない」。だから **cursor より前の Delta も catalog には全件載る**。cursor が制御するのは「何が新着か」だけで、「何が候補になれるか」ではありません。

## まとめ

| 観点 | 内容 |
|---|---|
| 責務 | Concept 候補検索フェーズの入力生成と出力検証。判断はしない |
| 一番効いている設計 | 検索用の軽い catalog と判断用の full context を分離し、Raw を catalog から排除 |
| LLM への態度 | 出力を信頼しない。path を検証し、空回答でも新着分でパイプラインを継続 |
| エラー方針 | 予算超過・不正 path・frontmatter 不備はすべて例外。静かな劣化を許さない |
| 現状の余裕 | Delta 92 件で catalog 64,825 / 160,000 bytes（約 41%） |

関連ファイル（すべて絶対パス）:

- `/Users/lilpacy/.herdr/worktrees/obsidian/worktree-rapid-stone-a736/scripts/pi_synthesis_candidates.rb`
- `/Users/lilpacy/.herdr/worktrees/obsidian/worktree-rapid-stone-a736/.github/workflows/pi-concept-synthesis.yml`
- `/Users/lilpacy/.herdr/worktrees/obsidian/worktree-rapid-stone-a736/test/pi_synthesis_candidates_test.rb`
- `/Users/lilpacy/.herdr/worktrees/obsidian/worktree-rapid-stone-a736/scripts/build_pi_synthesis_context.rb`
- `/Users/lilpacy/.herdr/worktrees/obsidian/worktree-rapid-stone-a736/scripts/synthesis_ledger.rb`
- `/Users/lilpacy/.herdr/worktrees/obsidian/worktree-rapid-stone-a736/lilpacy/CLAUDE.md`（Concept・synthesis の運用規約）
