# Change document to canonical sources

This reference captures a verified migration pattern from a change-shaped design document to stable sources of truth.

## Migration recipe

1. Inventory every durable statement in the change document.
2. Classify each statement as requirement/screen behavior, data/persistence, interaction lifecycle, architecture decision, or implementation procedure.
3. Move declarative statements into the existing owner for that responsibility.
4. Move ordered implementation and verification steps into the plan log.
5. Remove related screens or subsystems that share a trigger but have no direct contract dependency.
6. Preserve accepted ADR history; supersede only the decision that changed.
7. Delete the change-named document after link, index, duplication, and scope checks pass.

## Review questions

- Would this filename still make sense after the issue and PR are forgotten?
- Does each durable rule have exactly one authoritative owner?
- Is any current-state contract available only from a plan?
- Does the prose describe the system as it is, or the sequence used to change it?
- Are parallel consumers being grouped merely because they appear in the same scenario?
- Does a new general documentation rule conflict with legacy sections of the current corpus?

## Proven distinctions

- A shared upstream state can feed multiple independent screens; that does not make the screens depend on each other.
- Data semantics belong with the data and all of its writers, not only with the screen that exposed the requirement.
- Agent workflow policy can belong in agent instructions even when product documentation must remain purely declarative.
- A plan log is allowed to be procedural; canonical product and design documents are not implementation diaries.
