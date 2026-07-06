#!/bin/bash
LABEL="com.ruslan.audioinputfixer"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
BINARY="$HOME/.local/bin/audio-input-fixer"

launchctl unload "$PLIST" 2>/dev/null || true
rm -f "$PLIST" "$BINARY"
echo "AudioInputFixer uninstalled."
