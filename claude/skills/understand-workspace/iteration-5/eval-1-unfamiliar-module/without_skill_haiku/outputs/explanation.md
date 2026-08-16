# Pi Synthesis Candidates Script - Walkthrough

## Overview
This Ruby script builds and manages a **candidate catalog** for "Pi Synthesis" — likely a process that synthesizes (combines/generates) new knowledge concepts from accumulated delta files in your Obsidian vault. The script provides two main commands: `catalog` and `merge`.

## Architecture: Two Classes

### 1. `PiSynthesisCandidateCatalog`
**Purpose:** Generates a markdown file listing all delta files and their concept impact hints, with a size budget constraint.

**Key members:**
- `MAX_TOTAL_BYTES = 160_000`: Hard limit on the final output size (~160 KB)
- `@vault_dir`: Points to `lilpacy/` directory in your repo
- `@new_delta_paths`: Set of newly added/changed delta files (validated against path rules)

**Main method: `build(output_path)`**
1. Scans all `.md` files in `lilpacy/deltas/`
2. For each delta file:
   - Extracts YAML frontmatter (metadata)
   - Reads the "## Concept impact hints" section (if present)
   - Builds markdown output with links to `source` and `summary` references
   - Marks newly added deltas with `[new]` tag
3. Validates that total output doesn't exceed 160 KB budget
4. Writes to `output_path`

**Key validation:**
- Delta paths must start with `lilpacy/deltas/` and end with `.md`
- No path traversal (`..`) allowed
- File must actually exist on disk

**Example output structure:**
```
## lilpacy/deltas/some-file.md [new]

source: [[source-name]]
summary: [[summary-name]]
- hint 1
- hint 2
```

---

### 2. `PiSynthesisCandidateSelection`
**Purpose:** Merges newly discovered deltas with previously selected deltas from an external selection JSON, outputting a null-separated list.

**Main method: `merge(selection_path, output_path)`**
1. Reads a JSON file from `selection_path` containing previously selected delta paths
2. Validates JSON schema: must have `schema_version: 1` and `selected_delta_paths: Array`
3. Combines new delta paths with previously selected ones
4. Removes duplicates
5. Writes to `output_path` as a **null-separated binary list**: `path1\0path2\0path3\0`

**Why null-separated?** This is a low-level format that avoids line-ending ambiguity and allows shell tools like `tr '\0' '\n'` to process it safely.

---

## Command-Line Usage

### `catalog` command
```bash
ruby pi_synthesis_candidates.rb catalog REPO_ROOT OUTPUT_PATH NEW_DELTA_PATH...
```
- Builds a browseable catalog of all deltas with concept hints
- At least one new delta path required
- Fails if output exceeds 160 KB

**Example:**
```bash
ruby pi_synthesis_candidates.rb catalog . /tmp/catalog.md lilpacy/deltas/new1.md lilpacy/deltas/new2.md
```

### `merge` command
```bash
ruby pi_synthesis_candidates.rb merge REPO_ROOT SELECTION_JSON OUTPUT_ZLIST NEW_DELTA_PATH...
```
- Reads prior selections from JSON
- Adds new deltas
- Outputs null-separated binary list

**Example:**
```bash
ruby pi_synthesis_candidates.rb merge . selection.json /tmp/merged.zlist lilpacy/deltas/new1.md
```

---

## Key Implementation Details

### Frontmatter Parsing (`frontmatter` method)
- Reads YAML between `---` markers at file start
- Allows `Date` class only (security: no arbitrary class instantiation)
- Raises clear errors if malformed

### Concept Hints Extraction (`concept_hints` method)
- Finds "## Concept impact hints" heading
- Collects all bullet points (`- `) until next heading
- Filters out entries that say `"none"`
- Returns empty list if section doesn't exist

### Link Extraction (`required_link` method)
- Uses regex to find `[[link-text]]` patterns
- Supports pipe syntax: `[[full-name|display-name]]` → extracts `full-name`
- Raises error if field (e.g., "source", "summary") has no link

---

## Why This Exists

This script implements a **delta selection pipeline**:
1. You create new delta files (likely ingested knowledge artifacts)
2. Script catalogs them with concept hints (a brief non-deterministic summary of what concepts might be affected)
3. Someone (human or another tool) reviews the catalog and selects which deltas to synthesize
4. The `merge` command combines those selections with any new deltas for the next synthesis round

The size budget (160 KB) keeps the catalog reviewable — it won't balloon into an unwieldy document.

---

## Safety & Constraints

- **Path validation:** All delta paths are strictly validated; no symlinks or traversal
- **YAML parsing:** Safe loading only; no arbitrary code execution
- **Budget enforcement:** Output size must fit within 160 KB
- **Required metadata:** Every delta must have `source` and `summary` links; script fails loudly if missing
