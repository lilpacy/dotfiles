---
name: js-timezone-best-practices
description: |
  JavaScript/TypeScript timezone handling best practices, focusing on JST(UTC+9) <-> UTC conversion.
  Use this skill whenever the user is working with timezone conversion in JS/TS, dealing with
  Date object timezone issues, implementing DateRangePicker or date input components that need
  TZ-aware handling, debugging "9 hours off" bugs, using toLocaleString or Intl.DateTimeFormat
  with timezone concerns, or storing/retrieving dates between browser and DB.
  Also trigger when you see anti-patterns like `new Date(year, month, day)` used for
  cross-timezone scenarios, `setHours`/`setMinutes` for timezone conversion, or
  `toLocaleString` without a `timeZone` option.
  Even if the user doesn't mention "timezone" explicitly, if they're dealing with date/time
  mismatches between client and server, or dates shifting by hours when saved to DB, this skill applies.
---

# JS/TS Timezone Best Practices (JST <-> UTC)

## Core Problem

`Date` internally holds a UTC timestamp (ms since 1970-01-01T00:00:00Z), but many constructors and methods implicitly use the browser's local timezone. The same code produces different UTC values depending on the user's TZ setting:

```javascript
// JST browser: 2026-01-20T12:00:00.000Z
// UTC browser: 2026-01-20T21:00:00.000Z
new Date(2026, 0, 20, 21, 0).toISOString();
```

This is the root cause of "9 hours off" bugs in JST-targeted services.

**Scope note:** JST is a fixed +9 offset with no daylight saving time, so the `hour - 9` / `+ 9h` arithmetic below is safe. For timezones with DST, use `Intl.DateTimeFormat` instead of fixed offset math.

## Three Rules

1. **Create dates with `Date.UTC`** — never `new Date(y, m, d, h, min)` for cross-TZ scenarios
2. **Read date parts with `getUTC*` methods** — never `getHours()`, `getDate()`, etc.
3. **Display with explicit `timeZone` option** — never bare `toLocaleString("ja-JP")`

## Correct Patterns

### 1. User Input (JST) -> UTC Date

When a user picks "2026-01-20 21:00" in a DateRangePicker, that's JST. Convert to UTC:

```typescript
const JST_OFFSET_HOURS = 9;

function createDateFromJST(
  year: number,
  month: number, // 0-11
  day: number,
  hour: number,
  minute: number
): Date {
  // hour - 9 can go negative; Date.UTC handles underflow automatically
  const ms = Date.UTC(year, month, day, hour - JST_OFFSET_HOURS, minute, 0, 0);
  return new Date(ms);
}

// createDateFromJST(2026, 0, 20, 21, 0).toISOString()
// => "2026-01-20T12:00:00.000Z"
```

`Date.UTC` interprets arguments as UTC regardless of browser TZ. The `-9` converts JST intent to UTC.

### 2. UTC Date -> JST Components

When populating a DateRangePicker's initial value from a DB-stored UTC date:

```typescript
const JST_OFFSET_MS = 9 * 60 * 60 * 1000;

function getJSTComponents(date: Date) {
  const jstMs = date.getTime() + JST_OFFSET_MS;
  const jst = new Date(jstMs);
  return {
    year: jst.getUTCFullYear(),
    month: jst.getUTCMonth(),  // 0-11
    day: jst.getUTCDate(),
    hour: jst.getUTCHours(),
    minute: jst.getUTCMinutes(),
  };
}
```

The key: after shifting by +9h, read with `getUTC*` methods so the browser's local TZ never enters the picture.

**Generalizable alternative** using `Intl.DateTimeFormat.formatToParts` (works for any timezone, including DST zones):

```typescript
function getZonedComponents(date: Date, timeZone: string) {
  const dtf = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric", month: "2-digit", day: "2-digit",
    hour: "2-digit", minute: "2-digit", hour12: false,
  });
  const parts = dtf.formatToParts(date);
  const map = Object.fromEntries(parts.map(p => [p.type, p.value]));
  return {
    year: Number(map.year),
    month: Number(map.month) - 1, // 0-11
    day: Number(map.day),
    hour: Number(map.hour),
    minute: Number(map.minute),
  };
}
```

### 3. UTC Date -> JST Display String

```typescript
function formatDateTimeAsJST(date: Date): string {
  return date.toLocaleString("ja-JP", {
    timeZone: "Asia/Tokyo",
    year: "numeric", month: "2-digit", day: "2-digit",
    hour: "2-digit", minute: "2-digit", hour12: false,
  });
}
// formatDateTimeAsJST(new Date("2026-01-20T12:00:00.000Z"))
// => "2026/01/20 21:00"
```

The `timeZone: "Asia/Tokyo"` makes the output deterministic regardless of browser TZ.

**`toLocaleString` is for display only.** For persistence or comparison, use `toISOString()` or epoch ms.

## Anti-Patterns to Flag

### Local-TZ-dependent Date construction

```typescript
// BAD: result depends on browser TZ
const date = new Date(2026, 0, 20, 21, 0);
date.setHours(21);
```

Fix: use `Date.UTC` as shown above.

### Double conversion ("it's off by 9 hours so let me subtract 9")

```typescript
// BAD: fragile, breaks in non-JST environments
const localDate = new Date("2026-01-20T21:00:00"); // local TZ interpretation!
const utcDate = new Date(localDate.getTime() - 9 * 60 * 60 * 1000);
```

The string `"2026-01-20T21:00:00"` (no `Z`, no offset) is parsed as local time — already environment-dependent. Subtracting 9h on top of that only works if the browser happens to be in JST.

Fix: use `Date.UTC` from the start, or always include timezone in ISO strings (`Z` or `+09:00`).

### Missing `timeZone` in display

```typescript
// BAD: shows different times for users in different TZs
date.toLocaleString("ja-JP"); // no timeZone option
```

Fix: always pass `timeZone: "Asia/Tokyo"` (or the appropriate zone).

### TZ-ambiguous ISO strings

```typescript
// DANGEROUS: no TZ indicator, parsed as local time
new Date("2026-01-20T21:00:00");

// SAFE: explicit TZ
new Date("2026-01-20T21:00:00Z");         // UTC
new Date("2026-01-20T21:00:00+09:00");    // JST
```

## Boundary Value Tests

JST 00:00-08:59 maps to the previous UTC day. This is where most bugs hide:

| JST Input           | Expected UTC          | Why it matters              |
|---------------------|-----------------------|-----------------------------|
| 2026/01/21 00:00    | 2026/01/20 15:00      | Date rolls back             |
| 2026/01/21 08:59    | 2026/01/20 23:59      | Just before same-day cutoff |
| 2026/01/21 09:00    | 2026/01/21 00:00      | Same-day boundary           |
| 2026/01/01 00:00    | 2025/12/31 15:00      | Year rolls back             |
| 2024/02/29 00:00    | 2024/02/28 15:00      | Leap year + day rollback    |

When implementing timezone conversion, write tests covering these boundaries. The `Date.UTC` underflow handling makes them pass naturally, but explicit tests prevent regressions.

## Data Flow Summary

```
User Input (JST) --[Date.UTC, hour-9]--> Date (UTC internally) --[save]--> DB (UTC)
DB (UTC) --[fetch]--> Date (UTC internally) --[timeZone:"Asia/Tokyo"]--> Display (JST)
```

Keep this flow unidirectional. Never mix local-TZ methods into the pipeline.

## Future: Temporal API

The `Temporal` API (TC39 stage 3) will eventually replace `Date` with explicit timezone-aware types like `Temporal.ZonedDateTime`. For new projects where Temporal is available, prefer it over `Date`. Until then, the patterns above are the safest approach.
