# claude-code-notify-sound

Play a sound when [Claude Code](https://docs.claude.com/en/docs/claude-code) finishes responding or needs your input, using Claude Code [hooks](https://docs.claude.com/en/docs/claude-code/hooks).

## Setup

1. Drop a sound file into `sounds/` (IE: `notification.wav`) or use existing (`notification.m4r`)
2. Run:

```bash
./install.sh
```

Use `--project` to install into `./.claude/settings.json` (this repo only) instead of `~/.claude/settings.json` (global).

## What it does

- Copies your sound to `~/.claude/sounds/`
- Detects your OS and picks a player: `afplay` (macOS), `paplay`/`aplay` (Linux), PowerShell `SoundPlayer` (Windows/WSL)
- Adds `Stop` and `Notification` hooks to your settings.json, merging safely without touching existing hooks or settings
- Re-running updates the hook

## File formats

- **macOS**: any format `afplay` supports, including `.m4r` (default sound file)
- **Linux**: use `.wav` or `.ogg`. `.m4r`/`.m4a` are auto-converted to `.wav` via `ffmpeg` if installed
- **Windows/WSL**: `.wav`
- Avoid `.mp3` — not reliably supported by any of the above

`.wav` is the safest cross-platform choice if you want the repo to work for others with zero extra dependencies.

## Sample sound attribution

Sample notification sound sourced from [notificationsounds.com](https://notificationsounds.com/notification-sounds/elegant-notification-sound), licensed under [CC Attribution](https://notificationsounds.com/terms-of-use#copyright).

## Uninstall
Removes only the hooks this tool added.

```bash
./install.sh --uninstall
```
