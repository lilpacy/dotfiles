# Full-to-partial E2E triage

## Validated shifted-boundary pattern

A full run timed out while a save request was still pending. An exact-SHA remote partial later completed the slow save, then failed because the expected updated row never appeared. Both outcomes belonged to the same user flow:

```text
submit save -> wait for server response -> refresh/render updated state -> assert updated row
```

The partial did not contradict the full failure; it progressed one boundary farther and exposed a downstream symptom. Because the same logical test failed again, the evidence supported a reproducible defect rather than a flaky classification. The application root cause remained unresolved and was not generalized.

## Minimal evidence record

- application/test SHA
- workflow and runner provenance
- project and full test title
- seed/dependency mode
- artifact policy, including whether video was disabled
- original run's last completed boundary and elapsed time
- partial run's last completed boundary and elapsed time
- any environment or orchestration differences
- verdict with the remaining uncertainty stated explicitly

## Classification guardrails

| Full run | Equivalent partial | Classification |
|---|---|---|
| Fail | Fail | Reproducible; compare boundaries before deciding whether symptoms differ |
| Fail | Pass | Flaky candidate only; first exclude seed, dependency, mode, and provenance differences |
| Timeout | Downstream assertion fail | Potentially one defect with a shifted boundary; inspect the flow and state transition |

Do not convert a timeout into a timeout increase by default. First verify whether the operation completed correctly, whether the expected state was committed, and whether the UI refreshed from that state.
