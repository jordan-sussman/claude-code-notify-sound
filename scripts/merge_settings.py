#!/usr/bin/env python3
import argparse
import json
import os
import sys

EVENTS = ["Stop", "Notification"]


def get_path_variants(sounds_dir):
    variants = {sounds_dir}

    # Normalizes directory separators
    norm = os.path.normpath(sounds_dir)
    variants.add(norm)
    variants.add(norm.replace(os.sep, "/"))
    variants.add(norm.replace(os.sep, "\\"))

    # Adds tilde-contracted version if sounds_dir resides inside the user home directory
    home = os.path.expanduser("~")
    if home:
        norm_home = os.path.normpath(home)
        if norm.startswith(norm_home):
            contracted = "~" + norm[len(norm_home) :]
            variants.add(contracted)
            variants.add(contracted.replace(os.sep, "/"))
            variants.add(contracted.replace(os.sep, "\\"))

    return [v for v in variants if v]


def is_our_hook(hook_entry, sounds_dir):
    if not isinstance(hook_entry, dict):
        return False
    variants = get_path_variants(sounds_dir)
    for h in hook_entry.get("hooks", []):
        cmd = h.get("command", "")
        if any(v in cmd for v in variants):
            return True
    return False


def load_settings(path):
    if not os.path.exists(path):
        return {}
    try:
        with open(path, "r") as f:
            content = f.read().strip()
            if not content:
                return {}
            return json.loads(content)
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse JSON in settings file: {path}")
        print(f"Details: {e}")
        print("Please resolve the syntax error and try again.")
        sys.exit(1)


def save_settings(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def add_hooks(settings, command, sounds_dir):
    hooks = settings.setdefault("hooks", {})
    for event in EVENTS:
        event_hooks = hooks.setdefault(event, [])

        event_hooks[:] = [h for h in event_hooks if not is_our_hook(h, sounds_dir)]

        event_hooks.append(
            {"matcher": "", "hooks": [{"type": "command", "command": command}]}
        )
    return settings


def remove_hooks(settings, sounds_dir):
    hooks = settings.get("hooks", {})
    for event in EVENTS:
        if event in hooks:
            hooks[event] = [h for h in hooks[event] if not is_our_hook(h, sounds_dir)]
            if not hooks[event]:
                del hooks[event]
    if "hooks" in settings and not settings["hooks"]:
        del settings["hooks"]
    return settings


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--settings", required=True, help="Path to settings.json")
    parser.add_argument("--command", help="Shell command to play the sound")
    parser.add_argument(
        "--sounds-dir",
        required=True,
        help="Path to the sounds directory, used to identify our hooks",
    )
    parser.add_argument("--uninstall", action="store_true")
    args = parser.parse_args()

    settings = load_settings(args.settings)

    if args.uninstall:
        settings = remove_hooks(settings, args.sounds_dir)
    else:
        if not args.command:
            parser.error("--command is required unless --uninstall is set")
        settings = add_hooks(settings, args.command, args.sounds_dir)

    save_settings(args.settings, settings)


if __name__ == "__main__":
    main()
