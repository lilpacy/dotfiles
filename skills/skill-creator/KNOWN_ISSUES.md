## 概要

skill-creator の description 最適化ハーネス（`scripts/run_eval.py` / `scripts/run_loop.py`）が、どんな description でも recall 0% を返し、トリガー精度を測定できない。

goal-first skill の description チューニング（2026-08-19）で発覚。5 イテレーション全候補が train/test とも recall 0%（should-trigger 全滅、should-not-trigger 全 PASS = 一度もトリガーしない）。

## 原因（切り分け済み）

### 1. skill の置き場所が間違っている（バグ本体）

`run_eval.py` の `run_single_query()` は skill を `.claude/commands/<name>.md`（スラッシュコマンド置き場）に書き込む。現行の Claude Code ではここに置いたファイルは `/name` 起動専用で、モデルが自律選択する available_skills 一覧に載らない。

検証: skill 名を明示したクエリ（「goal-first というスキルを使って…」）ですらトリガー判定 0/1。同内容を `.claude/skills/<name>/SKILL.md` に置き直すと、名前明示クエリでトリガー成功（マーカー語が応答に出現）。

**修正案**: コマンドファイル生成を `.claude/skills/<clean_name>/SKILL.md`（frontmatter: name + description）の生成に変更する。cleanup も同様にディレクトリ削除へ。

### 2. `-p` 非対話モードでは自然文からの自動トリガーがほぼ起きない（修正後も残る制約）

置き場所を直しても、自然文クエリ（例:「本番のnightly batchが今朝落ちてた。調査方針教えて」）でのトリガーは 0/3。skill-creator 自身が SKILL.md に書いている通り「Claude は自力で処理できるタスクでは skill を引かない」傾向が `-p` 単発クエリでは特に強く、対話セッションとトリガー挙動が乖離する。

**含意**: ハーネスを直しても `-p` での測定値は実運用のトリガー率の proxy として弱い。評価クエリを「skill を引かないと解けない複雑さ」に寄せるか、測定方式自体の再設計（例: available_skills を明示注入した判定専用プロンプト）が必要。

## 再現手順

```bash
cd ~/.claude/skills/skill-creator
python3 -m scripts.run_loop \
  --eval-set <20クエリのeval_set.json> \
  --skill-path ~/dotfiles/skills/goal-first \
  --model claude-sonnet-5 --max-iterations 5 --verbose
# → 全イテレーション precision=100% recall=0%（一度もトリガーしない）
```

ログ: /tmp/goal-first-descloop2.log（2026-08-19 時点）

## 影響

- description 最適化ループ全体が無意味な結果を返す（best_description は「最初の候補」がスコア同率で選ばれるだけ）
- goal-first では自動最適化を断念し、生成候補から人手で要素を取り込んで対応した
