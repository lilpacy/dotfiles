---
name: chrome-devtools-mcp
description: Use when operating a browser via Chrome DevTools MCP (CDP) for debugging, form interaction, or performance checks. Covers Turnstile/bot-detection limits, DuckDuckGo-only search, and snapshot economy. Do NOT use CDP for web research — use web-doc-reading instead.
---

# Chrome DevTools MCP (CDP) Operations

CDP is for **debugging and performance analysis only**. For web research and
reading documentation, use the `web-doc-reading` skill (WebSearch / WebFetch)
instead — browsing through CDP is inefficient and risks bot detection.

## Forms behind Cloudflare Turnstile cannot be submitted via CDP

Bot-detection services such as Cloudflare Turnstile refuse to issue tokens to
CDP-controlled browsers, so form submission silently fails.

- **Before starting any form input**, check whether the page contains a
  Turnstile widget: look for a `cf-turnstile` class or a script loaded from
  `challenges.cloudflare.com`.
- If present, do not attempt submission via CDP. Write the intended input
  values to a text file and ask the user to submit the form manually.
- A browser session once connected via CDP does not recover by reloading —
  manual submission must happen in a separate, non-CDP browser.

## Keep snapshots to the minimum

- `take_snapshot` returns the full-page accessibility tree — often hundreds of
  lines including footers and navigation.
- To check form state, prefer `evaluate_script` to read field values; it is
  far more token-efficient.
- Restrict `take_screenshot` to the area you need instead of the full page.
