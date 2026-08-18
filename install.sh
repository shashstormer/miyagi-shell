#!/bin/bash

# Miyagi Shell Installation Script (Arch Linux)

set -e

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_LIKE=${ID_LIKE:-""}
else
    echo "Cannot detect OS. Miyagi Shell is designed for Arch Linux."
    exit 1
fi

# Check for Arch Linux
if [ "$OS" != "arch" ] && [[ ! "$OS_LIKE" =~ "arch" ]] && [ "$OS" != "archcraft" ] && [ "$OS" != "endeavouros" ] && [ "$OS" != "manjaro" ] && [ "$OS" != "cachyos" ]; then
    echo "Unsupported OS ($OS). Miyagi Shell currently supports Arch Linux."
    exit 1
fi

# Check for Git and Curl
MISSING_PKGS=""
if ! command -v git &>/dev/null; then
    MISSING_PKGS="$MISSING_PKGS git"
fi
if ! command -v curl &>/dev/null; then
    MISSING_PKGS="$MISSING_PKGS curl"
fi

if [ -n "$MISSING_PKGS" ]; then
    echo "Required packages missing:$MISSING_PKGS. Attempting to install..."
    SUDO=""
    if command -v sudo &>/dev/null; then
        SUDO="sudo"
    elif [ "$EUID" -ne 0 ]; then
        echo "Root privileges required for installation and sudo not found."
        exit 1
    fi
    $SUDO pacman -Sy --noconfirm $MISSING_PKGS
fi

# Repo Logic
REPO_URL="https://github.com/shashstormer/miyagi-shell"
INSTALL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/stormapps/miyagi-shell"
QUICKSHELL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/miyagi"
TARGET_DIR=""

if [ -f "shell.qml" ]; then
    echo "Running inside repository."
    TARGET_DIR=$(pwd)
else
    echo "Installing to $INSTALL_DIR..."
    mkdir -p "$(dirname "$INSTALL_DIR")"

    if [ -d "$INSTALL_DIR" ]; then
        echo "Directory exists. Updating..."
        cd "$INSTALL_DIR"
        git pull
    else
        git clone "$REPO_URL" "$INSTALL_DIR"
        cd "$INSTALL_DIR"
    fi
    TARGET_DIR="$INSTALL_DIR"
fi

# Create symlink in quickshell directory if target is different
if [ "$TARGET_DIR" != "$QUICKSHELL_DIR" ]; then
    echo "Setting up Quickshell configuration symlink..."
    mkdir -p "$(dirname "$QUICKSHELL_DIR")"
    if [ -d "$QUICKSHELL_DIR" ] && [ ! -L "$QUICKSHELL_DIR" ]; then
        echo "Note: $QUICKSHELL_DIR exists as a directory. Backing up to ${QUICKSHELL_DIR}.bak"
        mv "$QUICKSHELL_DIR" "${QUICKSHELL_DIR}.bak"
    fi
    ln -sfn "$TARGET_DIR" "$QUICKSHELL_DIR"
    echo "Symlinked $TARGET_DIR -> $QUICKSHELL_DIR"
fi

# Make scripts in TARGET_DIR executable
chmod +x "$TARGET_DIR/start.sh" "$TARGET_DIR/update.sh" "$TARGET_DIR/install.sh" 2>/dev/null || true

# Install Dependencies / Services
echo ""
echo "========================================"
echo " Installing Miyagi Service... "
echo "========================================"
bash <(curl -fsSL https://raw.githubusercontent.com/shashstormer/miyagi-service/master/install.sh)

echo ""
echo "========================================"
echo " Installing ArchBoard... "
echo "========================================"
bash <(curl -fsSL https://raw.githubusercontent.com/shashstormer/arch-board/master/install.sh)

echo ""
echo "========================================"
echo "   Miyagi Shell install complete!       "
echo "========================================"
echo "Location: $TARGET_DIR"
echo "Quickshell Link: $QUICKSHELL_DIR"
echo ""
echo "You can start the shell with:"
echo "  $TARGET_DIR/start.sh"
echo "Or via Quickshell:"
echo "  quickshell -p $QUICKSHELL_DIR"
