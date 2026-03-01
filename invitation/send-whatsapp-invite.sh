#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  send-whatsapp-invite.sh — Send wedding invitations via WhatsApp
#
#  Opens WhatsApp Web with the message pre-filled for each guest.
#  You click "Send" in each chat window. Free, no API keys needed.
#
#  Usage:
#    bash send-whatsapp-invite.sh              # print links
#    bash send-whatsapp-invite.sh --open       # auto-open in browser
#    bash send-whatsapp-invite.sh --preview    # see the message
# ═══════════════════════════════════════════════════════════════

set -euo pipefail
cd "$(dirname "$0")"

# ─────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────

PHONE_LIST="phones.csv"

MESSAGE='✨ You'"'"'re Invited! ✨

Nithya & Luke joyfully invite you to celebrate their wedding.

📅 Saturday, June 6, 2026
🕐 1:00 PM
📍 Duluth, Georgia

Open your invitation:
🔗 https://www.lukeandnithya.com/invite

We can'"'"'t wait to celebrate with you!
With love, N & L 💛'

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
GOLD='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# ─────────────────────────────────────────
# FUNCTIONS
# ─────────────────────────────────────────

print_banner() {
    echo ""
    echo -e "${GOLD}  ╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GOLD}  ║                                              ║${NC}"
    echo -e "${GOLD}  ║     ${BOLD}  WhatsApp Invite Sender  ${NC}${GOLD}              ║${NC}"
    echo -e "${GOLD}  ║         Nithya & Luke · 06.06.2026           ║${NC}"
    echo -e "${GOLD}  ║                                              ║${NC}"
    echo -e "${GOLD}  ╚══════════════════════════════════════════════╝${NC}"
    echo ""
}

# Strip everything except digits and leading +
clean_phone() {
    local cleaned
    cleaned=$(echo "$1" | sed 's/[^0-9+]//g')
    [[ ! "$cleaned" =~ ^\+ ]] && cleaned="+${cleaned}"
    echo "$cleaned"
}

# URL-encode the message
get_encoded_message() {
    python3 -c "import urllib.parse; print(urllib.parse.quote('''${MESSAGE}'''))"
}

# Read phone numbers from file
read_phones() {
    local phones=()
    while IFS= read -r line; do
        line=$(echo "$line" | xargs)
        [[ -z "$line" || "$line" == \#* ]] && continue
        phones+=("$(clean_phone "$line")")
    done < "$PHONE_LIST"
    echo "${phones[@]}"
}

# ─────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────

print_banner

# ── --preview: show the message ──
if [[ "${1:-}" == "--preview" ]]; then
    echo -e "${CYAN}Message Preview:${NC}"
    echo -e "${GOLD}───────────────────────────────────────${NC}"
    echo "$MESSAGE"
    echo -e "${GOLD}───────────────────────────────────────${NC}"
    exit 0
fi

# Check phone list exists
if [[ ! -f "$PHONE_LIST" ]]; then
    echo -e "${RED}Phone list not found: ${PHONE_LIST}${NC}"
    echo "   Add phone numbers to phones.csv (one per line, with country code)"
    exit 1
fi

# Read numbers
mapfile -t PHONES < <(
    tr -d '\r' < "$PHONE_LIST" |
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//' |
    grep -v '^\s*$\|^\s*#'
)

TOTAL=${#PHONES[@]}
if [[ "$TOTAL" -eq 0 ]]; then
    echo -e "${RED}No phone numbers found in ${PHONE_LIST}${NC}"
    exit 1
fi

ENCODED_MSG=$(get_encoded_message)

# ── --open: auto-open each in browser ──
if [[ "${1:-}" == "--open" ]]; then
    echo -e "${GOLD}Found ${BOLD}${TOTAL}${NC}${GOLD} phone numbers${NC}"
    echo ""
    echo -e "  This will open WhatsApp Web for each number."
    echo -e "  ${CYAN}You need to click Send in each chat.${NC}"
    echo ""

    for i in "${!PHONES[@]}"; do
        PHONE=$(clean_phone "${PHONES[$i]}")
        WA_NUM="${PHONE#+}"
        URL="https://api.whatsapp.com/send?phone=${WA_NUM}&text=${ENCODED_MSG}"
        NUM=$((i + 1))

        echo -ne "  [${NUM}/${TOTAL}] ${BOLD}${PHONE}${NC} — opening... "

        if command -v xdg-open &> /dev/null; then
            xdg-open "$URL" 2>/dev/null &
        elif command -v open &> /dev/null; then
            open "$URL" 2>/dev/null &
        else
            echo -e "${RED}can't auto-open, copy this link:${NC}"
            echo -e "         ${CYAN}${URL}${NC}"
            continue
        fi

        echo -e "${GREEN}opened${NC}"

        # Wait between opens so you have time to send each one
        if [[ $NUM -lt $TOTAL ]]; then
            echo -ne "         waiting 5s before next (press Enter to skip)..."
            read -t 5 -r _ 2>/dev/null || true
            echo ""
        fi
    done

    echo ""
    echo -e "${GREEN}Done! Remember to click Send in each chat.${NC}"
    exit 0
fi

# ── Default: print links ──
echo -e "${GOLD}Found ${BOLD}${TOTAL}${NC}${GOLD} phone numbers${NC}"
echo ""
echo -e "${CYAN}Click each link to open WhatsApp with the message ready:${NC}"
echo ""

for i in "${!PHONES[@]}"; do
    PHONE=$(clean_phone "${PHONES[$i]}")
    WA_NUM="${PHONE#+}"
    URL="https://api.whatsapp.com/send?phone=${WA_NUM}&text=${ENCODED_MSG}"
    NUM=$((i + 1))

    echo -e "  ${GOLD}${NUM}.${NC} ${BOLD}${PHONE}${NC}"
    echo -e "     ${CYAN}${URL}${NC}"
    echo ""
done

echo -e "${GOLD}═══════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}${TOTAL} links generated.${NC}"
echo ""
echo -e "  ${GOLD}Tip:${NC} Run with ${CYAN}--open${NC} to auto-open each in your browser:"
echo -e "       ${CYAN}bash send-whatsapp-invite.sh --open${NC}"
echo -e "${GOLD}═══════════════════════════════════════════════${NC}"
echo ""
