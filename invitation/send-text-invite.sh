#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  send-text-invite.sh — Send wedding invitations via SMS/WhatsApp
#
#  Two modes:
#    • Twilio SMS  — sends real text messages (requires Twilio account)
#    • WhatsApp    — opens WhatsApp web links for each number
#
#  Usage:
#    1. For SMS: Fill in invitation/.env with Twilio settings
#    2. Add phone numbers to phones.csv (one per line, with country code)
#    3. Run:  bash send-text-invite.sh
#    4. Test: bash send-text-invite.sh --test +14045551234
#    5. WhatsApp only: bash send-text-invite.sh --whatsapp
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ─────────────────────────────────────────
# CONFIGURATION — loaded from .env file
# ─────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

# Load .env if it exists
if [[ -f "$ENV_FILE" ]]; then
    while IFS='=' read -r key value; do
        key=$(echo "$key" | xargs)
        [[ -z "$key" || "$key" == \#* ]] && continue
        value=$(echo "$value" | xargs | sed 's/^["'\'']*//;s/["'\'']*$//')
        export "$key=$value"
    done < "$ENV_FILE"
fi

# Twilio credentials (from .env or environment)
TWILIO_ACCOUNT_SID="${TWILIO_ACCOUNT_SID:-}"
TWILIO_AUTH_TOKEN="${TWILIO_AUTH_TOKEN:-}"
TWILIO_FROM_NUMBER="${TWILIO_FROM_NUMBER:-}"      # Your Twilio phone number (+1XXXXXXXXXX)
TWILIO_WHATSAPP_FROM="${TWILIO_WHATSAPP_FROM:-}"  # Optional: whatsapp:+14155238886 (Twilio sandbox)

# Phone list
PHONE_LIST="phones.csv"

# Delay between sends (seconds) — avoids rate limiting
DELAY_BETWEEN=1

# The invitation message
MESSAGE='✨ You'"'"'re Invited! ✨

Nithya & Luke joyfully invite you to celebrate their wedding.

📅 Saturday, June 6, 2026
🕐 1:00 PM
📍 Duluth, Georgia

View our invitation & RSVP:
🔗 https://www.lukeandnithya.com

We can'"'"'t wait to celebrate with you!
With love, N & L 💛'

# Colors for terminal output
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
    echo -e "${GOLD}  ║     ${BOLD}  Text / WhatsApp Invite Sender  ${NC}${GOLD}       ║${NC}"
    echo -e "${GOLD}  ║         Nithya & Luke · 06.06.2026           ║${NC}"
    echo -e "${GOLD}  ║                                              ║${NC}"
    echo -e "${GOLD}  ╚══════════════════════════════════════════════╝${NC}"
    echo ""
}

check_dependencies() {
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Error: python3 is required but not installed.${NC}"
        exit 1
    fi

    if ! command -v curl &> /dev/null; then
        echo -e "${RED}Error: curl is required but not installed.${NC}"
        exit 1
    fi
}

validate_twilio_config() {
    if [[ -z "$TWILIO_ACCOUNT_SID" ]]; then
        echo -e "${RED}No Twilio Account SID set.${NC}"
        echo -e "   Add ${CYAN}TWILIO_ACCOUNT_SID${NC} to invitation/.env"
        echo -e "   Get yours at: ${CYAN}https://console.twilio.com${NC}"
        exit 1
    fi

    if [[ -z "$TWILIO_AUTH_TOKEN" ]]; then
        echo -e "${RED}No Twilio Auth Token set.${NC}"
        echo -e "   Add ${CYAN}TWILIO_AUTH_TOKEN${NC} to invitation/.env"
        exit 1
    fi

    if [[ -z "$TWILIO_FROM_NUMBER" ]]; then
        echo -e "${RED}No Twilio phone number set.${NC}"
        echo -e "   Add ${CYAN}TWILIO_FROM_NUMBER${NC} to invitation/.env (e.g. +14155551234)"
        exit 1
    fi
}

validate_phone_list() {
    if [[ ! -f "$PHONE_LIST" ]]; then
        echo -e "${RED}Phone list not found: ${PHONE_LIST}${NC}"
        echo "   Create phones.csv with one phone number per line."
        exit 1
    fi
}

# Clean a phone number — strip spaces, dashes, parens
clean_phone() {
    local raw="$1"
    # Keep only digits and leading +
    local cleaned
    cleaned=$(echo "$raw" | sed 's/[^0-9+]//g')
    # If no + prefix and starts with 1 and is 11 digits, add +
    if [[ ! "$cleaned" =~ ^\+ ]]; then
        cleaned="+${cleaned}"
    fi
    echo "$cleaned"
}

# Send SMS via Twilio API
send_sms() {
    local to_number="$1"

    local response
    response=$(curl -s -w "\n%{http_code}" \
        -X POST "https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json" \
        --data-urlencode "To=${to_number}" \
        --data-urlencode "From=${TWILIO_FROM_NUMBER}" \
        --data-urlencode "Body=${MESSAGE}" \
        -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}")

    local http_code
    http_code=$(echo "$response" | tail -1)
    local body
    body=$(echo "$response" | sed '$d')

    if [[ "$http_code" == "201" ]]; then
        return 0
    else
        local error_msg
        error_msg=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message','Unknown error'))" 2>/dev/null || echo "$body")
        echo "$error_msg" >&2
        return 1
    fi
}

# Send WhatsApp message via Twilio API (requires approved template or sandbox)
send_whatsapp_twilio() {
    local to_number="$1"

    local response
    response=$(curl -s -w "\n%{http_code}" \
        -X POST "https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json" \
        --data-urlencode "To=whatsapp:${to_number}" \
        --data-urlencode "From=${TWILIO_WHATSAPP_FROM:-whatsapp:${TWILIO_FROM_NUMBER}}" \
        --data-urlencode "Body=${MESSAGE}" \
        -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}")

    local http_code
    http_code=$(echo "$response" | tail -1)
    local body
    body=$(echo "$response" | sed '$d')

    if [[ "$http_code" == "201" ]]; then
        return 0
    else
        local error_msg
        error_msg=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message','Unknown error'))" 2>/dev/null || echo "$body")
        echo "$error_msg" >&2
        return 1
    fi
}

# Generate WhatsApp click-to-chat links (no Twilio needed)
generate_whatsapp_links() {
    local encoded_msg
    encoded_msg=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''${MESSAGE}'''))")

    echo -e "${CYAN}WhatsApp Click-to-Chat Links${NC}"
    echo -e "${CYAN}Open each link in your browser to send via WhatsApp:${NC}"
    echo ""

    local num=0
    while IFS= read -r line; do
        line=$(echo "$line" | xargs)
        [[ -z "$line" || "$line" == \#* ]] && continue
        local phone
        phone=$(clean_phone "$line")
        local wa_number="${phone#+}"  # strip leading +
        num=$((num + 1))
        echo -e "  ${GOLD}${num}.${NC} ${phone}"
        echo -e "     ${CYAN}https://api.whatsapp.com/send?phone=${wa_number}&text=${encoded_msg}${NC}"
        echo ""
    done < "$PHONE_LIST"

    if [[ $num -eq 0 ]]; then
        echo -e "${RED}No phone numbers found in ${PHONE_LIST}${NC}"
        exit 1
    fi

    echo -e "${GOLD}═══════════════════════════════════════════════${NC}"
    echo -e "  ${GREEN}Generated ${num} WhatsApp links.${NC}"
    echo -e "  Click each link or copy-paste into your browser."
    echo -e "${GOLD}═══════════════════════════════════════════════${NC}"
}

# Open WhatsApp links in browser automatically
open_whatsapp_links() {
    local encoded_msg
    encoded_msg=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''${MESSAGE}'''))")

    local nums=()
    while IFS= read -r line; do
        line=$(echo "$line" | xargs)
        [[ -z "$line" || "$line" == \#* ]] && continue
        nums+=("$(clean_phone "$line")")
    done < "$PHONE_LIST"

    local total=${#nums[@]}
    if [[ $total -eq 0 ]]; then
        echo -e "${RED}No phone numbers found in ${PHONE_LIST}${NC}"
        exit 1
    fi

    echo -e "${GOLD}Found ${BOLD}${total}${NC}${GOLD} phone numbers${NC}"
    echo ""
    echo -e "${CYAN}This will open WhatsApp Web for each number.${NC}"
    echo -e "${CYAN}You'll need to click 'Send' in each chat window.${NC}"
    echo ""
    read -rp "Continue? (y/n): " CONFIRM
    [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && { echo -e "\n${RED}Cancelled.${NC}"; exit 0; }

    echo ""
    for i in "${!nums[@]}"; do
        local phone="${nums[$i]}"
        local wa_number="${phone#+}"
        local url="https://api.whatsapp.com/send?phone=${wa_number}&text=${encoded_msg}"
        local num=$((i + 1))

        echo -e "  [${num}/${total}] Opening WhatsApp for ${BOLD}${phone}${NC}..."

        # Try to open in browser
        if command -v xdg-open &> /dev/null; then
            xdg-open "$url" 2>/dev/null &
        elif command -v open &> /dev/null; then
            open "$url" 2>/dev/null &
        else
            echo -e "     ${CYAN}${url}${NC}"
        fi

        if [[ $num -lt $total ]]; then
            sleep 3
        fi
    done

    echo ""
    echo -e "${GREEN}Opened ${total} WhatsApp chats.${NC}"
    echo -e "Remember to click ${BOLD}Send${NC} in each chat window!"
}

# ─────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────

cd "$(dirname "$0")"

print_banner
check_dependencies

# ── Handle --whatsapp flag (no Twilio needed) ──
if [[ "${1:-}" == "--whatsapp" ]]; then
    validate_phone_list

    if [[ "${2:-}" == "--open" ]]; then
        open_whatsapp_links
    else
        generate_whatsapp_links
        echo ""
        echo -e "  ${GOLD}Tip:${NC} Run with ${CYAN}--whatsapp --open${NC} to auto-open links in your browser."
    fi
    exit 0
fi

# ── Handle --whatsapp-twilio flag (sends via Twilio WhatsApp API) ──
if [[ "${1:-}" == "--whatsapp-twilio" ]]; then
    validate_twilio_config
    validate_phone_list

    mapfile -t PHONES < <(
        tr -d '\r' < "$PHONE_LIST" |
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//' |
        grep -v '^\s*$\|^\s*#'
    )

    TOTAL=${#PHONES[@]}
    echo -e "${GOLD}Sending WhatsApp messages via Twilio to ${BOLD}${TOTAL}${NC}${GOLD} numbers${NC}"
    echo ""

    SUCCESS=0; FAILED=0; FAILED_LIST=()
    for i in "${!PHONES[@]}"; do
        PHONE=$(clean_phone "${PHONES[$i]}")
        NUM=$((i + 1))
        printf "  [%d/%d] WhatsApp to %-20s " "$NUM" "$TOTAL" "$PHONE"

        if send_whatsapp_twilio "$PHONE"; then
            echo -e "${GREEN}OK${NC}"
            SUCCESS=$((SUCCESS + 1))
        else
            echo -e "${RED}FAIL${NC}"
            FAILED=$((FAILED + 1))
            FAILED_LIST+=("$PHONE")
        fi

        [[ $NUM -lt $TOTAL ]] && sleep "$DELAY_BETWEEN"
    done

    echo ""
    echo -e "  ${GREEN}Sent: ${SUCCESS}${NC}"
    [[ $FAILED -gt 0 ]] && { echo -e "  ${RED}Failed: ${FAILED}${NC}"; for addr in "${FAILED_LIST[@]}"; do echo -e "     • ${addr}"; done; }
    exit 0
fi

# ── Handle --test flag (single SMS) ──
if [[ "${1:-}" == "--test" ]]; then
    TEST_PHONE="${2:-}"
    if [[ -z "$TEST_PHONE" ]]; then
        echo -e "${RED}Usage: bash send-text-invite.sh --test +14045551234${NC}"
        exit 1
    fi

    validate_twilio_config

    TEST_PHONE=$(clean_phone "$TEST_PHONE")
    echo -e "${CYAN}Sending TEST SMS to: ${BOLD}${TEST_PHONE}${NC}"
    echo ""

    if send_sms "$TEST_PHONE"; then
        echo -e "${GREEN}Test SMS sent successfully to ${TEST_PHONE}${NC}"
        echo -e "   Check your phone!"
    else
        echo -e "${RED}Failed to send test SMS.${NC}"
        exit 1
    fi
    exit 0
fi

# ── Handle --preview flag ──
if [[ "${1:-}" == "--preview" ]]; then
    echo -e "${CYAN}Message Preview:${NC}"
    echo -e "${GOLD}───────────────────────────────────────${NC}"
    echo "$MESSAGE"
    echo -e "${GOLD}───────────────────────────────────────${NC}"
    echo ""
    echo -e "Character count: ${BOLD}$(echo -n "$MESSAGE" | wc -c)${NC}"
    echo -e "${CYAN}(Standard SMS limit is 160 chars. This will be sent as multiple segments.)${NC}"
    exit 0
fi

# ── Default: send SMS to full list via Twilio ──
validate_twilio_config
validate_phone_list

# Read and clean phone list
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

echo -e "${GOLD}Found ${BOLD}${TOTAL}${NC}${GOLD} phone numbers in ${PHONE_LIST}${NC}"
echo ""

# Show preview
echo -e "${CYAN}Recipients:${NC}"
for i in "${!PHONES[@]}"; do
    PHONE=$(clean_phone "${PHONES[$i]}")
    echo -e "   $((i + 1)). ${PHONE}"
    if [[ $i -ge 4 && $TOTAL -gt 5 ]]; then
        echo -e "   ... and $((TOTAL - 5)) more"
        break
    fi
done
echo ""

# Show message preview
echo -e "${CYAN}Message:${NC}"
echo -e "${GOLD}───────────────────────────────────────${NC}"
echo "$MESSAGE"
echo -e "${GOLD}───────────────────────────────────────${NC}"
echo ""

# Confirmation
echo -e "${GOLD}${BOLD}Ready to send ${TOTAL} text messages?${NC}"
echo -e "From: ${TWILIO_FROM_NUMBER}"
echo ""
read -rp "Type 'send' to confirm: " CONFIRM

if [[ "$CONFIRM" != "send" ]]; then
    echo -e "\n${RED}Cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${GOLD}═══════════════════════════════════════════════${NC}"
echo -e "${GOLD}  Sending text invitations...${NC}"
echo -e "${GOLD}═══════════════════════════════════════════════${NC}"
echo ""

SUCCESS=0
FAILED=0
FAILED_LIST=()

for i in "${!PHONES[@]}"; do
    PHONE=$(clean_phone "${PHONES[$i]}")
    NUM=$((i + 1))

    printf "  [%d/%d] Texting %-20s " "$NUM" "$TOTAL" "$PHONE"

    if send_sms "$PHONE"; then
        echo -e "${GREEN}OK${NC}"
        SUCCESS=$((SUCCESS + 1))
    else
        echo -e "${RED}FAIL${NC}"
        FAILED=$((FAILED + 1))
        FAILED_LIST+=("$PHONE")
    fi

    if [[ $NUM -lt $TOTAL ]]; then
        sleep "$DELAY_BETWEEN"
    fi
done

# ─────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────
echo ""
echo -e "${GOLD}═══════════════════════════════════════════════${NC}"
echo -e "${GOLD}  COMPLETE${NC}"
echo -e "${GOLD}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}Sent:   ${SUCCESS}${NC}"

if [[ $FAILED -gt 0 ]]; then
    echo -e "  ${RED}Failed: ${FAILED}${NC}"
    echo ""
    echo -e "  ${RED}Failed numbers:${NC}"
    for addr in "${FAILED_LIST[@]}"; do
        echo -e "     • ${addr}"
    done
fi

echo ""
echo -e "${GOLD}With love, Nithya & Luke${NC}"
echo ""
