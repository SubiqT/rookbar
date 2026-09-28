#!/usr/bin/env bash
# Replaces a running jaybar with rookbar, keeping jaybar's launch agent so restore-jaybar.sh can undo it.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
agents="$HOME/Library/LaunchAgents"
domain="gui/$(id -u)"

make -C "$root" install

if [[ -f "$agents/com.jaybar.plist" ]]; then
    launchctl bootout "$domain/com.jaybar" 2>/dev/null || true
    mv "$agents/com.jaybar.plist" "$agents/com.jaybar.plist.disabled"
fi
pkill -x jaybar 2>/dev/null || true

if command -v yabai >/dev/null; then
    yabai -m signal --list 2>/dev/null \
        | grep -o '"label":"jaybar_[a-z_]*"' | cut -d'"' -f4 \
        | while read -r label; do yabai -m signal --remove "$label" || true; done
fi

/Applications/rookbar.app/Contents/MacOS/rookbar --enable-service
