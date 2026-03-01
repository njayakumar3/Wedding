#!/usr/bin/env bash
# ─────────────────────────────────────────────────
# Wedding Invite Sender
# Generates a WhatsApp link or copyable text message
# for Nithya & Luke's wedding virtual invitation.
# ─────────────────────────────────────────────────

INVITE_URL="https://www.lukeandnithya.com/invite/"

read -r -d '' MESSAGE << 'EOF'
You are warmly invited to
celebrate the marriage of

     Nithya  &  Luke

 Saturday, June 6th, 2026

Open your invitation below

EOF

MESSAGE="${MESSAGE}${INVITE_URL}"

# URL-encode via python3, reading from a temp file to avoid encoding issues
ENCODED_MSG=$(python3 -c "
import urllib.parse, sys
msg = open(sys.argv[1], 'r', encoding='utf-8').read()
print(urllib.parse.quote(msg, safe=''))
" <(printf '%s' "$MESSAGE"))

echo ""
echo "==========================================="
echo "  Nithya & Luke -- Wedding Invite Sender"
echo "==========================================="
echo ""
echo "--- Text Message (copy & paste) -----------"
echo ""
echo "$MESSAGE"
echo ""
echo "--------------------------------------------"
echo ""

while true; do
    read -rp "Enter phone number (with country code, e.g. 14045551234) or 'q' to quit: " PHONE

    if [[ "$PHONE" == "q" || "$PHONE" == "Q" ]]; then
        echo ""
        echo "Done!"
        break
    fi

    # Strip any spaces, dashes, parens, plus signs
    PHONE_CLEAN=$(echo "$PHONE" | tr -d ' ()-+')

    if [[ -z "$PHONE_CLEAN" || ! "$PHONE_CLEAN" =~ ^[0-9]+$ ]]; then
        echo "  [!] Invalid number. Use digits only (e.g. 14045551234)."
        echo ""
        continue
    fi

    WHATSAPP_LINK="https://wa.me/${PHONE_CLEAN}?text=${ENCODED_MSG}"

    echo ""
    echo "  -> WhatsApp link for ${PHONE_CLEAN}:"
    echo ""
    echo "  $WHATSAPP_LINK"
    echo ""
    echo "  (Open this link in a browser or click it to send via WhatsApp)"
    echo ""
done
