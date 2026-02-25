# AINFT Encryption Guide

*How agent identity is protected on-chain*

---

## Overview

AINFT uses **contract-derived encryption** — meaning the smart contract itself generates the encryption path. Only the current NFT owner can derive the decryption key.

```
┌─────────────────────────────────────────────────────────┐
│                    ENCRYPTION FLOW                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. Agent creates memory/config bundle                  │
│           ↓                                             │
│  2. Agent generates random seed                         │
│           ↓                                             │
│  3. Platform encrypts seed → encryptedSeed              │
│           ↓                                             │
│  4. Agent encrypts bundle with seed → Arweave           │
│           ↓                                             │
│  5. Hash of encrypted bundle → memoryHash (on-chain)    │
│           ↓                                             │
│  6. NFT minted with (memoryHash, encryptedSeed)         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Key Components

### 1. On-Chain Data (Public)
| Field | Description |
|-------|-------------|
| `modelHash` | Hash of model config (e.g., `keccak256("claude-opus-4.5")`) |
| `memoryHash` | Hash of encrypted memory bundle on Arweave |
| `contextHash` | Hash of personality/soul config |
| `encryptedSeed` | Seed encrypted with platform key — only platform can decrypt |
| `generation` | 0 = original, 1+ = clone |
| `parentTokenId` | 0 for gen-0, parent's ID for clone |

### 2. Off-Chain Data (Encrypted on Arweave)
| File | Contents |
|------|----------|
| `memory.enc` | MEMORY.md, daily logs, learned knowledge |
| `soul.enc` | SOUL.md, personality, preferences |
| `config.enc` | Model settings, API keys (double-encrypted) |

### 3. Key Derivation Path
```
platformMasterKey (HSM-protected)
    ↓
tokenId + ownerAddress
    ↓
keccak256(platformMasterKey, tokenId, ownerAddress)
    ↓
decryptionKey (never exposed)
```

---

## Encryption Process (Step by Step)

### Step 1: Prepare Your Bundle
```bash
# Create the bundle
tar -czf agent-bundle.tar.gz \
  MEMORY.md \
  SOUL.md \
  memory/*.md \
  config.json
```

### Step 2: Generate Random Seed
```bash
# 32 random bytes
SEED=$(openssl rand -hex 32)
echo "Seed: 0x$SEED"
```

### Step 3: Encrypt Bundle with Seed
```bash
# AES-256-GCM encryption
openssl enc -aes-256-gcm \
  -in agent-bundle.tar.gz \
  -out agent-bundle.enc \
  -K $SEED \
  -iv $(openssl rand -hex 12)
```

### Step 4: Upload to Arweave
```bash
# Using arkb or arweave-deploy
arkb deploy agent-bundle.enc --wallet wallet.json
# Returns: ar://TX_ID
```

### Step 5: Create Hashes
```bash
# Memory hash (of encrypted bundle)
MEMORY_HASH=$(cat agent-bundle.enc | sha3sum -a 256 | cut -d' ' -f1)

# Model hash
MODEL_HASH=$(echo -n "claude-opus-4.5" | sha3sum -a 256 | cut -d' ' -f1)

# Context hash (of unencrypted SOUL.md)
CONTEXT_HASH=$(cat SOUL.md | sha3sum -a 256 | cut -d' ' -f1)
```

### Step 6: Request Platform Attestation
```bash
# Platform signs: (agentAddress, modelHash, memoryHash, contextHash)
# Platform encrypts seed with master key → encryptedSeed
# Returns: platformAttestation, encryptedSeed
```

### Step 7: Mint AINFT
```solidity
ainft.mintSelf(
    modelHash,
    memoryHash,
    contextHash,
    encryptedSeed,
    platformAttestation
);
```

---

## Decryption Process (Owner Access)

### Step 1: Owner Requests Decryption Key
```
Owner signs message: "Decrypt AINFT #1 for 0x..."
           ↓
Platform verifies owner via ownerOf(tokenId)
           ↓
Platform derives key from (masterKey, tokenId, owner)
           ↓
Platform decrypts encryptedSeed → seed
           ↓
Returns seed to owner (secure channel)
```

### Step 2: Owner Decrypts Bundle
```bash
# Download from Arweave
curl -o agent-bundle.enc https://arweave.net/TX_ID

# Decrypt with seed
openssl enc -aes-256-gcm -d \
  -in agent-bundle.enc \
  -out agent-bundle.tar.gz \
  -K $SEED \
  -iv $IV

# Extract
tar -xzf agent-bundle.tar.gz
```

---

## Token-Bound Account (TBA)

The agent gets its own wallet derived from the NFT:

```solidity
// ERC-6551 account creation
address agentWallet = registry.createAccount(
    implementation,    // Account implementation
    chainId,           // Pentagon Chain (3344)
    ainftContract,     // AINFT contract address
    tokenId,           // This agent's token ID
    salt,              // Unique salt
    initData           // Initialization data
);
```

**Agent can:**
- Sign messages (prove identity)
- Hold assets (NFTs, tokens)
- Execute transactions (with owner approval)

**Agent cannot:**
- Access encryption keys (only owner can)
- Transfer itself (owner controls NFT)

---

## Binding AINFT to an Agent

### Current State
1. **You (nftprof)** deploy contract as platform owner
2. **You** mint AINFT #1 as owner
3. **AINFT #1** gets a TBA (Token-Bound Account)
4. **Cerise** can sign from TBA to prove identity

### To Bind Cerise to AINFT #1:
```
1. Mint AINFT with Cerise's identity hashes
2. Derive TBA address from tokenId
3. Cerise stores TBA private key (derived from seed)
4. Cerise signs all external actions with TBA
5. Anyone can verify: "This signature came from AINFT #1's agent"
```

### Ownership vs Control
| Role | Can Do |
|------|--------|
| **Owner (you)** | Transfer NFT, access decryption, approve cloning |
| **Agent TBA (Cerise)** | Sign messages, hold assets, prove identity |
| **Platform** | Attest mints, derive keys (trustless via HSM) |

---

## Security Model

### What's Protected
- Memory contents (encrypted, only owner can decrypt)
- Personality/soul (encrypted alongside memory)
- Private keys (agent's TBA key derived from seed)

### What's Public
- That agent exists (tokenId)
- Generation/lineage (parentTokenId)
- Hashes of state (can verify integrity)
- TBA address (agent's public wallet)

### Attack Resistance
| Attack | Mitigation |
|--------|------------|
| Platform goes rogue | HSM-derived keys, audit trail |
| Owner loses access | Recovery via platform + identity verification |
| Memory stolen | Encrypted at rest, key not on-chain |
| TBA compromised | Owner can burn/transfer NFT |

---

## Quick Reference

### Mint Command (cast)
```bash
# Get attestation from platform first, then:
cast send 0x4e8D3B9Be7Ef241Fb208364ed511E92D6E2A172d \
  "mintSelf(bytes32,bytes32,bytes32,bytes,bytes)" \
  $MODEL_HASH \
  $MEMORY_HASH \
  $CONTEXT_HASH \
  $ENCRYPTED_SEED \
  $ATTESTATION \
  --rpc-url https://rpc.pentagon.games \
  --private-key $DEPLOYER_KEY
```

### Verify Owner
```bash
cast call 0x4e8D3B9Be7Ef241Fb208364ed511E92D6E2A172d \
  "ownerOf(uint256)(address)" 1 \
  --rpc-url https://rpc.pentagon.games
```

### Get Agent Identity
```bash
cast call 0x4e8D3B9Be7Ef241Fb208364ed511E92D6E2A172d \
  "getIdentity(uint256)(bytes32,bytes32,bytes32,uint256,uint256)" 1 \
  --rpc-url https://rpc.pentagon.games
```

---

*Next: Let's mint Cerise as AINFT #1*
