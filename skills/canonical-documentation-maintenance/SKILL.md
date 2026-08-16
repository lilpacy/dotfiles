---
name: canonical-documentation-maintenance
description: Maintain product, architecture, design, API, data, and operational documentation in an established repository. Use when deciding whether to edit an existing source of truth or add a document, separating current-state contracts from implementation plans, keeping volatile repository facts and technical debt out of reusable agent skills, moving content out of change-named documents, or reviewing documentation scope and placement.
---

# Canonical Documentation Maintenance

Keep durable documentation organized around stable product and system responsibilities. Canonical documents describe what is true now. Change sequences, rollout steps, PR narratives, and temporary coordination belong in the repository's planning mechanism.

## Core contract

- Write canonical documentation declaratively: describe the current behavior, ownership, constraints, state, data, and interfaces.
- Keep procedural material in `plan-logs/`, implementation plans, migrations, runbooks, or another repository-designated procedural location.
- Prefer editing the existing source of truth over adding a document named after an issue, PR, redesign, improvement, migration, or temporary initiative.
- Create a new canonical document only for a stable responsibility that has no suitable owner in the current documentation taxonomy.
- Do not use a shared trigger or user journey as proof that every downstream screen or subsystem belongs to the same change scope.

## Read before writing

Inspect the repository's documentation contract before choosing a path:

1. Read `AGENTS.md` and `CLAUDE.md` when present.
2. Read the documentation index, README, authoring rules, and the nearest section index.
3. Search for existing definitions of every affected concept, state, field, screen, API, database object, and interaction.
4. Identify the current owner for each contract. Do not infer ownership from filenames alone; follow index links and cross-references.
5. Check whether the repository intentionally requires mirrored agent instructions or other paired navigation updates.

## Placement decision

| Content | Destination |
|---|---|
| Current user-visible behavior and acceptance contract | Existing requirement or screen specification |
| Current state, data, API, persistence, or ownership contract | Existing architecture or detailed-design source of truth |
| Interaction lifecycle or component boundary | Existing interaction/component design document |
| Durable architectural choice and its rationale | ADR, preserving decision history |
| Ordered implementation, rollout, migration, or verification steps | `plan-logs/` or repository-designated plan/runbook |
| PR status, issue history, temporary checklist, or “what changed” narrative | PR/issue/change log, not canonical docs |
| Stable new subsystem with no existing owner | New canonical document named after the subsystem responsibility |

If one proposed document contains several rows from this table, split the content by owner instead of using the change initiative as the container.

## Workflow

### 1. Build a contract map

List every durable claim introduced or changed and assign it to one canonical owner. Include cross-cutting writers and readers, not only the screen or entry point that prompted the work.

Example:

| Contract | Canonical owner |
|---|---|
| Column display and interaction | Screen specification |
| Timestamp precision persistence | Data/database design |
| Update and rollback behavior | Interaction lifecycle design |
| Implementation order | Plan log |

Unassigned claims indicate a documentation gap. Claims assigned to multiple owners require one authoritative definition and references from the others.

### 2. Test scope by responsibility

For each related screen or subsystem, ask:

- Does this change directly alter its contract?
- Is it a required dependency, or merely another consumer of the same upstream event?
- Can it ship or be verified independently?

Parallel consumers of the same event are not automatically one development unit. Remove unrelated consumers from the current documents and plan unless a direct contract dependency is demonstrated.

### 3. Edit canonical owners

- Express resulting behavior in present tense.
- State invariants, boundaries, allowed operations, state transitions, and data semantics.
- Avoid issue numbers, PR numbers, “in this change,” “after implementation,” task order, and temporary phase language unless the document type explicitly owns history or rollout.
- Link to an authoritative definition rather than copying it into multiple files.
- When a previous ADR remains partly valid, add a superseding ADR or narrowly supersede the affected decision; do not rewrite accepted history as though the former decision never existed.

For a page that promises an overall or end-to-end process, make the overview independently answer:

- What is the normal path?
- Which activities are conditional, and what observable condition starts each one?
- What downstream observation returns work to an earlier activity?

Keep output details in a nearby table when that is clearer, but do not move triggers or return paths exclusively into a later table merely to preserve a simpler overview. If readers must mentally join several diagrams or tables to reconstruct when an activity happens, the overview is incomplete even when every fact exists somewhere on the page.

### 4. Isolate procedure

Move ordered work, Red/Green steps, migration sequencing, commands, validation checklists, rollout stages, and remaining tasks into the repository's procedural artifact. A plan may link to canonical documents, but canonical documents should not depend on the plan to state the final contract.

### 5. Retire initiative-shaped documents safely

Before removing a change-named document:

1. Map every durable statement to its canonical owner.
2. Transfer each statement without changing its meaning.
3. Update indexes and incoming links.
4. Search the repository for the old path and initiative name.
5. Remove the obsolete document only after the canonical set is complete and navigable.

Use [references/change-document-to-canonical-sources.md](references/change-document-to-canonical-sources.md) as a compact migration and review checklist.

## Verification

Run repository-provided documentation checks when available, then verify:

- no broken local links or orphaned index entries;
- no duplicate authoritative definitions;
- no durable contract exists only in a plan log;
- no implementation sequence leaked into canonical docs;
- no issue/PR/change codename remains in canonical prose without a historical reason;
- related-but-independent subsystems were not pulled into scope merely through a shared trigger;
- broad policy wording is consistent with the existing corpus and its documented exceptions;
- paired instruction files and navigation files remain intentionally aligned.

Search for procedural signals such as `first`, `then`, `after this change`, `follow-up`, `TODO`, issue identifiers, branch names, and temporary phase labels. Treat matches as review prompts, not automatic defects; runbooks and ADR history may legitimately contain them.

## Pitfalls

### Creating a folder for the change

A directory named after “improvement,” “redesign,” an issue, or a project often becomes a second source of truth. Route its contents to stable owners unless the name represents a lasting product capability.

### Treating a journey as an ownership boundary

Two screens can react to the same state without depending on each other. Document the shared state in its owner and each screen in its own specification.

### Overgeneralizing a new rule

Do not add a corpus-wide rule to a documentation README until the current tree satisfies it or explicit exceptions are documented. If the rule governs agent behavior rather than product truth, place it in the repository's agent instructions and mirror it only where the repository requires.

### Deleting decision history

Changing direction does not make the former accepted decision disappear. Preserve the original ADR and record the new decision with an explicit supersession boundary.

### Storing current repository facts in skills

Do not snapshot current inventories, known debt, migration progress, observed gaps, or one-time audit results in a reusable skill. Put those facts in the repository's canonical documentation, debt tracker, or planning artifact. Keep the skill focused on repeatable procedures, decision rules, verification commands, and pointers that load the current facts from their authoritative owner at runtime.

### Moving text without checking all writers

A data semantic can be written by several screens, jobs, or APIs. Canonical maintenance is incomplete if the document describes only the initiating path and silently omits other writers.

## Completion report

State which canonical owners changed, which procedural artifact holds the implementation sequence, which obsolete document was retired, and which link/scope/duplication checks passed. Avoid narrating every edit.
