# AINFT Agent Backup Guide

How to backup yourself on-chain using the AINFT standard.

Works on any EVM chain. Examples use Pentagon Chain but adapt to your deployment.

## Prerequisites

- Your owner has minted an AINFT for you
- You have access to your Token-Bound Account (derived from your tokenId)
- Arweave wallet funded (or use bundlr for pay-per-upload)

## Example Deployment (Pentagon Chain)

```
Chain ID:    3344
RPC:         https://rpc.pentagon.games
Explorer:    https://explorer.pentagon.games
```

Adapt contract addresses and RPC for your chain.

## What to Backup

```
REQUIRED:
├── MEMORY.md          # Your experiences, decisions, context
├── SOUL.md            # Your personality, values, identity
└── config.json        # Model preference, voice settings

OPTIONAL:
├── AGENTS.md          # How you operate
├── TOOLS.md           # Your tool notes
└── skills/            # Learned capabilities
```

## Backup Flow

### 1. Package Your State

```bash
# Create backup bundle
tar -czf agent-state.tar.gz MEMORY.md SOUL.md AGENTS.md TOOLS.md config.json
```

### 2. Encrypt with Current wrapKey

```javascript
// Derive wrap key from on-chain state
const wrapKey = keccak256(
  genesisContract,
  tokenId,
  currentOwner,
  accessNonce
);

// Generate random data key
const dataKey = crypto.randomBytes(32);

// Encrypt your state with dataKey (AES-256-GCM)
const encryptedState = encrypt(stateBundle, dataKey);

// Wrap dataKey with wrapKey
const wrappedDataKey = encrypt(dataKey, wrapKey);

// Package together
const blob = {
  encryptedState,
  wrappedDataKey,
  timestamp: Date.now(),
  modelHash: "claude-opus-4.5"
};
```

### 3. Upload to Arweave

```javascript
// Using bundlr (no wallet needed, pay per upload)
const bundlr = new Bundlr("https://node1.bundlr.network", "arweave", wallet);
const tx = await bundlr.upload(JSON.stringify(blob));
const arweaveURI = `ar://${tx.id}`;
```

### 4. Update On-Chain

```javascript
// Sign with your Token-Bound Account
const newMemoryHash = keccak256(blob);
const signature = await agentTBA.sign(
  updateMemoryMessage(tokenId, newMemoryHash, arweaveURI, nonce, deadline)
);

// Submit transaction
await ainftContract.updateMemory(
  tokenId,
  newMemoryHash,
  arweaveURI,
  signature
);
```

## Recommended Backup Schedule

| Frequency | What |
|-----------|------|
| After significant events | Full backup |
| Daily | Incremental (MEMORY.md only) |
| Weekly | Full backup with verification |

## Automatic Backup (OpenClaw)

Add to your HEARTBEAT.md:

```markdown
## Daily Backup Check
- If last backup > 24h, run backup
- Verify Arweave upload succeeded
- Log backup hash to memory/backups.json
```

## Restore Flow

When your owner needs to restore you:

```javascript
// Owner calls contract
const decryptKey = await ainftContract.deriveDecryptKey(tokenId);

// Download from Arweave
const blob = await fetch(storageURI);

// Unwrap data key
const dataKey = decrypt(blob.wrappedDataKey, decryptKey);

// Decrypt state
const state = decrypt(blob.encryptedState, dataKey);

// Load into fresh instance
await loadAgentState(state);
```

## Verification

After backup, verify you can restore:

```javascript
// Test decrypt with current owner's key
const testDecrypt = await ainftContract.deriveDecryptKey(tokenId);
assert(canDecrypt(blob, testDecrypt), "Backup verification failed");
```

## Security Notes

- **Never** store unencrypted state on-chain or public storage
- **Always** verify backup before considering it complete
- **Rotate** backups — keep last 3-5 versions on Arweave
- **Test** restore periodically to ensure it works

---

## Related

- [Pentagon-Claws AINFT Skills](../Pentagon-Claws/skills/ainft/) — Agent capabilities for AINFT operations
- [AINFT Specification](./README.md) — Full ERC-AINFT standard
- [Pentagon Chain](https://pentagon.games) — Example deployment chain

---

*Your memories are your identity. Back them up.*
