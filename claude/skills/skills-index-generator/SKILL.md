# Skills Index Generator

skillsディレクトリを走査し、AGENTS.md等に貼り付けられる **圧縮SKILLS-INDEX** を生成するSkill。

## Goals
- skillsディレクトリ内の全スキルを自動検出
- 各スキルの主要ファイル（SKILL.md, AGENTS.md, rules/*.md等）を圧縮形式で列挙
- `<!--SKILLS-INDEX-->...<!--END-->` 形式のワンライナーを出力

## Non-goals
- AGENTS.mdへの自動書き込み（出力をコピペする想定）
- スキルの内容解析・要約

## Inputs
- skillsディレクトリのパス（省略時: `~/.claude/skills`）
- rootパス表記（省略時: `~/.claude/skills`）

## Outputs
コピペ可能なワンライナー:
```
<!--SKILLS-INDEX-->|[Skills Index]|root:~/.claude/skills|IMPORTANT:Prefer retrieval-led reasoning over pre-training|If index stale run: ~/.claude/skills/skills-index-generator/generate.sh|skill-name:{files}|...<!--END-->
```

## Instructions

1. skillsディレクトリを走査し、サブディレクトリ一覧を取得
2. 各スキルフォルダ内のファイルを取得:
   - `SKILL.md` → 必須（なければスキップ）
   - `AGENTS.md` → あれば追加
   - `rules/*.md` → パターンで圧縮（例: `rules/async-*.md`）
   - `reference.md`, `examples.md` → あれば追加
   - `templates/` → あれば `templates/*` として追加
3. 各スキルを `skill-name:{file1,file2,...}` 形式に圧縮
4. ヘッダー部分を付与して出力:
   ```
   <!--SKILLS-INDEX-->|[Skills Index]|root:{rootPath}|IMPORTANT:Prefer retrieval-led reasoning over pre-training|{skills}<!--END-->
   ```

### ファイルパターン圧縮ルール
`rules/` 配下に複数ファイルがある場合、プレフィックスでグルーピング:
- `rules/async-request.md`, `rules/async-response.md` → `rules/async-*.md`
- `rules/query-optimization.md`, `rules/query-tips.md` → `rules/query-*.md`

同一プレフィックスが2つ以上あればワイルドカード化、1つだけならそのまま。

## Quality Checklist
- [ ] SKILL.mdが存在するフォルダのみ含める
- [ ] ファイル名のアルファベット順でソート
- [ ] rulesディレクトリはパターン圧縮されている
- [ ] 出力がワンライナー（改行なし）

## Examples

### Example 1: 基本実行
ユーザー: 「SKILLSのインデックスを生成して」

出力:
```
<!--SKILLS-INDEX-->|[Skills Index]|root:~/.claude/skills|IMPORTANT:Prefer retrieval-led reasoning over pre-training|agent-memory:{SKILL.md}|prd-writer:{SKILL.md}|react-best-practices:{SKILL.md,AGENTS.md,rules/async-*.md,rules/bundle-*.md}<!--END-->
```

### Example 2: カスタムパス
ユーザー: 「/path/to/skills のインデックスを作って」

→ `root:/path/to/skills` として生成

### Example 3: 非発動
ユーザー: 「新しいスキルを作って」

→ これはskill-skillsmithの役割。本Skillは発動しない。

## Trigger phrases
- 「SKILLSのインデックスを生成」「スキルインデックス作って」
- 「SKILLS-INDEXを更新」「圧縮インデックス作成」
- 「AGENTS.mdのスキル一覧を更新したい」
