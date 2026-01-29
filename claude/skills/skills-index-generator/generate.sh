#!/bin/zsh
# Skills Index Generator
# Usage: ./generate.sh [skills_dir] [root_path]

SKILLS_DIR="${1:-$HOME/.claude/skills}"
ROOT_PATH="${2:-~/.claude/skills}"

# Expand ~ for actual directory access
EXPANDED_DIR="${SKILLS_DIR/#\~/$HOME}"

if [[ ! -d "$EXPANDED_DIR" ]]; then
    echo "Error: Directory not found: $SKILLS_DIR" >&2
    exit 1
fi

# Start building index
INDEX="<!--SKILLS-INDEX-->|[Skills Index]|root:$ROOT_PATH|IMPORTANT:Prefer retrieval-led reasoning over pre-training|If index stale run: ~/.claude/skills/skills-index-generator/generate.sh"

# Get skill directories sorted
for skill_dir in "$EXPANDED_DIR"/*(N/on); do
    skill_name="${skill_dir:t}"

    # Skip if no SKILL.md
    [[ ! -f "$skill_dir/SKILL.md" ]] && continue

    files=("SKILL.md")

    # Check for AGENTS.md
    [[ -f "$skill_dir/AGENTS.md" ]] && files+=("AGENTS.md")

    # Check for reference.md
    [[ -f "$skill_dir/reference.md" ]] && files+=("reference.md")

    # Check for examples.md
    [[ -f "$skill_dir/examples.md" ]] && files+=("examples.md")

    # Process rules/ directory with pattern compression
    if [[ -d "$skill_dir/rules" ]]; then
        typeset -A prefix_counts
        prefix_counts=()

        for rule_file in "$skill_dir/rules"/*.md(N); do
            [[ -f "$rule_file" ]] || continue
            filename="${rule_file:t:r}"  # basename without extension
            # Extract prefix (before first dash)
            if [[ "$filename" == *-* ]]; then
                prefix="${filename%%-*}"
                prefix_counts[$prefix]=$(( ${prefix_counts[$prefix]:-0} + 1 ))
            else
                files+=("rules/$filename.md")
            fi
        done

        # Add compressed patterns (sorted)
        for prefix in ${(ok)prefix_counts}; do
            count=${prefix_counts[$prefix]}
            if (( count >= 2 )); then
                files+=("rules/$prefix-*.md")
            else
                # Find the single file with this prefix
                for rule_file in "$skill_dir/rules/$prefix"-*.md(N); do
                    [[ -f "$rule_file" ]] && files+=("rules/${rule_file:t}")
                    break
                done
            fi
        done
    fi

    # Check for templates/
    [[ -d "$skill_dir/templates" ]] && files+=("templates/*")

    # Build file list
    file_list="${(j:,:)files}"
    INDEX="$INDEX|$skill_name:{$file_list}"
done

INDEX="$INDEX<!--END-->"

echo "$INDEX"
