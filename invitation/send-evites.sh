#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  send-evites.sh — Send wedding email invitations
#  
#  Reads email addresses from emails.csv (one per line)
#  and sends the HTML evite to each guest via SMTP.
#
#  Usage:
#    1. Fill in your SMTP settings below
#    2. Make sure emails.csv exists (one email per line)
#    3. Run:  bash send-evites.sh
#    4. Optional: bash send-evites.sh --test me@gmail.com
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ─────────────────────────────────────────
# CONFIGURATION — loaded from .env file
# ─────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

# Load .env if it exists
if [[ -f "$ENV_FILE" ]]; then
    # Read .env, skip comments and blank lines
    while IFS='=' read -r key value; do
        key=$(echo "$key" | xargs)             # trim whitespace
        [[ -z "$key" || "$key" == \#* ]] && continue
        value=$(echo "$value" | xargs | sed 's/^["'\'']*//;s/["'\'']*$//')  # trim quotes
        export "$key=$value"
    done < "$ENV_FILE"
fi

# Credentials (from .env or environment)
SMTP_SERVER="${SMTP_SERVER:-smtp.gmail.com}"
SMTP_PORT="${SMTP_PORT:-587}"
SENDER_EMAIL="${SENDER_EMAIL:-your-email@gmail.com}"
SENDER_NAME="Nithya & Luke"
SENDER_PASSWORD="${SENDER_PASSWORD:-}"

# Email content
SUBJECT="You're Invited — Nithya & Luke's Wedding 💒"
HTML_FILE="email-evite.html"
EMAIL_LIST="emails.csv"

# Delay between sends (seconds) — avoids rate limiting
DELAY_BETWEEN=2

# ─────────────────────────────────────────
# GMAIL APP PASSWORD INSTRUCTIONS
# ─────────────────────────────────────────
# Gmail blocks "less secure apps" so you need an App Password:
#
#   1. Go to https://myaccount.google.com/security
#   2. Enable 2-Step Verification (if not already on)
#   3. Go to https://myaccount.google.com/apppasswords
#   4. Select "Mail" → "Other (Custom name)" → type "Wedding Evite"
#   5. Copy the 16-character password
#   6. Paste it as SENDER_PASSWORD above
#
# ⚠️  NEVER commit this file with your password filled in!
#     Use: export EVITE_PASSWORD="xxxx" and read from env instead.
# ─────────────────────────────────────────

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
GOLD='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ─────────────────────────────────────────
# FUNCTIONS
# ─────────────────────────────────────────

print_banner() {
    echo ""
    echo -e "${GOLD}  ╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GOLD}  ║                                              ║${NC}"
    echo -e "${GOLD}  ║     ${BOLD}💌  Wedding Evite Sender  💌${NC}${GOLD}              ║${NC}"
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
}

validate_config() {
    if [[ "$SENDER_EMAIL" == "your-email@gmail.com" ]]; then
        echo -e "${RED}⚠  Please set SENDER_EMAIL in ${CYAN}invitation/.env${NC}"
        exit 1
    fi

    if [[ -z "$SENDER_PASSWORD" ]]; then
        echo -e "${RED}⚠  No password set. Add SENDER_PASSWORD to ${CYAN}invitation/.env${NC}"
        echo -e "   Get an App Password at: ${CYAN}https://myaccount.google.com/apppasswords${NC}"
        exit 1
    fi

    if [[ ! -f "$HTML_FILE" ]]; then
        echo -e "${RED}⚠  HTML file not found: ${HTML_FILE}${NC}"
        echo "   Make sure you're running this from the invitation/ directory."
        exit 1
    fi

    if [[ ! -f "$EMAIL_LIST" ]]; then
        echo -e "${RED}⚠  Email list not found: ${EMAIL_LIST}${NC}"
        echo "   Create emails.csv with one email address per line."
        exit 1
    fi
}

send_email() {
    local recipient="$1"
    local html_content="$2"

    python3 -c "
import smtplib
import sys
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

msg = MIMEMultipart('alternative')
msg['Subject'] = '''${SUBJECT}'''
msg['From'] = '${SENDER_NAME} <${SENDER_EMAIL}>'
msg['To'] = '${recipient}'
msg['Reply-To'] = '${SENDER_EMAIL}'

# Plain text fallback for clients that don't render HTML
text_part = MIMEText(
    'Nithya & Luke joyfully invite you to celebrate their wedding!\n\n'
    'Saturday, June 6, 2026 at 1:00 PM\n'
    '1700 Buford Highway, Duluth, Georgia 30097\n'
    'Formal Attire Requested\n\n'
    'Kindly respond by May 15th\n'
    'RSVP & Details: https://www.lukeandnithya.com\n\n'
    'With love, Nithya & Luke',
    'plain', 'utf-8'
)

html_part = MIMEText(open('${HTML_FILE}', 'r', encoding='utf-8').read(), 'html', 'utf-8')

# Attach plain text first, HTML second (email clients prefer the last one they can render)
msg.attach(text_part)
msg.attach(html_part)

try:
    server = smtplib.SMTP('${SMTP_SERVER}', ${SMTP_PORT})
    server.ehlo()
    server.starttls()
    server.ehlo()
    server.login('${SENDER_EMAIL}', '${SENDER_PASSWORD}')
    server.sendmail('${SENDER_EMAIL}', '${recipient}', msg.as_string())
    server.quit()
    sys.exit(0)
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
"
}

# ─────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────

# Change to script's directory
cd "$(dirname "$0")"

print_banner
check_dependencies

# Handle --test flag
if [[ "${1:-}" == "--test" ]]; then
    TEST_EMAIL="${2:-}"
    if [[ -z "$TEST_EMAIL" ]]; then
        echo -e "${RED}Usage: bash send-evites.sh --test your@email.com${NC}"
        exit 1
    fi

    validate_config

    echo -e "${CYAN}📧 Sending TEST email to: ${BOLD}${TEST_EMAIL}${NC}"
    echo ""

    if send_email "$TEST_EMAIL" ""; then
        echo -e "${GREEN}✅ Test email sent successfully!${NC}"
        echo -e "   Check your inbox (and spam folder) at ${BOLD}${TEST_EMAIL}${NC}"
    else
        echo -e "${RED}❌ Failed to send test email.${NC}"
        exit 1
    fi
    exit 0
fi

# Full send mode
validate_config

# Read and clean email list
mapfile -t EMAILS < <(grep -v '^\s*$\|^\s*#' "$EMAIL_LIST" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -d '\r')

TOTAL=${#EMAILS[@]}

if [[ "$TOTAL" -eq 0 ]]; then
    echo -e "${RED}⚠  No email addresses found in ${EMAIL_LIST}${NC}"
    exit 1
fi

echo -e "${GOLD}Found ${BOLD}${TOTAL}${NC}${GOLD} email addresses in ${EMAIL_LIST}${NC}"
echo ""

# Show preview
echo -e "${CYAN}Recipients:${NC}"
for i in "${!EMAILS[@]}"; do
    echo -e "   $((i + 1)). ${EMAILS[$i]}"
    if [[ $i -ge 4 && $TOTAL -gt 5 ]]; then
        echo -e "   ... and $((TOTAL - 5)) more"
        break
    fi
done
echo ""

# Confirmation prompt
echo -e "${GOLD}${BOLD}Ready to send ${TOTAL} invitations?${NC}"
echo -e "Subject: ${SUBJECT}"
echo -e "From: ${SENDER_NAME} <${SENDER_EMAIL}>"
echo ""
read -rp "Type 'send' to confirm: " CONFIRM

if [[ "$CONFIRM" != "send" ]]; then
    echo -e "\n${RED}Cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${GOLD}═══════════════════════════════════════════════${NC}"
echo -e "${GOLD}  Sending invitations...${NC}"
echo -e "${GOLD}═══════════════════════════════════════════════${NC}"
echo ""

SUCCESS=0
FAILED=0
FAILED_LIST=()

for i in "${!EMAILS[@]}"; do
    EMAIL="${EMAILS[$i]}"
    NUM=$((i + 1))

    printf "  [%d/%d] Sending to %-40s " "$NUM" "$TOTAL" "$EMAIL"

    if send_email "$EMAIL" ""; then
        echo -e "${GREEN}✅${NC}"
        ((SUCCESS++))
    else
        echo -e "${RED}❌${NC}"
        ((FAILED++))
        FAILED_LIST+=("$EMAIL")
    fi

    # Delay between sends (skip after last)
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
echo -e "  ${GREEN}✅ Sent successfully:  ${SUCCESS}${NC}"

if [[ $FAILED -gt 0 ]]; then
    echo -e "  ${RED}❌ Failed:             ${FAILED}${NC}"
    echo ""
    echo -e "  ${RED}Failed addresses:${NC}"
    for addr in "${FAILED_LIST[@]}"; do
        echo -e "     • ${addr}"
    done
fi

echo ""
echo -e "${GOLD}💌 With love, Nithya & Luke${NC}"
echo ""
