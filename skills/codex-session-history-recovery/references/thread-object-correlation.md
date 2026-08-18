# Thread and object correlation

## Failure pattern

A request to reuse an artifact from “this thread” can match a newer artifact in another Codex session. Sorting all sessions by timestamp may recover valid content for the wrong PR, issue, branch, or file and can cause a cross-object write.

## Required correlation

Before reusing or publishing recovered content:

1. Resolve the target object from the current thread first: repository, PR or issue number, branch, URL, file, and the user’s demonstratives such as “this PR.”
2. Search the current session before searching other sessions.
3. Require the recovered artifact to share at least one stable target identifier with the current request and corroborate it with another item, such as the surrounding user request or assistant completion.
4. Rank candidates by target identity and semantic match. Use timestamps only to break ties between already-matching candidates.
5. If candidates point to different target objects, stop and ask which one the user means.
6. Before an external write, preview the destination and artifact together, then re-read the created content from that destination.

## Anti-pattern

Do not interpret “most recent matching output” as “the output from this conversation.” Recency proves order, not identity.
