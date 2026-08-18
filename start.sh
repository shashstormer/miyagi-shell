#!/bin/bash

# Miyagi Shell Startup Script

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "Starting Miyagi Shell from $DIR..."

# Check for updates
if [ -f "$DIR/update.sh" ]; then
    "$DIR/update.sh" "$@"
fi

# Launch quickshell
QT_NO_XDG_DESKTOP_PORTAL=1 exec quickshell -p "$DIR" "$@"
