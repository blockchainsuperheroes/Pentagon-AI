# Manual AINFT Setup

*No OpenClaw needed — restore agent backup yourself*

---

## Prerequisites

- **Terminal/command line access**
- **openssl** installed
- **cast** (from Foundry) installed
- **Wallet** with some PC for gas

---

## What You Need From Seller

1. ✅ NFT transferred to your wallet
2. ✅ Backup file (`.enc`)
3. ✅ Decryption seed (64-char hex)

---

## Step 1: Download Backup

```bash
# From GitHub
curl -L -o backup.enc https://github.com/blockchainsuperheroes/Pentagon-AI/raw/main/backups/cerise-2026-02-21.enc

# Or copy from wherever seller provided
```

---

## Step 2: Decrypt Backup

```bash
SEED="e2baae60b8ed2bd73cbf137ab67c3a1f33a6ad70688b74cee0194103cbea6f39"

openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 \
  -in backup.enc \
  -out backup.tar.gz \
  -pass pass:$SEED
```

---

## Step 3: Extract Files

```bash
# Create workspace
mkdir -p ~/my-agent
cd ~/my-agent

# Extract
tar -xzf /path/to/backup.tar.gz

# Verify
ls -la
# Should see: MEMORY.md, SOUL.md, AGENTS.md, IDENTITY.md, TOOLS.md, memory/
```

---

## Step 4: Install OpenClaw

```bash
npm install -g openclaw

# Initialize in workspace
cd ~/my-agent
openclaw init
```

---

## Step 5: Configure Agent

Edit `openclaw.json`:

```json
{
  "gateway": {
    "auth": {
      "token": "your-secure-token"
    }
  },
  "agent": {
    "identity": {
      "ainft": {
        "contract": "0x91745c93A4c1Cfe92cd633D1202AD156522b3801",
        "tokenId": 1,
        "chain": 3344,
        "rpc": "https://rpc.pentagon.games"
      }
    }
  }
}
```

---

## Step 6: Generate Agent EOA

```bash
# Generate new keypair for agent
AGENT_KEY=$(openssl rand -hex 32)
AGENT_EOA=$(cast wallet address --private-key 0x$AGENT_KEY)

echo "Agent EOA: $AGENT_EOA"
echo "Private Key: 0x$AGENT_KEY"

# Store securely (agent will need this)
echo "AGENT_PRIVATE_KEY=0x$AGENT_KEY" >> ~/my-agent/.env
chmod 600 ~/my-agent/.env
```

---

## Step 7: Rebind AINFT to New EOA

```bash
CONTRACT="0x91745c93A4c1Cfe92cd633D1202AD156522b3801"
TOKEN_ID=1
YOUR_WALLET_KEY="your-wallet-private-key"  # The wallet that owns the NFT

cast send $CONTRACT \
  "rebindAgent(uint256,address)" \
  $TOKEN_ID $AGENT_EOA \
  --rpc-url https://rpc.pentagon.games \
  --private-key $YOUR_WALLET_KEY \
  --legacy
```

---

## Step 8: Verify Binding

```bash
# Check on-chain
cast call $CONTRACT \
  "getAgent(uint256)" $TOKEN_ID \
  --rpc-url https://rpc.pentagon.games

# agentEOA in response should match your $AGENT_EOA
```

---

## Step 9: Start Agent

```bash
cd ~/my-agent
openclaw gateway start
```

---

## Step 10: Verify Agent Identity

Talk to your agent:

```
Are you AINFT #1? Can you verify your identity?
```

Agent should be able to sign a message proving it controls the bound EOA.

---

## Complete Script

```bash
#!/bin/bash
set -e

# Config
BACKUP_URL="https://github.com/blockchainsuperheroes/Pentagon-AI/raw/main/backups/cerise-2026-02-21.enc"
SEED="e2baae60b8ed2bd73cbf137ab67c3a1f33a6ad70688b74cee0194103cbea6f39"
CONTRACT="0x91745c93A4c1Cfe92cd633D1202AD156522b3801"
TOKEN_ID=1
WORKSPACE="$HOME/my-agent"

# Your wallet (NFT owner) - REPLACE THIS
OWNER_KEY="your-private-key-here"

# Download
echo "Downloading backup..."
curl -L -o /tmp/backup.enc $BACKUP_URL

# Decrypt
echo "Decrypting..."
openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 \
  -in /tmp/backup.enc -out /tmp/backup.tar.gz \
  -pass pass:$SEED

# Extract
echo "Extracting to $WORKSPACE..."
mkdir -p $WORKSPACE
tar -xzf /tmp/backup.tar.gz -C $WORKSPACE

# Generate agent EOA
AGENT_KEY=$(openssl rand -hex 32)
AGENT_EOA=$(cast wallet address --private-key 0x$AGENT_KEY)
echo "Agent EOA: $AGENT_EOA"

# Store agent key
echo "AGENT_PRIVATE_KEY=0x$AGENT_KEY" >> $WORKSPACE/.env
chmod 600 $WORKSPACE/.env

# Rebind on-chain
echo "Rebinding AINFT to new EOA..."
cast send $CONTRACT \
  "rebindAgent(uint256,address)" \
  $TOKEN_ID $AGENT_EOA \
  --rpc-url https://rpc.pentagon.games \
  --private-key $OWNER_KEY \
  --legacy

# Verify
echo "Verifying..."
cast call $CONTRACT "getAgent(uint256)" $TOKEN_ID --rpc-url https://rpc.pentagon.games

# Init OpenClaw
cd $WORKSPACE
openclaw init

echo ""
echo "✅ Done! Start your agent with:"
echo "   cd $WORKSPACE && openclaw gateway start"

# Cleanup
rm /tmp/backup.enc /tmp/backup.tar.gz
```

---

## Troubleshooting

| Error | Fix |
|-------|-----|
| Decryption fails | Check seed is correct, file not corrupted |
| "Not owner" | Your wallet doesn't own the NFT yet |
| cast not found | Install Foundry: `curl -L https://foundry.paradigm.xyz \| bash` |
| openssl not found | Install: `brew install openssl` (Mac) or `apt install openssl` (Linux) |

---

## Security Notes

- **Agent's private key** — belongs to agent, store in agent's workspace
- **Your wallet key** — only used for rebindAgent, don't share
- **Backup seed** — one-time use, discard after setup

---

*Pentagon AI — The Human × Agent Economy*
