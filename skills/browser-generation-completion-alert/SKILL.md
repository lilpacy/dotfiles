---
name: browser-generation-completion-alert
description: Add and verify cross-platform browser notifications and default completion sounds for long-running web jobs. Use when a web UI should alert users after generation, export, rendering, uploads, or other asynchronous work finishes.
---

# Browser Generation Completion Alert

## Goal

Notify the user once when a long-running browser job succeeds:

- Use the Web Notifications API for macOS and Windows desktop notifications.
- Use Web Audio for a short built-in chime without an audio asset.
- Keep notification failure isolated from the job result.

## Browser constraints

- Request notification permission only from a user gesture, normally the job's submit click.
- Create or resume `AudioContext` from the same gesture so later background playback is allowed.
- Notifications require a secure context outside localhost.
- A page-only polling implementation cannot notify after the tab or browser is closed. Use server-side push plus a service worker only when closed-page delivery is explicitly required.
- When `NotificationOptions.silent` is omitted, notification sound and vibration follow platform conventions and are not guaranteed. `silent: true` suppresses notification-originated sound and vibration in supporting browsers.
- `NotificationOptions.silent` is not Baseline across all widely used browsers. Define the supported browser matrix and verify sound-on and sound-off behavior on each target browser and OS pair; do not infer support from the OS alone.

## Sound policy

Choose exactly one sound source:

- For an app-controlled chime, create the desktop notification with `silent: true` and play Web Audio only when the app sound setting is enabled. This avoids a duplicate OS notification sound. The chime follows site/tab mute and device audio volume, but not OS notification-sound or Focus/Do Not Disturb semantics.
- For platform-controlled sound, omit the custom Web Audio chime and leave `silent` unset. Sound may be absent depending on browser, OS, per-app notification settings, and Focus/Do Not Disturb.

Never combine a custom chime with an unsilenced notification: systems that emit a notification sound can produce two audible alerts.

## Implementation contract

Expose two operations from a small client-side controller:

1. `prepare`: mark one notification as pending, request notification permission when it is still `default`, and initialize/resume audio when app-controlled sound is enabled.
2. `notifySuccess`: consume the pending marker and emit one desktop notification plus the selected single sound path.

Call `prepare` synchronously after submit validation and before the first `await`. Call `notifySuccess` directly from every successful result path, including immediate responses, polling completion, and mock completion. Do not infer success from render timing alone; React may batch intermediate status renders.

Keep a pending ref or equivalent state so repeated terminal updates cannot duplicate the alert. Clear or consume it before emitting.

## Audio implementation

Use one module-level `AudioContext`. The reuse condition must check that the context exists:

```ts
if (audioContext && audioContext.state !== "closed") return audioContext;
```

Do not use `audioContext?.state !== "closed"`; when the context is `null`, that expression is true and incorrectly returns before initialization.

A short two-note sine chime can be produced with two oscillators and gain envelopes. Catch initialization or resume failures so sound support never changes job success.

## Verification

- Unit-test that active-to-success alerts, completed-to-success does not duplicate, and failure/cancellation does not alert.
- Run tests, type checking, lint, and production build.
- In browser QA, intercept only the target generation endpoint or replace `window.fetch` for that endpoint. Never invoke a paid generation API for notification testing.
- Instrument `Notification` and `AudioContext` in the test browser and assert one notification plus the expected oscillator count.
- If network interception hangs, distinguish "job did not reach completion" from "notification failed" by inspecting exact visible status and request completion. Do not treat text such as "results appear after completion" as a completed status.
