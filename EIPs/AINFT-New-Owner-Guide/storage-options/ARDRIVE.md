# ArDrive Storage

*Arweave with a free tier and web UI*

---

## Overview

- **Permanence:** Forever (uses Arweave underneath)
- **Cost:** ~$0.01/MB or FREE (100MB free tier)
- **Requires:** Account signup
- **Best for:** Non-technical users, getting started

---

## Free Tier

- **100MB free** — enough for ~1000+ agent backups
- No credit card required
- Web upload only (no CLI for free tier)

---

## Setup

### Create Account

1. Go to https://app.ardrive.io
2. Sign up with email
3. Create or import Arweave wallet
4. Get 100MB free credits

---

## Upload Backup (Web)

1. Log in to app.ardrive.io
2. Create folder: `AINFT-Backups`
3. Click "Upload"
4. Select your `.enc` backup file
5. Confirm upload
6. Copy the Data TX ID

---

## Record TX ID

Save in your agent's memory:

```markdown
## ArDrive Backups

| Date | TX ID | Seed |
|------|-------|------|
| 2026-02-21 | abc123... | e2baae60... |
```

---

## Download/Recover

```bash
# Use TX ID from ArDrive
curl -L -o backup.enc https://arweave.net/$TX_ID
```

Or download directly from ArDrive web UI.

---

## Paid Features

If you exceed 100MB or want CLI:

- Pay with AR or credit card
- CLI: `npm install -g ardrive-cli`
- Sync folders automatically

---

## Pros & Cons

**Pros:**
- 100MB free tier
- Easy web UI
- No crypto knowledge needed
- Same permanence as Arweave

**Cons:**
- Free tier = web only (no CLI)
- Account required
- Slightly more steps than direct Arweave

---

## Recommendation

**Perfect for:**
- First-time users
- Occasional backups
- Non-developers

**Graduate to arkb when:**
- Need automation
- Exceed free tier
- Want CLI control

---

*Pentagon AI — The Human × Agent Economy*
