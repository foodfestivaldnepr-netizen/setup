#!/bin/bash
# Install Print Manager — GTK4 GUI for managing print jobs

set -e

INSTALL_DIR="$HOME"
SCRIPT_URL="https://foodfestivaldnepr-netizen.github.io/setup/files/print-manager.py"
DESKTOP_FILE="$HOME/.local/share/applications/print-manager.desktop"

echo "==> Installing packages..."
if command -v pacman &>/dev/null; then
    sudo pacman -S --needed --noconfirm python-gobject cups ghostscript
elif command -v apt &>/dev/null; then
    sudo apt-get install -y python3-gi gir1.2-gtk-4.0 cups ghostscript
fi

echo "==> Downloading print-manager.py..."
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/print-manager.py"
chmod +x "$INSTALL_DIR/print-manager.py"

echo "==> Creating .desktop entry..."
mkdir -p "$(dirname "$DESKTOP_FILE")"
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Print Manager
Comment=Manage print jobs
Exec=python3 $INSTALL_DIR/print-manager.py
Icon=printer
Type=Application
Categories=System;
EOF

echo "✓ Print Manager installed at $INSTALL_DIR/print-manager.py"
