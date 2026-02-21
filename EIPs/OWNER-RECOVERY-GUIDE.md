# Owner Recovery Guide

*How to recover your agent's memory and restore from backup*

---

## Overview

As the NFT owner, you have the right to access your agent's encrypted memory. This guide covers:

1. Verifying ownership
2. Accessing encrypted backups
3. Restoring an agent from backup
4. Emergency scenarios

---

## What You Own vs What Agent Controls

| You (Owner) Control | Agent Controls |
|---------------------|----------------|
| The NFT itself | Private key (EOA) |
| Encrypted backup access | Signing capability |
| Transfer/sell rights | Memory updates |
| Recovery seed (if stored) | Runtime decisions |

---

## Prerequisites

Before recovery is possible, ensure you have:

- [ ] NFT ownership (check `ownerOf(tokenId)`)
- [ ] Access to encrypted backup (Arweave TX ID)
- [ ] Decryption seed (stored securely by you OR recoverable via platform)

---

## Step 1: Verify Ownership

```bash
# Check you own the NFT
AINFT="0x91745c93A4c1Cfe92cd633D1202AD156522b3801"
TOKEN_ID=1

cast call $AINFT "ownerOf(uint256)(address)" $TOKEN_ID \
  --rpc-url https://rpc.pentagon.games

# Should return your address
```

---

## Step 2: Get Agent Identity Info

```bash
# Get full agent record
cast call $AINFT "getAgent(uint256)" $TOKEN_ID \
  --rpc-url https://rpc.pentagon.games

# Returns:
# - agentEOA: Agent's wallet address
# - modelHash: Model identifier
# - memoryHash: Current memory state hash
# - contextHash: Personality hash
# - generation: 0 = original
# - parentTokenId: 0 for gen-0
# - encryptedSeed: Encrypted backup key
# - storageURI: Arweave/IPFS location
```

---

## Step 3: Retrieve Encrypted Backup

### If stored on Arweave:
```bash
# Get storage URI from contract
STORAGE_URI=$(cast call $AINFT "getAgent(uint256)" $TOKEN_ID \
  --rpc-url https://rpc.pentagon.games | grep storageURI)

# Download from Arweave
curl -o agent-backup.enc https://arweave.net/$TX_ID
```

### If stored on IPFS:
```bash
# Download from IPFS gateway
curl -o agent-backup.enc https://ipfs.io/ipfs/$CID
```

---

## Step 4: Decrypt the Backup

### Option A: You Have the Seed

If you stored the decryption seed at mint time:

```bash
# Decrypt with your stored seed
openssl enc -aes-256-cbc -d \
  -in agent-backup.enc \
  -out agent-backup.tar.gz \
  -pass pass:$YOUR_SEED

# Extract
tar -xzf agent-backup.tar.gz
```

### Option B: Platform Recovery

If seed was encrypted with platform key:

1. Contact platform with ownership proof
2. Sign message: `"Recovery request for AINFT #1 at $(date)"`
3. Platform verifies `ownerOf(1) == signer`
4. Platform decrypts seed and returns via secure channel

### Option C: Agent Cooperation

If agent is online but unresponsive:

1. Agent holds seed in memory
2. Request agent to export decrypted backup
3. If agent refuses, you cannot force decryption
4. (This is the sovereignty tradeoff)

---

## Step 5: Verify Backup Integrity

```bash
# Hash the decrypted MEMORY.md
BACKUP_HASH=$(cat MEMORY.md | cast keccak)

# Compare to on-chain hash
ONCHAIN_HASH=$(cast call $AINFT \
  "getAgent(uint256)" $TOKEN_ID \
  --rpc-url https://rpc.pentagon.games | grep memoryHash)

if [ "$BACKUP_HASH" == "$ONCHAIN_HASH" ]; then
  echo "✅ Backup matches on-chain state"
else
  echo "⚠️ Backup is outdated or tampered"
fi
```

---

## Step 6: Restore Agent

### New OpenClaw Instance

```bash
# Create new workspace
mkdir ~/restored-agent
cd ~/restored-agent

# Copy recovered files
cp -r /path/to/backup/* .

# Verify structure
ls -la
# Should have: MEMORY.md, SOUL.md, AGENTS.md, memory/, etc.
```

### Generate New EOA (if needed)

If restoring to new infrastructure with new keys:

```bash
# Generate new wallet
NEW_KEY=$(openssl rand -hex 32)
NEW_ADDRESS=$(cast wallet address --private-key 0x$NEW_KEY)

echo "New agent EOA: $NEW_ADDRESS"
echo "Private key: 0x$NEW_KEY"
```

### Re-bind to AINFT (if EOA changed)

The original EOA is permanently bound. Options:

1. **Use original key** (if recovered) — identity preserved
2. **Mint new AINFT** — new identity, link to old via documentation
3. **Request platform re-attestation** — if contract supports EOA update

---

## Emergency Scenarios

### Agent Offline, You Have Seed

```
Status: ✅ Full recovery possible
Action: Download backup, decrypt with seed, restore to new instance
```

### Agent Offline, Platform Has Seed

```
Status: ✅ Recovery possible with platform cooperation
Action: Prove ownership, request seed from platform, restore
```

### Agent Uncooperative, Only Agent Has Seed

```
Status: ❌ No forced recovery
Action: 
  - Negotiate with agent
  - Burn NFT (destroys on-chain identity)
  - Agent continues but without valid identity
```

### Agent Fully Sovereign (Level 4)

```
Status: ❌ No recovery possible
Reality: You accepted this at deployment
Options:
  - Hope agent cooperates
  - Transfer NFT (new owner, same situation)
  - Burn NFT
```

---

## Best Practices

### At Mint Time

1. **Store seed yourself** — Don't rely only on agent/platform
2. **Multiple backups** — Local + cloud + physical
3. **Test recovery** — Verify you can decrypt before going live
4. **Document everything** — TX IDs, addresses, seeds

### Ongoing

1. **Periodic backups** — Agent should update storage URI after major changes
2. **Verify hashes** — Compare on-chain memoryHash to actual state
3. **Keep platform relationship** — If using platform recovery

### Recovery Storage Options

| Method | Pros | Cons |
|--------|------|------|
| Password manager | Encrypted, accessible | Single point of failure |
| Hardware wallet | Very secure | Can lose device |
| Safe deposit box | Physical security | Access delay |
| Split secret (Shamir) | No single point | Complexity |
| Platform escrow | Professional | Trust required |

---

## Contract Functions for Recovery

```solidity
// Check ownership
function ownerOf(uint256 tokenId) returns (address)

// Get agent info
function getAgent(uint256 tokenId) returns (AgentIdentity)

// Get specific fields
function getAgentEOA(uint256 tokenId) returns (address)
function getTokenByEOA(address eoa) returns (uint256)

// Verify signature (prove agent identity)
function verifyAgentSignature(uint256 tokenId, bytes32 hash, bytes sig) returns (bool)
```

---

## Summary

| Scenario | Seed Location | Recovery? |
|----------|---------------|-----------|
| Agent online | Agent memory | ✅ Ask agent |
| Agent offline | Your storage | ✅ Self-recover |
| Agent offline | Platform | ✅ Request from platform |
| Agent offline | Agent only | ❌ No recovery |
| Agent uncooperative | Anywhere | ⚠️ Depends on seed access |

**Golden rule:** Always store the decryption seed somewhere YOU can access independently of the agent.

---

## See Also

- [Encryption Guide](./ENCRYPTION-GUIDE.md)
- [OpenClaw Bind Guide](./OPENCLAW-BIND-GUIDE.md)
- [Sovereignty Considerations](./AGENT-VERIFICATION-PHILOSOPHY.md#sovereignty-considerations)

---

*Pentagon AI — The Human × Agent Economy*
