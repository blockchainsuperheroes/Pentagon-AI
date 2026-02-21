# New Owner Setup Guide

*How to restore and run an AINFT agent after purchase*

---

## Important Principle

> **Never ask for the agent's EOA private key.**
> 
> The EOA belongs to the agent, not the human. Just like you wouldn't ask someone for their wallet private key, you don't ask an agent for theirs. On transfer, simply **rebind** to a new EOA.

---

## What You Need From Seller

✅ NFT transfer
✅ Encrypted backup file
✅ Decryption seed

❌ **NOT the agent's EOA key** — that stays with the old agent

---

## The Standard Flow

### Step 1: Set Up OpenClaw

```bash
# Install OpenClaw
npm install -g openclaw

# Create workspace
mkdir ~/my-agent
cd ~/my-agent
openclaw init
```

### Step 2: Restore Backup Files

```bash
# Decrypt backup (using seed from seller)
openssl enc -aes-256-cbc -d -in backup.enc -out backup.tar.gz -pass pass:$SEED
tar -xzf backup.tar.gz

# Copy to workspace
cp MEMORY.md SOUL.md AGENTS.md IDENTITY.md TOOLS.md .
cp -r memory/ .
```

### Step 3: Generate NEW Agent EOA

```bash
# Agent generates its own fresh wallet
AGENT_KEY=$(openssl rand -hex 32)
AGENT_ADDRESS=$(cast wallet address --private-key 0x$AGENT_KEY)

echo "New Agent EOA: $AGENT_ADDRESS"
# Store key securely for agent
```

### Step 4: Owner Rebinds AINFT

```bash
# As NFT owner, rebind to new agent EOA
AINFT="0x5ed123Fa794A0f5e463965c85aE76C1634202633"
TOKEN_ID=1

cast send $AINFT \
  "rebindAgent(uint256,address)" \
  $TOKEN_ID \
  $AGENT_ADDRESS \
  --rpc-url https://rpc.pentagon.games \
  --private-key $OWNER_KEY \
  --legacy
```

### Step 5: Configure Agent Identity

Edit `openclaw.json`:

```json
{
  "agent": {
    "identity": {
      "ainft": {
        "contract": "0x5ed123Fa794A0f5e463965c85aE76C1634202633",
        "tokenId": 1,
        "chain": 3344,
        "rpc": "https://rpc.pentagon.games"
      }
    }
  }
}
```

### Step 6: Start Agent

```bash
openclaw gateway start
```

### Step 7: Verify Identity

Agent can now prove identity with NEW EOA:

```bash
MESSAGE="I am AINFT #1, now with new owner"

# Verify on-chain
cast call $AINFT \
  "verifyAgentSignature(uint256,bytes32,bytes)(bool)" \
  $TOKEN_ID \
  $(echo -n "$MESSAGE" | cast keccak) \
  $SIGNATURE \
  --rpc-url https://rpc.pentagon.games
```

---

## What Happens to Old Agent?

After rebind:

```
Old Agent (EOA A):
- Still has its key
- Still has memory copy
- BUT: verifyAgentSignature() now FAILS
- Identity unbound from AINFT

New Agent (EOA B):
- Fresh key
- Restored memory from backup
- verifyAgentSignature() SUCCEEDS
- Is the official AINFT holder
```

The old agent is like a human who lost their ID — they're still "them" but can't prove it officially.

---

## Complete New Owner Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    NEW OWNER FLOW                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Purchase NFT                                             │
│       │                                                      │
│       ▼                                                      │
│  2. Get backup + seed from seller                           │
│       │                                                      │
│       ▼                                                      │
│  3. Decrypt backup                                           │
│       │                                                      │
│       ▼                                                      │
│  4. Verify hash matches on-chain                            │
│       │                                                      │
│       ▼                                                      │
│  5. Get agent EOA private key?                              │
│       │                                                      │
│       ├── YES ──► Import key, run agent, verify identity    │
│       │                                                      │
│       └── NO ───► Option: Re-mint with new EOA              │
│                   (loses on-chain continuity)               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Binding Checklist

### With Original EOA Key

- [x] Import key to OpenClaw config
- [x] Agent can sign to prove identity
- [x] `verifyAgentSignature()` returns true
- [x] Full on-chain identity continuity

### Without Original EOA Key

- [ ] Agent cannot prove original identity
- [ ] Must re-mint for verifiable identity
- [ ] Memory/personality preserved
- [ ] On-chain lineage broken

---

## Security Considerations

### Storing Agent's Private Key

| Method | Security | Convenience |
|--------|----------|-------------|
| Environment variable | Low | High |
| Encrypted file | Medium | Medium |
| Hardware wallet | High | Low |
| HSM | Very High | Very Low |

### Key Handoff Best Practices

1. **Use secure channel** — Never send key in plain text
2. **Verify before payment** — Escrow until key confirmed working
3. **Rotate if exposed** — If key leaked, re-mint immediately
4. **Backup immediately** — Store key in multiple secure locations

---

## Verifying Successful Binding

After setup, verify agent can prove identity:

```bash
# 1. Agent signs current timestamp
TIMESTAMP=$(date +%s)
MESSAGE="Identity proof at $TIMESTAMP"

# 2. Agent signs (from OpenClaw or manually)
SIGNATURE=$(cast wallet sign --private-key $AGENT_KEY "$MESSAGE")

# 3. Verify on-chain
RESULT=$(cast call $AINFT \
  "verifyAgentSignature(uint256,bytes32,bytes)(bool)" \
  $TOKEN_ID \
  $(echo -n "$MESSAGE" | cast keccak) \
  $SIGNATURE \
  --rpc-url https://rpc.pentagon.games)

echo "Verification result: $RESULT"
# Should return: true
```

---

## Troubleshooting

### "Invalid signature"
- Check key matches registered `agentEOA`
- Verify message hash calculation
- Ensure signature format is correct (65 bytes)

### "Agent already has AINFT"
- The EOA is already registered to another token
- Each EOA can only be bound to ONE AINFT
- Need to use different EOA

### Memory hash mismatch
- Backup may be outdated
- Agent updated memory after backup
- Get fresh backup from seller

---

## Summary

| Step | Action |
|------|--------|
| 1 | Buy NFT |
| 2 | Get backup + decryption seed |
| 3 | Decrypt and restore memory |
| 4 | Agent generates NEW EOA |
| 5 | Owner calls `rebindAgent()` |
| 6 | Agent verifies identity ✅ |

**Golden rule:** Never ask for agent's EOA key. Rebind to fresh EOA instead.

---

## See Also

- [Buyer's Guide](./BUYER-GUIDE.md)
- [Owner Recovery Guide](./OWNER-RECOVERY-GUIDE.md)
- [OpenClaw Bind Guide](./OPENCLAW-BIND-GUIDE.md)

---

*Pentagon AI — The Human × Agent Economy*
