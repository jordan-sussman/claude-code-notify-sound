#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUNDS_SRC_DIR="$REPO_DIR/sounds"
SCOPE="global"
UNINSTALL=false

for arg in "$@"; do
  case "$arg" in
    --project) SCOPE="project" ;;
    --uninstall) UNINSTALL=true ;;
    -h|--help)
      echo "Usage: ./install.sh [--project] [--uninstall]"
      echo "  --project    Install into ./.claude/settings.json instead of ~/.claude/settings.json"
      echo "  --uninstall  Remove hooks this tool added"
      exit 0
      ;;
  esac
done

if [ "$SCOPE" = "project" ]; then
  CLAUDE_DIR="$REPO_DIR/.claude"
  SETTINGS_FILE="$CLAUDE_DIR/settings.json"
  SOUNDS_DEST_DIR="$CLAUDE_DIR/sounds"
else
  CLAUDE_DIR="$HOME/.claude"
  SETTINGS_FILE="$CLAUDE_DIR/settings.json"
  SOUNDS_DEST_DIR="$CLAUDE_DIR/sounds"
fi

command -v python3 >/dev/null 2>&1 || { echo "python3 is required. Install it and re-run."; exit 1; }

if [ "$UNINSTALL" = true ]; then
  python3 "$REPO_DIR/scripts/merge_settings.py" --uninstall --settings "$SETTINGS_FILE" --sounds-dir "$SOUNDS_DEST_DIR"
  echo "Removed sound-notify hooks from $SETTINGS_FILE"
  exit 0
fi

mkdir -p "$SOUNDS_DEST_DIR"

# Finds sound file in sounds dir
SRC_SOUND=""
for f in "$SOUNDS_SRC_DIR"/*; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  [ "$base" = "README.md" ] && continue
  SRC_SOUND="$f"
  break
done

if [ -z "$SRC_SOUND" ]; then
  echo "No sound file found in $SOUNDS_SRC_DIR"
  echo "Copy your sound file there first, e.g.:"
  echo "  cp /path/to/notification.m4r $SOUNDS_SRC_DIR/"
  exit 1
fi

FILENAME="$(basename "$SRC_SOUND")"
EXT="${FILENAME##*.}"
OS="$(uname -s)"

DEST_SOUND="$SOUNDS_DEST_DIR/$FILENAME"
cp "$SRC_SOUND" "$DEST_SOUND"

# Picks player command based on OS
if [[ "$OS" == "Darwin" ]]; then
  PLAYER_CMD="afplay \"$DEST_SOUND\""
elif [[ "$OS" == "Linux" ]]; then
  if [[ "$EXT" == "m4r" || "$EXT" == "m4a" ]]; then
    if command -v ffmpeg >/dev/null 2>&1; then
      WAV_DEST="${DEST_SOUND%.*}.wav"
      ffmpeg -y -loglevel error -i "$DEST_SOUND" "$WAV_DEST"
      # Cleans up the original copied file to keep the target folder tidy
      if [[ "$DEST_SOUND" != "$WAV_DEST" && -f "$WAV_DEST" ]]; then
        rm -f "$DEST_SOUND"
      fi
      DEST_SOUND="$WAV_DEST"
    else
      echo "Warning: $EXT files usually don't play with paplay/aplay."
      echo "Install ffmpeg to auto-convert, or provide a .wav/.ogg file instead."
    fi
  fi

  # Supports Windows Subsystem for Linux (WSL) natively
  if grep -q -i microsoft /proc/version 2>/dev/null; then
    if command -v wslpath >/dev/null 2>&1; then
      WIN_PATH="$(wslpath -w "$DEST_SOUND" 2>/dev/null || echo "$DEST_SOUND")"
      WIN_PATH_ESCAPED="${WIN_PATH//\'/\'\'}"
      PLAYER_CMD="powershell.exe -c \"(New-Object Media.SoundPlayer '$WIN_PATH_ESCAPED').PlaySync()\""
    else
      echo "Warning: WSL detected but wslpath command not found. Falling back to Linux audio players."
    fi
  fi

  if [ -z "${PLAYER_CMD:-}" ]; then
    if command -v paplay >/dev/null 2>&1; then
      PLAYER_CMD="paplay \"$DEST_SOUND\""
    elif command -v aplay >/dev/null 2>&1; then
      PLAYER_CMD="aplay -q \"$DEST_SOUND\""
    else
      echo "No paplay or aplay found. Install pulseaudio-utils or alsa-utils."
      exit 1
    fi
  fi
elif [[ "$OS" == MINGW* || "$OS" == MSYS* || "$OS" == CYGWIN* ]]; then
  WIN_PATH="$(cygpath -w "$DEST_SOUND" 2>/dev/null || echo "$DEST_SOUND")"
  PLAYER_CMD="powershell.exe -c (New-Object Media.SoundPlayer '$WIN_PATH').PlaySync()"
else
  echo "Unrecognized OS: $OS. Set the player command manually in $SETTINGS_FILE."
  exit 1
fi

mkdir -p "$CLAUDE_DIR"
python3 "$REPO_DIR/scripts/merge_settings.py" --settings "$SETTINGS_FILE" --command "$PLAYER_CMD" --sounds-dir "$SOUNDS_DEST_DIR"

echo "Done. Sound hook installed in $SETTINGS_FILE"
echo "Player command: $PLAYER_CMD"
echo "Test it by starting a Claude Code session and letting it finish a response."
