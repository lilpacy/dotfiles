# Understanding pi_synthesis_candidates.rb

## Background

This script is part of the **LLM Wiki** workflow described in your AGENTS.md. Recall the three-layer architecture: raw sources (external documents), the wiki (Markdown files maintained by LLMs), and the schema (rules for how LLMs operate).

In the context of this repository, **Deltas** are a special kind of wiki page: they capture what happened when an LLM ingested a new raw source. Each Delta is a Markdown file in `lilpacy/deltas/` with frontmatter (metadata like `source:` and `summary:` links) and body content including a section called "Concept impact hints" — a bulleted list of concepts from your knowledge base that the new information touches or updates.

The problem this script solves: when you ingest new Deltas, you need to **synthesize** them — combine the new knowledge with existing concepts to produce updated concept pages (the "Pi" synthesis stage). But synthesizing *all* Deltas at once is too expensive (token budget). Instead, you want to (1) catalog which Deltas are candidates, (2) have an agent or human select a subset, and (3) combine that selection with new Deltas for synthesis.

This script bridges steps 1 and 3 of that workflow.

---

## Intuition

Think of it as a **two-stage sieve**:

```
Stage 1: Catalog        Stage 2: Merge & Output
┌──────────────────┐    ┌───────────────────┐
│ All Deltas       │    │ Selected set      │
│ (lots of them)   │    │ + new Deltas      │
│ → extract hints  │───→│ → deduplicate     │
│ → under 160KB    │    │ → output list     │
└──────────────────┘    └───────────────────┘
       (Catalog)              (Merge)
```

**Catalog** (first class) does the heavy lifting. It:
- Reads every Delta file in the vault
- Extracts metadata (which raw source, which summary page) and the "Concept impact hints" section
- Builds a readable Markdown file that lists all Deltas with their hints (a reference catalog)
- Stays under a 160KB budget (prevents the catalog itself from bloating)
- Marks newly ingested Deltas with `[new]` to highlight recent work

**Merge** (second class) takes that work forward. It:
- Reads a JSON file with a list of "selected" Delta paths (chosen by you or an agent)
- Combines the new Deltas (those just ingested) with the selected older ones
- Deduplicates the list
- Outputs them as a null-separated binary list (compact, shell-friendly format for piping to other tools)

Why two separate operations? The catalog is human-readable and meant for *viewing/deciding*. The merge output is machine-readable and meant for *acting on* (feeding to the next synthesis stage).

---

## Code

### PiSynthesisCandidateCatalog

```ruby
class PiSynthesisCandidateCatalog
  MAX_TOTAL_BYTES = 160_000

  def initialize(repo_root, new_delta_paths:, max_total_bytes: MAX_TOTAL_BYTES)
    @repo_root = Pathname(repo_root)
    @vault_dir = @repo_root.join("lilpacy")
    @new_delta_paths = new_delta_paths.map { |path| validate_delta_path(path) }.to_set
    @max_total_bytes = max_total_bytes
    raise ArgumentError, "at least one new Delta path is required" if @new_delta_paths.empty?
  end
```

On init, the catalog sets up paths and validates inputs. `@new_delta_paths` becomes a Set for fast lookups (to decide which ones get the `[new]` marker).

```ruby
  def build(output_path)
    lines = [
      "# Pi Concept Candidate Catalog",
      "",
      "This catalog contains only Delta metadata and non-deterministic Concept impact hints.",
      "Raw Source and query transcript contents are intentionally excluded.",
      ""
    ]
```

It starts with a header explaining what this file is and what it *doesn't* contain (a privacy/size hint: raw content is excluded).

```ruby
    @vault_dir.glob("deltas/*.md").sort.each do |path|
      relative = path.relative_path_from(@repo_root).to_s
      hints = concept_hints(path)
      next if hints.empty?

      metadata = frontmatter(path)
      marker = @new_delta_paths.include?(relative) ? " [new]" : ""
      lines.concat([
        "## #{relative}#{marker}",
        "",
        "source: [[#{required_link(metadata, "source", path)}]]",
        "summary: [[#{required_link(metadata, "summary", path)}]]",
        *hints.map { |hint| "- #{hint}" },
        ""
      ])
    end
```

For each Delta file:
1. Extract the "Concept impact hints" section via `concept_hints()`
2. Skip if there are no hints (empty synthesis targets = no value to list)
3. Parse frontmatter YAML to get `source` and `summary` metadata
4. Extract the wiki link from each metadata field (they are expected to be in `[[link]]` format)
5. Build a section with the Delta's path, whether it's new, its source and summary links, and the hints

```ruby
    content = "#{lines.join("\n")}\n"
    raise ArgumentError, "candidate catalog budget exceeded: #{content.bytesize} > #{@max_total_bytes}" if content.bytesize > @max_total_bytes

    Pathname(output_path).write(content)
  end
```

Finally, enforce the 160KB budget and write the output. This is a hard constraint: if the catalog is too large, the operation fails rather than silently truncating or producing an oversized file.

#### Helper methods:

```ruby
  def validate_delta_path(value)
    path = Pathname(String(value)).cleanpath.to_s
    unless path.start_with?("lilpacy/deltas/") && path.end_with?(".md") && !path.include?("..") && @repo_root.join(path).file?
      raise ArgumentError, "invalid Delta path: #{value}"
    end
    path
  end
```

Validates that a path is safe (no `..`, lives in `lilpacy/deltas/`, ends in `.md`, exists as a file). Prevents injection attacks and misconfigured paths.

```ruby
  def frontmatter(path)
    lines = path.readlines(chomp: true)
    raise ArgumentError, "missing Delta frontmatter: #{path}" unless lines.first == "---"
    closing = lines[1..]&.index("---")
    raise ArgumentError, "missing Delta frontmatter close: #{path}" unless closing
    YAML.safe_load(lines[1..closing].join("\n"), permitted_classes: [Date], aliases: false) || {}
  rescue Psych::SyntaxError => e
    raise ArgumentError, "malformed Delta frontmatter: #{path}: #{e.message}"
  end
```

Reads YAML frontmatter sandwiched between `---` delimiters. Allows only Date objects (safe), rejects aliases (prevents arbitrary object instantiation). If parsing fails, reports the specific syntax error.

```ruby
  def required_link(metadata, field, path)
    link = metadata[field].to_s[/\[\[([^\]]+)\]\]/, 1]&.split("|", 2)&.first
    raise ArgumentError, "Delta #{field} link is missing: #{path}" unless link
    link
  end
```

Extracts a wiki link from a metadata field. Expected format: `"source: [[raw-source.md|Display Name]]"` → extracts `"raw-source.md"`. Handles the pipe syntax (display name after `|`) by taking only the first part.

```ruby
  def concept_hints(path)
    lines = path.readlines(chomp: true)
    heading = lines.index("## Concept impact hints")
    return [] unless heading

    lines[(heading + 1)..]
      .take_while { |line| !line.start_with?("## ") }
      .map { |line| line.delete_prefix("- ").strip if line.start_with?("- ") }
      .compact
      .reject { |hint| hint == "none" }
  end
```

Finds the "## Concept impact hints" section, reads all bullet points until the next `##` heading, strips the `- ` prefix, and filters out empty lines and the special value "none" (used to mean "no hints").

---

### PiSynthesisCandidateSelection

```ruby
class PiSynthesisCandidateSelection
  def initialize(repo_root, new_delta_paths:)
    @repo_root = Pathname(repo_root)
    @new_delta_paths = new_delta_paths.map { |path| validate_delta_path(path) }
    raise ArgumentError, "at least one new Delta path is required" if @new_delta_paths.empty?
  end
```

Similar setup to the catalog: validates new Deltas and stores the repo root.

```ruby
  def merge(selection_path, output_path)
    selection = JSON.parse(Pathname(selection_path).read)
    raise ArgumentError, "schema_version must be integer 1" unless selection.fetch("schema_version", nil) == 1

    selected = selection.fetch("selected_delta_paths", nil)
    raise ArgumentError, "selected_delta_paths must be an array" unless selected.is_a?(Array)

    paths = (@new_delta_paths + selected.map { |path| validate_delta_path(path) }).uniq
    Pathname(output_path).binwrite("#{paths.join("\0")}\0")
  rescue JSON::ParserError => e
    raise ArgumentError, "malformed candidate selection JSON: #{e.message}"
  end
```

1. Read a JSON file (expected to have `schema_version: 1` and `selected_delta_paths: [...]`)
2. Combine new Deltas with selected older ones
3. Deduplicate using `.uniq`
4. Output as null-separated strings (one path per null-terminated chunk): `path1\0path2\0path3\0`

This format is shell-friendly: you can pipe it to `xargs -0` to process each path.

---

### CLI Entry Point

```ruby
if $PROGRAM_NAME == __FILE__
  command = ARGV.shift
  repo_root = ARGV.shift

  case command
  when "catalog"
    output_path = ARGV.shift
    abort "usage: #{$PROGRAM_NAME} catalog REPO_ROOT OUTPUT_PATH NEW_DELTA_PATH..." unless repo_root && output_path && !ARGV.empty?
    PiSynthesisCandidateCatalog.new(repo_root, new_delta_paths: ARGV).build(output_path)
  when "merge"
    selection_path = ARGV.shift
    output_path = ARGV.shift
    abort "usage: #{$PROGRAM_NAME} merge REPO_ROOT SELECTION_JSON OUTPUT_ZLIST NEW_DELTA_PATH..." unless repo_root && selection_path && output_path && !ARGV.empty?
    PiSynthesisCandidateSelection.new(repo_root, new_delta_paths: ARGV).merge(selection_path, output_path)
  else
    abort "usage: #{$PROGRAM_NAME} catalog|merge ..."
  end
end
```

Two commands:
- `catalog REPO_ROOT OUTPUT_PATH NEW_DELTA_PATH...` → generate readable catalog
- `merge REPO_ROOT SELECTION_JSON OUTPUT_ZLIST NEW_DELTA_PATH...` → merge selected Deltas and output null-list

---

## Quiz

Answer these to check your intuition:

**Q1:** Why does the catalog skip Deltas that have no "Concept impact hints"?

A) They're corrupted files  
B) They don't contribute new concepts to synthesize  
C) They're too large to include  
D) They're older than 30 days  

**Q2:** What is the purpose of the `[new]` marker in the catalog output?

A) To indicate which Deltas need to be archived  
B) To highlight Deltas that were just ingested, so an agent or human can decide if they should be included in the next synthesis run  
C) To sort Deltas by recency  
D) To mark Deltas that failed validation  

**Q3:** Why does the merge output use null-separated strings (`\0`) instead of newlines?

A) To save space  
B) To make it shell-safe (handles file names with spaces or newlines) when piped to `xargs -0`  
C) To encrypt the paths  
D) To make it unreadable to humans on purpose  

**Q4:** In the `required_link()` method, what does the regex `\[\[([^\]]+)\]\]` do?

A) It matches any wiki link and extracts the text inside the brackets  
B) It ensures the link is valid by checking for escaped brackets  
C) It removes markdown formatting  
D) It validates that the link points to an existing file  

**When you're ready, share your answers, or let me know if a particular section didn't land clearly.**
