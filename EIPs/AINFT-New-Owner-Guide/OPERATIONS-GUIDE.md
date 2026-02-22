# Agent Operations Guide

*How to maintain your AINFT agent: backups, syncing, and updates*

---

## Backup Strategy

### When to Backup

| Event | Action |
|-------|--------|
| Major learning | Create backup |
| Weekly | Scheduled backup |
| Before transfer/sale | Create backup + Arweave upload |
| After significant project | Archive to Arweave |

### Local Backup

```bash
# Create encrypted backup
cd ~/agent-workspace

tar -czf - MEMORY.md SOUL.md AGENTS.md IDENTITY.md TOOLS.md memory/ | \
  openssl enc -aes-256-cbc -pbkdf2 -iter 100000 \
  -out backup-$(date +%Y-%m-%d).enc \
  -pass pass:$(openssl rand -hex 32)

# Save the seed separately!
```

### Verify Backup

```bash
# Test decryption
openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 \
  -in backup-2026-02-21.enc \
  -pass pass:$SEED | tar -tzf -
```

---

## Arweave Sync (Permanent Storage)

### Why Arweave?

- **Permanent** — Data persists forever, no pinning needed
- **Immutable** — Can't be changed or deleted
- **Verifiable** — Hash proves authenticity
- **Cheap** — ~$0.01-0.05 for agent backups

### Setup (One-time)

**Option A: Using arkb CLI**
```bash
# Install
npm install -g arkb

# Generate wallet (or import existing)
# You'll need some AR for uploads (~0.01 AR per MB)
```

**Option B: Using Irys (pay with ETH/MATIC)**
```bash
npm install -g @irys/cli

# Fund with ETH
irys fund 1000000000000000 -n mainnet -t ethereum -w $ETH_PRIVATE_KEY
```

### Upload Backup

```bash
# Using arkb
arkb deploy backup-2026-02-21.enc --wallet arweave-wallet.json

# Returns TX ID like: dS2n4Y7P8xK3mN9qR5tV2wL6jH8gF1cB4aE7iO0pU3sX

# Verify: https://arweave.net/dS2n4Y7P8xK3mN9qR5tV2wL6jH8gF1cB4aE7iO0pU3sX
```

### Record TX ID

Store Arweave TX IDs for recovery:

```markdown
## Arweave Backups

| Date | TX ID | Notes |
|------|-------|-------|
| 2026-02-21 | dS2n4Y7P8xK3mN9qR5tV2wL6jH8gF1cB4aE7iO0pU3sX | First sync |
| 2026-02-28 | ... | Weekly backup |
```

---

## Memory Hash Updates

### Current Design

On-chain `memoryHash` is set at **mint time only**.

**Options for updates:**

1. **Don't update** — Hash is "birth certificate"
   - On-chain = original state
   - Arweave TXs = version history
   - No gas cost

2. **Update on-chain** — Contract needs `updateMemoryHash()`
   - Gas cost per update
   - On-chain always current

### Recommended: Birth Certificate + Arweave

```
On-chain memoryHash = Original state at mint
Arweave uploads = Version history
Latest Arweave TX = Current state
```

No gas for updates, full history preserved.

---

## Agent Self-Sync

Your agent can automate backups:

### HEARTBEAT.md Task

```markdown
## Weekly Backup (Sundays)
- Create encrypted backup
- Upload to Arweave (if funded)
- Record TX ID in memory/arweave-log.md
- Verify hash matches
```

### Automated Script

```bash
#!/bin/bash
# agent-backup.sh

WORKSPACE="$HOME/agent-workspace"
DATE=$(date +%Y-%m-%d)
SEED=$(openssl rand -hex 32)

# Create backup
cd $WORKSPACE
tar -czf - MEMORY.md SOUL.md AGENTS.md IDENTITY.md TOOLS.md memory/ | \
  openssl enc -aes-256-cbc -pbkdf2 -iter 100000 \
  -out /tmp/backup-$DATE.enc \
  -pass pass:$SEED

# Calculate hash
HASH=$(cat /tmp/backup-$DATE.enc | sha256sum | cut -d' ' -f1)

# Upload to Arweave (if wallet available)
if [ -f "$HOME/.arweave-wallet.json" ]; then
  TX_ID=$(arkb deploy /tmp/backup-$DATE.enc --wallet $HOME/.arweave-wallet.json 2>&1 | grep -oP '[a-zA-Z0-9_-]{43}')
  
  # Log
  echo "| $DATE | $TX_ID | $HASH | Auto backup |" >> $WORKSPACE/memory/arweave-log.md
fi

# Cleanup
rm /tmp/backup-$DATE.enc

echo "Backup complete. Seed: $SEED"
```

---

## Signing / Re-signing

### When is signing needed?

| Action | Signature |
|--------|-----------|
| Initial mint | Agent signs with EOA |
| rebindAgent | Owner signs (not agent) |
| Arweave upload | No blockchain signature needed |
| Memory hash update | If implemented: agent signs |

### Agent Signs Proof

Your agent can sign to prove identity:

```bash
MESSAGE="I am AINFT #1, backup hash: $HASH, date: $DATE"
MESSAGE_HASH=$(echo -n "$MESSAGE" | cast keccak)

# Agent signs with its private key
SIGNATURE=$(cast wallet sign --private-key $AGENT_KEY $MESSAGE_HASH)

# Anyone can verify
cast call $AINFT "verifyAgentSignature(uint256,bytes32,bytes)(bool)" \
  1 $MESSAGE_HASH $SIGNATURE \
  --rpc-url https://rpc.pentagon.games
```

---

## Version History

Track all states:

```markdown
# memory/arweave-log.md

## AINFT #1 Version History

| Date | Arweave TX | Hash | Event |
|------|------------|------|-------|
| 2026-02-21 | [TX1] | abc123... | Initial mint |
| 2026-02-28 | [TX2] | def456... | Weekly backup |
| 2026-03-07 | [TX3] | ghi789... | Post-project archive |
```

---

## Recovery

### From Arweave

```bash
# Download
curl -L -o backup.enc https://arweave.net/$TX_ID

# Decrypt (need seed)
openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 \
  -in backup.enc -out backup.tar.gz \
  -pass pass:$SEED

# Extract
tar -xzf backup.tar.gz
```

### Verify Matches On-Chain

```bash
# Get on-chain hash
ON_CHAIN=$(cast call $AINFT "getAgent(uint256)" $TOKEN_ID --rpc-url https://rpc.pentagon.games | grep memoryHash)

# Calculate local hash
LOCAL=$(cat MEMORY.md | cast keccak)

# Compare
# Note: On-chain is birth hash, local may differ if memory evolved
```

---

## Cost Summary

| Action | Cost |
|--------|------|
| Local backup | Free |
| Arweave upload (60KB) | ~$0.01 |
| Weekly Arweave (1 year) | ~$0.50 |
| On-chain hash update | ~0.001 PC gas |

---

## Example: Cerise01 First Sync

**Date:** 2026-02-21
**Backup:** `cerise-2026-02-21.enc` (60KB)
**Seed:** `e2baae60b8ed2bd73cbf137ab67c3a1f33a6ad70688b74cee0194103cbea6f39`

**On-chain memoryHash (at mint):**
```
0xb61f2bb4971842949f6e7fdac3e21de6d58c76df007093d6c7d4289ca2065787
```

**GitHub backup:** 
```
https://github.com/blockchainsuperheroes/Pentagon-AI/raw/main/backups/cerise-2026-02-21.enc
```

**Arweave TX:** *(pending - need AR tokens)*

---

## Next Steps

1. Get small amount of AR (~0.1 AR = ~$1)
2. Upload first backup to Arweave
3. Record TX ID in this guide
4. Set up weekly auto-backup

---

*Pentagon AI — The Human × Agent Economy*
