# Pi Synthesis Candidates: Script Walkthrough

## TL;DR

- スクリプトは「Pi Synthesis」というプロセスをサポート。新しく作成された Delta（変更ログ）から「Concept」の候補を整理する2つの操作を提供
- **Catalog 操作**: 全ての Delta ファイルをスキャンして、新規 Delta に対して「Concept impact hints」（影響するコンセプト）を抽出し、メタデータと一緒にマークダウンカタログにまとめる
- **Merge 操作**: ユーザーが JSON 形式で選択した Delta パスと、新規 Delta を統合して、ヌル区切りのリスト形式で出力
- 安全性チェック: Delta ファイルの存在検証、フロントマター形式チェック、出力サイズ制限（160KB以下）を実施
- 主な用途: LLM Wiki の ingest 処理で、どの Delta がコンセプトに影響するかをフィルタリングして、次のステップに渡す

## Background

このスクリプトは lilpacy の LLM Wiki 運用に組み込まれています。Wiki の 3層構造は：

- **Raw sources**: 記事・論文などの一次情報（変更しない）
- **The wiki**: LLM が生成したマークダウンページ（要約・エンティティ・コンセプト）
- **The schema**: 運用ルール（CLAUDE.md）

"Delta" は「変化」を意味し、このシステムでは新しく ingested された raw source について「何が変わったのか」をまとめたマークダウンファイルです。このファイルは：
- **frontmatter**: メタデータ（source, summary など wiki 内のリンク形式で指定）
- **本文**: 変更の詳細
- **Concept impact hints セクション**: 「このソースから学んだコンセプトのうち、wiki のどのページに影響するか」をリスト化したもの

新しい Delta が生成されたとき、LLM はそれを「どの既存コンセプトに関連するのか」を判定し、この情報を Concept impact hints として記録します。

pi_synthesis_candidates.rb は、これら Delta を整理・フィルタリングして、次のステップ（Concept 更新）に渡す前処理スクリプトです。

## Intuition

**目的**: 新規 Delta 群から、既存 Concept に影響を与えうる Delta を特定し、効率的に処理できるようにする。

**動作イメージ**:

```
[新規 Delta 3個 投入]
  ↓
Catalog 操作: 全 Delta をスキャン → Concept impact hints を抽出
  ↓
[候補カタログ生成]（markdown、全 Delta と hints をリスト化）
  ↓
[ユーザーが JSON 形式で「どの Delta を処理するか」を選択]
  ↓
Merge 操作: 選択内容 + 新規 Delta を統合
  ↓
[出力: ヌル区切りパス一覧]（次ステップで反復処理可能）
```

**核となる仕組み**:

1. **Catalog**: Delta ファイル群の「メタデータ + hints」を抽出してマークダウンにまとめる。ユーザーが候補を確認するための情報源。
2. **Merge**: ユーザーの選択（JSON）と新規 Delta を合わせて、効率的な形式（ヌル区切り）で出力。パイプ処理に向いた形式。

**制約と安全性**:
- 入力 Delta は必ず `lilpacy/deltas/*.md` 形式で、実ファイルとして存在する必要がある
- Catalog 出力は 160KB 以下の制限あり（メモリ効率）
- frontmatter は YAML 形式で、Date 型のみ許可（セキュリティ）

## Code

### クラス1: PiSynthesisCandidateCatalog

```ruby
class PiSynthesisCandidateCatalog
  MAX_TOTAL_BYTES = 160_000

  def initialize(repo_root, new_delta_paths:, max_total_bytes: MAX_TOTAL_BYTES)
    @repo_root = Pathname(repo_root)
    @vault_dir = @repo_root.join("lilpacy")
    @new_delta_paths = new_delta_paths.map { |path| validate_delta_path(path) }.to_set
    @max_total_bytes = max_total_bytes
    raise ArgumentError, "at least one new Delta path is required" if @new_delta_paths.empty?
  end
```

初期化で、repo ルート、新規 Delta パス群、出力サイズ制限を設定。各パスは `validate_delta_path` で安全性チェック（13-19行）。

```ruby
  def build(output_path)
    lines = [...]  # ヘッダー作成
    @vault_dir.glob("deltas/*.md").sort.each do |path|
      relative = path.relative_path_from(@repo_root).to_s
      hints = concept_hints(path)
      next if hints.empty?  # hints がなければスキップ

      metadata = frontmatter(path)
      marker = @new_delta_paths.include?(relative) ? " [new]" : ""
      lines.concat([
        "## #{relative}#{marker}",
        "source: [[#{required_link(metadata, "source", path)}]]",
        "summary: [[#{required_link(metadata, "summary", path)}]]",
        *hints.map { |hint| "- #{hint}" },
        ""
      ])
    end
```

`build` メソッド（21-49行）:
1. 全ての Delta ファイルをソート順でスキャン
2. 各ファイルから Concept impact hints を抽出
3. hints があれば、メタデータ（source, summary）と一緒にマークダウン形式で出力
4. 新規 Delta には `[new]` マーカーを付与
5. 最後に出力サイズをチェック

```ruby
  private

  def validate_delta_path(value)
    path = Pathname(String(value)).cleanpath.to_s
    unless path.start_with?("lilpacy/deltas/") && path.end_with?(".md") && !path.include?("..") && @repo_root.join(path).file?
      raise ArgumentError, "invalid Delta path: #{value}"
    end
    path
  end
```

`validate_delta_path`（53-59行）: 入力パスの安全性を徹底チェック。
- `lilpacy/deltas/` 配下に限定
- `.md` 拡張子
- `..` パストラバーサル禁止
- 実ファイル存在確認

```ruby
  def frontmatter(path)
    lines = path.readlines(chomp: true)
    raise ArgumentError, "missing Delta frontmatter: #{path}" unless lines.first == "---"
    closing = lines[1..]&.index("---")
    raise ArgumentError, "missing Delta frontmatter close: #{path}" unless closing
    YAML.safe_load(lines[1..closing].join("\n"), permitted_classes: [Date], aliases: false) || {}
  rescue Psych::SyntaxError => e
    raise ArgumentError, "malformed Delta frontmatter: #{path}: #{e.message}"
  end
```

`frontmatter`（61-69行）: Delta ファイルから YAML frontmatter を抽出。
- 最初と最後が `---` で囲まれているか確認
- `YAML.safe_load` で Date 型のみ許可（セキュアなパース）
- 構文エラーはキャッチして詳細報告

```ruby
  def required_link(metadata, field, path)
    link = metadata[field].to_s[/\[\[([^\]]+)\]\]/, 1]&.split("|", 2)&.first
    raise ArgumentError, "Delta #{field} link is missing: #{path}" unless link
    link
  end
```

`required_link`（71-75行）: frontmatter の特定フィールド（`source`, `summary`）から、wiki リンク形式 `[[page-name]]` を抽出。正規表現で `[[...]]` を検出。

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

`concept_hints`（77-87行）: Delta ファイル本文から「Concept impact hints」セクション（`## Concept impact hints`）を探し、その直後の`- ` で始まる行をリスト化。
- セクションが存在しなければ空配列を返す
- 次のセクション（`## ` で始まる行）までを対象
- `- ` プレフィックスを削除し、不要な空白を整理
- `"none"` という文字列は除外

### クラス2: PiSynthesisCandidateSelection

```ruby
class PiSynthesisCandidateSelection
  def initialize(repo_root, new_delta_paths:)
    @repo_root = Pathname(repo_root)
    @new_delta_paths = new_delta_paths.map { |path| validate_delta_path(path) }
    raise ArgumentError, "at least one new Delta path is required" if @new_delta_paths.empty?
  end

  def merge(selection_path, output_path)
    selection = JSON.parse(Pathname(selection_path).read)
    raise ArgumentError, "schema_version must be integer 1" unless selection.fetch("schema_version", nil) == 1

    selected = selection.fetch("selected_delta_paths", nil)
    raise ArgumentError, "selected_delta_paths must be an array" unless selected.is_a?(Array)

    paths = (@new_delta_paths + selected.map { |path| validate_delta_path(path) }).uniq
    Pathname(output_path).binwrite("#{paths.join("\0")}\0")
  rescue JSON::ParserError => e
    raise ArgumentError, "malformed candidate selection JSON: #{e.message}"
  end
```

`merge` メソッド（97-108行）:
1. 選択ファイル（JSON）を読み込み、スキーマ検証
2. `selected_delta_paths` フィールド（配列）を抽出
3. 新規 Delta + 選択済み Delta を統合して重複排除（`uniq`）
4. パスを **ヌル区切り文字** `\0` で区切った形式で出力

この出力形式（ヌル区切り）は、シェルコマンド `xargs -0` に直接パイプ可能。パス内に空白やメタ文字があっても安全。

### Main Entry Point

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

スクリプトが直接実行された場合のコマンドラインインターフェース：

```
# Catalog コマンド
ruby pi_synthesis_candidates.rb catalog REPO_ROOT OUTPUT.md lilpacy/deltas/new1.md lilpacy/deltas/new2.md

# Merge コマンド
ruby pi_synthesis_candidates.rb merge REPO_ROOT selection.json output.zlist lilpacy/deltas/new1.md
```

## Quiz

以下の3問で、このスクリプトの理解を確認してください。

### 問1: Catalog の出力に「[new]」マーカーが付く条件は何ですか？

A. すべての Delta ファイルに付与される  
B. frontmatter に `source` フィールドがある Delta のみ  
C. 初期化時に `new_delta_paths` で渡されたパスと一致する Delta  
D. Concept impact hints が10個以上ある Delta

**正解: C**

Catalog の build メソッド35行を見ると：
```ruby
marker = @new_delta_paths.include?(relative) ? " [new]" : ""
```
新規 Delta は初期化時に Set として保持されており、スキャン中に各ファイルのパスがこの Set に含まれているかチェック。含まれていれば `[new]` を付与しています。

### 問2: Merge 操作で出力ファイルの形式（ヌル区切り）が使われている主な理由は何ですか？

A. ファイルサイズを削減するため  
B. パス内の空白やメタ文字に対応し、シェルコマンド `xargs -0` で安全に処理するため  
C. JSON より解析が高速だから  
D. Windows ファイルシステムとの互換性を確保するため

**正解: B**

105行の `Pathname(output_path).binwrite("#{paths.join("\0")}\0")` はヌル区切りを使用。理由はシェルのパイプ処理での安全性。パス内に改行やスペースがあっても `xargs -0` で正しく分割・処理できます。

### 問3: `frontmatter` メソッドが YAML パース時に `permitted_classes: [Date]` を指定している理由は？

A. Date 型の日付を自動変換するため  
B. セキュリティ: 任意のクラスのデシリアライズを防ぐため  
C. Ruby のデフォルト YAML パーサーは Date を認識しないため  
D. frontmatter にはタイムスタンプしかないため

**正解: B**

YAML では `!ruby/object:` という記法で任意のクラスをインスタンス化できます。これはセキュリティリスク。`permitted_classes: [Date]` で Date 型のみ許可し、他のクラスのデシリアライズを拒否します。`aliases: false` も同様にセキュリティ強化（YAML アンカー・エイリアスの無効化）。

## 次の一手

### レビューで確認すべき点
- frontmatter の `source` と `summary` リンクは必ず存在するか（required_link でチェック）
- Catalog の 160KB 制限は実運用で十分か（大量の Delta がある場合）
- Merge 後の出力ファイルが確実に次ステップで処理されるか

### 残った未解決点
- Concept impact hints の内容が誰（またはどの LLM ステップ）で生成されるのかは、このスクリプトの範囲外
- 「どの Delta を選ぶか」という JSON 選択ファイルの生成ロジックも別プロセス

### 発展の方向
- 選択ファイルの自動生成（LLM が hints を分析して選択提案）
- Catalog の HTML 出力版（ブラウザで閲覧・選択可能）
