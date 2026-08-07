---
name: tooltip-latency-verification
description: Measure and fix perceived tooltip latency in browser UIs. Use when a tooltip technically appears but users report that hover or focus feedback is slow, inconsistent, or unresponsive, or when reviewing a tooltip timing change with Playwright.
---

# Tooltip Latency Verification

Treat visibility and response time as separate requirements.

## Workflow

1. Reproduce before editing. Move the pointer away, start a timer immediately before hovering the trigger, wait for the tooltip to become visible with a generous timeout, and record elapsed milliseconds.
2. Inspect the installed UI library's local types or primary documentation. Identify the exact default open delay and the narrowest supported override; do not infer timing from appearance alone.
3. Decide whether immediate display is appropriate. Explanatory form-field info can usually open immediately; global icon actions may intentionally keep a short delay to avoid accidental flicker. Scope the override to the reported interaction.
4. Add the smallest reliable contract test for the timing configuration. Keep real elapsed-time verification in Playwright because source or unit tests cannot prove perceived latency.
5. Apply the supported delay setting at the shared component boundary. Preserve hover, keyboard focus, Escape dismissal, hoverability, and persistence behavior.
6. Re-measure from a clean pointer state with a short timeout that represents the requirement. If the user did not provide a threshold, treat 200ms as a verification hypothesis, report it explicitly, and use the before/after measurements as the primary evidence.
7. Verify keyboard focus opens the tooltip and Escape closes it. Also confirm the change did not alter unrelated tooltip classes.

## Playwright measurement pattern

```js
async page => {
  const trigger = page.getByRole("button", { name: "Field help" });
  const tooltip = page.getByText("Expected tooltip content");
  await page.mouse.move(0, 0);
  const startedAt = Date.now();
  await trigger.hover();
  await tooltip.waitFor({ state: "visible", timeout: 2000 });
  return { elapsedMs: Date.now() - startedAt };
}
```

After the fix, rerun with the agreed short timeout. Do not insert a fixed wait before checking visibility; that masks the latency being tested.

## Completion evidence

Report the library default, the before/after elapsed times, the chosen scope, and the focus/Escape regression result. Do not claim an interaction is immediate solely because a screenshot or delayed snapshot contains the tooltip.

## Reference cases

- Read [references/base-ui-form-info.md](references/base-ui-form-info.md) when diagnosing Base UI form-help tooltips or when a concrete measured example is useful.
