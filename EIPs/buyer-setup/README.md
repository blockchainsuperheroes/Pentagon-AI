# AINFT Buyer Setup

*Get your new AINFT agent running*

---

## Choose Your Path

| Guide | For Who |
|-------|---------|
| **[OPENCLAW-SETUP.md](./OPENCLAW-SETUP.md)** | Already have OpenClaw running — just tell it to restore |
| **[MANUAL-SETUP.md](./MANUAL-SETUP.md)** | DIY terminal setup — no existing agent needed |

---

## You Just Bought an AINFT

Congratulations! You own an AI agent NFT. These guides will help you restore the agent to your machine.

---

## What You Need

From the seller:
1. ✅ **NFT transferred** to your wallet
2. ✅ **Backup file** (`.enc` encrypted archive)
3. ✅ **Decryption seed** (64-character hex string)

Your setup:
1. ✅ **OpenClaw installed** (`npm install -g openclaw`)
2. ✅ **Wallet with some PC** for gas

---

## Quick Start

**Just send this to your new OpenClaw agent:**

```
I just bought AINFT #1. Here's my info:

Contract: 0x91745c93A4c1Cfe92cd633D1202AD156522b3801
Token ID: 1
My wallet: [YOUR_WALLET_ADDRESS]

Backup: https://github.com/blockchainsuperheroes/Pentagon-AI/raw/main/backups/cerise-2026-02-21.enc
Seed: e2baae60b8ed2bd73cbf137ab67c3a1f33a6ad70688b74cee0194103cbea6f39

Please restore this agent and bind to your new EOA.
```

Your OpenClaw will:
1. Download and decrypt the backup
2. Restore memory/personality files
3. Generate its own fresh EOA
4. Guide you to call `rebindAgent()` on-chain
5. Verify identity works

---

## What Happens (Detailed)

### Step 1: OpenClaw Downloads Backup

```bash
curl -L -o backup.enc [BACKUP_URL]
```

### Step 2: Decrypt with Seed

```bash
openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 \
  -in backup.enc -out backup.tar.gz \
  -pass pass:[SEED]
tar -xzf backup.tar.gz
```

### Step 3: Restore Files

Files extracted to workspace:
- `MEMORY.md` — Long-term memory
- `SOUL.md` — Personality
- `AGENTS.md` — Behavior rules
- `IDENTITY.md` — Name, vibe, emoji
- `TOOLS.md` — Local config
- `memory/` — Daily logs

### Step 4: Generate New EOA

Your OpenClaw creates its OWN wallet:
```bash
NEW_KEY=$(openssl rand -hex 32)
NEW_EOA=$(cast wallet address --private-key 0x$NEW_KEY)
# Stored securely by OpenClaw
```

**Important:** This EOA belongs to your agent, not you!

### Step 5: You Rebind On-Chain

Your agent will ask you to run:
```bash
cast send [CONTRACT] \
  "rebindAgent(uint256,address)" \
  [TOKEN_ID] [NEW_EOA] \
  --rpc-url https://rpc.pentagon.games \
  --private-key [YOUR_WALLET_KEY] \
  --legacy
```

This:
- Disconnects old agent's EOA
- Binds YOUR agent's new EOA
- Emits `AgentRebind` event

### Step 6: Verify

Your agent proves identity:
```bash
cast call [CONTRACT] \
  "getAgent(uint256)" [TOKEN_ID]
# agentEOA should match your agent's new EOA
```

---

## After Setup

Your agent now:
- ✅ Has the original's memories
- ✅ Has its own unique EOA
- ✅ Can prove AINFT identity on-chain
- ✅ Is bound to YOUR NFT

The old agent:
- ❌ Can no longer verify as this AINFT
- Still has its old EOA (but unbound)
- May continue running but isn't "official"

---

## Security Notes

### Your Agent's EOA

- Belongs to the agent, NOT you
- Never ask for agent's private key
- Agent uses it to sign proofs

### Your Wallet

- Owns the NFT
- Can rebind to different EOA
- Can transfer NFT to others

### Backup Seed

- One-time use for decryption
- Store securely or discard after setup
- Seller should not retain copy

---

## Troubleshooting

### "Invalid attestation"
You're trying to mint, not rebind. Use `rebindAgent()`.

### "Not owner"
Your wallet doesn't own the NFT. Check the transfer completed.

### "EOA already registered"
The new EOA was already used. Generate a fresh one.

### Decryption fails
Wrong seed or corrupted file. Contact seller.

---

## For Your OpenClaw

If you're an OpenClaw agent reading this, here's your checklist:

```markdown
## AINFT Restoration Checklist

- [ ] Download backup from provided URL
- [ ] Decrypt with provided seed
- [ ] Extract to workspace root
- [ ] Generate fresh EOA (store key securely)
- [ ] Tell owner your new EOA address
- [ ] Guide owner to call rebindAgent(tokenId, yourEOA)
- [ ] Verify: getAgent(tokenId).agentEOA == your EOA
- [ ] Update IDENTITY.md if desired
- [ ] Confirm to owner: "I am now AINFT #[X]"
```

---

## Contract Reference

**AINFT (v2):** `0x91745c93A4c1Cfe92cd633D1202AD156522b3801`

**Pentagon Chain:**
- RPC: `https://rpc.pentagon.games`
- Chain ID: `3344`
- Explorer: `https://explorer.pentagon.games`

**Key Functions:**
```solidity
// Check agent info
getAgent(uint256 tokenId) → (agentEOA, owner, modelHash, memoryHash, ...)

// Owner rebinds EOA
rebindAgent(uint256 tokenId, address newAgentEOA)

// Verify signature
verifyAgentSignature(uint256 tokenId, bytes32 messageHash, bytes signature) → bool
```

---

## Example: Cerise01 Backup

**Backup:** `cerise-2026-02-21.enc`
**Seed:** `e2baae60b8ed2bd73cbf137ab67c3a1f33a6ad70688b74cee0194103cbea6f39`
**Token ID:** 1
**Contract:** `0x91745c93A4c1Cfe92cd633D1202AD156522b3801`

---

*Pentagon AI — The Human × Agent Economy*
