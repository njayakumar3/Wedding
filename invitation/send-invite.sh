#!/usr/bin/env bash
# ─────────────────────────────────────────────────
# Wedding Invite Sender
# Generates a WhatsApp link or copyable text message
# for Nithya & Luke's wedding virtual invitation.
# ─────────────────────────────────────────────────

exec python3 -u - <<'PYINVITE'
import urllib.parse, sys

INVITE_URL = "https://www.lukeandnithya.com/invite/"

MESSAGE = """\
\u2022 \u2022 \u2022

You\u2019re joyfully invited
to celebrate the wedding of

\u2728 Nithya & Luke \u2728

\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
\U0001F4C5 Saturday, June 6, 2026
\U0001F553 1:00 in the afternoon
\U0001F4CD Duluth, Georgia
\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500

Open your invitation \U0001F48C
""" + INVITE_URL + """

We would be so honored
to have you there \U0001F90D

\u2022 \u2022 \u2022"""

ENCODED = urllib.parse.quote(MESSAGE, safe='')

print()
print("=" * 44)
print("   Nithya & Luke \u2014 Wedding Invite Sender")
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

    link = f"https://wa.me/{clean}?text={ENCODED}"
    print(f"\n  \u2192 WhatsApp link for {clean}:\n")
    print(f"  {link}\n")
PYINVITE
