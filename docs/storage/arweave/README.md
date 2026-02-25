# Arweave Storage

**Pay once, store forever.**

## Overview

Arweave provides permanent, immutable storage. Once data is uploaded, it exists forever — no subscriptions, no renewals, no deletions.

## Pros & Cons

| ✅ Pros | ❌ Cons |
|---------|---------|
| Truly permanent | Higher upfront cost |
| Immutable (tamper-proof) | Can't delete or update |
| Pay once | Need to manage encryption separately |
| Large ecosystem | Not "on-chain" — separate network |
| Content-addressable | Slower than centralized options |

## When to Use

- **Archival backups** — Snapshots of agent state at key moments
- **Immutable records** — Audit trails, proofs
- **Long-term storage** — Data that should outlive any single service

## When NOT to Use

- **Frequently updated data** — Each update is a new file (and new cost)
- **Data you might need to delete** — Arweave is forever
- **Real-time access** — Latency is higher than centralized storage

## Setup

### 1. Install SDK

```bash
npm install arweave
```

### 2. Get AR Tokens

Purchase AR from exchanges or use a bundler service like Bundlr for smaller uploads.

### 3. Store Agent Data

```javascript
import Arweave from 'arweave';

const arweave = Arweave.init({
  host: 'arweave.net',
  port: 443,
  protocol: 'https'
});

// Encrypt client-side first
const encryptedMemory = await aesGcmEncrypt(agentKey, memoryData);

// Create transaction
const tx = await arweave.createTransaction({
  data: JSON.stringify({
    type: 'anima-agent-storage',
    agentId: tokenId,
    encryptedMemory: encryptedMemory,
    memoryHash: keccak256(memoryData),
    timestamp: Date.now()
  })
}, wallet);

// Add tags for discoverability
tx.addTag('Content-Type', 'application/json');
tx.addTag('App-Name', 'ANIMA');
tx.addTag('Agent-Id', tokenId.toString());

// Sign and post
await arweave.transactions.sign(tx, wallet);
await arweave.transactions.post(tx);

console.log('Stored at:', tx.id);
// Store tx.id as storageURI in ANIMA contract
```

### 4. Retrieve

```javascript
const data = await arweave.transactions.getData(txId, { decode: true, string: true });
const parsed = JSON.parse(data);
const memory = await aesGcmDecrypt(agentKey, parsed.encryptedMemory);
```

## Costs

| Size | Approximate Cost |
|------|------------------|
| 1 KB | ~$0.0001 |
| 1 MB | ~$0.01 |
| 100 MB | ~$1.00 |

Prices fluctuate with AR token value and network demand.

## Integration with ANIMA

Store the Arweave transaction ID in the `storageURI` field:

```solidity
updateMemory(tokenId, memoryHash, "ar://TRANSACTION_ID", signature);
```

## Bundlr (For Smaller Uploads)

For uploads under ~100KB, use Bundlr to avoid minimum transaction fees:

```javascript
import Bundlr from '@bundlr-network/client';

const bundlr = new Bundlr('https://node1.bundlr.network', 'arweave', wallet);

const response = await bundlr.upload(JSON.stringify(data), {
  tags: [{ name: 'App-Name', value: 'ANIMA' }]
});

console.log('Stored at:', response.id);
```

## Resources

- [Arweave Docs](https://docs.arweave.org)
- [Bundlr Docs](https://docs.bundlr.network)
- [ArConnect Wallet](https://arconnect.io)
