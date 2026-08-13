---
name: macos-app-uninstall
description: Safely and completely uninstall a named macOS app by resolving its bundle identity, enumerating app-owned state, removing permissions and registrations, and verifying no active remnants remain.
---

# macOS App Uninstall

Use when a user asks to completely uninstall a macOS application, including its local support files.

## Procedure

1. Resolve the exact `.app` path and read `CFBundleIdentifier` from `Contents/Info.plist`. Do not delete by app-name glob alone.
2. Check exact-name processes, login items, launch agents/daemons, package receipts, and Homebrew cask ownership.
3. Enumerate app-owned paths using both the app name and bundle ID under:
   - `/Applications` and `~/Applications`
   - `~/Library/{Application Support,Caches,Preferences,Logs,Saved Application State,HTTPStorages,Containers,Group Containers,LaunchAgents}`
   - `/Library/{Application Support,Caches,Preferences,Logs,LaunchAgents,LaunchDaemons}`
   - `DARWIN_USER_TEMP_DIR` and `DARWIN_USER_CACHE_DIR`
4. Check likely Keychain service names with `security find-generic-password` without `-w`. Never print password/token values.
5. Before moving the app, unregister it with `lsregister -u`, reset privacy grants with `tccutil reset All <bundle-id>`, and delete its defaults domain.
6. Remove only the verified exact paths. Prefer a dedicated folder in `~/.Trash` when direct deletion is unsafe or blocked; never empty unrelated Trash contents.
7. Recheck every original path, exact executable names, login items, and launch services.

## Important distinction

An app-name match in a process command may be an independent integration, not an app remnant. Inspect its parent executable and configuration origin before stopping or deleting it. For process checks, display only PID, parent PID, and executable identity; command lines can contain bearer tokens or other secrets.

## Completion report

State what was removed, whether permissions were reset, verification status, and whether a dedicated Trash staging folder remains for recoverability. Report independent integrations separately and do not remove them without scope confirmation.
