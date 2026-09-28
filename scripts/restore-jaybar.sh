#!/usr/bin/env bash
# Undoes replace-jaybar.sh: stops rookbar and re-enables jaybar's launch agent.
set -euo pipefail

agents="$HOME/Library/LaunchAgents"
domain="gui/$(id -u)"

if [[ -x /Applications/rookbar.app/Contents/MacOS/rookbar ]]; then
    /Applications/rookbar.app/Contents/MacOS/rookbar --disable-service
fi

if [[ -f "$agents/com.jaybar.plist.disabled" ]]; then
    mv "$agents/com.jaybar.plist.disabled" "$agents/com.jaybar.plist"
fi
launchctl bootstrap "$domain" "$agents/com.jaybar.plist"
echo "jaybar service restored"
