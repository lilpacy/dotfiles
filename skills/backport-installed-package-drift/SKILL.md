---
name: backport-installed-package-drift
description: Compare an installed package, its release archive, and its source repository; distinguish source drift from runtime state; and backport verified installed-only fixes. Use when installed files or a ZIP were edited directly, or when the repository may be stale.
---

# Backport Installed Package Drift

1. Read the installer to map repository files to deployed paths. Exclude generated configuration, registries, fetched vendor data, caches, and user content.
2. Fetch the current repository HEAD and compare hashes across repository, release archive, and installed static files.
3. Classify each difference:
   - installed = archive != repository: candidate release change missing from the repository;
   - installed != archive = repository: unrecorded live edit;
   - all differ: inspect provenance before editing.
4. Confirm intent from timestamps, history, and the actual call path. Never print secrets found in local state.
5. Backport with TDD: add the smallest regression check, confirm Red, apply the minimal source fix, confirm Green, then update manifests.
6. Verify archive equivalence, checksums, syntax, relevant tests, and secret scans.
7. Commit and review with the repository's normal workflows, then push only after confirming the remote has not advanced.

Keep the repository as the source of truth afterward. Modify the repository first, redeploy from it, and generate archives from the committed tree; do not maintain installed files or ZIPs as parallel sources.
