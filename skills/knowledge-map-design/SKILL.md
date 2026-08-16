---
name: knowledge-map-design
description: Design and review source-grounded knowledge maps, domain maps, learning roadmaps, and curriculum views. Use when separating historical development from present-day concept structure, deriving purpose-specific learning paths, preserving provenance across competing sources, or deciding how to present machine-readable map records to humans without forcing meaningless diagrams.
---

# Knowledge Map Design

Design the smallest map that answers a real navigation question. Do not treat a catalog, graph-shaped rendering, or curriculum order as a map merely because it is structured.

## Establish the questions first

Separate these views before choosing a schema:

| View | Question | Typical facts |
|---|---|---|
| Diachronic | How and why did concepts develop over time? | events, dates or eras, pressures, `evolved-from`, `superseded-by`, `coexisted-with` |
| Synchronic | How are concepts related at a stated point in time? | containment, dependency, alternatives, cardinality, validity interval |
| Curriculum | What should this learner study, for this purpose, in what order? | selected concepts, sequencing rationale, exercises, checkpoints |
| Learning state | What evidence exists about this learner's current understanding? | encounters, self-reports, demonstrations, review needs |

Reuse stable concept identities across views, but do not merge their semantics. Treat the reusable Domain Map as the combination of diachronic and synchronic views. Treat curricula and personal learning paths as separate derived artifacts:

`domain map = diachronic view + synchronic view`

`purpose curriculum = f(relevant subgraphs from 1..* domain maps, external curriculum evidence, goal, constraints, pedagogy)`

`personal learning path = g(purpose curriculum, learning state)`

A Domain Map may support `0..*` curricula, and a curriculum may reference `1..*` Domain Maps. Select only the needed nodes and relations from each map; do not make an entire map a prerequisite by default. Create a curriculum only when its learning purpose is clear enough to choose and order those subgraphs.

If no adequate external curriculum exists, replace that input with an explicit synthesis grounded in at least two independent external sources. Correct diachronic and synchronic maps are necessary but do not uniquely determine a learning order.

## Ground the map in sources

1. Define the domain, purpose, audience, and `as_of` time.
2. Prefer sources that explicitly carry the needed structure:
   - official standards, specifications, curricula, or syllabi;
   - established books or university courses;
   - maintained professional roadmaps;
   - AI synthesis from multiple independent sources only when no suitable structure exists.
3. Preserve immutable source snapshots or equivalent stable evidence.
4. Record which source supports each node, relation, event, and path assertion.
5. Distinguish asserted structure from inference. Do not promote chapter order, numbering, visual proximity, or absence of disagreement into prerequisites.
6. Keep conflicting source-specific paths when their purposes differ. Mark same-purpose contradictions as disputed instead of flattening them.
7. Treat source acquisition and view construction as one bounded attempt: gather the minimum evidence needed, build the required views, and validate them before publishing. Do not publish placeholder views or let source collection become an unbounded pre-phase.

A completed Domain Map requires substantive diachronic and synchronic views. If either view cannot be grounded, retain the sources and report the missing evidence, but do not publish an incomplete artifact as a completed map. Curriculum is not a mandatory third view of every map; it is a separate purpose-dependent artifact and may legitimately be absent.

Read [references/source-grounded-map-lessons.md](references/source-grounded-map-lessons.md) when selecting human views, validating a flat source, deriving a curriculum, or defining automatic map-maintenance entrypoints and scope.

## Model the minimum semantics

Start with concepts and explicit relations. Add event objects only when the diachronic view needs to express a cause, transition, or period that a direct edge cannot represent faithfully.

For every relation, define:

- predicate and direction;
- source evidence;
- scope or path, if conditional;
- valid time or `as_of`, when the relation can change;
- status such as `asserted`, `inferred`, or `disputed`;
- cardinality only when the source or domain contract supports it.

Keep provenance outside display labels so the same facts can support several views.

## Separate storage from presentation

Maintain one authoritative semantic model and project it into reader-specific views.

- Put the human-readable view before machine records when both share one document.
- Use a table for flat catalogs, exact comparisons, or compact cardinalities.
- Use a timeline for dated development and transitions.
- Use a graph or Mermaid diagram only when edges, branching, hierarchy, or multiplicity become easier to inspect than in prose or a table.
- Omit a diagram when removing it loses no information or makes the page easier to scan.
- Never invent relations merely to make a diagram look useful.

Do not validate a human view by requiring a rendering syntax. Validate the semantic outcome: the view is present, readable, grounded, and communicates the intended relationships without unsupported claims.

## Merge sources without erasing purpose

| New evidence | Action |
|---|---|
| Same concept and meaning | Reuse the concept identity and add provenance |
| Compatible new concept or relation | Add it to the shared model |
| Same relation from another source | Merge evidence, not duplicate edges |
| Different order for different goals | Preserve purpose-specific paths |
| Contradiction for the same goal and time | Keep both claims as disputed |
| Uncertain concept identity | Keep separate pending review |

## Derive curricula explicitly

1. Select a learning goal and audience.
2. Select the relevant `as_of` snapshot.
3. Use synchronic dependencies to prevent prerequisite gaps.
4. Use diachronic context when it explains why concepts exist or clarifies tradeoffs; do not equate historical order with teaching order.
5. Incorporate an external curriculum when one exists: reuse its teaching order, exercises, and outcomes only after checking them against both base maps. If none exists, synthesize from at least two independent external sources and label the synthesis explicitly.
6. Apply constraints and pedagogy, then record every derivation input and rationale so the curriculum can be regenerated.
7. Apply Learning State only when producing a personal learning path from the purpose curriculum.
8. Make every stage runnable: state the task, observable passing evidence, and the next unlocked stage. When delivering it interactively, ask one focused question at a time and judge the learner's reasoning rather than accepting a correct label without its required rationale.

Keep Learning State separate from domain truth and from the reusable purpose curriculum. A learner asking about a concept proves exposure, not mastery.

Read [references/interactive-curriculum-delivery.md](references/interactive-curriculum-delivery.md) when turning a curriculum into a guided session with stage gates, concise learner replies, or a real goal that must be narrowed into measurable outcomes.

## Validate

Check the smallest set that can falsify the design:

- every displayed edge, event, order, and multiplicity has evidence or an explicit inference label;
- diachronic order is not silently reused as prerequisite order;
- synchronic claims state their time scope when they can change;
- alternate purposes remain separate paths;
- machine-readable records and human projections agree;
- a flat source produces a readable catalog, not a decorative graph;
- every required view contains grounded claims rather than a heading, placeholder, or "not built" notice;
- curriculum evidence reaches the diachronic, synchronic, and external-curriculum inputs it claims to derive from;
- purpose curriculum changes when its goal, constraints, or pedagogy changes materially, and personal learning paths change when learner state changes.

## Avoid

- calling an ID-tagged topic list a roadmap;
- requiring Mermaid or any visualization technology as a proxy for readability;
- deriving domain truth from a learner's question history;
- treating one curriculum as evidence of historical evolution;
- collapsing competing purposes into one universal order;
- adding graph databases, embeddings, automated crawling, or progress UI before the map semantics are proven useful.
