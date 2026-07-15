#!/usr/bin/env bash
# opencode delivery plug — markdown rule-file. Only turn|off reach this function:
# opencode's manifest declares delivery_modes=turn off, so delivery.sh's central
# gate rejects monitor/both before apply runs. Uses resolve_hooks_file + SKILL_DIR
# from delivery.sh's sourced context.
agmsg_delivery_apply() {
  local type="$1"
  local project="$2"
  local mode="$3"
  local rule_file
  rule_file=$(resolve_hooks_file "$type" "$project")

  rm -f "$rule_file"

  if [ "$mode" = "turn" ]; then
    mkdir -p "$(dirname "$rule_file")"
    cat <<EOF > "$rule_file"
# agmsg Integration Rule

## PostToolUse
After each tool call, automatically check the agmsg inbox for unread messages.
- Command: '$SKILL_DIR/scripts/check-inbox.sh' '$type' '$project'
EOF
  fi
}
agmsg_delivery_status() { rulefile_status "$@"; }
