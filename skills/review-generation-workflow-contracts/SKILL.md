---
name: review-generation-workflow-contracts
description: Review and design multi-input, multi-stage generation workflow contracts before changing UI, APIs, or execution graphs. Use when adding or reassigning reference images, prompts, models, or other inputs; when a generation stage has input-count or node-capacity limits; or when deciding whether a change belongs in application-side graph mutation versus the generation runtime.
---

# Review Generation Workflow Contracts

Prevent locally plausible changes from dropping existing inputs or exceeding a downstream stage's real capacity.

## Trace the complete path

Read the implementation before proposing a graph change. Follow every input through:

```text
UI field -> request schema -> server handler -> upload/normalization -> graph builder -> execution stage -> runtime
```

Search every caller of the graph builder and every consumer of the request contract. Treat existing required inputs as part of the contract even when the request only discusses a new input.

## Build the input ledger

List all inputs before assigning any of them to stages.

| Field | Record |
|---|---|
| Identity | Stable field or semantic name |
| Role | What information it contributes |
| Required | Required, optional, or derived |
| Source | User upload, stored asset, prior-stage output, or constant |
| Consumer | Exact stage or node that uses it |
| Lifetime | Upload, retain, retry, replace, or discard behavior |

Do not equate upload count with stage input count. A prior-stage output is not a new upload, but it still consumes a downstream input position.

## Check capacity per stage

Create a stage matrix from the actual graph or builder code.

| Stage | Inputs consumed | Capacity | Result |
|---|---|---:|---|
| Stage N | Explicit input identities | Measured limit | Fits or exceeds |

Verify both invariants:

```text
every required input has at least one intended consumer
inputs consumed by each stage <= that stage's measured capacity
```

Never infer total workflow capacity from one node's arity. Count fan-in, adapters, derived outputs, and stage-specific reuse where the graph actually consumes them.

Read [references/input-accounting.md](references/input-accounting.md) when expanding an existing workflow with a new input or another generation stage.

## Preserve semantic roles

Keep inputs separate when their meanings differ and the runtime can receive them separately. State the role in the request contract and prompt or node configuration.

Use a composite only when the execution contract requires one. A visual overlay can remain a preview without becoming the generation source of truth; flattening distinct inputs can destroy provenance and make conflicts ambiguous.

## Choose the change boundary

Inspect what the runtime API accepts rather than assuming the graph is fixed.

| Change | Usual boundary |
|---|---|
| Values, prompts, input files, existing-node wiring | Application-side graph construction |
| Adding/removing nodes already supported by the runtime | Application-side graph construction, then serialized-graph validation |
| Installing a missing node type, model, or runtime capability | Generation runtime/environment |

This is a decision guide, not a platform guarantee. Confirm it against the current client and runtime.

## Make the smallest complete change

Reuse the existing graph loader, upload path, node conventions, and validation utilities. Add only the fields and wiring required by the new contract. Avoid a new workflow file when the existing graph needs only a small, inspectable mutation; use a dedicated workflow when graph structure is materially different and a checked-in graph is easier to review.

## Verify

Leave one runnable check that proves the changed contract:

1. Serialize or build the final graph.
2. Assert every required input maps to its intended consumer.
3. Assert every stage remains within measured capacity.
4. Assert semantic roles are not silently swapped or flattened.
5. Run the repository's existing graph/schema validator when present.

A stage matrix is design evidence, not implementation proof. Do not call the workflow supported until the built graph or request has been validated.
