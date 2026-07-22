# claude-code-notify-sound

Play a notification sound when [Claude Code](https://docs.claude.com/en/docs/claude-code) finishes responding or needs your input, using Claude Code [hooks](https://docs.claude.com/en/docs/claude-code/hooks).

## Setup

1. Optional: Drop a sound file into `sounds` folder. If omitted, the default `notification.m4r` sound will be used.
2. Run:

```bash
./install.sh
```

Use `--project` to install into `./.claude/settings.json` (this repo only) instead of `~/.claude/settings.json` (global).

## What it does

- Copies your sound to `~/.claude/sounds/`
- Detects your OS and picks a player type
- Adds `Stop` and `Notification` hooks to your settings.json without touching existing hooks or settings
- Supports updating the hook through reruns

## File formats

- **macOS**: any format `afplay` supports, including `.m4r` (default sound file)
- **Linux**: use `.wav` or `.ogg`. `.m4r`/`.m4a` are auto-converted to `.wav` via `ffmpeg` if installed
- **Windows/WSL**: `.wav`

## Sample sound attribution

Sample notification sound sourced from [notificationsounds.com](https://notificationsounds.com/notification-sounds), licensed under [CC Attribution](https://notificationsounds.com/terms-of-use#copyright).

## Uninstall
Remove only the hooks this tool added:

```bash
./install.sh --uninstall
```
