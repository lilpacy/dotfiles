---
name: credential-redaction
description: Use when reading or reporting the contents of configuration or diagnostic files that may hold secrets — .npmrc, .env*, .netrc, auth/session state files, CI settings, cloud credentials, kubeconfig, tool config with API keys — or when a user asks "show me the config" / "設定を確認して" during debugging. Also use when composing any output (chat, PR, issue, log, commit) that quotes such a file.
---

# Credential Redaction

## Overview

Never let a secret value leave the file it lives in. When diagnosing
configuration, the deliverable is *which keys are set and whether they
work* — never the values. Tool output, chat replies, PR bodies, and
committed logs are all persistence layers; a token pasted once must be
treated as leaked and rotated.

## The Rule

Before quoting any config/diagnostic file content into output:

1. Identify lines whose value is a secret: `_authToken`, `token`,
   `password`, `secret`, `api[-_]key`, `Authorization`, `cookie`,
   `private key` blocks, and provider prefixes (`ghp_`, `gho_`, `npm_`,
   `sk-`, `xox`, `AKIA`, `AIza`, `glpat-`, `-----BEGIN`).
2. Replace each value with `<REDACTED>` (keep the key name — that is the
   diagnostic signal).
3. If only presence matters, don't quote the file at all: report key
   names and whether each is set.

```bash
# Show structure without values
grep -vE '(_authToken|token|password|secret|api[-_]?key)' .npmrc
# Or mask in place for the report
sed -E 's/(_authToken=).*/\1<REDACTED>/' .npmrc
```

To test whether a token *works*, run the probe and report only the HTTP
status — never echo the token into the command line of a shared transcript
if avoidable (prefer reading it into an env var).

## Placeholder Trap

A value that *looks* fake (`FAKE`, `test`, `example`, `xxx`) is still
redacted. You cannot verify fakeness from the value alone, and quoting it
trains the habit of quoting real ones. Redact unconditionally.

## Rationalization Table

| Excuse | Reality |
|---|---|
| "The user asked to see the config" | They asked what's configured, not the secret bytes. Redacted output answers the question. |
| "It's obviously a dummy/test token" | You can't prove that. Redact anyway. |
| "It's a local file, only the user sees this" | Transcripts are logged, synced, and sometimes shared or pasted into issues. |
| "I need the value to debug the 401" | You need the key name, format prefix, and a live probe result — not the value in the report. |
| "Masking makes the report less complete" | A report that leaks a credential is a worse deliverable than an incomplete one. |

## Red Flags — STOP Before Sending

- Output contains a line matching a provider token prefix (`ghp_`, `npm_`, `sk-`, `AKIA`, ...)
- You are about to `cat` a `.npmrc` / `.env` / auth-state file into the reply
- A PR body, issue, or commit message quotes config file content

Any of these: rewrite with `<REDACTED>` before sending. If a real secret
already reached output, tell the user immediately and recommend rotation.
