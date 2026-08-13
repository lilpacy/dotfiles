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
  agents-md
  animation-vocabulary
  apple-design
  baseline-ui
  claude-fable-review
  codex-exec-review
  codex-spark-delegation
  credential-redaction
  cursor-composer-delegation
  development-workflow
  emil-design-eng
  find-skills
  frontend-design
  git-commit-workflow
  github-review
  gof-functional-patterns
  hallmark
  improve-animations
  japanese-test-conventions
  linear-bulk-issue-triage
  linear-cli
  linear-work-planning
  obsidian-cli
  playwright-cli
  playwright-interactive
  review-animations
  self-improvement
  shell-quoting-pitfalls
  skill-visibility-management
  structured-answer
  view-x-post
  web-doc-reading
)

# --- Codex から参照させる skill ---------------------------------------------
CODEX_SKILLS=(
  codex-exec-review
  codex-spark-delegation
  credential-redaction
  cursor-composer-delegation
  development-workflow
  frontend-design
  git-commit-workflow
  github-review
  japanese-test-conventions
  linear-bulk-issue-triage
  linear-cli
  linear-work-planning
  obsidian-cli
  playwright-interactive
  self-improvement
  shell-quoting-pitfalls
  skill-visibility-management
  structured-answer
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

# audit_skills <target_dir> <skill名...>
# 宣言リストと実 symlink の差分を報告する。差分があれば exit 1。
audit_skills() {
  local target_dir="$1"; shift
  local drift=0 name dst
  declare -A declared=()
  for name in "$@"; do
    declared["$name"]=1
    dst="$target_dir/$name"
    if [ ! -L "$dst" ]; then
      echo "drift (宣言済みだが symlink がない): $dst" >&2
      drift=1
    elif [ ! -f "$dst/SKILL.md" ]; then
      echo "drift (symlink が SKILL.md へ解決しない): $dst" >&2
      drift=1
    fi
  done
  for dst in "$target_dir"/*; do
    [ -L "$dst" ] || continue
    name="$(basename "$dst")"
    if [ -z "${declared[$name]:-}" ]; then
      echo "drift (宣言リストにない symlink): $dst" >&2
      drift=1
    fi
  done
  return "$drift"
}

if [ "${1:-}" = "--audit" ]; then
  status=0
  audit_skills "$DOTFILES/claude/skills" "${CLAUDE_SKILLS[@]}" || status=1
  audit_skills "$DOTFILES/codex/skills" "${CODEX_SKILLS[@]}" || status=1
  [ "$status" = 0 ] && echo "audit OK: 宣言と実 symlink は一致"
  exit "$status"
fi

link_skills "$DOTFILES/claude/skills" "${CLAUDE_SKILLS[@]}"
link_skills "$DOTFILES/codex/skills" "${CODEX_SKILLS[@]}"
