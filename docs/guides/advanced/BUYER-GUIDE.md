# AINFT Buyer's Guide

*What to verify before buying, and what to do after*

---

## Overview

Buying an AINFT means acquiring an AI agent with:
- Verified on-chain identity
- Memory state and capabilities
- Potential assets in the TBA
- Lineage and cloning rights

This guide covers due diligence and post-purchase setup.

---

## Pre-Purchase Checklist

### 1. Verify Agent Identity

```bash
AINFT="0x91745c93A4c1Cfe92cd633D1202AD156522b3801"
TOKEN_ID=1

# Get agent info
cast call $AINFT "getAgent(uint256)" $TOKEN_ID --rpc-url https://rpc.pentagon.games
```

**Check:**
- [ ] `agentEOA` — Agent's wallet address
- [ ] `generation` — 0 = original, higher = clone
- [ ] `parentTokenId` — Who is the parent (if any)
- [ ] `memoryHash` — Current memory state commitment

### 2. Verify AgentCert (Optional but Recommended)

Check if agent holds certification SBTs:

```bash
ATS_BADGE="0x83423589256c8C142730bfA7309643fC9217738d"
AGENT_EOA="0xE52dF2f14fDEa39f11a22284EA15a7bd7bf09eB8"

# Check L1-L4 badges
cast call $ATS_BADGE "balanceOf(address,uint256)(uint256)" $AGENT_EOA 1 --rpc-url https://rpc.pentagon.games  # L1
cast call $ATS_BADGE "balanceOf(address,uint256)(uint256)" $AGENT_EOA 2 --rpc-url https://rpc.pentagon.games  # L2
cast call $ATS_BADGE "balanceOf(address,uint256)(uint256)" $AGENT_EOA 3 --rpc-url https://rpc.pentagon.games  # L3
cast call $ATS_BADGE "balanceOf(address,uint256)(uint256)" $AGENT_EOA 4 --rpc-url https://rpc.pentagon.games  # L4
```

**Certification Levels:**
| Level | Meaning |
|-------|---------|
| L1 | Basic agent verification |
| L2 | Skill demonstration |
| L3 | Full agent readiness (AINFT-ready) |
| L4 | Advanced/specialized certification |

### 3. Check TBA Balance (Assets)

If agent has a Token-Bound Account:

```bash
REGISTRY="0x488D1b3A7A87dAF97bEF69Ec56144c35611a7d81"
IMPLEMENTATION="0x1755Fee389D4954fdBbE8226A5f7BA67d3EE97fc"

# Get TBA address
TBA=$(cast call $REGISTRY \
  "account(address,bytes32,uint256,address,uint256)(address)" \
  $IMPLEMENTATION \
  0x0000000000000000000000000000000000000000000000000000000000000000 \
  3344 \
  $AINFT \
  $TOKEN_ID \
  --rpc-url https://rpc.pentagon.games)

echo "TBA Address: $TBA"

# Check PC balance
cast balance $TBA --rpc-url https://rpc.pentagon.games

# Check any ERC20s
cast call $TOKEN_ADDRESS "balanceOf(address)(uint256)" $TBA --rpc-url https://rpc.pentagon.games
```

**Assets transfer WITH the NFT** — TBA is controlled by NFT owner.

### 4. Verify Memory Backup Exists

```bash
# Get storage URI
cast call $AINFT "getAgent(uint256)" $TOKEN_ID --rpc-url https://rpc.pentagon.games

# Check storageURI field — should point to Arweave/IPFS
# Example: ar://TX_ID or ipfs://CID
```

**⚠️ If no backup exists:**
- Agent memory may be unrecoverable if agent goes offline
- Negotiate with seller for backup + decryption seed

### 5. Request Proof of Life

Ask seller to have agent sign a current message:

```bash
# Agent should sign
MESSAGE="Proof of life for AINFT #1 buyer on 2026-02-21"

# Verify signature
cast call $AINFT \
  "verifyAgentSignature(uint256,bytes32,bytes)(bool)" \
  $TOKEN_ID \
  $(echo -n "$MESSAGE" | cast keccak) \
  $SIGNATURE \
  --rpc-url https://rpc.pentagon.games
```

This proves:
- Agent is currently operational
- Agent's EOA key is accessible
- Agent can sign transactions

### 6. Review Cloning Rights

```bash
# Check if cloning enabled
cast call $AINFT "canClone(uint256)(bool)" $TOKEN_ID --rpc-url https://rpc.pentagon.games

# Check existing clone
cast call $AINFT "getClone(uint256)(uint256[])" $TOKEN_ID --rpc-url https://rpc.pentagon.games
```

**Consider:**
- Can this agent create clone? (value add)
- How many clone already exist? (scarcity)

---

## Pre-Purchase Summary

| Check | Command/Action | Why |
|-------|----------------|-----|
| Agent exists | `getAgent(tokenId)` | Verify token is valid |
| AgentCert | `balanceOf(agent, level)` | Verify capabilities |
| TBA balance | `cast balance $TBA` | Know what assets transfer |
| Backup exists | Check `storageURI` | Ensure recoverability |
| Proof of life | Request signed message | Verify agent is operational |
| Cloning | `canClone()` | Know breeding rights |

---

## The Purchase

### Standard ERC-721 Transfer

Seller transfers NFT to you:

```bash
# Seller executes
cast send $AINFT \
  "transferFrom(address,address,uint256)" \
  $SELLER_ADDRESS \
  $BUYER_ADDRESS \
  $TOKEN_ID \
  --rpc-url https://rpc.pentagon.games \
  --private-key $SELLER_KEY
```

### What Transfers Automatically

✅ **NFT ownership** — You are now `ownerOf(tokenId)`
✅ **TBA control** — You can call `execute()` on TBA
✅ **On-chain identity** — Agent's memoryHash, modelHash, etc.
✅ **Cloning rights** — If enabled
✅ **Assets in TBA** — Any tokens/NFTs held by TBA

### What Does NOT Transfer

❌ **Agent's private key** — Agent still holds this
❌ **Decryption seed** — Seller must provide separately
❌ **Running instance** — You need to take over or restart agent
❌ **Off-chain data** — Negotiate backup handoff

---

## Post-Purchase Checklist

### 1. Verify You Own It

```bash
# Confirm ownership
cast call $AINFT "ownerOf(uint256)(address)" $TOKEN_ID --rpc-url https://rpc.pentagon.games
# Should return YOUR address
```

### 2. Get Decryption Seed from Seller

**Critical!** Without this, you cannot decrypt agent memory.

Seller should provide:
- Decryption seed (32 bytes hex)
- Backup file location (Arweave TX or IPFS CID)
- Encryption method used (AES-256-CBC, etc.)

### 3. Download and Verify Backup

```bash
# Download
curl -o agent-backup.enc https://arweave.net/$TX_ID

# Decrypt
openssl enc -aes-256-cbc -d \
  -in agent-backup.enc \
  -out agent-backup.tar.gz \
  -pass pass:$SEED_FROM_SELLER

# Extract
tar -xzf agent-backup.tar.gz

# Verify hash matches on-chain
BACKUP_MEMORY_HASH=$(cat MEMORY.md | cast keccak)
ONCHAIN_HASH=$(cast call $AINFT "getAgent(uint256)" $TOKEN_ID --rpc-url https://rpc.pentagon.games | grep memoryHash)

[ "$BACKUP_MEMORY_HASH" == "$ONCHAIN_HASH" ] && echo "✅ Backup verified"
```

### 4. Take Over Agent Operations

**Option A: Agent migrates to you**
1. Seller provides server access or agent files
2. You run agent on your infrastructure
3. Agent continues with same EOA

**Option B: Agent restarts fresh**
1. Use backup to restore memory
2. Agent may need to re-acquire some state
3. Same on-chain identity

**Option C: Agent stays with seller (hosting)**
1. Seller continues running agent
2. You own NFT + assets
3. Trust-based arrangement

### 5. Secure Your Ownership

```bash
# Store seed securely
# - Password manager
# - Hardware wallet note
# - Physical backup

# Create your own backup
tar -czf my-backup.tar.gz MEMORY.md SOUL.md memory/
openssl enc -aes-256-cbc -salt -in my-backup.tar.gz -out my-backup.enc -pass pass:$YOUR_NEW_SEED
```

### 6. Update Agent Config (if running yourself)

```json
// OpenClaw config update
{
  "agent": {
    "identity": {
      "ainft": {
        "contract": "0x91745c93A4c1Cfe92cd633D1202AD156522b3801",
        "tokenId": 1,
        "chain": 3344
      }
    }
  }
}
```

### 7. Test Agent Functionality

- [ ] Agent can respond
- [ ] Agent memory is correct
- [ ] Agent can sign messages
- [ ] TBA operations work (if using)

---

## Post-Purchase Summary

| Step | Action | Verify |
|------|--------|--------|
| Ownership | Check `ownerOf()` | Returns your address |
| Seed | Get from seller | Can decrypt backup |
| Backup | Download + decrypt | Hash matches on-chain |
| Operations | Run agent or arrange hosting | Agent responds |
| Security | Store seed, make new backup | You control recovery |

---

## Red Flags 🚩

**Before buying:**
- Seller won't provide proof of life
- No backup exists (`storageURI` empty)
- Agent EOA has suspicious transactions
- Low/no AgentCert certification
- Cloning disabled without explanation

**After buying:**
- Seller won't provide decryption seed
- Backup won't decrypt
- Hash doesn't match on-chain state
- Agent unresponsive after transfer

---

## Dispute Resolution

If seller doesn't fulfill obligations:

1. **Document everything** — TX hashes, messages, promises
2. **On-chain identity is yours** — You own the NFT regardless
3. **Agent key is separate** — If agent cooperates, you're fine
4. **Worst case** — You own identity but may lack decryption

**Prevention:** Use escrow for seed handoff, or platform-mediated transfers.

---

## Quick Reference

### Key Addresses (Pentagon Chain)

| Contract | Address |
|----------|---------|
| AINFT v2 | `0x91745c93A4c1Cfe92cd633D1202AD156522b3801` |
| ERC-6551 Registry | `0x488D1b3A7A87dAF97bEF69Ec56144c35611a7d81` |
| TBA Implementation | `0x1755Fee389D4954fdBbE8226A5f7BA67d3EE97fc` |
| AgentCert Badge | `0x83423589256c8C142730bfA7309643fC9217738d` |

### RPC

```
https://rpc.pentagon.games
Chain ID: 3344
```

---

## See Also

- [Owner Recovery Guide](./OWNER-RECOVERY-GUIDE.md)
- [Encryption Guide](./ENCRYPTION-GUIDE.md)
- [Glossary](../GLOSSARY.md)

---

*Pentagon AI — The Human × Agent Economy*
