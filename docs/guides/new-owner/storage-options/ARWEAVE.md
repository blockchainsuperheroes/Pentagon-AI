# Arweave Storage

*Permanent, immutable storage via arkb CLI*

---

## Overview

- **Permanence:** Forever (pay once, stored forever)
- **Cost:** ~$5-10 per GB (~$0.01 for 60KB backup)
- **Requires:** AR tokens
- **Best for:** Developers, automation, large backups

---

## Setup

### Install arkb

```bash
npm install -g arkb
```

### Get AR Tokens

1. Buy AR on exchange (Binance, etc.)
2. Create wallet at arweave.app
3. Transfer AR to wallet
4. Download wallet JSON

### Save Wallet

```bash
arkb wallet-save /path/to/arweave-wallet.json
```

---

## Upload Backup

```bash
# Single file
arkb deploy backup-2026-02-21.enc

# Returns TX ID
# e.g., dS2n4Y7P8xK3mN9qR5tV2wL6jH8gF1cB4aE7iO0pU3sX
```

---

## Verify Upload

```bash
# Check status
arkb status dS2n4Y7P8xK3mN9qR5tV2wL6jH8gF1cB4aE7iO0pU3sX

# View file
# https://arweave.net/dS2n4Y7P8xK3mN9qR5tV2wL6jH8gF1cB4aE7iO0pU3sX
```

---

## Download/Recover

```bash
curl -L -o backup.enc https://arweave.net/$TX_ID
```

---

## Automation Script

```bash
#!/bin/bash
# weekly-backup.sh

WORKSPACE="$HOME/agent-workspace"
DATE=$(date +%Y-%m-%d)
SEED=$(openssl rand -hex 32)

# Create backup
cd $WORKSPACE
tar -czf - MEMORY.md SOUL.md AGENTS.md memory/ | \
  openssl enc -aes-256-cbc -pbkdf2 -iter 100000 \
  -out /tmp/backup-$DATE.enc \
  -pass pass:$SEED

# Upload
TX_ID=$(arkb deploy /tmp/backup-$DATE.enc 2>&1 | grep -oP '[a-zA-Z0-9_-]{43}')

# Log
echo "| $DATE | $TX_ID | $SEED |" >> $WORKSPACE/memory/arweave-log.md

# Cleanup
rm /tmp/backup-$DATE.enc

echo "Uploaded: https://arweave.net/$TX_ID"
echo "Seed: $SEED (SAVE THIS)"
```

---

## Cost Estimate

| Backup Size | Cost |
|-------------|------|
| 60KB | ~$0.01 |
| 500KB | ~$0.05 |
| 1MB | ~$0.10 |
| Weekly/year | ~$0.50-5.00 |

---

## Pros & Cons

**Pros:**
- Truly permanent
- Immutable (can't be deleted)
- Decentralized
- CLI automation

**Cons:**
- Need to buy AR tokens
- No free tier
- Wallet setup required

---

*Pentagon AI — The Human × Agent Economy*
