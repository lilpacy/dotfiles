---
name: install-cli-without-system-changes
description: Install third-party CLI tools without sudo, system package changes, or global language-package installs. Use when an installer recommends a system mode or global npm/pip operation, when pipx's shared Python is broken, or when tools must remain in dedicated user-owned directories.
---

# Install CLI Without System Changes

Keep the requested tool usable while preserving the user's system and unrelated package-manager state.

## Workflow

1. Read the official installation guide and inspect the installer's implementation when its flags are broader than their names imply.
2. Run only read-only preflight checks: OS/architecture, executable paths, versions, existing target directories, package metadata, and documented dry-run/check modes.
3. Stop before `sudo`, OS package-manager writes, global language-package installs, shell-profile edits, or writes outside the documented user scope unless the user explicitly approves them.
4. Use the first healthy option:
   - existing user-scoped package manager;
   - dedicated venv from an already-installed Python version supported by the package;
   - local Node install with `npm install --prefix <app-tools-dir> <package>`;
   - a tiny launcher in an existing user `PATH` directory when the tool needs its private environment first.
5. Never run an upstream `--system` mode when it bundles disallowed operations. Reproduce only the necessary, explicitly scoped user-level actions.
6. Do not let third-party installers write agent skill roots directly. Use the environment's guarded skill manager.
7. Validate with executable versions, the tool's read-only doctor/check command, and one harmless live request when configuration alone cannot prove connectivity.

## Broken pipx recovery

If pipx fails while importing `pip`, `pyexpat`, or another shared-runtime module:

1. Confirm no partial target environment remains.
2. Test the installed Python variants individually, including the failing import.
3. Choose a healthy version that satisfies the package's declared `requires-python` range.
4. Create a dedicated venv for the requested tool. Do not repair or reinstall unrelated pipx environments unless the user asks.

Keep application files under its dedicated user directory, temporary files under `/tmp`, and the active workspace untouched.
