---
name: secure-private-repo-publish
description: Safely turn a local source directory or release archive into a new private GitHub repository, with secret scanning before commit and across Git history, privacy-preserving commit metadata, release-archive verification, and post-push visibility checks.
---

# Secure Private Repository Publish

Use this procedure when publishing local source or a release archive to a newly created private GitHub repository.

## Preconditions

- Confirm the intended owner and repository name.
- Verify GitHub CLI authentication and that the target repository does not already exist.
- Resolve the local destination and confirm it is absent before extracting an archive.
- Inspect archive entries for absolute paths, parent traversal, and symlinks before extraction.
- Use the Homebrew-installed `gitleaks` executable explicitly when another installation shadows it on `PATH`.

## Secret and privacy checks

1. Run `gitleaks dir` with `--redact=100` before Git initialization.
2. Keep reports outside the repository and do not print secret values. Print only redacted rule and location metadata if findings exist.
3. Search separately for personal absolute paths, account names, and suspicious credential assignments that secret scanners may not classify.
4. Use a repository-local GitHub noreply email instead of a personal global Git email.
5. Stop before commit or push if any unresolved finding exists.

## Verification and commit

1. Run the package's manifest check, syntax checks, and tests before committing.
2. Inspect `git status`, the staged diff, and `git diff --cached --check`.
3. Commit only intended files.
4. Run `gitleaks git` after committing so every commit in the history is scanned.
5. For a non-trivial package, complete the configured read-only review before publishing.

## Release archives

- Build a release archive from tracked `HEAD` files with `git archive`; never archive the working directory with `.git` or local untracked files.
- Extract the generated archive into a new temporary directory.
- Re-run manifest verification, tests, and `gitleaks dir` against the extracted artifact.
- Replace the distributable archive only after the independent extraction checks pass.

## Private repository creation

- Create the remote only after every local check passes.
- Use `gh repo create OWNER/REPO --private --source=. --remote=origin --push`.
- Verify both `visibility=PRIVATE` and `private=true` through GitHub CLI/API output.
- Compare local `HEAD` with `refs/heads/main` from the remote.
- Confirm the working tree is clean and the branch tracks the expected remote.

## Failure handling

- If GitHub creation succeeds but push fails, do not create a second repository; repair the existing remote and retry the push.
- If a review identifies a real safety defect, fix it with a failing regression test first, rerun all security checks, commit, and review again.
- Treat advisory boundaries explicitly chosen by the user as design constraints, but do not dismiss independent data-loss or secret-exposure paths.
