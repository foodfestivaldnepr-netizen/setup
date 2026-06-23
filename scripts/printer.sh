#!/bin/bash
# Configure HP LaserJet 400 M401dn with PCL5 CUPS filter
# Fixes HP 79 Service Error caused by complex PostScript/PDF sent via Firefox or GTK apps

set -e

PRINTER_NAME="printer1floor"
PRINTER_URI="ipp://192.168.4.251/ipp/print"
FILTER_PATH="/usr/lib/cups/filter/pdftoljet4"

echo "==> Installing packages..."
if command -v pacman &>/dev/null; then
    sudo pacman -S --needed --noconfirm cups ghostscript cups-filters
elif command -v apt &>/dev/null; then
    sudo apt-get install -y cups ghostscript cups-filters
fi

sudo systemctl enable --now cups

echo "==> Creating CUPS filter (PDF → PCL5 via Ghostscript)..."
sudo tee "$FILTER_PATH" > /dev/null << 'EOF'
#!/bin/bash
exec gs -q -dBATCH -dNOPAUSE -dSAFER \
    -sDEVICE=ljet4 \
    -r600 \
    -dNOINTERPOLATE \
    -sOutputFile=- \
    "${6:--}" 2>/dev/null
EOF
sudo chmod 755 "$FILTER_PATH"

echo "==> Adding printer to CUPS..."
# Add with IPP Everywhere first so CUPS fetches capabilities
if ! lpstat -p "$PRINTER_NAME" &>/dev/null; then
    sudo lpadmin -p "$PRINTER_NAME" -v "$PRINTER_URI" -m everywhere -E
    sleep 2
fi

echo "==> Patching PPD to use PCL5 filter..."
curl -s "http://localhost:631/printers/${PRINTER_NAME}.ppd" -o /tmp/printer_setup.ppd

if ! grep -q "pdftoljet4" /tmp/printer_setup.ppd; then
    sed -i '/\*cupsFilter2: "application\/vnd.cups-pdf/a *cupsFilter2: "application\/pdf application\/vnd.hp-PCL 5 pdftoljet4"' \
        /tmp/printer_setup.ppd
fi

sudo lpadmin -p "$PRINTER_NAME" \
    -v "$PRINTER_URI" \
    -P /tmp/printer_setup.ppd \
    -o print-color-mode=monochrome \
    -o media=A4 \
    -E

sudo cupsenable "$PRINTER_NAME"
echo "✓ $PRINTER_NAME configured at $PRINTER_URI"
