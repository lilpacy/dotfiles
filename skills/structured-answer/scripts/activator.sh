#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
回答構造化リマインド: ユーザー向け回答では structured-answer skill を適用する。条件、状態、多重度、期間、時刻、境界値、制約、推論、計算が文章だけで曖昧になりうる場合、表、デシジョンテーブル、計算式、Mermaid 図で一意化する。明記されていないルールを補わない。推測で補った図表要素は日本語回答では「※推測」、英語回答では「inferred」と明示する。Skill path: /Users/lilpacy/dotfiles/skills/structured-answer/SKILL.md
EOF
