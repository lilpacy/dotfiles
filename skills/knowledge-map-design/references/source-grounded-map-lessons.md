# Source-grounded map lessons

## Verified failure pattern

A pilot used a reputable curriculum containing a flat list of topics. The stored Node, Path, and Relation records were machine-readable, but the page was not a useful human map because the source supplied almost no hierarchy, dependency, or recommended order.

Requiring a Mermaid block or table did not solve the semantic gap. A diagram showing only that every topic belonged to the same course added visual noise without revealing a relationship that was hard to see in a list.

The working correction was:

- require a non-empty human-readable view before machine records;
- accept a compact table for a flat catalog;
- use a diagram only when it materially clarifies hierarchy, branching, flow, time, or multiplicity;
- test for readability and supported meaning, not for a specific rendering syntax;
- reject unsupported ordering or dependencies even when they would make the picture look more map-like.

## View and artifact separation learned from the pilot

The durable model separates:

1. a diachronic view of how concepts arose, changed, coexisted, or were superseded;
2. a synchronic `as_of` snapshot of containment, dependency, alternatives, and cardinality;
3. a purpose-specific curriculum derived from selected subgraphs of one or more Domain Maps, external curriculum evidence, a goal, constraints, and pedagogy;
4. a personal learning path derived by applying Learning State to a purpose curriculum.

The first two views constitute a reusable Domain Map. Curriculum is a separate artifact because a learning purpose may not exist when the map is built, one map can support many curricula, and one curriculum can span many maps. The precise multiplicities are:

| Source | Target | Multiplicity |
|---|---|---:|
| Domain Map | Curriculum | `0..*` |
| Curriculum | Domain Map | `1..*` |

A curriculum should reference only the needed nodes and relations from each map, then add cross-map teaching order or prerequisites with evidence and rationale.

This prevents common category errors:

- curriculum order is not historical order;
- historical development does not prove present-day dependency;
- accurate domain maps do not uniquely determine a curriculum without external curriculum evidence, a goal, constraints, and pedagogy;
- learner state personalizes a purpose curriculum but does not define reusable domain truth.

## Source implications

A source is useful only for the structure it actually asserts. A curriculum may support topic scope and teaching order while saying little about historical development or present-day multiplicity. Build each view from sources suited to that view, share concept identities where justified, and preserve provenance per claim.

## Completion semantics and one-attempt workflow

A completed Domain Map requires both grounded base views:

- the diachronic view must contain reviewable historical claims;
- the synchronic view must contain reviewable present-structure claims;
- a missing base view blocks publication rather than becoming a placeholder;
- source acquisition and two-view construction should normally finish in the same bounded attempt;
- if evidence cannot be obtained, retain valid snapshots and name the exact gap and resumption condition.

Curriculum is generated separately only when a learning purpose is clear enough to select and order relevant map subgraphs. It is valid for a completed Domain Map to have no curriculum.

This avoids empty maps, speculative curricula, and an indefinite "collect sources now, build someday" phase.

## Curriculum inputs

A purpose curriculum is derived from relevant subgraphs of one or more Domain Maps, an external curriculum when available, and the goal, constraints, and pedagogy. External curricula contribute teaching order, exercises, and outcomes, but must be checked against the base maps rather than treated as universal truth.

When no adequate curriculum exists, use an explicitly labelled synthesis backed by at least two independent external sources. Learning State is applied later to personalize the purpose curriculum; it is not an input to reusable domain truth.

## Do not confuse routing concepts

Keep these separate in design and explanations:

| Concept | Example | Meaning |
|---|---|---|
| Generation entrypoint | explicit request; maintenance completion hook | What starts map construction or maintenance |
| Scope signal | deltas since the map cursor | What changed, not the final map boundary |
| Curriculum derivation branch | external curriculum; multi-source synthesis fallback | How curriculum evidence is selected inside curriculum construction |
| Source role label | `curriculum-synthesis-input` | Metadata used for provenance and validation; it runs nothing |

## Automatic map maintenance

A validated maintenance flow separates timing from scope:

```text
Concept Synthesis completes
  -> launch independent Map maintenance
  -> read Deltas since the Map cursor
  -> expand each Delta to related Summary, Entity, Concept, and existing Map context
  -> classify existing-map update, new-map candidate, or no impact
```

Use the completion hook only to decide when maintenance runs. Use Deltas as change signals, not as the map scope or sole evidence; otherwise the result overfits recent sources.

Prefer updating an existing Map. Create a new Map only when the knowledge does not fit an existing scope and both diachronic and synchronic views can be grounded. Otherwise skip without publishing a placeholder. Curriculum generation remains a separate on-demand flow triggered by an explicit learning purpose.
