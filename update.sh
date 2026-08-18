#!/bin/bash

# Miyagi Shell Update Script

CONFIG_FILE=".update_policy"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

# Parse arguments
FORCE_CHECK=false
FORCE_UPDATE=false

for arg in "$@"; do
    if [ "$arg" == "--no-update" ]; then
        exit 0
    fi
    if [ "$arg" == "--check-update" ]; then
        FORCE_CHECK=true
    fi
    if [ "$arg" == "--force-update" ]; then
        FORCE_CHECK=true
        FORCE_UPDATE=true
    fi
done

# Load Config
POLICY="ASK"
LAST_CHECK=0

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Function to save config
save_config() {
    echo "POLICY=\"$POLICY\"" > "$CONFIG_FILE"
    echo "LAST_CHECK=\"$LAST_CHECK\"" >> "$CONFIG_FILE"
}

# Function to perform update
do_update() {
    echo "Updating Miyagi Shell..."

    if git pull; then
        # Ensure scripts are executable
        chmod +x start.sh update.sh install.sh 2>/dev/null || true

        # Ensure symlink is intact
        QUICKSHELL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/miyagi"
        if [ "$REPO_DIR" != "$QUICKSHELL_DIR" ]; then
            mkdir -p "$(dirname "$QUICKSHELL_DIR")"
            ln -sfn "$REPO_DIR" "$QUICKSHELL_DIR"
        fi

        echo "Miyagi Shell update complete."
    else
        echo "Update failed. Please check git status."
        exit 1
    fi
}

if [ "$FORCE_UPDATE" == "true" ]; then
    do_update
    exit 0
fi

# Check Policy: DISABLE
if [ "$POLICY" == "DISABLE" ]; then
    exit 0
fi

# Check if inside git repo
if [ ! -d ".git" ]; then
    # Not a git repo, skip
    exit 0
fi

# Check Time Frequency (Default: 24h = 86400s)
NOW=$(date +%s)
TIME_DIFF=$((NOW - LAST_CHECK))

if [ "$POLICY" == "REMIND_LATER" ]; then
    # Remind in 1 week (604800s)
    if [ "$FORCE_CHECK" == "false" ] && [ "$TIME_DIFF" -lt 604800 ]; then
        exit 0
    fi
elif [ "$FORCE_CHECK" == "false" ] && [ "$TIME_DIFF" -lt 86400 ]; then
    # Less than 24 hours since last check
    exit 0
fi

# Update Check timestamp
LAST_CHECK=$NOW
save_config

# Check Internet
if ! ping -c 1 github.com &>/dev/null; then
    exit 0
fi

# Check for updates
echo "Checking for updates..."
if ! git fetch origin >/dev/null 2>&1; then
    exit 0
fi

LOCAL=$(git rev-parse HEAD 2>/dev/null)
REMOTE=$(git rev-parse @{u} 2>/dev/null)

if [ -z "$LOCAL" ] || [ -z "$REMOTE" ]; then
    exit 0
fi

if [ "$LOCAL" == "$REMOTE" ]; then
    exit 0
fi

# New version available

# Check Policy: AUTO
if [ "$POLICY" == "AUTO" ]; then
    do_update
    exit 0
fi

# Interactive Prompt
echo ""
echo "A new version of Miyagi Shell is available!"
echo "What would you like to do?"
echo "  [u] Update now"
echo "  [s] Skip this time"
echo "  [d] Disable update checks"
echo "  [r] Remind me in 1 week"
echo "  [a] Enable auto-updates"
echo ""
read -p "Select an option [u/s/d/r/a]: " choice

case "$choice" in
    u|U)
        do_update
        ;;
    s|S)
        echo "Skipping update."
        ;;
    d|D)
        POLICY="DISABLE"
        save_config
        echo "Update checks disabled."
        ;;
    r|R)
        POLICY="REMIND_LATER"
        LAST_CHECK=$(date +%s)
        save_config
        echo "Will remind you in 1 week."
        ;;
    a|A)
        POLICY="AUTO"
        save_config
        do_update
        ;;
    *)
        echo "Invalid option. Skipping update."
        ;;
esac
