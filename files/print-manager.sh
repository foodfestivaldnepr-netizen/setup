#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  ADEPTUS MECHANICUS — LITANY OF MANIFOLD INSCRIPTION
#  lp/lpstat print manager — no Python/GTK required
# ══════════════════════════════════════════════════════════════════════════════

R=$'\033[0;31m'       # Crimson
G=$'\033[1;33m'       # Sacred Gold
DW=$'\033[2;37m'      # Dim Parchment
DR=$'\033[2;31m'      # Dim Red (borders)
CY=$'\033[1;36m'      # Cyan
GN=$'\033[1;32m'      # Green (success)
NC=$'\033[0m'         # Reset

W=60    # number of ═ between ╔ and ╗
IW=58   # inner content width = W - 2

declare -A PRINTER_MEDIA=(
    [printer1floor]='A4'
    [HP_LaserJet_400_M401dn_93020A]='A4'
    [XP-480B]='w4h4'
)
MONOCHROME_PRINTERS='printer1floor HP_LaserJet_400_M401dn_93020A'

_hl2() { local n=$1 s=''; while (( n-- > 0 )); do s+='═'; done; printf '%s' "$s"; }

is_monochrome() { [[ " $MONOCHROME_PRINTERS " == *" $1 "* ]]; }

get_media() { printf '%s' "${PRINTER_MEDIA[$1]:-A4}"; }

# ── Fetch available printers ──────────────────────────────────────────────────
get_printers() {
    mapfile -t PRINTERS < <(lpstat -p 2>/dev/null | awk '{print $2}')
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
    printf "  ║ %b\`--^-'%b  %bLITANY OF MANIFOLD INSCRIPTION%b                         %b10·01·10%b ║\n" \
        "$R" "$DR" "$DW" "$DR" "$CY" "$DR"
    printf '%s\n' \
        '  ╚═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╧═╝'
    printf '%b\n' "$NC"
}

# ── Printer selection sub-screen ──────────────────────────────────────────────
select_printer() {
    draw_banner
    get_printers

    printf '%b  ╔'; _hl2 $W; printf '╗%b\n' "$NC"
    printf '%b  ║ %b%-*s%b ║%b\n' "$DR" "$G" $IW "  SACRED MANIFOLD SELECTION" "$NC" "$DR" "$NC"
    printf '%b  ╠'; _hl2 $W; printf '╣%b\n' "$NC"

    if [[ ${#PRINTERS[@]} -eq 0 ]]; then
        printf '%b  ║ %b%-*s%b ║%b\n' "$DR" "$R" $IW \
            "  NO MANIFOLDS DETECTED — is CUPS running?" "$NC" "$DR" "$NC"
        printf '%b  ╚'; _hl2 $W; printf '╝%b\n\n' "$NC"
        printf '%b  Press [Enter] to return...%b ' "$DW" "$NC"; read -r
        return 1
    fi

    local i=0
    for p in "${PRINTERS[@]}"; do
        local media; media=$(get_media "$p")
        local mono; is_monochrome "$p" && mono=' [mono]' || mono=''
        printf '%b  ║ %b[%d]%b %-*s%b ║%b\n' "$DR" "$R" "$i" "$DW" \
            $((IW-4)) "$p  (${media}${mono})" "$NC" "$DR" "$NC"
        (( i++ ))
    done

    printf '%b  ╚'; _hl2 $W; printf '╝%b\n\n' "$NC"

    printf '%b  SELECT MANIFOLD [0-%d, or Enter to cancel]: %b' "$R" $(( ${#PRINTERS[@]} - 1 )) "$NC"
    read -r idx

    [[ -z "$idx" ]] && return 1
    if ! [[ "$idx" =~ ^[0-9]+$ ]] || (( idx >= ${#PRINTERS[@]} )); then
        printf '%b  ✗ INVALID SELECTION%b\n' "$R" "$NC"; sleep 1; return 1
    fi

    PRINTER="${PRINTERS[$idx]}"
    MEDIA=$(get_media "$PRINTER")
    return 0
}

# ── Execute print rite ────────────────────────────────────────────────────────
do_print() {
    local printer="$1" filepath="$2" media="$3" copies="$4" fit="$5"

    if [[ "${filepath,,}" == *.pdf ]]; then
        local ps_path='/tmp/print_manager_out.ps'
        printf '%b  Converting manuscript to PostScript...%b\n' "$DW" "$NC"
        if ! pdf2ps "$filepath" "$ps_path" 2>&1; then
            printf '%b  ✗ RITE FAILED — pdf2ps conversion error%b\n' "$R" "$NC"
            return 1
        fi
        filepath="$ps_path"
    fi

    local cmd=('lp' '-d' "$printer" '-n' "$copies" '-o' "media=$media")
    [[ "$fit" == y ]] && cmd+=('-o' 'fit-to-page')
    is_monochrome "$printer" && cmd+=('-o' 'print-color-mode=monochrome')
    cmd+=("$filepath")

    printf '%b  TRANSMITTING LITANY TO MANIFOLD: %b%s%b\n' "$DW" "$G" "$printer" "$NC"

    local out
    if out=$("${cmd[@]}" 2>&1); then
        printf '%b  ✓ LITANY ACCEPTED — THE OMNISSIAH PROVIDES%b\n' "$GN" "$NC"
        printf '%b  %s%b\n' "$DW" "$out" "$NC"
        return 0
    else
        printf '%b  ✗ RITE FAILED — MACHINE SPIRIT REFUSES: %s%b\n' "$R" "$out" "$NC"
        return 1
    fi
}

# ── Main loop ─────────────────────────────────────────────────────────────────
main() {
    local PRINTER='' MEDIA='A4' FILEPATH='' COPIES=1 FIT=y STATUS=''

    while true; do
        draw_banner

        local fit_label; [[ "$FIT" == y ]] && fit_label='YES' || fit_label='NO'

        printf '%b  ╔'; _hl2 $W; printf '╗%b\n' "$NC"
        printf '%b  ║ %b%-*s%b ║%b\n' "$DR" "$G" $IW "  LITANY OF MANIFOLD INSCRIPTION" "$NC" "$DR" "$NC"
        printf '%b  ╠'; _hl2 $W; printf '╣%b\n' "$NC"

        printf '%b  ║ %b%-*s%b ║%b\n' "$DR" "$R" $IW "  SACRED MANIFOLD" "$NC" "$DR" "$NC"
        printf '%b  ║   %b%-*s%b ║%b\n' "$DR" "$DW" $((IW-2)) \
            "${PRINTER:-(not selected — press p)}" "$NC" "$DR" "$NC"

        printf '%b  ║ %b%-*s%b ║%b\n' "$DR" "$R" $IW "  MANUSCRIPT" "$NC" "$DR" "$NC"
        printf '%b  ║   %b%-*s%b ║%b\n' "$DR" "$DW" $((IW-2)) \
            "${FILEPATH:-(not designated — press f)}" "$NC" "$DR" "$NC"

        printf '%b  ║ %b%-*s%b ║%b\n' "$DR" "$R" $IW \
            "  ITERATIONS: $COPIES   SCALE TO PARCHMENT: $fit_label   PARCHMENT GRADE: $MEDIA" "$NC" "$DR" "$NC"

        if [[ -n "$STATUS" ]]; then
            printf '%b  ╠'; _hl2 $W; printf '╣%b\n' "$NC"
            printf '%b  ║ %b%-*s%b ║%b\n' "$DR" "$GN" $IW "  $STATUS" "$NC" "$DR" "$NC"
            STATUS=''
        fi

        printf '%b  ╠'; _hl2 $W; printf '╣%b\n' "$NC"
        printf '%b  ║ %b%-*s%b ║%b\n' "$DR" "$DW" $IW \
            "  [p]rinter  [f]ile  [c]opies  [t]oggle-fit  [Enter]print  [q]uit" "$NC" "$DR" "$NC"
        printf '%b  ╚'; _hl2 $W; printf '╝%b\n\n' "$NC"

        printf '%b  AWAITING COMMAND, ADEPT: %b' "$DW" "$NC"
        read -rsn1 key

        case "$key" in
            p|P)
                select_printer && : ;;

            f|F)
                printf '\n%b  DESIGNATE MANUSCRIPT PATH: %b' "$R" "$NC"
                read -re input
                if [[ -n "$input" ]]; then
                    input="${input/#\~/$HOME}"
                    if [[ -f "$input" ]]; then
                        FILEPATH="$input"
                    else
                        printf '%b  ✗ FILE NOT FOUND%b\n' "$R" "$NC"; sleep 1
                    fi
                fi ;;

            c|C)
                printf '\n%b  ITERATIONS [1-99, currently %d]: %b' "$R" "$COPIES" "$NC"
                read -r input
                if [[ "$input" =~ ^[1-9][0-9]?$ ]]; then
                    COPIES="$input"
                elif [[ -n "$input" ]]; then
                    printf '%b  ✗ INVALID — keeping %d%b\n' "$R" "$COPIES" "$NC"; sleep 1
                fi ;;

            t|T)
                [[ "$FIT" == y ]] && FIT=n || FIT=y ;;

            ''|$'\n'|$'\r')
                echo
                if [[ -z "$PRINTER" ]]; then
                    printf '%b  ⚠ DESIGNATE A SACRED MANIFOLD FIRST, ADEPT.%b\n' "$R" "$NC"
                    sleep 2; continue
                fi
                if [[ -z "$FILEPATH" ]]; then
                    printf '%b  ⚠ DESIGNATE A MANUSCRIPT FIRST, ADEPT.%b\n' "$R" "$NC"
                    sleep 2; continue
                fi
                do_print "$PRINTER" "$FILEPATH" "$MEDIA" "$COPIES" "$FIT" \
                    && STATUS='LITANY ACCEPTED — THE OMNISSIAH PROVIDES'
                printf '\n%b  Press [Enter] to continue...%b ' "$DW" "$NC"; read -r ;;

            q|Q)
                printf '\n%b  SANCTUM SEALED. THE OMNISSIAH GUIDE YOUR CIRCUITS.%b\n\n' "$DW" "$NC"
                exit 0 ;;
        esac
    done
}

main
