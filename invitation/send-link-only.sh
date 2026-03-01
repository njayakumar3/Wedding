#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  send-link-only.sh — Send plain-text wedding invitations
#
#  The simplest option — a plain-text email with just the
#  essentials and a link to lukeandnithya.com. No HTML, no CSS,
#  no rendering issues. Works everywhere.
#
#  Usage:
#    1. Fill in invitation/.env with SMTP settings
#    2. Make sure emails.csv exists (one email per line)
#    3. Run:  bash send-link-only.sh
#    4. Test: bash send-link-only.sh --test me@gmail.com
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

# Credentials (from .env or environment)
SMTP_SERVER="${SMTP_SERVER:-smtp.gmail.com}"
SMTP_PORT="${SMTP_PORT:-587}"
SENDER_EMAIL="${SENDER_EMAIL:-your-email@gmail.com}"
SENDER_NAME="Nithya & Luke"
SENDER_PASSWORD="${SENDER_PASSWORD:-}"

# Email content
SUBJECT="You're Invited — Nithya & Luke's Wedding"
EMAIL_LIST="emails.csv"

# Delay between sends (seconds) — avoids rate limiting
DELAY_BETWEEN=2

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
    echo -e "${GOLD}  ║     ${BOLD}  Link-Only Invite Sender  ${NC}${GOLD}             ║${NC}"
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
        echo -e "${RED}Please set SENDER_EMAIL in ${CYAN}invitation/.env${NC}"
        exit 1
    fi

    if [[ -z "$SENDER_PASSWORD" ]]; then
        echo -e "${RED}No password set. Add SENDER_PASSWORD to ${CYAN}invitation/.env${NC}"
        echo -e "   Get an App Password at: ${CYAN}https://myaccount.google.com/apppasswords${NC}"
        exit 1
    fi

    if [[ ! -f "$EMAIL_LIST" ]]; then
        echo -e "${RED}Email list not found: ${EMAIL_LIST}${NC}"
        echo "   Create emails.csv with one email address per line."
        exit 1
    fi
}

send_email() {
    local recipient="$1"

    python3 -c "
import smtplib
import sys
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

plain = '''Together with their families,

Nithya & Luke
joyfully invite you to celebrate their marriage.

Saturday, the Sixth of June, 2026
at 1:00 PM
Duluth, Georgia

RSVP & Details: https://www.lukeandnithya.com

With love,
N & L'''

html = '''<!DOCTYPE html>
<html><head><meta charset=\"utf-8\"></head>
<body style=\"margin:0;padding:0;background:#f0ebe3;font-family:Georgia,serif;\">
<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" style=\"background:#f0ebe3;\"><tr><td align=\"center\" style=\"padding:40px 16px;\">
<table width=\"520\" cellpadding=\"0\" cellspacing=\"0\" style=\"max-width:520px;background:#fefcf4;border:1px solid #d4c4a8;\"><tr><td style=\"padding:48px 40px;text-align:center;\">

  <p style=\"margin:0 0 20px;font-size:13px;font-style:italic;color:#8c7a5a;letter-spacing:.1em;\">You are invited to the wedding of</p>

  <p style=\"margin:0 0 24px;font-size:32px;color:#4a3b27;letter-spacing:.04em;\">Nithya <span style=\"font-size:24px;color:#8c7a5a;\">&amp;</span> Luke</p>

  <a href=\"https://www.lukeandnithya.com\" target=\"_blank\" style=\"display:inline-block;padding:13px 40px;font-family:Georgia,serif;font-size:12px;color:#8a6a3e;letter-spacing:.14em;text-transform:uppercase;text-decoration:none;border:1px solid #c9a882;\">View Invitation</a>

</td></tr></table>
</td></tr></table>
</body></html>'''

msg = MIMEMultipart('alternative')
msg['Subject'] = '''${SUBJECT}'''
msg['From'] = '${SENDER_NAME} <${SENDER_EMAIL}>'
msg['To'] = '${recipient}'
msg['Reply-To'] = '${SENDER_EMAIL}'
msg.attach(MIMEText(plain, 'plain', 'utf-8'))
msg.attach(MIMEText(html, 'html', 'utf-8'))

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

cd "$(dirname "$0")"

print_banner
check_dependencies

# Handle --test flag
if [[ "${1:-}" == "--test" ]]; then
    TEST_EMAIL="${2:-}"
    if [[ -z "$TEST_EMAIL" ]]; then
        echo -e "${RED}Usage: bash send-link-only.sh --test your@email.com${NC}"
        exit 1
    fi

    validate_config

    echo -e "${CYAN}Sending TEST email to: ${BOLD}${TEST_EMAIL}${NC}"
    echo ""

    if send_email "$TEST_EMAIL"; then
        echo -e "${GREEN}Test email sent successfully.${NC}"
        echo -e "   Check your inbox (and spam folder) at ${BOLD}${TEST_EMAIL}${NC}"
    else
        echo -e "${RED}Failed to send test email.${NC}"
        exit 1
    fi
    exit 0
fi

# Full send mode
validate_config

# Read and clean email list
mapfile -t EMAILS < <(
    tr -d '\r' < "$EMAIL_LIST" |
    tr ',' '\n' |
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//' |
    grep -v '^\s*$\|^\s*#'
)

TOTAL=${#EMAILS[@]}

if [[ "$TOTAL" -eq 0 ]]; then
    echo -e "${RED}No email addresses found in ${EMAIL_LIST}${NC}"
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

# Confirmation
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
echo -e "${GOLD}  Sending plain-text invitations...${NC}"
echo -e "${GOLD}═══════════════════════════════════════════════${NC}"
echo ""

SUCCESS=0
FAILED=0
FAILED_LIST=()

for i in "${!EMAILS[@]}"; do
    EMAIL="${EMAILS[$i]}"
    NUM=$((i + 1))

    printf "  [%d/%d] Sending to %-40s " "$NUM" "$TOTAL" "$EMAIL"

    if send_email "$EMAIL"; then
        echo -e "${GREEN}OK${NC}"
        SUCCESS=$((SUCCESS + 1))
    else
        echo -e "${RED}FAIL${NC}"
        FAILED=$((FAILED + 1))
        FAILED_LIST+=("$EMAIL")
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
    echo -e "  ${RED}Failed addresses:${NC}"
    for addr in "${FAILED_LIST[@]}"; do
        echo -e "     • ${addr}"
    done
fi

echo ""
echo -e "${GOLD}With love, Nithya & Luke${NC}"
echo ""
