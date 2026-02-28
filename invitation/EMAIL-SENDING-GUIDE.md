# ✉️ Email Evite — Sending Guide

## Your file: `email-evite.html`

This is a fully email-client-compatible HTML invitation styled to match
your **lukeandnithya.com** warm gold & cream aesthetic.

---

## 🎨 What's Already Done

| Feature | Status |
|---|---|
| Table-based layout (email-safe) | ✅ |
| All styles inline | ✅ |
| Outlook VML fallbacks | ✅ |
| Mobile responsive (stacking, sizing) | ✅ |
| Dark mode prevention | ✅ |
| Bulletproof RSVP button | ✅ |
| Gmail preview text hack | ✅ |
| Warm gold/cream palette (`#c9a882`, `#FFF8F0`, `#8a6a3e`) | ✅ |

---

## 📋 Before You Send — Checklist

### 1. Host Your Images

Email clients **do not support local/relative images**. Every `<img src="">` must be an absolute URL.

**Options (best → easiest):**

| Method | Pros | How |
|---|---|---|
| **Your own site** | Most reliable, fast | Upload `couple-photo.jpg` to `lukeandnithya.com/images/` and use `https://www.lukeandnithya.com/images/couple-photo.jpg` |
| **Imgur** | Free, quick | Upload at imgur.com, use the direct image link |
| **Google Drive** | You already have it | Upload → Share → "Anyone with link" → convert link to direct format |
| **Cloudinary** | Free tier, auto-optimization | Sign up, drag-and-drop upload |

**Recommended image specs:**
- Couple photo: **320×352px** minimum (2x for retina)
- Format: **JPG** (smallest file size for email)
- Keep total email size **under 100KB** for fast loading

### 2. Update the RSVP Link

Find both instances of:
```
https://www.lukeandnithya.com
```
in the RSVP button section and replace with your Google Form URL or website RSVP page:
```
https://docs.google.com/forms/d/e/YOUR_FORM_ID/viewform
```

### 3. Update Preview Text

The hidden preview text (line ~68) is what shows in inbox previews next to
the subject line. Customize it:
```html
<div style="display: none; ..." aria-hidden="true">
    Your custom preview text here...
</div>
```

---

## 📧 How to Actually Send It

### Option A: Mailchimp / Mailerlite (Recommended for 50+ guests)

1. Create a free account at [mailchimp.com](https://mailchimp.com) or [mailerlite.com](https://mailerlite.com)
2. Create a new campaign → choose "Code your own" / "Custom HTML"
3. Paste the entire contents of `email-evite.html`
4. Import your guest list (CSV with name + email)
5. Send a test to yourself first
6. Schedule or send

**Why this is best:** Handles deliverability, unsubscribes, tracking, and inbox placement.

### Option B: Gmail (For small guest lists < 20)

> ⚠️ Gmail's compose editor strips most HTML. You need a workaround.

**Method — Chrome extension:**
1. Install the Chrome extension **"HTML Email" by cloudHQ** (free)
2. Open Gmail → Compose
3. Click the extension icon → paste your HTML
4. It injects the rendered HTML into the compose window
5. Send normally

**Method — Developer console (advanced):**
1. Open `email-evite.html` in Chrome
2. Select all (Ctrl+A), Copy (Ctrl+C)
3. In Gmail compose, paste (Ctrl+V)
4. Some styling may be lost — test first

### Option C: Outlook Desktop

1. Open `email-evite.html` in a browser
2. Select all (Ctrl+A), Copy (Ctrl+C)
3. New Email → paste into body
4. Outlook preserves table-based layouts well

### Option D: SendGrid / Amazon SES (Technical)

If you're comfortable with APIs, you can send programmatically:
```bash
# Example with SendGrid (after setup)
curl --request POST \
  --url https://api.sendgrid.com/v3/mail/send \
  --header "Authorization: Bearer YOUR_API_KEY" \
  --header "Content-Type: application/json" \
  --data '{"personalizations":[{"to":[{"email":"guest@email.com"}]}],"from":{"email":"nithya@lukeandnithya.com"},"subject":"You'\''re Invited!","content":[{"type":"text/html","value":"<PASTE HTML HERE>"}]}'
```

---

## 🔍 Email Rendering — The Reality

### How Different Clients Render HTML Email

| Client | CSS Support | Quirks |
|---|---|---|
| **Apple Mail / iOS Mail** | ✅ Excellent | Supports Google Fonts, media queries, everything |
| **Gmail (web)** | ⚠️ Good | Strips `<style>` from `<head>`, only inline styles survive. Our file is inline ✅ |
| **Gmail (app)** | ⚠️ Good | Same as web. Doesn't support media queries in `<style>` but inline works |
| **Outlook 2019/365 (desktop)** | ❌ Poor | Uses **Word's rendering engine** (!). No CSS `border-radius`, no `background-image`. We use VML fallbacks ✅ |
| **Outlook.com (web)** | ⚠️ Decent | Better than desktop Outlook. Strips some CSS |
| **Yahoo Mail** | ⚠️ Decent | Rewrites class names, but inline styles survive ✅ |
| **Samsung Mail** | ⚠️ OK | Similar to Gmail app |
| **Thunderbird** | ✅ Good | Solid rendering |

### What We Built To Handle This

1. **All styles are inline** → Gmail, Yahoo can't strip them
2. **Table-based layout** → Outlook Word engine handles tables fine
3. **VML code for Outlook** → The `<!--[if mso]>` blocks give Outlook its own button/image rendering
4. **Responsive `@media` queries** → For Apple Mail & iOS (the majority of mobile opens)
5. **Web-safe font stack** → `'Cormorant Garamond', Georgia, serif` — if Google Fonts fail, Georgia is beautiful too
6. **Dark mode prevention** → `color-scheme: light` meta tags keep your cream/gold intact

### Known Limitations (and why they're OK)

| What | Where | Impact |
|---|---|---|
| Google Fonts may not load | Gmail web, Outlook | Falls back to **Georgia** — still elegant |
| `border-radius` on photo | Outlook desktop | Photo shows as square — still looks great |
| Gradient dividers | Outlook desktop | Shows as solid line — perfectly fine |
| `opacity` property | Some old clients | Monogram may show fully opaque — subtle difference |

---

## 🧪 Testing Before You Send

### Free Testing Tools

1. **[Litmus PutsMail](https://putsmail.com/)** — paste HTML, send test to yourself
2. **[Email on Acid](https://www.emailonacid.com/)** — free trial, shows renders across 90+ clients
3. **[Mailtrap](https://mailtrap.io/)** — free tier, HTML email testing
4. **Send to yourself** — test on Gmail, iPhone Mail, and Outlook at minimum

### Quick Self-Test Checklist

- [ ] Open `email-evite.html` in browser — looks perfect?
- [ ] Send test to your **Gmail** — images load? Button works?
- [ ] Send test to your **iPhone** — responsive? Readable?
- [ ] Send test to an **Outlook** user (Luke?) — no broken layout?
- [ ] Click the RSVP button — goes to correct link?
- [ ] Check inbox preview text — reads well?

---

## 💌 Suggested Email Details

**Subject line ideas:**
- `You're Invited — Nithya & Luke, June 6, 2026`
- `Save the Date: Nithya & Luke's Wedding`
- `Together with their families… You're Invited ✨`
- `Join us for a celebration of love — June 6, 2026`

**From name:** `Nithya & Luke` (if your email service allows custom sender names)

---

## 📁 File Structure

```
invitation/
├── invitation.html          ← Original print invitation (5×7 card)
├── invitation.css           ← Print invitation styles
├── invitation_picture.png   ← Your couple photo
├── email-evite.html         ← ✨ EMAIL VERSION (this file)
├── EMAIL-SENDING-GUIDE.md   ← You are here
└── templates/               ← Alternative template options
```
