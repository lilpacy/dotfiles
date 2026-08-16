# Understanding pi_synthesis_candidates.rb

## Background

This vault (`lilpacy/`) uses a **Delta** system to track incremental knowledge changes. Deltas are Markdown files stored in `lilpacy/deltas/` that document when new information is ingested. Each Delta has:
- YAML frontmatter with metadata (source, summary links)
- A "Concept impact hints" section listing which concepts this knowledge affects

The script coordinates a two-stage process: **catalog building** and **selection merging**. It's part of a workflow that identifies which Deltas should be synthesized into higher-level "Pi Concepts" (synthesis targets).

## Intuition

The script implements a human-in-the-loop workflow for knowledge synthesis:

```
New Delta files arrive
    ↓
[Catalog] Extract metadata + hints → Bundle into browsable list
    ↓
[Human review] Decide which Deltas to synthesize
    ↓
[Merge] Combine new Deltas + previously selected ones → Output as null-separated list
```

The **catalog** is a read-only index: it shows what's new and hints about impact without including the full Delta content (too large to include everything). The **merge** is a persistence layer: it combines new Deltas with a JSON selection file to build a deterministic list for downstream synthesis.

## Code Walkthrough

### Class 1: PiSynthesisCandidateCatalog

**Initialization:**
```ruby
def initialize(repo_root, new_delta_paths:, max_total_bytes: MAX_TOTAL_BYTES)
  @new_delta_paths = new_delta_paths.map { |path| validate_delta_path(path) }.to_set
  @max_total_bytes = max_total_bytes  # 160KB budget
```

Validates input paths and stores new Delta paths as a Set for fast lookups (used later to mark which items are newly added).

**Build Method - Main Logic:**
```ruby
def build(output_path)
  lines = [header...]
  @vault_dir.glob("deltas/*.md").sort.each do |path|
    relative = path.relative_path_from(@repo_root).to_s
    hints = concept_hints(path)
    next if hints.empty?
    
    metadata = frontmatter(path)
    marker = @new_delta_paths.include?(relative) ? " [new]" : ""
```

Iterates through **all** Delta files (sorted), extracts frontmatter + concept hints. Marks newly added ones with `[new]`. Skips any Delta with no concept hints (doesn't impact synthesis).

```ruby
    lines.concat([
      "## #{relative}#{marker}",
      "source: [[#{required_link(metadata, "source", path)}]]",
      "summary: [[#{required_link(metadata, "summary", path)}]]",
      *hints.map { |hint| "- #{hint}" },
      ""
    ])
  end
  content = "#{lines.join("\n")}\n"
  raise ArgumentError, "catalog budget exceeded..." if content.bytesize > @max_total_bytes
  Pathname(output_path).write(content)
```

Builds Markdown with backlinks to source and summary, lists concept impact hints, and enforces the 160KB size limit (prevents the catalog from growing unbounded).

**Helper: concept_hints**
```ruby
def concept_hints(path)
  heading = lines.index("## Concept impact hints")
  return [] unless heading
  
  lines[(heading + 1)..]
    .take_while { |line| !line.start_with?("## ") }
    .map { |line| line.delete_prefix("- ").strip if line.start_with?("- ") }
    .compact
    .reject { |hint| hint == "none" }
```

Extracts the "Concept impact hints" section from a Delta file, stopping at the next heading. Strips list markers, filters out "none" entries, and returns remaining hints.

### Class 2: PiSynthesisCandidateSelection

**Merge Method:**
```ruby
def merge(selection_path, output_path)
  selection = JSON.parse(Pathname(selection_path).read)
  raise ArgumentError, "schema_version must be integer 1" unless selection.fetch("schema_version", nil) == 1
  
  selected = selection.fetch("selected_delta_paths", nil)
  raise ArgumentError, "selected_delta_paths must be an array" unless selected.is_a?(Array)
```

Reads and validates the JSON selection file (must have schema_version 1 and a selected_delta_paths array).

```ruby
  paths = (@new_delta_paths + selected.map { |path| validate_delta_path(path) }).uniq
  Pathname(output_path).binwrite("#{paths.join("\0")}\0")
```

Merges newly arriving Deltas with previously chosen ones, deduplicates, and writes them as **null-separated binary** format. This binary format is efficient for downstream tools to parse paths without worrying about special characters.

### CLI Entry Point

```ruby
case command
when "catalog"
  PiSynthesisCandidateCatalog.new(repo_root, new_delta_paths: ARGV).build(output_path)
when "merge"
  PiSynthesisCandidateSelection.new(repo_root, new_delta_paths: ARGV).merge(selection_path, output_path)
```

Two commands:
- `catalog REPO_ROOT OUTPUT_PATH NEW_DELTA_PATH...` — Generate browsable catalog
- `merge REPO_ROOT SELECTION_JSON OUTPUT_ZLIST NEW_DELTA_PATH...` — Finalize synthesis targets by merging human selections with new Deltas

## Quiz

**Q1: What happens if a Delta has the "## Concept impact hints" section but it's empty or only says "none"?**
- A) It's included in the catalog anyway
- B) It's excluded from the catalog
- C) It causes an error

**Q2: Why does the script use `@new_delta_paths` as a Set instead of an Array?**
- A) To keep lines of code down
- B) For O(1) inclusion checks when marking Deltas as `[new]`
- C) To sort Deltas in the output

**Q3: The `merge` command writes output as null-separated binary. Why null bytes instead of newlines?**
- A) It's faster to parse
- B) File paths can contain newlines; null is a safer delimiter
- C) It reduces file size

Please respond with your answers (A/B/C for each question). If any don't click, I can walk through that concept with a concrete example.
