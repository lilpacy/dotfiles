# pi_synthesis_candidates.rb ウォークスルー

## TL;DR

- **用途**: Pi（パーソナル LLM Wiki）に新しい Delta（ナレッジ差分）を追加するときに、どの Concept ページを影響を受ける可能性があるかを把握するツール
- **2つのモード**: 
  - `catalog`: 新しい Delta 群の「概念的影響ヒント」をカタログ化（160KB の予算制限内）
  - `merge`: カタログから人間が選んだ Delta 群を、既存セレクションとマージして null 区切りのリストで出力
- **安全装置**: 入力パス検証、YAML frontmatter の必須チェック、バイト予算の超過防止
- **出力形式**: Markdown（catalog）と null 区切りテキスト（merge）

---

## Background

### 個人 LLM Wiki (Pi) とはなにか（既知なら読み飛ばし）

個人用ナレッジベースを LLM が自動で構築・維持する仕組み。ユーザーが情報源を追加すると：

1. LLM が読み込み、重要な情報を抽出
2. Concept ページ（概念ページ）を作成・更新
3. 相互リンク（backlink）を保持

**Delta** は「ある情報源が new/modified/deleted の差分」を記録した Markdown ファイル。frontmatter に `source:` と `summary:` を持ち、本体に `## Concept impact hints` セクションを持つことがある。

### 問題状況

新しい Delta を複数個まとめて追加するとき、「どの Concept ページが影響を受けるか」を一覧化したい。しかし：

- Concept ページはユーザーが wiki 内で手作業で探すのは手間（数十から数百ファイル）
- すべての Concept 更新を自動で決定すると、誤判定のリスク
- **人間のレビューを挟む** ために、まず「候補リスト」を作り、人間が選別する仕組みが必要

---

## Intuition

### ゴール

**「新しい Delta が追加されたとき、影響を受ける可能性のある Concept ページ候補を、人間レビュー用のカタログとして作る」**

フロー図：

```mermaid
flowchart LR
  A["新しい Delta を複数個追加"] --> B["pi_synthesis_candidates.rb catalog"]
  B --> C["Concept Hints を抽出<br/>→ Markdown カタログ生成"]
  C --> D["人間がカタログを読む<br/>→ 本当に Concept<br/>更新すべき Delta を選ぶ"]
  D --> E["選んだ Delta を JSON で記述"]
  E --> F["pi_synthesis_candidates.rb merge"]
  F --> G["最終的な Delta リスト<br/>→ LLM wiki の<br/>Concept 更新に使う"]
```

### コア概念

**Concept Hints**: 各 Delta の frontmatter に「この Delta がどの Concept に影響するか」をユーザー/LLM が手書きしておく欄。例：

```markdown
## Concept impact hints
- 機械学習
- 推論
- パラメータ最適化
```

`catalog` コマンドがこれを集約して表示 → 人間が「本当に必要な Delta」を JSON で指定 → `merge` コマンドが最終リストを作る。

---

## Code

### 全体構造

2つのクラスが 2つの責務を分担：

| クラス | 責務 | 入力 | 出力 |
|---|---|---|---|
| `PiSynthesisCandidateCatalog` | Delta を読み込み、Concept Hints を抽出して Markdown 表形式で表示 | 新 Delta パスのリスト | Markdown カタログ |
| `PiSynthesisCandidateSelection` | 人間が選んだ JSON セレクションと新 Delta をマージ | selection JSON + 新 Delta | null 区切りのパスリスト |

### PiSynthesisCandidateCatalog: カタログ生成

```ruby
class PiSynthesisCandidateCatalog
  MAX_TOTAL_BYTES = 160_000

  def initialize(repo_root, new_delta_paths:, max_total_bytes: MAX_TOTAL_BYTES)
    # 入力パス検証
    @new_delta_paths = new_delta_paths.map { |path| validate_delta_path(path) }.to_set
    @max_total_bytes = max_total_bytes
    raise ArgumentError, "at least one new Delta path is required" if @new_delta_paths.empty?
  end
```

初期化時に：
- 全 Delta パスを検証（悪意あるパスの防止）
- 「新しく追加された Delta」を Set で記録（後で `[new]` マーカーをつけるため）
- バイト予算を保存

```ruby
  def build(output_path)
    lines = []
    @vault_dir.glob("deltas/*.md").sort.each do |path|
      hints = concept_hints(path)      # "## Concept impact hints" セクションを抽出
      next if hints.empty?

      metadata = frontmatter(path)     # YAML frontmatter を読む
      marker = @new_delta_paths.include?(relative) ? " [new]" : ""
      
      lines.concat([
        "## #{relative}#{marker}",
        "source: [[#{required_link(metadata, "source", path)}]]",
        "summary: [[#{required_link(metadata, "summary", path)}]]",
        *hints.map { |hint| "- #{hint}" },
      ])
    end
    
    content = "#{lines.join("\n")}\n"
    raise ArgumentError, "budget exceeded" if content.bytesize > @max_total_bytes
    Pathname(output_path).write(content)
  end
```

カタログを構築：

1. `lilpacy/deltas/*.md` 全ファイルをソート順で列挙
2. 各ファイルから Concept Hints を抽出（なければスキップ）
3. Frontmatter から `source` と `summary` リンクを必須チェック
4. 「新」フラグを付けて整形
5. バイト予算チェック（160KB 超過は error）
6. ファイルに書き込み

### 重要な検証関数

```ruby
  def frontmatter(path)
    lines = path.readlines(chomp: true)
    raise unless lines.first == "---"           # YAML frontmatter 開始
    closing = lines[1..]&.index("---")          # YAML frontmatter 終了行
    raise unless closing
    YAML.safe_load(lines[1..closing].join("\n"), 
                   permitted_classes: [Date], 
                   aliases: false) || {}         # alias を使った RCE 防止
  rescue Psych::SyntaxError => e
    raise ArgumentError, "malformed frontmatter: #{e.message}"
  end
```

Delta ファイルは **必ず frontmatter で始まる** という不変条件を強制。YAML デシリアライゼーション時に alias や任意クラス実行を許さない（セキュリティ）。

```ruby
  def required_link(metadata, field, path)
    link = metadata[field].to_s[/\[\[([^\]]+)\]\]/, 1]&.split("|", 2)&.first
    raise ArgumentError, "Delta #{field} link is missing: #{path}" unless link
    link
  end
```

Markdown リンク `[[ページ名|表示名]]` から `ページ名` を抽出。Concept Hints 以外の部分で frontmatter の `source` と `summary` が **必須** であることをチェック。

```ruby
  def concept_hints(path)
    lines = path.readlines(chomp: true)
    heading = lines.index("## Concept impact hints")
    return [] unless heading                    # なければ空リスト

    lines[(heading + 1)..]
      .take_while { |line| !line.start_with?("## ") }   # 次の heading まで
      .map { |line| line.delete_prefix("- ").strip if line.start_with?("- ") }
      .compact
      .reject { |hint| hint == "none" }        # "- none" の行は明示的に無視
  end
```

`## Concept impact hints` セクションを探し、その直後の箇条書き行を全部抽出（`- ` プレフィックスを剥がす）。他の section に遭遇したら終了。`"none"` は「影響なし」の明示的な宣言として扱う。

### PiSynthesisCandidateSelection: マージ

```ruby
class PiSynthesisCandidateSelection
  def merge(selection_path, output_path)
    selection = JSON.parse(Pathname(selection_path).read)
    raise unless selection.fetch("schema_version", nil) == 1
    
    selected = selection.fetch("selected_delta_paths", nil)
    raise unless selected.is_a?(Array)
    
    paths = (@new_delta_paths + selected.map { |path| validate_delta_path(path) }).uniq
    Pathname(output_path).binwrite("#{paths.join("\0")}\0")
  end
```

1. JSON から `selected_delta_paths` 配列を取得
2. 新 Delta パスと既存選定パスをマージ（重複削除）
3. **null 区切り** `\0` で連結してバイナリ出力

null 区切り形式は Unix の標準（`xargs -0`, `find -print0` など）。パス内のスペースや改行に対応する。

### CLI エントリポイント

```ruby
if $PROGRAM_NAME == __FILE__
  command = ARGV.shift   # "catalog" or "merge"
  
  case command
  when "catalog"
    PiSynthesisCandidateCatalog.new(repo_root, new_delta_paths: ARGV).build(output_path)
  when "merge"
    PiSynthesisCandidateSelection.new(repo_root, new_delta_paths: ARGV).merge(selection_path, output_path)
  end
end
```

使用例：

```bash
# Step 1: カタログを作成
ruby pi_synthesis_candidates.rb catalog . catalog.md lilpacy/deltas/新論文.md lilpacy/deltas/新記事.md

# Step 2: 人間が catalog.md を読んで、選んだ Delta を JSON で記述
cat > selection.json <<EOF
{
  "schema_version": 1,
  "selected_delta_paths": [
    "lilpacy/deltas/既存Delta1.md",
    "lilpacy/deltas/新論文.md"
  ]
}
EOF

# Step 3: 最終リストをマージ
ruby pi_synthesis_candidates.rb merge . selection.json output.zlist lilpacy/deltas/別の新Delta.md
```

---

## Quiz

**Q1**: `PiSynthesisCandidateCatalog` が frontmatter 内の `source` と `summary` を必須として検証する理由は何か？

a) Markdown の文法規格で required だから  
b) Concept Hints だけでは、影響を受けた Delta がどの情報源に由来するか追跡不可能なため、カタログを読む人間が文脈を持つため  
c) JSON スキーマで定義されているから  
d) セキュリティ上の理由（alias RCE 防止）  

<details><summary>答えと解説</summary>

**正解: b**

Concept Hints は「どの Concept に影響するか」だけを示す。しかし人間がカタログを読むとき「この Concept 影響は、どの情報源から来たのか」を知りたい。`source` リンクと `summary` リンクが frontmatter にあれば、人間はワンクリックで原情報源に遡れる。a)は誤り（Markdown 文法に「必須」はない）。c) は誤り（ここでは JSON スキーマを検証していない）。d) は関連があるが（frontmatter パース時に alias を禁止する）、**必須化の理由ではなく、パース方法の安全性**である。

</details>

---

**Q2**: `merge` コマンドが出力形式として null 区切り (`\0`) を選ぶ理由は？

a) JSON より人間が読みやすいから  
b) ファイルサイズが小さいから  
c) パス内のスペース・改行・特殊文字を安全に処理できる Unix 標準  
d) Ruby の `binwrite` 専用の形式だから  

<details><summary>答えと解説</summary>

**正解: c**

null 区切りは Markdown Wiki のコンテキストでは不可避。パス名が日本語を含むことがあり、スペースや改行も含まれうる。改行で区切ると曖昧になるが、null は ファイル名に使えない文字なので安全。Unix の `xargs -0`, `find -print0` など標準ツール群と相互運用可能。a) は誤り（人間が読むならテキスト形式の方が良い）。b) は関係ない（パス数が少ない場合、フォーマットの差は微々たるもの）。d) は誤り（単なる実装詳細）。

</details>

---

**Q3**: `concept_hints` メソッドが `reject { |hint| hint == "none" }` をするのはなぜか？

a) "none" は無効な Concept 名だから  
b) Delta が「Concept への影響なし」を明示的に宣言したときをサイレント削除するため  
c) YAML の null キーワード対策  
d) コメント行を削除するため  

<details><summary>答えと解説</summary>

**正解: b**

Delta ファイルのユーザー/LLM が「このファイルは何の Concept にも影響しない」と明示的に書く場合がある。その際に `- none` と書くことで、「セクションは存在するが、実質的に空」を表現できる。単純に `## Concept impact hints` セクションを削除するのではなく、セクションはあるけど `"- none"` だけ書く形式を採用すれば、「フロントマターの完全性」を保ちながら「実質的に影響なし」を記録できる。a) は誤り（"none" は Concept 名ではなく、特殊な値）。c) は誤り（YAML パースは frontmatter セクションで完結）。d) は誤り（コメント行は `#` で始まる）。

</details>

---

**Q4**: `new_delta_paths` が Set に変換される理由は？

a) 重複排除のため  
b) 後で `include?` 検査をするとき、配列の O(n) より Set の O(1) が高速  
c) JSON セリアライゼーション対応  
d) a と b 両方  

<details><summary>答えと解説</summary>

**正解: d**

`initialize` で `@new_delta_paths = new_delta_paths.map { ... }.to_set` と変換。後に `build` メソッド内で `@new_delta_paths.include?(relative)` をループ内で何度も呼ぶ。Set の `include?` は O(1)、配列は O(n)。新 Delta が数十個の場合、差は目に見えるほど。c) は誤り（Set をそのままシリアライズできない）。

</details>

---

**Q5**: `validate_delta_path` が `!path.include?("..")` をチェックするのはなぜか？

a) ファイルシステムのバグ対策  
b) パストラバーサル攻撃を防ぐため  
c) 相対パスが深すぎるとき警告するため  
d) シンボリックリンクを検出するため  

<details><summary>答えと解説</summary>

**正解: b**

`lilpacy/deltas/../../../../../../etc/passwd` のような入力を受け取ったとき、`cleanpath` は `etc/passwd` に正規化する。しかし元の入力に `..` が含まれていたなら、入力元（外部コマンド引数や JSON）が信頼できない可能性がある。`..` の存在を明示的に禁止することで、意図しない親ディレクトリアクセスを未然に防ぐ。a) は誤り（ファイルシステムのバグではなく、セキュリティ設計）。c) は誤り（深さ制限ではなく、親参照の禁止）。d) は誤り（シンボリックリンクは別の検証が必要）。

</details>

---

## 次の一手

**理解確認**:  
クイズに 4 問以上正解できれば、このスクリプトの 2つのモード（catalog / merge）と、安全装置（バイト予算・frontmatter 必須・パス検証）の設計意図が掴めています。

**発展的な質問**（興味があれば）:

1. **「なぜ 160KB の予算？」**: カタログ生成後、LLM に与えるコンテキスト予算の兼ね合い。人間がレビュー可能なサイズの目安。
2. **「merge 出力の活用先は？」**: null 区切りリストは、次の LLM ステップ（Concept 更新）に Unix パイプで渡される想定。  
3. **「Concept Hints は手書き or 自動生成？」**: 現在は不明ですが、LLM が Delta を読んで自動記入することも、ユーザーが手書きすることも可能な設計。

**コード追読のポイント**:  
次は `lilpacy/deltas/*.md` ファイルの実例を 1~2 件見ると、frontmatter と `## Concept impact hints` セクションの形式が具体的に理解でき、このスクリプトがどんなデータを受け取るのかが明確になります。
