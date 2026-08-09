# Herdr/tmux migration progress

Updated: 2026-07-12

## Current evidence

- Herdr installed locally: `herdr 0.7.3`.
- Default Herdr config exposes:
  - `prefix = "ctrl+b"`
  - `workspace_picker = "prefix+w"`
  - `previous_workspace` / `next_workspace`
  - `switch_workspace = ""` with documented `prefix+shift+1..9` example
  - `new_tab = "prefix+c"`
  - `previous_tab = "prefix+p"`
  - `switch_tab = "prefix+1..9"`
  - `focus_pane_h/j/k/l`, `split_vertical`, `split_horizontal`, `zoom`, `resize_mode`, `toggle_sidebar`
  - `[[keys.command]]` with `type = "pane"` for temporary panes.
- Current `~/.config/herdr/config.toml` only contains:
  - `onboarding = false`
  - `[ui] agent_panel_sort = "spaces"`
- `herdr workspace list` and `herdr api snapshot` expose workspace `number`, `label`, `workspace_id`, focus state, `worktree.checkout_path`, tab data, pane `cwd`, and pane `foreground_cwd`.
- Current Ghostty config has no command/entrypoint marker. Current `.zshrc` auto-attaches tmux unless disabled.
- Existing `herdrp`, `herdrw`, `herdr-layout-dev`, and `herdr-layout-dev-wide` were created under the earlier wrong premise and do not need compatibility preservation.

## Decisions

- Main workspace overview UI: Herdr sidebar as the always-available overview, plus `prefix+w` workspace picker for jump/search and `prefix+shift+1..9` for indexed switching.
- tmux window equivalent: Herdr workspace, one project directory per workspace.
- tmux pane layout equivalent: tabs and panes inside each workspace. `prefix+c` creates a new tab in the current workspace, because that is Herdr's native default and preserves the current cwd working unit without overloading workspace creation.
- Split key mapping:
  - tmux `prefix+"` is vertical stacking, so map to Herdr `split_horizontal = "prefix+\""`.
  - tmux `prefix+%` is side-by-side, so map to Herdr `split_vertical = "prefix+%"`.
  - Herdr 0.7.3 accepted both literal punctuation bindings during config parse validation.
- Resize mapping: use Herdr `resize_mode = "prefix+r"` as the reliable primary path. Direct `prefix+shift+h/j/k/l` resize actions are not exposed in the default config key list, so do not invent unsupported action names.
- Popup replacements: use `[[keys.command]] type = "pane"` temporary panes for shell/lazygit/lazysql/nvim/top/fzf workflows. Because Herdr docs do not guarantee pane-type command cwd, each command must explicitly `cd` to `${HERDR_ACTIVE_PANE_CWD:-$PWD}` before launching the helper.
- Popup key conflicts: move or unset the built-ins that conflict with tmux muscle memory:
  - `goto = ""` so `prefix+g` can be lazygit.
  - `settings = "prefix+comma"` so `prefix+s` can be lazysql.
  - `rename_pane = ""` so `prefix+shift+p` can be the popup shell replacement.
- Session restore:
  - Keep Herdr native snapshot restore as primary.
  - Add explicit helper-managed workspace history containing `session`, `saved_at`, `active_workspace_path`, and workspace entries with `label` and canonical `path`.
  - Do not save pane screen history or command replay.
  - Do not change `resume_agents_on_restore`.
- Ghostty entry:
  - Add `env = HERDR_AUTO_ENTRY=1` to Ghostty config.
  - Keep Ghostty launching the normal login shell; do not wrap `command` in `/usr/bin/env`, because Ghostty's `command` with arguments is shell-wrapped and can interfere with shell integration detection.
  - `.zshrc` enters Herdr only when `HERDR_AUTO_ENTRY=1` and all guards pass.
  - Unset `HERDR_AUTO_ENTRY` before `exec herdrp` so Herdr child shells do not recursively attach.
- `ghq + peco`: when inside Herdr, make selection call `herdrw open <path>` instead of `cd <path>`. Outside Herdr keep the existing `cd` behavior.
- History save timing: save after `herdrw open` and `herdrw restore`; provide explicit `herdrw save`. Do not hook detach yet because Herdr exposes no direct detach hook in observed CLI/config.

## Implementation plan

1. Add dotfiles-managed Herdr config at `.config/herdr/config.toml`.
2. Update `link.sh` to create `~/.config/herdr` and symlink the Herdr config.
3. Replace `.zshrc` tmux auto-attach with guarded Herdr auto-entry: keep the existing Conductor/tmux protections, and newly add Codex/SSH/Herdr-pane guards from the requirements.
4. Add Ghostty top-level marker with Ghostty's `env = HERDR_AUTO_ENTRY=1`.
5. Replace `bin/herdrw` with subcommands:
   - `herdrw list`
   - `herdrw open [path]`
   - `herdrw save`
   - `herdrw restore`
   - plus `--session NAME`.
6. Keep `bin/herdrp` as the safe shared-session entrypoint, but call `herdrw open` explicitly.
7. Remove or stop linking obsolete layout helpers unless a later measured need returns.
8. Update `bin/AGENTS.md` to match the new helper contract.
9. Validate with shell syntax checks, Herdr config reload, keybinding parse checks, helper dry runs against a temporary Herdr session, guarded zsh entry checks, and requirement-by-requirement audit.

## Deferred tmux-specific behavior

- tmux copy-mode vi keymap and `pbcopy`: not recreated. Use Herdr `edit_scrollback = "prefix+e"` plus terminal/editor copy flows. Pane history replay stays disabled for security.
- Mouse drag copy: not recreated in Herdr config. Keep terminal-native selection behavior where possible; Herdr mouse UI remains enabled for normal pane/sidebar interaction.
- Right-click custom pane menu: not recreated. Herdr's built-in pane UI/menu is the replacement; custom tmux menu actions are outside the migration goal.
- Focus-follows-mouse: no explicit Herdr config equivalent was found in the observed default config, so keyboard focus bindings and normal mouse UI are the replacement.
- Image passthrough: not mapped. No requirement depends on reproducing tmux passthrough, and Herdr's default config only exposes remote image paste for remote attach.
- tmux statusline colors/time: not recreated. Herdr sidebar/picker/indexed switching replace the window-list role; statusline cosmetics are not a goal.
- tmux window save/restore hooks: replaced by Herdr native snapshot restore plus explicit `herdrw save`/`restore`. No documented detach hook was found.
- `tmux-dev-layout` / `tmux-dev-layout2` equivalents: old Herdr layout helpers were removed because they encoded the wrong tmux-compatibility goal. Herdr tabs/panes and native splits are the replacement unless a measured need returns.

## Review log

- Fable plan review completed. Critical fixes applied:
  - Avoid built-in/custom key conflicts for `prefix+g`, `prefix+s`, and `prefix+shift+p`.
  - Use Ghostty `env = HERDR_AUTO_ENTRY=1` instead of wrapping `command` with `env`.
  - Do not rely on undocumented `type = "pane"` cwd; explicitly `cd` via `HERDR_ACTIVE_PANE_CWD`.
- Codex plan review completed. Critical fix applied:
  - Clarified that Codex/SSH/Herdr guards must be newly added, not merely preserved.

## Validation log

- `bash -n bin/herdrw bin/herdrp link.sh` passed.
- `zsh -n .zshrc` passed.
- `shellcheck bin/herdrw bin/herdrp link.sh` passed.
- Herdr 0.7.3 accepted `.config/herdr/config.toml` by starting a temporary `codex-herdr-migration-check` session.
- `herdrw --session codex-herdr-migration-check open/list/save/restore` passed against a temporary Herdr session.
- Saved history contained `session`, `active_workspace_path`, and workspace `label`/canonical `path`.
- Restore from a history containing `/no/such/herdr/path` skipped the missing directory and restored only `/Users/lilpacy/dotfiles`.
- `.zshrc` guard tests passed for Codex, SSH, and existing Herdr-pane env; `HERDR_AUTO_ENTRY` was unset and Herdr was not entered.
- `.zshrc` positive auto-entry path passed with a stub `herdrp` in a temporary `ZDOTDIR`.
- `~/.config/herdr/config.toml` now symlinks to `/Users/lilpacy/dotfiles/.config/herdr/config.toml`.
- `herdr server reload-config` returned `status: applied` with no diagnostics for the running Herdr server.
- `command -v herdrw` and `command -v herdrp` resolve to `/Users/lilpacy/dotfiles/bin/...`; `herdrw list` shows the current `dotfiles` workspace.
