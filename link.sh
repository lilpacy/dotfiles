#!/usr/bin/env bash
# links.conf の宣言表を適用して symlink を張る。
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
LINKS_CONF="$DOTFILES/links.conf"

while IFS=$'\t' read -r src dst; do
  [[ -z "$src" || "$src" == \#* || -z "$dst" ]] && continue
  dst="${dst/#\~/$HOME}"
  dst="${dst//\$HOME/$HOME}"
  if [[ ! -e "$DOTFILES/$src" ]]; then
    echo "skip (src が存在しない): $src" >&2
    continue
  fi
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$DOTFILES/$src" "$dst"
done <"$LINKS_CONF"

"$DOTFILES/link-skills.sh"

# git hooks (husky の代替。npm 依存なしで pre-commit を有効化する)
git -C "$DOTFILES" config core.hooksPath githooks

# /usr/local/bin へ置く CLI (sudo 環境や PATH 未設定シェルからも使うもの)
SYSTEM_BIN=(task_cal sssh ecs-sh tmux-dev herdrw herdrp)
if [[ "${SKIP_SUDO_LINKS:-0}" != "1" ]]; then
  sudo mkdir -p /usr/local/bin
  for name in "${SYSTEM_BIN[@]}"; do
    sudo ln -sf "$DOTFILES/bin/$name" "/usr/local/bin/$name"
  done
  for obsolete in herdr-layout-dev herdr-layout-dev-wide; do
    target="/usr/local/bin/$obsolete"
    if [[ -L "$target" && "$(readlink "$target")" == "$HOME/dotfiles/bin/$obsolete" ]]; then
      sudo rm -f "$target"
    fi
  done
fi

# bin 直下のスクリプトのみ実行可能にする (bin/src のソースは対象外)
find "$DOTFILES/bin" -maxdepth 1 -type f -print0 | xargs -0 chmod 755
