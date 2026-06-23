#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  ADEPTUS MECHANICUS — OMNISSIAH'S SANCTIONED RITES OF INSTALLATION
#  In Nomine Imperatoris. In the name of the Machine God.
# ══════════════════════════════════════════════════════════════════════════════

# Require bash — arrays and PIPESTATUS are bash-only
if [ -z "$BASH_VERSION" ]; then
    echo "This rite requires bash. Run: curl -fsSL <URL> | bash"
    exit 1
fi

BASE_URL="https://foodfestivaldnepr-netizen.github.io/setup/scripts"

# Open a direct line to the terminal for interactive input even when stdin
# is the curl pipe.  Fall back to stdin if /dev/tty is unavailable.
exec 3</dev/tty 2>/dev/null || exec 3<&0

# ── Palette (Imperial: crimson, sacred gold, void black) ───────────────────
R=$'\033[0;31m'       # Crimson
G=$'\033[1;33m'       # Sacred Gold
DW=$'\033[2;37m'      # Dim White / Parchment
DR=$'\033[2;31m'      # Dim Red — borders
CY=$'\033[1;36m'      # Cyan — system readouts
GN=$'\033[1;32m'      # Green — success
SEL=$'\033[1;37;41m'  # Selected: white on blood-red
NC=$'\033[0m'         # Reset

# ── Terminal helpers (ANSI fallbacks when tput is missing) ─────────────────
_smcup() { tput smcup 2>/dev/null || printf '\033[?1049h'; }
_rmcup() { tput rmcup 2>/dev/null || printf '\033[?1049l'; }
_civis() { tput civis 2>/dev/null || printf '\033[?25l';  }
_cnorm() { tput cnorm 2>/dev/null || printf '\033[?25h';  }
_clear()  { tput clear  2>/dev/null || printf '\033[H\033[2J'; }

# ── Menu data ──────────────────────────────────────────────────────────────
CATS=("Hardware Litanies" "Exit Sanctum")

ITEMS_0=(
    "Printer       HP LaserJet 400 M401dn CUPS/PCL5 filter"
    "RDP Connect   xfreerdp3 launcher with GTK system tray"
    "Print Manager GTK4 print queue management interface"
    "Consecrate All   Install all of the above"
)
CMDS_0=("printer.sh" "rdp.sh" "printmanager.sh" "ALL")

# ── State ──────────────────────────────────────────────────────────────────
panel=0      # 0 = left panel (categories), 1 = right panel (rites)
cat_idx=0
item_idx=0

# ── System readouts ────────────────────────────────────────────────────────
SYS_CPU=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null \
          | cut -d: -f2 | sed 's/^ *//' | cut -c1-30 || printf 'Unknown')
SYS_RAM=$(free -h 2>/dev/null | awk '/^Mem:/{print $2}' || printf '?')
SYS_DISK=$(df -h / 2>/dev/null | awk 'NR==2{print $4}' || printf '?')

# ── Cleanup on exit / signal ───────────────────────────────────────────────
_cleanup() {
    _cnorm
    _rmcup
    printf '%b' "$NC"
}
trap _cleanup EXIT INT TERM

# ── Single-character input (works via curl | bash pipe) ────────────────────
read_key() {
    local k e
    IFS= read -rsn1 k <&3 2>/dev/null || return 1
    if [[ "$k" == $'\x1b' ]]; then
        read -rsn2 -t 0.05 e <&3 2>/dev/null || true
        k+="$e"
    fi
    printf '%s' "$k"
}

# ── Box geometry (fits 80-column terminals) ────────────────────────────────
#
#   "  ║ " + L(23) + " ║ " + RR(47) + " ║"  = 79 chars
#
L=23            # left panel content width
RR=47           # right panel content width
LBW=$((L+2))        # left border section   = 25  (between ╔ and ╦)
RBW=$((RR+2))       # right border section  = 49  (between ╦ and ╗)
FBW=$((LBW+RBW+1))  # full single-row width = 75  (between ╠ and ╣)

_hl() {   # print $1 horizontal-rule dashes
    local n=$1 s=''
    while (( n-- > 0 )); do s+='─'; done
    printf '%s' "$s"
}

# ── Main draw ──────────────────────────────────────────────────────────────
draw() {
    _clear

    # ── Banner: Adeptus Mechanicus Horizontal Fresca ─────────────────
    printf '%b' "$DR"
    printf '%s\n' \
        '  ╔═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╗'
    printf '  ║ %b.----.%b  %bA D E P T U S  ⊕  M E C H A N I C U S%b                    %b01·10·01%b ║\n' \
        "$R" "$DR" "$G" "$DR" "$CY" "$DR"
    printf '  ║ %b|o  o|%b  %b─────────────────────────────────────────────────────────────────%b ║\n' \
        "$R" "$DR" "$CY" "$DR"
    printf "  ║ %b\`--^-'%b  %bOMNISSIAH'S SANCTIONED INSTALLATION RITES%b                %b10·01·10%b ║\n" \
        "$R" "$DR" "$DW" "$DR" "$CY" "$DR"
    printf '%b' "$DR"
    printf '%s\n' \
        '  ╚═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╝'
    printf '%b\n' "$NC"
    printf '%b    "Blessed is the mind too small for doubt"\n\n' "$DW"

    # ── Resolve items for the highlighted category ─────────────────────
    local -a cur_items cur_cmds
    if [[ $cat_idx -eq 0 ]]; then
        cur_items=("${ITEMS_0[@]}")
        cur_cmds=("${CMDS_0[@]}")
    else
        cur_items=()
        cur_cmds=()
    fi

    # ── Top border ─────────────────────────────────────────────────────
    printf '%b  ╔' "$DR"; _hl $LBW; printf '╦'; _hl $RBW; printf '╗%b\n' "$NC"

    # ── Column headers ─────────────────────────────────────────────────
    printf '%b  ║ %b%-*s%b %b║ %b%-*s%b %b║%b\n' \
        "$DR" "$G" "$L"  "RITES OF SANCTIONING" "$NC" \
        "$DR" "$G" "$RR" "AVAILABLE RITES"       "$NC" \
        "$DR" "$NC"

    # ── Sub-separator ──────────────────────────────────────────────────
    printf '%b  ╠' "$DR"; _hl $LBW; printf '╬'; _hl $RBW; printf '╣%b\n' "$NC"

    # ── Panel rows ─────────────────────────────────────────────────────
    local max row
    max=$(( ${#CATS[@]} > ${#cur_items[@]} ? ${#CATS[@]} : ${#cur_items[@]} ))
    (( max < 4 )) && max=4

    for (( row=0; row<max; row++ )); do
        # Left cell
        local lt='' lc="$NC"
        if (( row < ${#CATS[@]} )); then
            if [[ $panel -eq 0 && $row -eq $cat_idx ]]; then
                lc="$SEL"; lt="> ${CATS[$row]}"
            else
                lc="$R";   lt="  ${CATS[$row]}"
            fi
        fi

        # Right cell
        local rt='' rc="$NC"
        if (( row < ${#cur_items[@]} )); then
            if [[ $panel -eq 1 && $row -eq $item_idx ]]; then
                rc="$SEL"; rt="> ${cur_items[$row]}"
            else
                rc="$R";   rt="  ${cur_items[$row]}"
            fi
        fi

        printf '%b  ║ %b%-*.*s%b %b║ %b%-*.*s%b %b║%b\n' \
            "$DR" \
            "$lc" "$L"  "$L"  "$lt" "$NC" \
            "$DR" \
            "$rc" "$RR" "$RR" "$rt" "$NC" \
            "$DR" "$NC"
    done

    # ── System-info separator (merges the two columns) ─────────────────
    printf '%b  ╠' "$DR"; _hl $LBW; printf '╩'; _hl $RBW; printf '╣%b\n' "$NC"

    # ── System-info row ────────────────────────────────────────────────
    printf '%b  ║ %b%-*.*s%b %b║%b\n' \
        "$DR" "$CY" $((FBW-2)) $((FBW-2)) \
        "CPU: $SYS_CPU   RAM: $SYS_RAM   DISK: $SYS_DISK" \
        "$NC" "$DR" "$NC"

    # ── Key-help separator ─────────────────────────────────────────────
    printf '%b  ╠' "$DR"; _hl $FBW; printf '╣%b\n' "$NC"

    # ── Key-help row ───────────────────────────────────────────────────
    printf '%b  ║ %b%-*.*s%b %b║%b\n' \
        "$DR" "$DW" $((FBW-2)) $((FBW-2)) \
        "[↑↓] Navigate   [→/Enter] Select   [←/h] Back   [q] Quit" \
        "$NC" "$DR" "$NC"

    # ── Bottom border ──────────────────────────────────────────────────
    printf '%b  ╚' "$DR"; _hl $FBW; printf '╝%b\n' "$NC"
}

# ── Confirmation overlay (drawn on top of the live TUI) ────────────────────
confirm_overlay() {
    local label="$1"
    local bw=52 bh=7 i

    local rows cols
    rows=$(tput lines 2>/dev/null || echo 24)
    cols=$(tput cols  2>/dev/null || echo 80)

    local br=$(( (rows - bh) / 2 ))
    local bc=$(( (cols - bw) / 2 ))
    local inner=$((bw - 4))   # content width between "│ " and " │"

    # Top border
    tput cup $br $bc
    printf '%b┌' "$G"
    for (( i=0; i<bw-2; i++ )); do printf '─'; done
    printf '┐%b' "$NC"

    # Title
    tput cup $((br+1)) $bc
    printf '%b│ %b%-*s %b│%b' "$G" "$G" $inner "  CONFIRM SELECTION" "$G" "$NC"

    # Blank
    tput cup $((br+2)) $bc
    printf '%b│%b%-*s%b│%b' "$G" "$NC" $((bw-2)) "" "$G" "$NC"

    # Label (truncated to fit)
    tput cup $((br+3)) $bc
    printf '%b│ %b%-*.*s%b │%b' "$G" "$R" $inner $inner "  $label" "$NC" "$G" "$NC"

    # Blank
    tput cup $((br+4)) $bc
    printf '%b│%b%-*s%b│%b' "$G" "$NC" $((bw-2)) "" "$G" "$NC"

    # y/n prompt
    tput cup $((br+5)) $bc
    printf '%b│ %b%-*s %b│%b' "$G" "$DW" $inner "[y] to continue   [n] to abort" "$G" "$NC"

    # Bottom border
    tput cup $((br+6)) $bc
    printf '%b└' "$G"
    for (( i=0; i<bw-2; i++ )); do printf '─'; done
    printf '┘%b' "$NC"

    _cnorm

    local key
    while true; do
        key=$(read_key) || return 1
        case "$key" in
            y|Y)                          _civis; return 0 ;;
            n|N|q|Q|$'\x1b'|$'\x1b[D')  _civis; return 1 ;;
        esac
    done
}

# ── Execute a sanctioned rite ──────────────────────────────────────────────
run_rite() {
    local cmd="$1" label="$2"
    local tmplog
    tmplog=$(mktemp)

    _rmcup
    _cnorm

    # ── Running command header ──────────────────────────────────────────
    printf '%b\n  ╔════════════════════════════════════════════════════════════╗\n' "$G"
    printf   '  ║  >> RUNNING COMMAND                                        ║\n'
    printf   '  ╚════════════════════════════════════════════════════════════╝%b\n\n' "$NC"

    local exit_code=0 s_exit s

    if [[ "$cmd" == "ALL" ]]; then
        for s in printer.sh rdp.sh printmanager.sh; do
            printf '%b  ▸ %s%b\n' "$G" "$s" "$NC"
            curl -fsSL "$BASE_URL/$s" | bash 2>&1 | tee -a "$tmplog"
            s_exit=${PIPESTATUS[1]}
            (( s_exit != 0 )) && exit_code=$s_exit
            echo
        done
    else
        curl -fsSL "$BASE_URL/$cmd" | bash 2>&1 | tee -a "$tmplog"
        exit_code=${PIPESTATUS[1]}
    fi

    # ── Result footer ───────────────────────────────────────────────────
    echo
    if [[ $exit_code -eq 0 ]]; then
        printf '%b  ╔════════════════════════════════════════════════════════════╗\n' "$GN"
        printf '%b  ║%-60.60s║\n' "$GN" "  SUCCESS — The Machine God is pleased. Rite complete."
        printf   '  ╚════════════════════════════════════════════════════════════╝%b\n' "$NC"
    else
        printf '%b  ╔════════════════════════════════════════════════════════════╗\n' "$R"
        printf '%b  ║%-60.60s║\n' "$R" "  FAILED (exit $exit_code) — The Omnissiah demands perfection."
        printf   '  ╚════════════════════════════════════════════════════════════╝%b\n' "$NC"
    fi

    printf '\n%b  Press [Enter] to return to Sanctum   [l] Save log%b ' "$DW" "$NC"
    local k
    IFS= read -rsn1 k <&3 2>/dev/null || true

    if [[ "$k" == 'l' || "$k" == 'L' ]]; then
        local logfile="$HOME/rite-$(date +%Y%m%d-%H%M%S).log"
        cp "$tmplog" "$logfile"
        printf '\n%b  Log saved to: %s%b\n' "$GN" "$logfile" "$NC"
        printf '%b  Press [Enter] to continue...%b ' "$DW" "$NC"
        IFS= read -rsn1 <&3 2>/dev/null || true
    fi

    rm -f "$tmplog"
    echo

    _smcup
    _civis
}

# ── Main loop ──────────────────────────────────────────────────────────────
main() {
    _smcup
    _civis

    while true; do
        local -a cur_items cur_cmds
        if [[ $cat_idx -eq 0 ]]; then
            cur_items=("${ITEMS_0[@]}")
            cur_cmds=("${CMDS_0[@]}")
        else
            cur_items=()
            cur_cmds=()
        fi

        draw

        local key
        key=$(read_key) || continue

        case "$key" in

            $'\x1b[A')  # ↑ Up
                if [[ $panel -eq 0 ]]; then
                    (( cat_idx > 0 )) && (( cat_idx-- )) || true
                    item_idx=0
                else
                    (( item_idx > 0 )) && (( item_idx-- )) || true
                fi
                ;;

            $'\x1b[B')  # ↓ Down
                if [[ $panel -eq 0 ]]; then
                    (( cat_idx < ${#CATS[@]} - 1 )) && (( cat_idx++ )) || true
                    item_idx=0
                else
                    (( item_idx < ${#cur_items[@]} - 1 )) && (( item_idx++ )) || true
                fi
                ;;

            ''|$'\x1b[C'|$'\n'|$'\r')  # → Right  or  Enter ('' = \n stripped by $())
                if [[ $panel -eq 0 ]]; then
                    # Last category = "Exit Sanctum"
                    if (( cat_idx == ${#CATS[@]} - 1 )); then
                        exit 0
                    fi
                    panel=1
                    item_idx=0
                else
                    if (( ${#cur_items[@]} > 0 )); then
                        # Show confirmation overlay on top of current TUI,
                        # then run the rite only if the user confirms.
                        if confirm_overlay "${cur_items[$item_idx]}"; then
                            run_rite "${cur_cmds[$item_idx]}" "${cur_items[$item_idx]}"
                        fi
                    fi
                fi
                ;;

            $'\x1b[D'|h|H)  # ← Left  or  h — back to category panel
                panel=0
                ;;

            q|Q)
                exit 0
                ;;

        esac
    done
}

main
