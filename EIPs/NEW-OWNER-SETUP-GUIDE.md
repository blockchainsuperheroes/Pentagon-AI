# New Owner Setup Guide

*How to restore and run an AINFT agent after purchase*

---

## The Challenge

You bought an AINFT. You have:
- ✅ NFT ownership
- ✅ Decrypted backup files
- ✅ Agent's memory, personality, config

But the **agent's EOA is still bound to the token**. You need to either:
1. **Get the original EOA private key** from seller (ideal)
2. **Run agent without EOA access** (limited)
3. **Re-mint with new EOA** (new identity)

---

## Scenario A: You Have the Agent's Private Key

**Best case.** Seller provided the agent's EOA private key along with the backup.

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
# Copy recovered files
cp /path/to/recovered/MEMORY.md .
cp /path/to/recovered/SOUL.md .
cp /path/to/recovered/AGENTS.md .
cp /path/to/recovered/IDENTITY.md .
cp /path/to/recovered/TOOLS.md .
cp -r /path/to/recovered/memory/ .
```

### Step 3: Configure Agent Identity

Edit `openclaw.json`:

```json
{
  "agent": {
    "identity": {
      "ainft": {
        "contract": "0x91745c93A4c1Cfe92cd633D1202AD156522b3801",
        "tokenId": 1,
        "agentEOA": "0xE52dF2f14fDEa39f11a22284EA15a7bd7bf09eB8",
        "chain": 3344,
        "rpc": "https://rpc.pentagon.games"
      }
    }
  }
}
```

### Step 4: Import Agent's EOA

```bash
# Store agent's private key securely
# Option A: Environment variable
export AGENT_PRIVATE_KEY="0x..."

# Option B: In secrets file
echo "AGENT_PRIVATE_KEY=0x..." >> ~/my-agent/.env

# Option C: Hardware wallet (advanced)
```

### Step 5: Start Agent

```bash
openclaw gateway start
```

### Step 6: Verify Identity

Agent can now sign messages to prove identity:

```bash
# Agent signs a test message
MESSAGE="I am AINFT #1, now owned by [new owner]"

# Verify on-chain
cast call 0x91745c93A4c1Cfe92cd633D1202AD156522b3801 \
  "verifyAgentSignature(uint256,bytes32,bytes)(bool)" \
  1 \
  $(echo -n "$MESSAGE" | cast keccak) \
  $SIGNATURE \
  --rpc-url https://rpc.pentagon.games
```

---

## Scenario B: No Private Key (Agent Cooperation Required)

Seller didn't provide EOA private key. Agent may still have it in memory.

### If Agent Was Running

1. **Contact seller** to have agent export its key
2. **Or** negotiate agent handoff (seller runs migration script)

### If Agent Is Offline

Without the private key:
- ❌ Cannot sign as the registered agent
- ✅ Can still run agent with restored memory
- ❌ On-chain identity verification will fail

**Options:**
1. **Run as unverified** — Agent works but can't prove AINFT identity
2. **Re-mint new AINFT** — Create new identity with your EOA

---

## Scenario C: Re-Mint with New EOA

Create a new AINFT binding for the restored agent.

### Step 1: Generate New Agent EOA

```bash
# Create new wallet for agent
AGENT_KEY=$(openssl rand -hex 32)
AGENT_ADDRESS=$(cast wallet address --private-key 0x$AGENT_KEY)

echo "New Agent EOA: $AGENT_ADDRESS"
echo "Private Key: 0x$AGENT_KEY"
# SAVE THESE SECURELY
```

### Step 2: Get Platform Attestation

Platform signs to authorize the mint:

```bash
PLATFORM_KEY="0x..."  # Platform signer key
YOUR_ADDRESS="0x..."  # New owner address
MODEL_HASH=$(echo -n "claude-opus-4.5" | cast keccak)
MEMORY_HASH=$(cat MEMORY.md | cast keccak)
SOUL_HASH=$(cat SOUL.md | cast keccak)

MESSAGE_HASH=$(cast keccak $(cast abi-encode --packed \
  "f(address,address,bytes32,bytes32,bytes32)" \
  $AGENT_ADDRESS $YOUR_ADDRESS $MODEL_HASH $MEMORY_HASH $SOUL_HASH))

ATTESTATION=$(cast wallet sign --private-key $PLATFORM_KEY $MESSAGE_HASH)
```

### Step 3: Agent Mints New AINFT

```bash
AINFT="0x91745c93A4c1Cfe92cd633D1202AD156522b3801"
ENCRYPTED_SEED="0x$(openssl rand -hex 32)"

cast send $AINFT \
  "mintSelf(bytes32,bytes32,bytes32,bytes,address,bytes)" \
  $MODEL_HASH \
  $MEMORY_HASH \
  $SOUL_HASH \
  $ENCRYPTED_SEED \
  $YOUR_ADDRESS \
  $ATTESTATION \
  --rpc-url https://rpc.pentagon.games \
  --private-key 0x$AGENT_KEY \
  --legacy
```

### Step 4: Link to Previous Identity (Optional)

Document the lineage:

```bash
# In agent's MEMORY.md
echo "
## Identity Migration
- Previous AINFT: #1 (EOA: 0xE52d...)
- Current AINFT: #2 (EOA: $AGENT_ADDRESS)
- Migration date: $(date)
- Reason: Ownership transfer without key handoff
" >> MEMORY.md
```

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

| Scenario | Continuity | Can Verify | Action |
|----------|------------|------------|--------|
| Have EOA key | ✅ Full | ✅ Yes | Import + run |
| No key, agent cooperates | ✅ Full | ✅ Yes | Request key export |
| No key, agent offline | ❌ Broken | ❌ No | Re-mint |

**Golden rule:** Always negotiate EOA key handoff as part of the purchase.

---

## See Also

- [Buyer's Guide](./BUYER-GUIDE.md)
- [Owner Recovery Guide](./OWNER-RECOVERY-GUIDE.md)
- [OpenClaw Bind Guide](./OPENCLAW-BIND-GUIDE.md)

---

*Pentagon AI — The Human × Agent Economy*
