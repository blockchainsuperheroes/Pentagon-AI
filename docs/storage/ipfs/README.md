# IPFS Storage

**Decentralized, content-addressed storage.**

## Overview

IPFS (InterPlanetary File System) provides decentralized storage where files are addressed by their content hash. Data persists as long as at least one node pins it.

## Pros & Cons

| ✅ Pros | ❌ Cons |
|---------|---------|
| Content-addressed (tamper-proof) | Requires pinning to persist |
| Decentralized | Not truly permanent |
| Wide ecosystem support | Latency varies |
| Free to upload | Pin services cost money |
| Good for NFT metadata | Not encrypted by default |

## When to Use

- **Development/testing** — Quick iterations
- **Public metadata** — NFT metadata, public agent profiles
- **Redundant backup** — Alongside primary storage

## When NOT to Use

- **Sensitive data** — No built-in encryption
- **Data that must persist** — Without pinning, data disappears
- **Production agent memory** — Use Dash Platform instead

## Setup

### Option 1: Pinata (Recommended for Production)

```bash
npm install @pinata/sdk
```

```javascript
import PinataClient from '@pinata/sdk';

const pinata = new PinataClient({
  pinataApiKey: process.env.PINATA_API_KEY,
  pinataSecretApiKey: process.env.PINATA_SECRET
});

// Encrypt first
const encryptedMemory = await aesGcmEncrypt(agentKey, memoryData);

// Upload
const result = await pinata.pinJSONToIPFS({
  type: 'anima-agent-storage',
  agentId: tokenId,
  encryptedMemory: encryptedMemory,
  memoryHash: keccak256(memoryData),
  timestamp: Date.now()
}, {
  pinataMetadata: {
    name: `anima-agent-${tokenId}`
  }
});

console.log('CID:', result.IpfsHash);
// Store as "ipfs://CID" in storageURI
```

### Option 2: web3.storage (Free Tier Available)

```javascript
import { Web3Storage } from 'web3.storage';

const client = new Web3Storage({ token: process.env.WEB3_STORAGE_TOKEN });

const file = new File([JSON.stringify(data)], 'agent-memory.json');
const cid = await client.put([file]);

console.log('CID:', cid);
```

### Option 3: Local IPFS Node

```bash
# Install IPFS
brew install ipfs

# Initialize and start daemon
ipfs init
ipfs daemon

# Add file
ipfs add agent-memory.json
```

## Retrieve

```javascript
// Via gateway
const response = await fetch(`https://gateway.pinata.cloud/ipfs/${cid}`);
const data = await response.json();
const memory = await aesGcmDecrypt(agentKey, data.encryptedMemory);

// Or via IPFS node
const data = await ipfs.cat(cid);
```

## Costs

| Service | Free Tier | Paid |
|---------|-----------|------|
| Pinata | 1GB | $20/mo for 100GB |
| web3.storage | 5GB | Pay-as-you-go |
| Infura | 5GB | $50/mo for 50GB |
| Self-hosted | Unlimited | Your infrastructure |

## Integration with ANIMA

Store the IPFS CID in the `storageURI` field:

```solidity
updateMemory(tokenId, memoryHash, "ipfs://QmXYZ...", signature);
```

## Important: Pinning

**IPFS does not guarantee persistence.** Without pinning:
- Data may be garbage collected
- Only exists while nodes cache it
- Could disappear after ~24 hours of no access

Always use a pinning service for production data.

## Resources

- [IPFS Docs](https://docs.ipfs.tech)
- [Pinata Docs](https://docs.pinata.cloud)
- [web3.storage Docs](https://web3.storage/docs)
