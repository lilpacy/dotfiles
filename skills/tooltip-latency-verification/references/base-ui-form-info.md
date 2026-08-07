# Base UI form-info tooltip case

This verified case illustrates why delayed feedback can be mistaken for missing behavior.

## Observed behavior

- The tooltip eventually appeared, but the user initially perceived that hover did nothing.
- Inspection of the installed Base UI primitive identified a 600 ms default hover delay.
- Browser measurement observed 829 ms from hover initiation to visible content.

## Narrow fix

Set `delay={0}` on the shared form-input info tooltip boundary. Do not change the global tooltip provider when only explanatory form help needs immediate feedback; unrelated icon tooltips may intentionally retain a short delay.

The same browser measurement observed 34 ms after the scoped change.

## Verification recipe

1. Move the pointer away from the trigger.
2. Start timing immediately before hover.
3. Wait for the expected tooltip content to become visible without a fixed sleep.
4. Repeat with a short requirement-level timeout after the change.
5. Confirm keyboard focus still opens the tooltip and Escape still closes it.

Treat the property name and default duration as library-version-specific. Reinspect installed types or current primary documentation before applying this example elsewhere.
