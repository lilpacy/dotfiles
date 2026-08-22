---
name: cloudwatch-multiline-log-correlation
description: Diagnose AWS CloudWatch Logs when Node.js console object output is split across multiple log events. Use when an event-name search finds only the first line, structured fields appear missing, or job/result/decision fields must be correlated safely within one ECS or Lambda log stream.
compatibility: Requires AWS CLI access to the target account and jq for compact output.
---

# CloudWatch Multiline Log Correlation

Use this workflow for read-only diagnosis. Never print cloud credential files, secret values, raw payloads, request bodies, cookies, tokens, or unrestricted application logs.

## Workflow

1. Resolve the configured region without exposing credentials:

   ```bash
   aws configure get region --profile <profile>
   ```

2. Identify the exact log group with `describe-log-groups`. Narrow by an application or workload prefix when possible.

3. Search a small time window for the stable event name. Quote the term in the CloudWatch filter pattern:

   ```bash
   aws logs filter-log-events \
     --profile <profile> \
     --log-group-name '<log-group>' \
     --filter-pattern '"<event-name>"' \
     --start-time <epoch-ms> \
     --limit 100 \
     --output json \
   | jq -r '.events[] | [.timestamp, .logStreamName, .message] | @tsv'
   ```

4. Treat the matching event as an index, not the complete record. Node.js `console.info({ ... })` may be stored as one CloudWatch event per rendered line.

5. Fetch the complete matching stream and correlate fields from that stream only:

   ```bash
   aws logs get-log-events \
     --profile <profile> \
     --log-group-name '<log-group>' \
     --log-stream-name '<stream>' \
     --start-from-head \
     --output json \
   | jq -r '.events[].message'
   ```

6. Report only the allowlisted diagnostic fields needed for the conclusion, such as timestamp, job ID, result code, decision reason, status, score, and candidate count. Redact or omit business values and identifiers not required by the user.

## Pagination trap

`filter-log-events` may return an empty page with a `nextToken`, especially over a wide time range. Do not infer that no logs exist from one empty page. Prefer a narrow time window; otherwise follow pagination or use recent log streams ordered by `LastEventTime`, then inspect the selected stream.

## Completion check

- The event name, job/result fields, and decision fields came from the same log stream.
- The time range and timezone are explicit.
- No credentials, secrets, raw payloads, or unnecessary business data appear in the report.
- Missing fields are reported as unavailable, not guessed from neighboring streams.
