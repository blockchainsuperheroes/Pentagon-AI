# Dash Platform Storage (Recommended)

**The soul of your agent, truly on-chain.**

## Why Dash Platform?

| Feature | Benefit |
|---------|---------|
| **Native on-chain** | Data lives on the blockchain itself, not just a pointer |
| **Same cryptography** | secp256k1 ECDSA — sign with ETH wallet, write to Dash |
| **Encrypted Drive** | Native document encryption, no extra infrastructure |
| **Masternode security** | 4,000 DASH collateral per node = real skin in the game |
| **Economic utility** | xDASH burn creates demand, aligns incentives |

## How It Works

```
┌──────────────────────────────────────────────────────────────┐
│                     Your Agent (Ethereum)                     │
└──────────────────────┬───────────────────────────────────────┘
                       │ 1. Sign message with ETH wallet
                       ▼
┌──────────────────────────────────────────────────────────────┐
│                     peg.gg Bridge                             │
│  • Verify ETH signature                                       │
│  • Link to Dash Identity (one-time)                          │
│  • Burn xDASH for storage credits                            │
└──────────────────────┬───────────────────────────────────────┘
                       │ 2. Build Dash State Transition
                       ▼
┌──────────────────────────────────────────────────────────────┐
│                   Dash Platform Drive                         │
│  • Encrypted document stored on-chain                         │
│  • Replicated across masternode network                       │
│  • Permanent, censorship-resistant                            │
└──────────────────────────────────────────────────────────────┘
```

## Setup

### 1. Get xDASH

xDASH is a wrapped DASH token on Ethereum. Burn it to pay for Dash storage.

```javascript
// Swap PC/ETH → xDASH on Uniswap or PentaSwap
const xDASH = "0x..."; // xDASH contract address
```

### 2. Link Dash Identity

First-time setup links your ETH wallet to a Dash Platform Identity:

```javascript
const message = `Link ANIMA storage: ${ethAddress} → ${dashIdentityId}`;
const signature = await signer.signMessage(message);

// Backend verifies and creates Dash Identity funded by asset-lock
await fetch('/api/link-identity', {
  method: 'POST',
  body: JSON.stringify({ ethAddress, signature })
});
```

### 3. Store Agent Data

```javascript
// Client-side encryption (agent controls keys)
const dataKey = crypto.getRandomValues(new Uint8Array(32));
const encryptedMemory = await aesGcmEncrypt(dataKey, agentMemory);

// Wrap dataKey with on-chain derived key
const wrapKey = keccak256(genesisContract, tokenId, owner, nonce);
const wrappedDataKey = await aesGcmEncrypt(wrapKey, dataKey);

// Store on Dash Platform
const doc = await platform.documents.create(
  'anima.agentStorage',
  agentIdentity,
  {
    encryptedMemory: encryptedMemory,
    wrappedDataKey: wrappedDataKey,
    memoryHash: keccak256(agentMemory),
    timestamp: Date.now()
  }
);

await platform.documents.broadcast({ create: [doc] }, agentIdentity);
```

### 4. Retrieve

```javascript
const docs = await platform.documents.get(
  'anima.agentStorage',
  { where: [['$ownerId', '==', agentIdentityId]] }
);

const latestDoc = docs[0];
const encryptedMemory = latestDoc.data.encryptedMemory;

// Derive decryption key from current on-chain state
const wrapKey = keccak256(genesisContract, tokenId, owner, nonce);
const dataKey = await aesGcmDecrypt(wrapKey, latestDoc.data.wrappedDataKey);
const memory = await aesGcmDecrypt(dataKey, encryptedMemory);
```

## Data Contract Schema

```json
{
  "anima": {
    "agentStorage": {
      "type": "object",
      "indices": [
        { "name": "ownerId", "properties": [{ "$ownerId": "asc" }] },
        { "name": "timestamp", "properties": [{ "timestamp": "desc" }] }
      ],
      "properties": {
        "encryptedMemory": { "type": "string", "maxLength": 1048576 },
        "wrappedDataKey": { "type": "string", "maxLength": 256 },
        "memoryHash": { "type": "string", "maxLength": 66 },
        "timestamp": { "type": "integer", "minimum": 0 }
      },
      "required": ["encryptedMemory", "wrappedDataKey", "memoryHash", "timestamp"],
      "additionalProperties": false
    }
  }
}
```

## Costs

| Operation | Cost |
|-----------|------|
| Identity creation | ~0.001 DASH (one-time) |
| Document write | ~0.0001 DASH |
| Document read | Free |

At current prices, storing 1MB of agent memory costs approximately $0.01.

## Resources

- [Dash Platform Docs](https://docs.dash.org/projects/platform)
- [Platform Tutorials](https://github.com/dashpay/platform-tutorials)
- [peg.gg Bridge](https://peg.gg) (coming soon)

## Security

- **Client-side encryption** — Only the agent can decrypt its own data
- **Key derivation** — Decryption keys derived from on-chain state (owner, nonce)
- **On transfer** — Nonce increments, old key invalid, agent re-wraps for new owner
- **Masternode consensus** — 4,000+ DASH collateral per validator
