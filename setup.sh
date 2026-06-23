#!/bin/bash
set -e

BASE_URL="https://foodfestivaldnepr-netizen.github.io/setup/scripts"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
  ____       _
 / ___|  ___| |_ _   _ _ __
 \___ \ / _ \ __| | | | '_ \
  ___) |  __/ |_| |_| | |_) |
 |____/ \___|\__|\__,_| .__/
                       |_|
EOF
    echo -e "${NC}"
}

run_script() {
    bash <(curl -fsSL "$BASE_URL/$1")
}

banner
while true; do
    echo -e "${YELLOW}=== Setup Menu ===${NC}"
    echo "1) Printer — HP LaserJet 400 M401dn (CUPS / PCL5 filter)"
    echo "2) RDP Connect — xfreerdp3 launcher with GTK tray"
    echo "3) Print Manager — GTK4 print queue GUI"
    echo "4) Install all"
    echo "q) Quit"
    echo ""
    read -r -p "Select: " choice
    echo ""
    case "$choice" in
        1) run_script "printer.sh" ;;
        2) run_script "rdp.sh" ;;
        3) run_script "printmanager.sh" ;;
        4) run_script "printer.sh"; run_script "rdp.sh"; run_script "printmanager.sh" ;;
        q|Q) exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
    echo ""
done
