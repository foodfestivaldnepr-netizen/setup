#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  ADEPTUS MECHANICUS — RITE OF REMOTE COGNITION
#  xfreerdp3 launcher — no Python/GTK required
# ══════════════════════════════════════════════════════════════════════════════

R=$'\033[0;31m'       # Crimson
G=$'\033[1;33m'       # Sacred Gold
DW=$'\033[2;37m'      # Dim Parchment
DR=$'\033[2;31m'      # Dim Red (borders)
CY=$'\033[1;36m'      # Cyan
GN=$'\033[1;32m'      # Green (success)
NC=$'\033[0m'         # Reset

# Shares the same JSON config path as rdp_connect.py for interoperability
CONFIG="$HOME/.config/rdp_connect.json"
SCALES=(100 140 180)
SCALE=140

W=54    # number of ═ between ╔ and ╗
IW=52   # inner content width = W - 2

_hl2() { local n=$1 s=''; while (( n-- > 0 )); do s+='═'; done; printf '%s' "$s"; }

# ── Credentials (read from / write to JSON, compatible with Python version) ──
load_creds() {
    SERVER='' USERNAME='' PASSWORD=''
    [[ -f "$CONFIG" ]] || return
    SERVER=$(grep -o '"server"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG" \
             | grep -o '"[^"]*"$' | tr -d '"')
    USERNAME=$(grep -o '"username"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG" \
               | grep -o '"[^"]*"$' | tr -d '"')
    PASSWORD=$(grep -o '"password"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG" \
               | grep -o '"[^"]*"$' | tr -d '"')
}

save_creds() {
    mkdir -p "$(dirname "$CONFIG")"
    # Escape quotes and backslashes for safe JSON embedding
    local s u p
    s="${SERVER//\\/\\\\}";   s="${s//\"/\\\"}"
    u="${USERNAME//\\/\\\\}"; u="${u//\"/\\\"}"
    p="${PASSWORD//\\/\\\\}"; p="${p//\"/\\\"}"
    printf '{"server": "%s", "username": "%s", "password": "%s"}\n' \
        "$s" "$u" "$p" > "$CONFIG"
    chmod 600 "$CONFIG"
}

# ── Banner ────────────────────────────────────────────────────────────────────
draw_banner() {
    clear
    printf '%b' "$DR"
    printf '%s\n' \
        '  ╔═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╤═╗'
    printf '  ║ %b.----.%b  %bA D E P T U S  ⊕  M E C H A N I C U S%b                    %b01·10·01%b ║\n' \
        "$R" "$DR" "$G" "$DR" "$CY" "$DR"
    printf '  ║ %b|o  o|%b  %b─────────────────────────────────────────────────────────────────%b ║\n' \
        "$R" "$DR" "$CY" "$DR"
    printf "  ║ %b\`--^-'%b  %bRITE OF REMOTE COGNITION%b                               %b10·01·10%b ║\n" \
        "$R" "$DR" "$DW" "$DR" "$CY" "$DR"
    printf '%s\n' \
        '  ╚═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╝'
    printf '%b\n' "$NC"
}

# ── Main dialog ───────────────────────────────────────────────────────────────
draw_dialog() {
    draw_banner

    local pw_disp; [[ -n "$PASSWORD" ]] && pw_disp='••••••••' || pw_disp='(not set)'

    printf '%b  ╔'; _hl2 $W; printf '╗%b\n' "$NC"
    printf '%b  ║ %b%-*s%b ║%b\n' "$DR" "$G"  $IW "  ⚙  RITE OF REMOTE COGNITION" "$NC" "$DR" "$NC"
    printf '%b  ║ %b%-*s%b ║%b\n' "$DR" "$DW" $IW "     IN NOMINE OMNISSIAH"       "$NC" "$DR" "$NC"
    printf '%b  ╠'; _hl2 $W; printf '╣%b\n' "$NC"

    printf '%b  ║ %b%-*s%b ║%b\n' "$DR" "$R"  $IW "  NODE ADDRESS"                 "$NC" "$DR" "$NC"
    printf '%b  ║   %b%-*s%b ║%b\n' "$DR" "$DW" $((IW-2)) "${SERVER:-(not set)}"   "$NC" "$DR" "$NC"

    printf '%b  ║ %b%-*s%b ║%b\n' "$DR" "$R"  $IW "  OPERATOR IDENT"               "$NC" "$DR" "$NC"
    printf '%b  ║   %b%-*s%b ║%b\n' "$DR" "$DW" $((IW-2)) "${USERNAME:-(not set)}" "$NC" "$DR" "$NC"

    printf '%b  ║ %b%-*s%b ║%b\n' "$DR" "$R"  $IW "  CIPHER KEY"                   "$NC" "$DR" "$NC"
    printf '%b  ║   %b%-*s%b ║%b\n' "$DR" "$DW" $((IW-2)) "$pw_disp"               "$NC" "$DR" "$NC"

    printf '%b  ║ %b%-*s%b ║%b\n' "$DR" "$R"  $IW "  DISPLAY SCALE"               "$NC" "$DR" "$NC"
    printf '%b  ║   %b%-*s%b ║%b\n' "$DR" "$DW" $((IW-2)) "${SCALE}%  (available: ${SCALES[*]})" "$NC" "$DR" "$NC"

    printf '%b  ╠'; _hl2 $W; printf '╣%b\n' "$NC"
    printf '%b  ║ %b%-*s%b ║%b\n' "$DR" "$DW" $IW \
        "  [e]dit  [s]cale  [c]onnect  [q]uit" "$NC" "$DR" "$NC"
    printf '%b  ╚'; _hl2 $W; printf '╝%b\n\n' "$NC"
}

# ── Edit credentials ──────────────────────────────────────────────────────────
edit_creds() {
    draw_banner
    printf '%b  ╔'; _hl2 $W; printf '╗%b\n' "$NC"
    printf '%b  ║ %b%-*s%b ║%b\n' "$DR" "$G" $IW "  INSCRIBE COGITATOR COORDINATES" "$NC" "$DR" "$NC"
    printf '%b  ║ %b%-*s%b ║%b\n' "$DR" "$DW" $IW "  Leave blank to keep current value" "$NC" "$DR" "$NC"
    printf '%b  ╚'; _hl2 $W; printf '╝%b\n\n' "$NC"

    local input

    printf '%b  NODE ADDRESS%b [%s%s%b]: ' "$R" "$DW" "$NC" "$SERVER" "$NC"
    read -r input; [[ -n "$input" ]] && SERVER="$input"

    printf '%b  OPERATOR IDENT%b [%s%s%b]: ' "$R" "$DW" "$NC" "$USERNAME" "$NC"
    read -r input; [[ -n "$input" ]] && USERNAME="$input"

    printf '%b  CIPHER KEY%b [%s]: ' "$R" "$NC" \
        "$( [[ -n "$PASSWORD" ]] && printf '(set — press Enter to keep)' || printf '(not set)' )"
    read -rs input; echo
    [[ -n "$input" ]] && PASSWORD="$input"

    save_creds
    printf '\n%b  ✓ INSCRIBED TO COGITATOR%b\n' "$GN" "$NC"
    sleep 1
}

# ── Cycle display scale ───────────────────────────────────────────────────────
cycle_scale() {
    local i
    for i in "${!SCALES[@]}"; do
        if [[ "${SCALES[$i]}" == "$SCALE" ]]; then
            SCALE="${SCALES[$(( (i+1) % ${#SCALES[@]} ))]}"
            return
        fi
    done
    SCALE="${SCALES[0]}"
}

# ── Launch RDP session ────────────────────────────────────────────────────────
launch_rdp() {
    if [[ -z "$SERVER" || -z "$USERNAME" || -z "$PASSWORD" ]]; then
        printf '\n%b  ✗ RITE ABORTED — credentials incomplete. Use [e] to inscribe.%b\n' "$R" "$NC"
        sleep 2
        return
    fi

    printf '\n%b  INITIATING LINK TO NODE: %b%s%b\n' "$DW" "$G" "$SERVER" "$NC"
    printf '%b  IN NOMINE OMNISSIAH...%b\n\n' "$DW" "$NC"

    xfreerdp3 \
        "/v:$SERVER" \
        "/u:$USERNAME" \
        "/p:$PASSWORD" \
        /dynamic-resolution \
        "/scale:$SCALE" \
        /cert:ignore \
        /sec:rdp \
        +printer \
        -grab-keyboard \
        "/drive:Linux,$HOME" &

    local pid=$!
    printf '%b  ✓ LINK ESTABLISHED — machine spirit pid %d%b\n' "$GN" "$pid" "$NC"
    printf '\n%b  Press [Enter] to return to sanctum...%b ' "$DW" "$NC"
    read -r
}

# ── Main loop ─────────────────────────────────────────────────────────────────
main() {
    load_creds
    while true; do
        draw_dialog
        printf '%b  AWAITING COMMAND, ADEPT: %b' "$DW" "$NC"
        read -rsn1 key
        case "$key" in
            e|E) edit_creds; load_creds ;;
            s|S) cycle_scale ;;
            c|C) launch_rdp ;;
            q|Q)
                printf '\n%b  SANCTUM SEALED. THE OMNISSIAH GUIDE YOUR CIRCUITS.%b\n\n' "$DW" "$NC"
                exit 0 ;;
        esac
    done
}

main
