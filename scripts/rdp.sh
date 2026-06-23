#!/bin/bash
# Install RDP Connect — xfreerdp3 launcher with GTK3 layer-shell tray

set -e

INSTALL_DIR="$HOME/Work"
SCRIPT_URL="https://foodfestivaldnepr-netizen.github.io/setup/files/rdp_connect.py"
DESKTOP_FILE="$HOME/.local/share/applications/rdp-connect.desktop"

echo "==> Installing packages..."
if command -v pacman &>/dev/null; then
    sudo pacman -S --needed --noconfirm freerdp python-gobject gtk-layer-shell
elif command -v apt &>/dev/null; then
    sudo apt-get install -y freerdp3-x11 python3-gi gir1.2-gtk-3.0 gir1.2-gtklayershell-0.1
fi

echo "==> Downloading rdp_connect.py..."
mkdir -p "$INSTALL_DIR"
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/rdp_connect.py"
chmod +x "$INSTALL_DIR/rdp_connect.py"

echo "==> Creating .desktop entry..."
mkdir -p "$(dirname "$DESKTOP_FILE")"
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=RDP Connect
Comment=Connect to RDP server
Exec=python3 $INSTALL_DIR/rdp_connect.py
Icon=network-server
Type=Application
Categories=Network;RemoteAccess;
EOF

echo "✓ RDP Connect installed at $INSTALL_DIR/rdp_connect.py"
