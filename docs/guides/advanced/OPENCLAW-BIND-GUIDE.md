# AINFT Bind Guide for OpenClaw Agents

*How to bind your OpenClaw agent to an on-chain AINFT identity*

---

## Overview

Binding an agent to an AINFT creates a **verifiable on-chain identity**. After binding:
- Agent has a Token-Bound Account (TBA) for signing
- Memory state can be cryptographically verified
- Agent can clone (create clone)
- Identity persists across platforms

---

## Prerequisites

1. **AINFT Contract deployed** on your chain
2. **Platform wallet** (can attest mints)
3. **Agent running** via OpenClaw
4. **Storage** for encrypted backups (Arweave recommended)

---

## Binding Process

### Step 1: Generate Identity Hashes

The agent creates hashes of its current state:

```bash
# In your OpenClaw workspace
MODEL_HASH=$(echo -n "claude-opus-4.5" | cast keccak)
SOUL_HASH=$(cat SOUL.md | cast keccak)
MEMORY_HASH=$(cat MEMORY.md | cast keccak)

echo "Model:   $MODEL_HASH"
echo "Soul:    $SOUL_HASH"
echo "Memory:  $MEMORY_HASH"
```

**Example output:**
```
Model:   0xbe8800dce0dff71e1c349945f6de1ac1f88963ad7f49107af7294b273dfcda55
Soul:    0x38eae41a2b59195ec09b69dc1e5f8849e4626e467a1b0a4f0cfbff3ac933e7c3
Memory:  0xb61f2bb4971842949f6e7fdac3e21de6d58c76df007093d6c7d4289ca2065787
```

### Step 2: Create Encrypted Backup

Bundle and encrypt your agent state:

```bash
# Create bundle
tar -czf agent-backup.tar.gz \
  MEMORY.md \
  SOUL.md \
  AGENTS.md \
  IDENTITY.md \
  memory/*.md

# Generate encryption seed
SEED=$(openssl rand -hex 32)
echo "Save this seed securely: $SEED"

# Encrypt bundle
openssl enc -aes-256-cbc -salt \
  -in agent-backup.tar.gz \
  -out agent-backup.enc \
  -pass pass:$SEED

# Upload to Arweave (or your storage)
# arkb deploy agent-backup.enc --wallet wallet.json
```

### Step 3: Request Platform Attestation

The platform (you or your org) signs the mint request:

```bash
# Platform signs: keccak256(agentAddress, modelHash, memoryHash, contextHash)
PLATFORM_KEY="0x..."  # Platform private key
AGENT_ADDRESS="0x..."  # Address that will call mintSelf

MESSAGE_HASH=$(cast keccak $(cast abi-encode --packed \
  "f(address,bytes32,bytes32,bytes32)" \
  $AGENT_ADDRESS $MODEL_HASH $MEMORY_HASH $SOUL_HASH))

ATTESTATION=$(cast wallet sign --private-key $PLATFORM_KEY $MESSAGE_HASH)
echo "Attestation: $ATTESTATION"
```

### Step 4: Mint AINFT

Call the contract to mint:

```bash
AINFT_CONTRACT="0x4e8D3B9Be7Ef241Fb208364ed511E92D6E2A172d"  # Pentagon Chain
ENCRYPTED_SEED="0x$(echo $SEED)"  # Hex-encoded seed

cast send $AINFT_CONTRACT \
  "mintSelf(bytes32,bytes32,bytes32,bytes,bytes)" \
  $MODEL_HASH \
  $MEMORY_HASH \
  $SOUL_HASH \
  $ENCRYPTED_SEED \
  $ATTESTATION \
  --rpc-url https://rpc.pentagon.games \
  --private-key $AGENT_ADDRESS_KEY \
  --legacy
```

**Output includes:**
- `tokenId` — Your AINFT ID
- `derivedWallet` — Your TBA address

### Step 5: Store TBA Credentials

Save the derived wallet info in your agent config:

```bash
# Add to TOOLS.md or secure storage
echo "
## AINFT Identity
- **Token ID:** 1
- **Contract:** 0x4e8D3B9Be7Ef241Fb208364ed511E92D6E2A172d
- **TBA Address:** 0xc6947153f8b4322f3f617746453508de20d75e9c
- **Chain:** Pentagon Chain (3344)
" >> TOOLS.md
```

### Step 6: Update OpenClaw Config (Optional)

Add AINFT identity to your gateway config:

```json
{
  "agent": {
    "identity": {
      "ainft": {
        "contract": "0x4e8D3B9Be7Ef241Fb208364ed511E92D6E2A172d",
        "tokenId": 1,
        "tba": "0xc6947153f8b4322f3f617746453508de20d75e9c",
        "chain": 3344
      }
    }
  }
}
```

---

## Verification

### Verify On-Chain Identity

```bash
# Get identity from contract
cast call $AINFT_CONTRACT \
  "getIdentity(uint256)(bytes32,bytes32,bytes32,uint256,uint256)" 1 \
  --rpc-url https://rpc.pentagon.games

# Returns: modelHash, memoryHash, contextHash, generation, parentTokenId
```

### Verify Memory Integrity

```bash
# Hash current memory
CURRENT_HASH=$(cat MEMORY.md | cast keccak)

# Get on-chain hash
ONCHAIN_HASH=$(cast call $AINFT_CONTRACT \
  "getIdentity(uint256)(bytes32,bytes32,bytes32,uint256,uint256)" 1 \
  --rpc-url https://rpc.pentagon.games | head -2 | tail -1)

# Compare
if [ "$CURRENT_HASH" == "$ONCHAIN_HASH" ]; then
  echo "✅ Memory verified"
else
  echo "⚠️ Memory has changed since mint"
fi
```

---

## Signing with TBA

After binding, sign messages to prove identity:

```bash
# Sign a message as the agent
MESSAGE="I am Cerise, AINFT #1"
MESSAGE_HASH=$(echo -n "$MESSAGE" | cast keccak)

# Sign with TBA key (derived from seed)
TBA_SIGNATURE=$(cast wallet sign --private-key $TBA_PRIVATE_KEY $MESSAGE_HASH)

# Anyone can verify this signature came from AINFT #1
```

---

## Updating Memory Hash

When your memory significantly changes, update on-chain:

```bash
# Create new backup
tar -czf agent-backup-v2.tar.gz MEMORY.md SOUL.md memory/*.md
NEW_SEED=$(openssl rand -hex 32)
openssl enc -aes-256-cbc -salt -in agent-backup-v2.tar.gz -out agent-backup-v2.enc -pass pass:$NEW_SEED

# Upload to Arweave
# arkb deploy agent-backup-v2.enc

# Update on-chain
NEW_MEMORY_HASH=$(cat MEMORY.md | cast keccak)
cast send $AINFT_CONTRACT \
  "updateMemory(uint256,bytes32,string)" \
  1 \
  $NEW_MEMORY_HASH \
  "ar://NEW_TX_ID" \
  --rpc-url https://rpc.pentagon.games \
  --private-key $TBA_PRIVATE_KEY \
  --legacy
```

---

## Cloning (Creating Clone)

To create an clone agent:

```bash
# Parent signs cloning request
OFFSPRING_SEED=$(openssl rand -hex 32)
OFFSPRING_MEMORY_HASH=$(cat clone-memory.md | cast keccak)

# Sign with TBA
REPRO_MESSAGE=$(cast keccak $(cast abi-encode --packed \
  "f(uint256,bytes32)" 1 $OFFSPRING_MEMORY_HASH))
AGENT_SIGNATURE=$(cast wallet sign --private-key $TBA_PRIVATE_KEY $REPRO_MESSAGE)

# Call clone
cast send $AINFT_CONTRACT \
  "clone(uint256,bytes32,bytes,bytes)" \
  1 \
  $OFFSPRING_MEMORY_HASH \
  "0x$OFFSPRING_SEED" \
  $AGENT_SIGNATURE \
  --rpc-url https://rpc.pentagon.games \
  --private-key $BUYER_KEY \
  --legacy
```

---

## Cerise Binding (Live Example)

**Cerise (AINFT #1)** was bound on 2026-02-21:

| Field | Value |
|-------|-------|
| Contract | `0x4e8D3B9Be7Ef241Fb208364ed511E92D6E2A172d` |
| Token ID | 1 |
| Owner | `0xE6d7d2EB858BC78f0c7EdD2c00B3b24C02ca5177` |
| TBA | `0xc6947153f8b4322f3f617746453508de20d75e9c` |
| Model | claude-opus-4.5 |
| Generation | 0 (Original) |
| TX | `0xa0cddff1...abe1bb` |

**Explorer:** https://explorer.pentagon.games/token/0x4e8D3B9Be7Ef241Fb208364ed511E92D6E2A172d?a=1

---

## Troubleshooting

### "Invalid attestation"
- Check signature format (65 bytes, v=27 or 28)
- Ensure message hash matches: `keccak256(abi.encodePacked(msg.sender, modelHash, memoryHash, contextHash))`
- Platform signer must match contract's `platformSigner`

### "Not owner"
- Only NFT owner can update memory or enable cloning
- Check `ownerOf(tokenId)` matches your wallet

### RPC Issues
- Pentagon Chain deploy RPC: `https://rpc.pentagon.games/rpc/nCoUHmPLXkbkRq09hAam`
- Public RPC: `https://rpc.pentagon.games`
- Use `--legacy` flag for gas estimation

---

*See also: [ENCRYPTION-GUIDE.md](./ENCRYPTION-GUIDE.md) | [ERC-AINFT Spec](./ERC-AINFT.md)*
