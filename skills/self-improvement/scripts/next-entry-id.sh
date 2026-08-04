#!/bin/bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: next-entry-id.sh <LRN|ERR|FEAT> [--date YYYYMMDD] [--dir PATH]

Return the next unique sequential entry ID for a .learnings directory.
The command fails when the directory already contains duplicate entry IDs.
EOF
}

entry_type="${1:-}"
if [ -z "$entry_type" ]; then
    usage >&2
    exit 1
fi
shift

case "$entry_type" in
    LRN|ERR|FEAT) ;;
    *)
        printf 'entry type must be one of: LRN, ERR, FEAT\n' >&2
        exit 1
        ;;
esac

entry_date="$(date +%Y%m%d)"
learnings_dir=".learnings"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --date)
            [ "$#" -ge 2 ] || { printf '%s\n' '--date requires YYYYMMDD' >&2; exit 1; }
            entry_date="$2"
            shift 2
            ;;
        --dir)
            [ "$#" -ge 2 ] || { printf '%s\n' '--dir requires a path' >&2; exit 1; }
            learnings_dir="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'unknown option: %s\n' "$1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if ! [[ "$entry_date" =~ ^[0-9]{8}$ ]]; then
    printf 'date must use YYYYMMDD: %s\n' "$entry_date" >&2
    exit 1
fi

if [ ! -d "$learnings_dir" ]; then
    printf 'learnings directory does not exist: %s\n' "$learnings_dir" >&2
    exit 1
fi

shopt -s nullglob
markdown_files=("$learnings_dir"/*.md)
existing_ids=""
if [ "${#markdown_files[@]}" -gt 0 ]; then
    existing_ids=$(sed -nE 's/^## \[([A-Z]+-[0-9]{8}-[A-Z0-9]{3})\].*/\1/p' "${markdown_files[@]}")
fi

duplicate_ids=$(printf '%s\n' "$existing_ids" | sed '/^$/d' | LC_ALL=C sort | uniq -d)
if [ -n "$duplicate_ids" ]; then
    printf 'duplicate entry IDs found; resolve them before creating another entry:\n%s\n' "$duplicate_ids" >&2
    exit 2
fi

max_sequence=0
while IFS= read -r existing_id; do
    [ -n "$existing_id" ] || continue
    suffix="${existing_id##*-}"
    sequence=$((10#$suffix))
    if [ "$sequence" -gt "$max_sequence" ]; then
        max_sequence="$sequence"
    fi
done < <(printf '%s\n' "$existing_ids" | grep -E "^${entry_type}-${entry_date}-[0-9]{3}$" || true)

if [ "$max_sequence" -ge 999 ]; then
    printf 'no sequential IDs remain for %s-%s\n' "$entry_type" "$entry_date" >&2
    exit 2
fi

printf '%s-%s-%03d\n' "$entry_type" "$entry_date" "$((max_sequence + 1))"
