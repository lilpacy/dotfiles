#!/usr/bin/env bash
# Driver registry — axis-generic discovery + trust policy.
#
# agmsg's pluggable units are "drivers" grouped by axis (ADR 0001 / docs/spec/
# driver-interface.md). The agent-type registry (type-registry.sh) is the first
# consumer (axis = "types"); storage and delivery axes reuse the same machinery.
#
# This lib knows NOTHING about a given axis's internal layout (types use a
# directory with type.conf; another axis may differ). It only provides:
#   - the ordered search BASES   (in-tree built-ins, then external plugin dirs)
#   - the TRUST policy           (which external drivers the user opted into)
# Each axis facade enumerates `<base>/<axis>/...` itself and gates externals with
# agmsg_driver_is_trusted.
#
# Search bases, in priority order (later overrides earlier among ELIGIBLE ones):
#   1. <root>/scripts/drivers          in-tree built-ins — always trusted
#   2. <root>/plugins                  default external plugin dir (install_dir/plugins)
#   3. each dir in $AGMSG_PLUGIN_DIRS   ':'-separated extra external dirs
#
# SECURITY: external drivers are shell code that runs with the user's privileges.
# They are NEVER loaded unless explicitly opted into (`agmsg plugin trust`), so an
# unexpected drop-in cannot execute. An untrusted external driver that is present
# is ignored (a built-in of the same name still resolves); callers may warn.
#
# Safe under `set -u`: every env read is guarded.

# Resolve THIS lib's dir at source time (robust to later subshell/relative cwd).
_AGMSG_DRIVER_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"

# <skill-root> = up two from scripts/lib/.
_agmsg_driver_root() {
  cd "$_AGMSG_DRIVER_LIB_DIR/../.." 2>/dev/null && pwd
}

# Echo the search bases as "<kind>\t<dir>" lines, in priority order. <kind> is
# "builtin" (in-tree, always trusted) or "external" (requires opt-in).
agmsg_driver_bases() {
  local root
  root="$(_agmsg_driver_root)" || return 0
  [ -n "$root" ] || return 0
  printf 'builtin\t%s\n' "$root/scripts/drivers"
  printf 'external\t%s\n' "$root/plugins"
  # AGMSG_PLUGIN_DIRS: ':'-separated extra external bases (override last).
  local IFS=: d
  for d in ${AGMSG_PLUGIN_DIRS:-}; do
    [ -n "$d" ] && printf 'external\t%s\n' "$d"
  done
}

# Path to the opt-in allowlist. One trusted driver per line: "<axis>/<name>\t<abs-path>".
# Lives under db/ (preserved across --update installs, like config.yaml). A plain
# TSV — not config.yaml — because driver identities contain '/' which the YAML
# key parser does not handle, and append/grep/remove are trivial here.
agmsg_driver_trustfile() {
  local root
  root="$(_agmsg_driver_root)" || return 1
  printf '%s\n' "$root/db/trusted-plugins"
}

# 0 if the external driver <axis>/<name> at <path> was opted into (exact path
# match — a trusted name pointing elsewhere is NOT honored, so swapping the dir
# under a trusted name does not silently activate new code).
agmsg_driver_is_trusted() {
  local axis="$1" name="$2" path="$3" tf
  tf="$(agmsg_driver_trustfile)" || return 1
  [ -f "$tf" ] || return 1
  grep -qxF "$(printf '%s/%s\t%s' "$axis" "$name" "$path")" "$tf"
}

# Record an opt-in for <axis>/<name> at <path>. Idempotent.
agmsg_driver_trust() {
  local axis="$1" name="$2" path="$3" tf line
  tf="$(agmsg_driver_trustfile)" || return 1
  mkdir -p "$(dirname "$tf")"
  line="$(printf '%s/%s\t%s' "$axis" "$name" "$path")"
  [ -f "$tf" ] && grep -qxF "$line" "$tf" && return 0
  printf '%s\n' "$line" >> "$tf"
}

# Remove every opt-in for <axis>/<name> (any path).
agmsg_driver_untrust() {
  local axis="$1" name="$2" tf tmp
  tf="$(agmsg_driver_trustfile)" || return 1
  [ -f "$tf" ] || return 0
  tmp="$(mktemp "${TMPDIR:-/tmp}/agmsg-trust.XXXXXX")"
  grep -vE "^$(printf '%s/%s' "$axis" "$name" | sed 's/[][\.*^$/]/\\&/g')	" "$tf" > "$tmp" 2>/dev/null || true
  mv "$tmp" "$tf"
}
