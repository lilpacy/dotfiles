# Cross-workspace surface convergence

This verified case illustrates the difference between shared layout and shared visual grammar.

## Initial mismatch

A migrated workflow adopted the product's established page grid, top actions, and responsive input/output columns. Users still perceived different colors and styling. Inspection showed that its internal surfaces remained feature-specific: broad soft-background areas, additional nested bordered cards, and bespoke empty and progress treatments changed the visual weight despite using familiar tokens.

## Boundary that worked

Presentation-only primitives were extracted for the recurring card surface, header, primary action, empty/generating state, and progress treatment. The migrated workflow kept its own metadata, multiple-item input, result body, export action, and generation logic.

This avoided both failure modes:

- stopping at a shared outer grid while internal surfaces still diverged
- forcing unrelated workflows into one conditional domain component

## Verification split

Source contracts proved that the established and migrated workflows consumed the same primitives. Browser inspection then covered the residual perceptual claims:

1. Computed background, border color, radius, padding, and shadow matched between representative cards.
2. The result area used the intended surface nesting rather than several competing outer cards.
3. At 1440 px, input and output appeared side by side; at 390 px, they stacked without horizontal overflow.
4. Empty, progress, and primary-action presentation was checked in the rendered UI.

The key lesson is that primitive adoption is necessary evidence, but it is not sufficient evidence for visual sameness. Composition, occupied area, and runtime layout must also be observed.
