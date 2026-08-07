---
name: established-product-ui-integration
description: Integrate a new or migrated UI into an established product so its layout, surfaces, states, and interactions feel native without coupling unrelated domain logic. Use when a page looks stylistically different from neighboring workflows, when deciding what visual components to share, or when browser evidence is needed beyond source-level component contracts.
---

# Established Product UI Integration

Make a new workflow feel native to an existing product by matching its visual grammar and interaction states, not merely its outer grid or token names.

## Establish the reference

1. Select one or two established pages that represent the product's intended UI. Prefer neighboring workflows with comparable input/output structure.
2. Inspect both their source boundaries and rendered browser output. Record facts rather than inferring a design system from class names alone.
3. Inventory the recurring grammar:
   - page container, top actions, and responsive columns
   - card surfaces, headers, spacing, borders, radius, and shadow
   - field labels, required markers, contextual help, and upload areas
   - primary actions and hover, focus, disabled, and pending states
   - empty, generating, progress, success, and error treatments
4. Separate product-wide patterns from content that is inherently feature-specific.

## Compare in layers

Review the new workflow from the outside inward.

| Layer | Compare | Typical evidence |
|---|---|---|
| Structure | container, toolbar, columns, responsive stacking | DOM order, shared layout primitive, browser bounding boxes |
| Surface grammar | card count, nesting, occupied color area, borders, padding, shadow | shared surface primitive plus computed browser styles |
| Field grammar | labels, required state, info, upload affordance | component contract and keyboard/browser interaction |
| State grammar | empty, running, progress, success, failure | state/component tests plus representative browser states |
| Feature content | domain inputs, outputs, and actions | feature-owned contracts and tests |

Do not stop after structure matches. A shared outer layout can still feel unrelated when one page uses broad tinted areas, extra nested cards, different border density, or bespoke empty/progress states. Equal tokens also do not guarantee equal perception because nesting and occupied area change their visual weight.

## Choose the component boundary

| Relationship | Preferred boundary |
|---|---|
| Same appearance, different domain behavior | Small presentational primitive with content slots |
| Same behavior and appearance across workflows | Shared component or hook with an explicit contract |
| Domain-specific data, sequencing, or side effects | Keep inside the feature component |
| Similar only in one incidental detail | Reuse an existing token or primitive; do not extract a new abstraction yet |

Good shared primitives often include a workspace card, card header, primary action, empty/generating state, progress treatment, field help, and responsive input/output columns. Keep domain parsing, generation, persistence, result rendering, and feature-specific metadata outside those primitives.

Avoid a single mega-component that switches among unrelated workflows. The goal is a shared visual grammar with independently understandable domain components.

## Implement and verify

1. Define atomic verification points before production edits.
2. Use source or component contracts to prove each intended consumer adopts the shared primitive.
3. Implement the smallest presentational extraction that closes the observed mismatch.
4. Run feature tests to ensure domain behavior did not move accidentally.
5. Compare an established page and the new page in a real browser at representative desktop and narrow widths.
6. Inspect computed background, border color, radius, padding, shadow, surface nesting, and bounding boxes. Do not rely only on screenshots or matching class strings.
7. Check `documentElement.scrollWidth === documentElement.clientWidth` at the narrow width.
8. Exercise changed hover, focus, disabled, empty, progress, success, and error states. Measure interaction latency when responsiveness is part of the report; delayed snapshots can hide it.
9. Keep automated formatting or codemods from obscuring the semantic diff. Revert mechanical churn and retain only the intended extraction.

## Evidence boundaries

Source-level tests prove component adoption and static contracts. Browser evidence remains necessary for claims about rendered equivalence, spatial composition, responsive overflow, and perceived response time. Keep the browser checks narrow: one representative established page, the new page, the relevant states, and the breakpoints at risk.

## Completion criteria

- The new workflow uses the intended shared layout and visual primitives.
- Domain-specific behavior remains owned and tested by the feature.
- Computed surface properties and composition match the reference where equivalence was intended.
- Desktop and narrow layouts have the intended placement and no horizontal overflow.
- Changed interaction and state feedback is usable by pointer and keyboard.
- The diff contains the abstraction and consumer changes without unrelated formatting churn.

## Reference cases

- Read [references/cross-workspace-surface-convergence.md](references/cross-workspace-surface-convergence.md) for a verified case where sharing only the outer layout did not achieve visual consistency.
