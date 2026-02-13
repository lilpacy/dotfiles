#!/usr/bin/env bash
set -euo pipefail

slug="${1:-}"
if [[ -z "$slug" ]]; then
  echo "Usage: ./scripts/new_project.sh <project_slug>"
  exit 1
fi

root="plots/${slug}"
mkdir -p "${root}/views" "${root}/sources" "${root}/snapshots"

if [[ ! -f "${root}/plot.yml" ]]; then
  cat > "${root}/plot.yml" <<'YAML'
project:
  slug: TBD
  format: series
  genre_tags: []
  north_star:
    logline: TBD
    end_state_paragraph: TBD
YAML
fi

touch "${root}/notes.md"
touch "${root}/decisions.md"
touch "${root}/intake.yml"
touch "${root}/views/long_term.md"
touch "${root}/views/mid_term.md"
touch "${root}/views/short_term.md"

echo "Created: ${root}"
