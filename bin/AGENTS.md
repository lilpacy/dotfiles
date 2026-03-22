# bin/

Helper scripts managed in dotfiles. All scripts here are on PATH via `common.sh`.

## discord-bd-launch

Launches Discord with BetterDiscord re-installed. Intended to be called from `Discord BD Launcher.app` (`~/Applications/`).

- Quits running Discord, re-applies BetterDiscord via `bdcli`, then reopens Discord
- Uses a lock directory (`$TMPDIR/discord-bd-launch.lock`) to prevent concurrent runs
- Logs to `~/Library/Logs/discord-bd-launch.log`

### Rebuilding the launcher app

```sh
cat > /tmp/discord-bd-launcher.applescript <<'EOF'
set cmd to quoted form of (POSIX path of (path to home folder) & "dotfiles/bin/discord-bd-launch") & " >/dev/null 2>&1 &"
do shell script cmd
EOF
osacompile -o "$HOME/Applications/Discord BD Launcher.app" /tmp/discord-bd-launcher.applescript
rm /tmp/discord-bd-launcher.applescript
```

## aws-sso-remaining

Displays remaining time of AWS SSO token. Used in tmux statusline or shell prompt.

- `aws-sso-remaining` — uses `$AWS_PROFILE`
- `aws-sso-remaining <profile>` — specify profile explicitly
- Outputs `Xh XXm`, `Xm`, `expired`, `not logged in`, or nothing (if no SSO config)

## claude-search

Searches Claude Code conversation history (`~/.claude/projects/**/*.jsonl`) by keyword with fzf preview.

- `claude-search <keyword>` — search and browse matching sessions
- `claude-search -c <keyword>` — copy selected conversation to clipboard
- `-i` / `-s` / `-S` / `-F` — pass-through to ripgrep (case-insensitive, case-sensitive, smart-case, fixed-string)

## claude-skills

Browse and read Claude Code skill files (`~/.claude/skills/*/SKILL.md`) with fzf.

- `claude-skills` — browse and view in less
- `claude-skills -c` — copy selected skill to clipboard

## claude-thinking

Browse Claude Code thinking blocks from conversation history with fzf.

- `claude-thinking` — select project → session → view thinking blocks in less
- `claude-thinking -c` — copy to clipboard

## sssh

Interactive ECS Exec helper (by [yuki777](https://github.com/yuki777)). Walks through cluster → service → task → container selection via peco, then drops into a shell.

- `sssh` — interactive selection with default profile
- `sssh --profile <name> --region <region>` — specify AWS profile/region
- `sssh --command '/bin/bash'` — custom command (default: `/bin/bash`)
- `sssh --port 8080 --local-port 8080` — port forwarding mode
- Requires: `aws`, `session-manager-plugin`, `jq`, `peco`

## tmux-claude-indicator

Shows Claude Code status icon in tmux window-status. Called from `.tmux.conf` via `#(~/dotfiles/bin/tmux-claude-indicator '#{window_id}')`.

- Displays `⏳` (waiting for user) or `🔄` (working)
- Auto-clears stale flags when claude process is no longer running

## tmux-dev

Creates a new tmux session with 4-pane dev layout.

- `tmux-dev [session-name] [directory]` — defaults to `dev` / `$PWD`
- Layout: left-top (60%×70%), left-bottom, right-top, right-bottom
- Attaches to existing session if name matches

## tmux-dev-layout

Splits the **current** tmux window into 4-pane dev layout (bound to `prefix + D` in `.tmux.conf`).

## tmux-dev-layout2

Splits the **current** tmux window into 5-pane layout: top row 3-equal columns, bottom row 6:4 split (bound to `prefix + E` in `.tmux.conf`).

## tmux-save-windows / tmux-restore-windows

Persist and restore tmux window names + working directories across sessions.

- `tmux-save-windows` — save current session's windows to `~/.tmux/window-state-<session>.txt` (shows message)
- `tmux-restore-windows` — restore saved windows (shows message)
- Both support `--auto` flag for hook-driven use (silent, with guard flags to prevent loops)
- Auto-save hooks: `window-renamed`, `window-unlinked`, `client-detached`
- Auto-restore hook: `session-created`
