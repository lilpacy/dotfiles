# pi_synthesis_candidates.rb の理解

## TL;DR

- このスクリプトは **Pi（個人知識ベースの統合）生成に向けた候補選定の2段階プロセス** を実装している
- **Stage 1（Catalog）** — 新しく取り込んだ知識Deltaファイル群から、概念影響ヒントを抽出し、メタデータカタログを生成
- **Stage 2（Merge）** — ユーザーが外部でマークした選定結果（JSON）と新Deltaを統合し、最終的にLLMに渡される候補リストを出力
- 2つのクラスで役割を分離：`PiSynthesisCandidateCatalog`（カタログ生成）と `PiSynthesisCandidateSelection`（統合）
- 出力は160KBの厳密なバイト制限付きで、軽量な形式に保つ

## Background

このスクリプトは、Obsidian vaultの LLM Wiki 運用フローの一部として機能する。

Vaultの3層構造（`CLAUDE.md` に定義）：
- **schema層** — LLMへの指示書とテンプレート
- **wiki層** — `deltas/`（知識差分）, `summaries/`（source単位の理解）, `concepts/`（複数source横断の理解）など
- **raw層** — 元のノート、画像、会話記録（LLMは読むだけで編集しない）

**Knowledge Delta** は、特定のsource snapshotを取り込んだ時点での知識差分の不変記録。frontmatterに `source` と `summary` へのリンクを必須として持ち、本文には以下が含まれる：

- `## Changes` — 新規主張（new）、精密化（refines）、強化（reinforces）、矛盾（contradicts）、不確実（uncertain）のタグ付き
- `## Concept impact hints` — その差分が関連しうる概念を非決定的に列挙（「none」の場合もある）

このスクリプトは、新しく取り込まれた複数のDeltaを見て、「Conceptレイヤーの合成に向けて、LLMに提示すべき候補は何か」を段階的に絞り込む処理を実装している。

## Intuition

目標： **重い情報（Raw、生Queryの会話記録）を除外しつつ、Conceptに影響しうるDeltaメタデータを効率的にLLMに提示する**

ステップの流れ：

```mermaid
flowchart LR
  A["新Deltaを取り込み<br/>(複数件)"]
  B["Catalog生成<br/>(メタデータのみ)"]
  C["ユーザー: JSON で<br/>選定マーク"]
  D["Merge統合<br/>新 + ユーザー選定"]
  E["最終候補リスト<br/>バイナリ形式"]
  
  A --> B
  B --> C
  C --> D
  D --> E
  
  style B fill:#e1f5ff
  style D fill:#e1f5ff
  style E fill:#f3e5f5
```

**Catalog（Stage 1）** の役割：
- `lilpacy/deltas/` 全体をスキャンし、新規Deltaに `[new]` マーカーを付ける
- 各Deltaの frontmatter から `source` と `summary` へのリンクを抽出
- 本文の `## Concept impact hints` セクションを読み取り、概念候補を列挙
- 結果をMarkdownで出力（160KB上限を守る）
  - このカタログを見ることで、LLMは「新情報がどの概念に関連しそうか」を事前に知ることができる

**Merge（Stage 2）** の役割：
- ユーザーが外部ツール（Figmaやスプレッドシート等）で、「このDeltaを最終的に合成に使う」とマークしたJSONを読む
- 新Deltaと既選定Deltaを統合し、重複を排除
- NULL文字で区切られたバイナリリスト形式で出力（ファイルサイズ効率化）

**バイト制限の理由**：
- LLMへの入力サイズに制限がある
- 軽量なメタデータ（source/summary リンク＋ヒント）だけを渡し、生Rawやクエリ内容は含めない
- 160KBは、数百のDeltaのメタデータなら余裕があるサイズ

## Code

### Catalog の流れ

```ruby
class PiSynthesisCandidateCatalog
  def initialize(repo_root, new_delta_paths:, max_total_bytes: MAX_TOTAL_BYTES)
    @repo_root = Pathname(repo_root)
    @vault_dir = @repo_root.join("lilpacy")
    @new_delta_paths = new_delta_paths.map { |path| validate_delta_path(path) }.to_set
    @max_total_bytes = max_total_bytes
  end
```

初期化時に：
- Vaultのルートディレクトリを特定
- 新規Deltaのパス群をセットに格納（クイックな重複チェックと存在確認用）
- 各パスの正当性を検証（`lilpacy/deltas/` からの相対パス、`.md` 拡張子、親ディレクトリ参照 `..` なし、ファイル実在）

```ruby
def build(output_path)
  lines = [
    "# Pi Concept Candidate Catalog",
    ...
  ]
  @vault_dir.glob("deltas/*.md").sort.each do |path|
    relative = path.relative_path_from(@repo_root).to_s
    hints = concept_hints(path)
    next if hints.empty?  # ヒントがなければスキップ

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
  end
  content = "#{lines.join("\n")}\n"
  raise ArgumentError, "catalog budget exceeded..." if content.bytesize > @max_total_bytes
  Pathname(output_path).write(content)
end
```

実行内容：
1. `lilpacy/deltas/` 内の全Markdownファイルを辞書順でソート
2. 各ファイルから `concept_hints()` で概念ヒント行を抽出
3. ヒントがない場合はスキップ（Conceptに影響しないDeltaは出力しない）
4. Frontmatterから source と summary へのwikilink を抽出（`[[]]` 形式）
5. 新規Deltaなら末尾に `[new]` マーカーを付ける
6. Markdown形式で整形して連結
7. バイト数チェック後、ファイルに書き込み

### Frontmatter 解析

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

- ファイルの最初と最後が `---` であることを確認
- その間のYAMLを安全にパース（Date クラスのみ許可、エイリアス禁止）
- YAML構文エラーなら詳細メッセージと共に raise

### Concept impact hints の抽出

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

- `## Concept impact hints` セクションを探す（なければ空配列を返す）
- セクション内の行を、次の `## ` 見出しまで取得
- 箇条書き行（`- ` で始まる）だけを抽出し、`"none"` は除外

### Required link 抽出

```ruby
def required_link(metadata, field, path)
  link = metadata[field].to_s[/\[\[([^\]]+)\]\]/, 1]&.split("|", 2)&.first
  raise ArgumentError, "Delta #{field} link is missing: #{path}" unless link
  link
end
```

- Frontmatter値から `[[link|display]]` の `link` 部分を正規表現で抽出
- `|` がある場合は最初のパイプまで（Wiki表示テキストは無視）
- 見つからなければエラー

### Merge の流れ

```ruby
class PiSynthesisCandidateSelection
  def merge(selection_path, output_path)
    selection = JSON.parse(Pathname(selection_path).read)
    raise ArgumentError, "schema_version must be integer 1" unless selection.fetch("schema_version", nil) == 1

    selected = selection.fetch("selected_delta_paths", nil)
    raise ArgumentError, "selected_delta_paths must be an array" unless selected.is_a?(Array)

    paths = (@new_delta_paths + selected.map { |path| validate_delta_path(path) }).uniq
    Pathname(output_path).binwrite("#{paths.join("\0")}\0")
  end
end
```

実行内容：
1. 選定JSON（`selection_path`）をパース
2. `schema_version: 1` の確認（将来の互換性管理用）
3. `selected_delta_paths` 配列を抽出
4. 各パスを検証
5. 新Deltaと既選定Deltaを統合し、重複排除
6. NULL文字（`\0`）で区切ったバイナリ形式で出力

バイナリ形式を使う理由：テキスト改行の曖昧性を避け、パス文字列内に改行があっても正確に分割できる。

### CLI インターフェース

```ruby
if $PROGRAM_NAME == __FILE__
  command = ARGV.shift
  repo_root = ARGV.shift

  case command
  when "catalog"
    output_path = ARGV.shift
    # usage: script.rb catalog REPO_ROOT OUTPUT_PATH NEW_DELTA_PATH...
    PiSynthesisCandidateCatalog.new(repo_root, new_delta_paths: ARGV).build(output_path)
  when "merge"
    selection_path = ARGV.shift
    output_path = ARGV.shift
    # usage: script.rb merge REPO_ROOT SELECTION_JSON OUTPUT_ZLIST NEW_DELTA_PATH...
    PiSynthesisCandidateSelection.new(repo_root, new_delta_paths: ARGV).merge(selection_path, output_path)
  else
    abort "usage: #{$PROGRAM_NAME} catalog|merge ..."
  end
end
```

2つのサブコマンドを提供：

| コマンド | 入力 | 出力 | 用途 |
|---------|------|------|------|
| `catalog` | REPO_ROOT, OUTPUT_PATH, NEW_DELTA_PATH... | Markdownファイル | メタデータカタログを生成 |
| `merge` | REPO_ROOT, SELECTION_JSON, OUTPUT_ZLIST, NEW_DELTA_PATH... | NULL区切りバイナリ | ユーザー選定と新Deltaを統合 |

## Quiz

**問1: Concept impact hints セクションが「none」だけの場合、そのDeltaはCatalogに出力されるか？**

A. 出される（バイナリ形式だから）  
B. 出されない（ヒントがないとスキップされる）  
C. ユーザーが明示的に指示した場合だけ出される  
D. mergeコマンドでのみ処理される

**正解：B**

解説： `concept_hints()` メソッドで、 `"none"` を `reject` で除外してから、 `next if hints.empty?` でスキップが判定される。つまり空になったヒント配列を持つDeltaはCatalogに含まれない。Conceptに関連しないDeltaを軽量に保つための設計。

---

**問2: Merge操作で NULL 文字を区切り文字に使う理由は？**

A. ファイルサイズを最小化するため  
B. テキスト改行が含まれるパスでも正確に分割できるため  
C. 暗号化と互換性のため  
D. スクリプト実行速度を上げるため

**正解：B**

解説： `\0` （NULL文字）はテキストファイルパス内にはまず出現しない制御文字。テキスト形式で改行を使うと、パス自体に改行が含まれた場合、分割ロジックが誤認する可能性がある。バイナリ形式なら安全に境界を特定できる。

---

**問3: `validate_delta_path()` が複数の検査を同時に行う。その中で最も重要な防御は？**

A. `.md` 拡張子の確認  
B. `lilpacy/deltas/` で始まることの確認  
C. `..` （親ディレクトリ参照）が含まれないことの確認  
D. ファイルが実在することの確認

**正解：C**

解説： `..` が含まれていないことを確認する理由は、パストラバーサル攻撃を防ぐため。例えば `lilpacy/deltas/../../sensitive_file.md` のようなパスが許可されると、設定外のファイルにアクセスできる。`.md` 拡張子確認より、このセキュリティチェックが重要。

---

**問4: Catalogファイルのバイト制限（160KB）を超えた場合、スクリプトはどう動作するか？**

A. 古いDeltaから削除して、新規のみ残す  
B. エラーをraiseして実行を中止する  
C. 出力ファイルの名前を自動変更して複数ファイルに分割する  
D. 警告をログに出すが、全内容を出力する

**正解：B**

解説： `raise ArgumentError, "candidate catalog budget exceeded..."` により即座に失敗する。容量超過は、取り込みDeltaが多すぎるか Concept impact hints が過度に詳細な場合の警告シグナル。ユーザーが明示的に判断して対応すべき設計。

---

**問5: このスクリプトが処理する「新Delta」と「既存Delta」を区別する理由は何か？**

A. Catalogの読みやすさのためにマーカーで視覚的に分ける  
B. 新Delta だけに対して特別なバリデーションを行う  
C. Mergeで新Deltaを優先度高く扱うため  
D. 新しく追加された概念を LLM に意識させるため

**正解：A・D**（複合）

解説： Catalogの `[new]` マーカーは、LLMが「今回新しく入ってきた情報はこれらです」と一目で判別できるようにする視覚的な工夫。同時に、新情報の方が既存知識との統合・矛盾検出・Concept更新の対象になりやすいため、マーキングにより重要度が伝わる。Mergeでは特別扱いせず、同一の検証ルールを適用。

## 解答と解説

**問1:** B  
ヒントが空になると `next` でスキップされるため。

**問2:** B  
NULL文字はテキストパスに含まれず、安全に区切り文字として使える。改行が含まれるパスでも正確に分割できる。

**問3:** C  
パストラバーサル（`..` による親ディレクトリアクセス）を防ぐのが最重要セキュリティ対策。

**問4:** B  
バイト超過時は `raise ArgumentError` で実行を中止。容量管理はユーザー責任。

**問5:** A・D  
マーカーで新情報を視認化し、LLMの意識付け。Mergeでは区別しない。

## 次の一手

- **レビュー時に見るべき点**：
  - 新規Delta のフロントマッター検証は厳格（source / summary リンク必須）
  - Concept impact hints の粒度がカタログ容量と見合っているか
  - 160KBを超えやすい場合、定期的なヒント内容の整理が必要

- **残った未解決点**：
  - LLMへの渡し方（このスクリプトは候補を抽出するだけで、実際のPi合成は別処理）
  - ユーザーの「選定JSON」は外部ツール（Figmaなど）で生成される前提だが、そのプロトコルは本スクリプトでは定義されていない

- **発展の方向**：
  - Merge出力（NULL区切りバイナリ）を実際に受け取るLLM側のパーサーと連携確認
  - Catalogを定期実行し、新Deltaの蓄積に応じた容量管理のワークフロー構築
