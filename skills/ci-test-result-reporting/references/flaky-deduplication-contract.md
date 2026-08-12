# Flaky deduplication contract

## Verified scenario

In the reviewed Playwright configuration, project names were generated from a stage counter and spec selector, while every project used Playwright-managed `chromium`. The project name therefore described orchestration, and the browser value was constant rather than a useful discriminator.

| Candidate field | Observed role | Contract decision |
|---|---|---|
| Repository | Test identity namespace | Fingerprint |
| Relative spec path | Test identity | Fingerprint |
| Full test title path | Test identity | Fingerprint |
| Normalized failure signature | Failure identity | Fingerprint |
| Generated project / stage name | Spec selection and ordering | Exclude |
| Browser fixed to `chromium` | Constant execution setting | Exclude until it varies |
| CI job or run locator | Artifact lookup for one failure | Occurrence only |

A minimal stable key for that shape is:

```text
sha256(
  repository
  + relative spec path
  + full test title path
  + normalized failure signature
)
```

## Review procedure

1. Trace where project names and browser settings are generated; do not infer semantics from labels such as `project/browser`.
2. Enumerate whether each value varies across the current suite.
3. Classify each field as identity, reproduction variant, occurrence locator, or orchestration metadata.
4. Use only stable identity and varying reproduction fields in the deduplication contract.
5. Keep run/job locators with occurrences so trace, video, and screenshot artifacts can be found.
6. Search the canonical documentation, issue title, description template, fingerprint formula, and agent instructions for the old field and update them together.

## Upgrade triggers

- When the suite adds multiple browsers or device profiles, add the stable execution variant needed to distinguish reproducible failures.
- If a Playwright project becomes the canonical name of that stable variant, use a normalized variant identifier, not an incidental generated stage prefix.
- Do not add a field merely because the runner exposes it; add it after proving that it changes issue identity or reproduction.
