# pi_synthesis_candidates.rb: 何をしているか

## Background

このスクリプトは、LLM Wiki（obsidian vault）の Concept Synthesis パイプラインの一部として機能します。

Concept Synthesis は、複数の独立した情報源（Source）から抽出された「知識差分」（Knowledge Delta）を横断分析し、source を超えた普遍的な概念（Concept）を生成するプロセスです。このスクリプトはその**候補選定段階**を担当します。

具体的には：
1. 新着の Delta（新しく vault に取り込まれた知識記録）が存在する
2. 過去に作られた Delta たちのなかから、新着 Delta と関連しそうなものを見つける
3. その関連 Delta をリスト化し、LLM が Concept 生成に使う文脈（context）を組み立てる準備をする

このとき重要な制約が 3 つあります：
- **隔離**: Raw（元記事）や Query transcript の本文は context に含めない。Delta 層（vault 管理済みの知識記録）だけを使う
- **スケール**: Concept synthesis に入力できるサイズに制限がある。文脈が大きすぎると LLM に渡せない
- **根拠可能性**: 候補を選んだら、選んだ理由をログに記録し、あとから「なぜこれが必要だったのか」を検証できるようにする

## Intuition

このスクリプトの仕事を図で表すと：

```
[新着 Delta 群] → (1) Catalog作成 → [候補表示] → ユーザー選択
                          ↓
                    (2) Selection merge
                          ↓
                    [最終的な Delta リスト]
                          ↓
                    [Context builder に渡す]
```

より詳しく：

**Phase 1: Catalog作成（`PiSynthesisCandidateCatalog`クラス）**

vault の全 Delta を眺めて、各 Delta が「どの Concept へ影響しそうか」を示す"ヒント"を列挙する軽量ドキュメントを作ります。

```
## lilpacy/deltas/E2E高速化.md [new]
source: [[Raw Article 1]]
summary: [[summaries/E2E高速化]]
- キャッシュ戦略の効果
- 依存関係の削減

## lilpacy/deltas/テストの分離.md
source: [[Raw Article 2]]
summary: [[summaries/テストの分離]]
- テストの独立性が重要
```

ここで `[new]` は「今回新しく追加された」を示します。ユーザーはこれを眺めて、「この新着 Delta と一緒に context に入れる過去の Delta はどれか」を判断します。

サイズ制限（MAX_TOTAL_BYTES = 160KB）があるので、catalog 全体が大きすぎてはいけません。

**Phase 2: Selection merge（`PiSynthesisCandidateSelection`クラス）**

ユーザーの選択を JSON で受け取り、新着 Delta + 選ばれた過去 Delta の確定リストを作ります。この確定リストが次のステップ（Context Builder）の入力になります。

```
入力: {
  "schema_version": 1,
  "selected_delta_paths": [
    "lilpacy/deltas/テストの分離.md",
    "lilpacy/deltas/並列実行.md"
  ]
}

↓ merge 処理

出力: "lilpacy/deltas/E2E高速化.md\0lilpacy/deltas/テストの分離.md\0lilpacy/deltas/並列実行.md\0"
```

出力形式は「null文字（`\0`）区切り」。これはシェルやスクリプトで安全に行ごとに処理でき、ファイル名にスペースや特殊文字があっても壊れません。

## Code

### 1. PiSynthesisCandidateCatalog#build

```ruby
def build(output_path)
  lines = [
    "# Pi Concept Candidate Catalog",
    "",
    "This catalog contains only Delta metadata and non-deterministic Concept impact hints.",
    "Raw Source and query transcript contents are intentionally excluded.",
    ""
  ]
```

まずヘッダを作ります。「Raw と query を除外した」ことを明記するのは重要。後で誰かが「なぜ本文が無いのか」と混乱しないため。

```ruby
  @vault_dir.glob("deltas/*.md").sort.each do |path|
    relative = path.relative_path_from(@repo_root).to_s
    hints = concept_hints(path)
    next if hints.empty?
```

vault の `deltas/` 以下の全 `.md` ファイルを列挙します。`concept_hints(path)` で各 Delta から「Concept impact hints」セクションを抽出します。ヒントが無ければ `next` でスキップ。

```ruby
    metadata = frontmatter(path)
    marker = @new_delta_paths.include?(relative) ? " [new]" : ""
    lines.concat([
      "## #{relative}#{marker}",
      "",
      "source: [[#{required_link(metadata, "source", path)}]]",
      "summary: [[#{required_link(metadata, "summary", path)}]]",
      *hints.map { |hint| "- #{hint}" },
      ""
    ])
```

各 Delta について：
- frontmatter から `source` と `summary` の wikilink を抽出
- 新着 Delta には `[new]` マーカーを付加
- ヒントの各行を箇条書き化

```ruby
  content = "#{lines.join("\n")}\n"
  raise ArgumentError, "candidate catalog budget exceeded: #{content.bytesize} > #{@max_total_bytes}" if content.bytesize > @max_total_bytes

  Pathname(output_path).write(content)
```

サイズチェック後、ファイルに書き出し。予算超過は Silent failure ではなく**失敗させる**ことが重要（候補を欠落させて silent に partial context を LLM に渡すのを防ぐため）。

### 2. concept_hints と frontmatter

```ruby
def concept_hints(path)
  lines = path.readlines(chomp: true)
  heading = lines.index("## Concept impact hints")
  return [] unless heading

  lines[(heading + 1)..]
    .take_while { |line| !line.start_with?("## ") }
    .map { |line| line.delete_prefix("- ").strip if line.start_with?("- ") }
    .compact
    .reject { |hint| hint == "none" }
end
```

"## Concept impact hints" セクションを探し、その直後の行から次の `##` セクション始まるまでを取る。`- ` で始まる行を抽出（箇条書きの bullet を削除）。`"none"` リテラルは特別に除外（ヒントなしを示す明示的マーカー）。

### 3. PiSynthesisCandidateSelection#merge

```ruby
def merge(selection_path, output_path)
  selection = JSON.parse(Pathname(selection_path).read)
  raise ArgumentError, "schema_version must be integer 1" unless selection.fetch("schema_version", nil) == 1

  selected = selection.fetch("selected_delta_paths", nil)
  raise ArgumentError, "selected_delta_paths must be an array" unless selected.is_a?(Array)

  paths = (@new_delta_paths + selected.map { |path| validate_delta_path(path) }).uniq
  Pathname(output_path).binwrite("#{paths.join("\0")}\0")
```

新着 Delta と選ばれた過去 Delta を合わせ、`.uniq` で重複を除外（新着が過去リストに重複して入っていた場合のため）。最後に null 文字で join して binwrite。`.binwrite` は バイナリモードで書くので、`\0` が正しくエスケープされます。

### 4. validate_delta_path

```ruby
def validate_delta_path(value)
  path = Pathname(String(value)).cleanpath.to_s
  unless path.start_with?("lilpacy/deltas/") && path.end_with?(".md") && !path.include?("..") && @repo_root.join(path).file?
    raise ArgumentError, "invalid Delta path: #{value}"
  end
  path
end
```

path が本当に Delta ファイルかチェック：
- `lilpacy/deltas/` の配下か
- `.md` で終わるか
- `..` で上位ディレクトリへ逃げられないか（security check）
- 実ファイルとして存在するか

**重要**: 外部入力（JSON の`selected_delta_paths`）を信用しない。すべて検証してから使う。

### 5. CLI entry point

```ruby
if $PROGRAM_NAME == __FILE__
  command = ARGV.shift
  repo_root = ARGV.shift

  case command
  when "catalog"
    output_path = ARGV.shift
    abort "usage: ..." unless repo_root && output_path && !ARGV.empty?
    PiSynthesisCandidateCatalog.new(repo_root, new_delta_paths: ARGV).build(output_path)
  when "merge"
    selection_path = ARGV.shift
    output_path = ARGV.shift
    abort "usage: ..." unless repo_root && selection_path && output_path && !ARGV.empty?
    PiSynthesisCandidateSelection.new(repo_root, new_delta_paths: ARGV).merge(selection_path, output_path)
  else
    abort "usage: #{$PROGRAM_NAME} catalog|merge ..."
  end
end
```

2 つのコマンドをサポート：

```bash
ruby pi_synthesis_candidates.rb catalog /repo/root output.md lilpacy/deltas/New.md
ruby pi_synthesis_candidates.rb merge /repo/root selection.json output.zlist lilpacy/deltas/New.md
```

`ARGV.shift` で コマンド名 → repo_root → その次のパラメータの順に取ります。

---

## Quiz

読み終わったら、次の 3 問に答えてみてください。どれが正しいか選んでください。

### 問題 1: このスクリプトが作る「Catalog」の目的は何か？

**A.** Concept を生成するために必要な Delta を決定的に選ぶ LLM 自動判定プログラム

**B.** ユーザーが「どの過去 Delta を context に含めるべきか」を判断するための軽量な候補表示ドキュメント

**C.** Vault の全 Delta を JSON に変換し、別のスクリプトへ渡すための中間ファイル

**D.** Raw ソースの本文と Delta を一緒に Bundle して長期保存するアーカイブ

---

### 問題 2: なぜこのスクリプトは Raw Source と Query Transcript を catalog から除外するのか？

**A.** ファイルサイズが大きすぎるから

**B.** LLM の instruction token 予算を節約し、context は Wiki 層（Delta/Summary/Concept）だけに限定することで、Concept generation を根拠可能にするため

**C.** セキュリティの都合で秘密情報を隠すため

**D.** Raw と Query は毎日変わるため catalog をキャッシュできないから

---

### 問題 3: `validate_delta_path` が `path.include?("..")` をチェックするのはなぜか？

**A.** ファイル名に二重ピリオドが使われていないか形式チェックするため

**B.** 相対パスで上位ディレクトリへ逃げられることを防ぎ、入力の信用度を確保するセキュリティチェック

**C.** `Pathname#cleanpath` の動作確認用テスト

**D.** `.md` ファイル内の `..` マークダウンシンタックスと競合しないか確認するため

---

どれかに悩んだ、または複数選択肢に迷ったら、その箇所を教えてください。マイクロワールド（実際に Delta ファイルを作ってみて、catalog と merge の挙動を見る interactive script）で掴み直すことで理解が深まります。
