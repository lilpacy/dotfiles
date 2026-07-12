#!/usr/bin/env bash
# 共通 skills/ の各 skill を、エージェントごとの skills/ へ symlink する。
# どの skill をどのエージェントへ張るかは下のリストで制御する。
# 新規プロジェクト/環境ではこのスクリプトを実行すれば同じ振り分けを再現できる。
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
COMMON="$DOTFILES/skills"

# --- Claude から参照させる skill --------------------------------------------
CLAUDE_SKILLS=(
  agent-browser
  animation-vocabulary
  apple-design
  claude-fable-review
  codex-exec-review
  codex-spark-delegation
  cursor-composer-delegation
  development-workflow
  emil-design-eng
  frontend-design
  git-commit-workflow
  gof-functional-patterns
  improve-animations
  japanese-test-conventions
  linear-cli
  playwright-interactive
  review-animations
  self-improvement
  view-x-post
  web-doc-reading
)

# --- Codex から参照させる skill ---------------------------------------------
CODEX_SKILLS=(
  codex-exec-review
  codex-spark-delegation
  cursor-composer-delegation
  development-workflow
  frontend-design
  git-commit-workflow
  japanese-test-conventions
  linear-cli
  playwright-interactive
  self-improvement
  view-x-post
  web-doc-reading
)

# link_skills <target_dir> <skill名...>
# target_dir/<name> -> ../../skills/<name> を張る。
# 実体ディレクトリ(symlink でない)が既にある場合は上書きせずスキップ。
link_skills() {
  local target_dir="$1"; shift
  mkdir -p "$target_dir"
  local name src dst
  for name in "$@"; do
    src="$COMMON/$name"
    dst="$target_dir/$name"
    if [ ! -d "$src" ]; then
      echo "skip (共通skillが存在しない): $name" >&2
      continue
    fi
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
      echo "skip (実体が存在するため上書きしない): $dst" >&2
      continue
    fi
    ln -sfn "../../skills/$name" "$dst"
    echo "linked: $dst -> ../../skills/$name"
  done
}

link_skills "$DOTFILES/claude/skills" "${CLAUDE_SKILLS[@]}"
link_skills "$DOTFILES/codex/skills" "${CODEX_SKILLS[@]}"
