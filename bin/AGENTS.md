# bin/

Helper scripts managed in dotfiles. All scripts here are on PATH via `common.sh`.

## discord-bd-launch

Launches Discord with BetterDiscord re-installed. Intended to be called from the `Discord BD Launcher.app` (`~/Applications/`).

- Quits running Discord, re-applies BetterDiscord via `bdcli`, then reopens Discord
- Uses a lock directory (`$TMPDIR/discord-bd-launch.lock`) to prevent concurrent runs
- Logs to `~/Library/Logs/discord-bd-launch.log`

### Rebuilding the launcher app

If the script path changes, rebuild the AppleScript wrapper:

```sh
cat > /tmp/discord-bd-launcher.applescript <<'EOF'
set cmd to quoted form of (POSIX path of (path to home folder) & "dotfiles/bin/discord-bd-launch") & " >/dev/null 2>&1 &"
do shell script cmd
EOF
osacompile -o "$HOME/Applications/Discord BD Launcher.app" /tmp/discord-bd-launcher.applescript
rm /tmp/discord-bd-launcher.applescript
```
