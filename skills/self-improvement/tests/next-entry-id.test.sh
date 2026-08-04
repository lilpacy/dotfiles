#!/bin/bash

set -euo pipefail

SCRIPT_PATH="$(cd "$(dirname "$0")/.." && pwd)/scripts/next-entry-id.sh"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

assert_equals() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"

    if [ "$actual" != "$expected" ]; then
        printf 'FAIL: %s\nexpected: %s\nactual: %s\n' "$test_name" "$expected" "$actual" >&2
        exit 1
    fi

    printf 'PASS: %s\n' "$test_name"
}

assert_fails_with() {
    local test_name="$1"
    local expected_message="$2"
    shift 2

    local output
    if output=$("$@" 2>&1); then
        printf 'FAIL: %s\ncommand unexpectedly succeeded\n' "$test_name" >&2
        exit 1
    fi

    if [[ "$output" != *"$expected_message"* ]]; then
        printf 'FAIL: %s\nexpected message: %s\nactual: %s\n' "$test_name" "$expected_message" "$output" >&2
        exit 1
    fi

    printf 'PASS: %s\n' "$test_name"
}

random_suffix_dir="$TEST_ROOT/random-suffix"
mkdir -p "$random_suffix_dir"
printf '## [LRN-20260801-A7B] correction\n' > "$random_suffix_dir/LEARNINGS.md"
actual=$("$SCRIPT_PATH" LRN --date 20260801 --dir "$random_suffix_dir")
assert_equals \
    "準正常系: ランダムsuffixだけが存在するとき連番001を返す" \
    "LRN-20260801-001" \
    "$actual"

sequential_dir="$TEST_ROOT/sequential"
mkdir -p "$sequential_dir"
printf '## [LRN-20260801-001] correction\n## [LRN-20260801-003] best_practice\n' > "$sequential_dir/LEARNINGS.md"
actual=$("$SCRIPT_PATH" LRN --date 20260801 --dir "$sequential_dir")
assert_equals \
    "正常系: 同日最大連番の次にあたる一意なIDを返す" \
    "LRN-20260801-004" \
    "$actual"

duplicate_dir="$TEST_ROOT/duplicate"
mkdir -p "$duplicate_dir"
printf '## [LRN-20260801-001] correction\n' > "$duplicate_dir/LEARNINGS.md"
printf '## [LRN-20260801-001] best_practice\n' > "$duplicate_dir/OTHER.md"
assert_fails_with \
    "異常系: 保存領域に重複IDがあるとき新しいIDを発行しない" \
    "duplicate entry IDs" \
    "$SCRIPT_PATH" LRN --date 20260801 --dir "$duplicate_dir"

assert_fails_with \
    "異常系: 未対応のentry typeを指定したとき失敗する" \
    "entry type must be one of" \
    "$SCRIPT_PATH" NOTE --date 20260801 --dir "$sequential_dir"
