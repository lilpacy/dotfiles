# Claude Code Skills Index Pattern

## 背景

Vercelの[next-agents-md](https://vercel.com/blog/how-we-built-an-agent-first-docs-index-for-nextjs)で紹介されたパターン。

問題: スキル発動をエージェントに委ねると、発動しないことがある
解決: ドキュメントインデックスを直接AGENTS.mdに埋め込む

## コア原則

```
IMPORTANT: Prefer retrieval-led reasoning over pre-training
```

この指示により、Claude Codeが古い学習データに頼らず、最新のドキュメントを読んでから回答するよう促す。

## 圧縮インデックス形式

```
<!--SKILLS-INDEX-->|[Skills Index]|root:~/.claude/skills|IMPORTANT:Prefer retrieval-led reasoning over pre-training|If index stale run: ~/.claude/skills/skills-index-generator/generate.sh|skill-name:{SKILL.md,reference.md,rules/*.md}|...<!--END-->
```

要素:
- `root:` - スキルディレクトリのパス
- `IMPORTANT:` - retrieval優先の指示
- `If index stale run:` - 再生成コマンドのヒント
- `skill-name:{files}` - 各スキルと含まれるファイル

## ファイルパターン圧縮

`rules/` 配下に複数ファイルがある場合、プレフィックスでグルーピング:
- `rules/async-request.md`, `rules/async-response.md` → `rules/async-*.md`
- 同一プレフィックスが2つ以上あればワイルドカード化

## 自動生成

```bash
~/.claude/skills/skills-index-generator/generate.sh
```

出力をAGENTS.mdにコピペする。

## 相対パス vs 絶対パス

```diff
- root:./claude/skills    # プロジェクトごとに異なる
+ root:~/.claude/skills   # どのプロジェクトからも同じ
```

シンボリックリンク `~/.claude/skills` を使うことで、dotfilesで一元管理しつつ、どのプロジェクトからも参照可能にする。

## 参考

- [AGENTS.md outperforms Skills in our agent evals](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)
- next-agents-md: `npx @judegao/next-agents-md`
