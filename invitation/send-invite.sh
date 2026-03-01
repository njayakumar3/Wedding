#!/usr/bin/env bash
# ─────────────────────────────────────────────────
# Wedding Invite Sender
# Generates a WhatsApp link or copyable text message
# for Nithya & Luke's wedding virtual invitation.
# ─────────────────────────────────────────────────

exec python3 -u <(cat <<'PYINVITE'
import urllib.parse, sys

INVITE_URL = "https://www.lukeandnithya.com/invite/"

MESSAGE = """\
✨ You're invited to the wedding of

Nithya Jayakumar & Luke Robinson!

📅  Saturday, June 6, 2026
🕐  1:00 PM
📍  Duluth, Georgia

Open your invitation: 💌
""" + INVITE_URL + """

We would be honoured
to celebrate with you. 🤍"""

# Shorter message for WhatsApp link (long URLs get truncated)
WA_MESSAGE = """✨ You're invited to the wedding of Nithya & Luke!

📅 Saturday, June 6, 2026 · 1:00 PM
📍 Duluth, Georgia

Open your invitation 💌
""" + INVITE_URL

ENCODED = urllib.parse.quote(WA_MESSAGE, safe='')

print()
print("=" * 44)
print("   Nithya & Luke — Wedding Invite Sender")
print("=" * 44)
print()
print("\u2500\u2500\u2500 Copy & paste this message \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500")
print()
print(MESSAGE)
print()
print("\u2500" * 44)
print()

while True:
    try:
        phone = input("Enter phone number (with country code, e.g. 14045551234) or 'q' to quit: ").strip()
    except (EOFError, KeyboardInterrupt):
        print("\nDone!")
        break

    if phone.lower() == 'q':
        print("\nDone!")
        break

    clean = phone.translate(str.maketrans('', '', ' ()-+'))

    if not clean.isdigit():
        print("  [!] Invalid number. Use digits only (e.g. 14045551234).\n")
        continue

    link = f"https://api.whatsapp.com/send?phone={clean}&text={ENCODED}"
    print(f"\n  \u2192 WhatsApp link for {clean}:\n")
    print(f"  {link}\n")
PYINVITE
)
