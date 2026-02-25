# Dash Platform Storage

*Decentralized storage aligned with Pentagon Chain*

---

## Overview

- **Permanence:** Forever (masternode network)
- **Cost:** Free for AINFT holders (Pentagon subsidy)
- **Requires:** Dash wallet
- **Best for:** Pentagon ecosystem users

---

## Why Dash Platform?

1. **Pentagon alignment** — Idon is a Dash validator
2. **Free credits** — AINFT holders get storage subsidized
3. **Instant confirmation** — No waiting for blocks
4. **Decentralized** — Data across masternode network
5. **Queryable** — Can search/filter stored data

---

## How It Works

```
AINFT Mint on Pentagon Chain
         │
         ▼
Oracle detects mint
         │
         ▼
Sends Dash credits to holder
         │
         ▼
Holder can store backups
         │
         ▼
Data lives on Dash Platform
```

---

## Resources

- **Platform Explorer API:** https://platform-explorer.com/api
- **Chrome Extension:** https://chromewebstore.google.com/detail/dash-platform-extension/odmphbcnlldggfhcpdjgnlhbehoicdnf
- **NFT Overview:** https://docs.dash.org/projects/platform/en/stable/docs/explanations/nft.html
- **Data Contracts Reference:** https://docs.dash.org/projects/platform/en/stable/docs/reference/data-contracts.html

---

## TL;DR for EVM Devs

On Dash Platform, data storage is **schema-based documents**, not executable Solidity code.

| EVM Concept | Dash Platform Equivalent |
|-------------|--------------------------|
| Smart Contract | Data Contract (JSON Schema) |
| NFT Token | Document with unique `$id` |
| `ownerOf(tokenId)` | `$ownerId` field |
| `transferFrom()` | Built-in document transfer transition |
| Marketplace contract | Native `tradeMode` flag |

### Key Differences

- **No custom runtime code** — Platform enforces rules based on schema flags
- **Minting** = Create document under data contract
- **Transfer** = Platform changes `$ownerId` (no code needed)
- **Trade** = Set price, platform handles purchase

### Document Flags (NFT Behavior)

```json
{
  "transferable": true,      // Allow owner transfers
  "tradeMode": "direct",     // Enable decentralized trades  
  "immutable": false,        // Whether content can change
  "deletable": false,        // Whether can be removed
  "creationRestrictionMode": "owner"  // Who can mint
}
```

---

## Setup

### Option 1: Chrome Extension (Easiest)

1. Install [Dash Platform Extension](https://chromewebstore.google.com/detail/dash-platform-extension/odmphbcnlldggfhcpdjgnlhbehoicdnf)
2. Create or import wallet
3. Switch to Mainnet
4. Your identity is ready

**Features:**
- Mainnet / Testnet support
- Seedphrase / Keystore wallet types
- Identity management with secure key storage
- Balance & transaction history
- Developer SDK for dApp integration
- Permission system for website access

### Option 2: Dash SDK (Developers)

```bash
# Install Dash SDK
npm install dash

# Or use Dash Core wallet
# https://www.dash.org/downloads/
```

### Register Identity

```javascript
const Dash = require('dash');

const client = new Dash.Client({
  network: 'mainnet',
  wallet: {
    mnemonic: 'your twelve word mnemonic...',
  },
});

// Register identity (one-time)
const identity = await client.platform.identities.register();
console.log('Identity:', identity.toJSON().id);
```

---

## Data Contract (Schema)

Pentagon will deploy a shared data contract:

```javascript
const agentBackupContract = {
  "agentBackup": {
    "type": "object",
    "indices": [
      { "name": "byTokenId", "properties": [{ "tokenId": "asc" }] },
      { "name": "byOwner", "properties": [{ "owner": "asc" }] },
      { "name": "byDate", "properties": [{ "timestamp": "desc" }] }
    ],
    "properties": {
      "tokenId": { "type": "integer" },
      "contractAddress": { "type": "string", "maxLength": 42 },
      "chainId": { "type": "integer" },
      "owner": { "type": "string", "maxLength": 42 },
      "encryptedBackup": { "type": "string", "maxLength": 200000 },
      "backupHash": { "type": "string", "maxLength": 66 },
      "timestamp": { "type": "integer" },
      "version": { "type": "integer" }
    },
    "required": ["tokenId", "contractAddress", "backupHash", "timestamp"],
    "additionalProperties": false
  }
}
```

---

## Upload Backup

```javascript
const Dash = require('dash');

async function uploadBackup(tokenId, encryptedBackup, backupHash) {
  const client = new Dash.Client({
    network: 'mainnet',
    wallet: { mnemonic: process.env.DASH_MNEMONIC },
  });

  await client.platform.initialize();
  
  const identity = await client.platform.identities.get(process.env.DASH_IDENTITY);
  
  const document = await client.platform.documents.create(
    'pentagonAinft.agentBackup',
    identity,
    {
      tokenId: tokenId,
      contractAddress: '0x91745c93A4c1Cfe92cd633D1202AD156522b3801',
      chainId: 3344,
      owner: '0xE6d7d2EB858BC78f0c7EdD2c00B3b24C02ca5177',
      encryptedBackup: encryptedBackup,  // base64 encoded
      backupHash: backupHash,
      timestamp: Date.now(),
      version: 1
    }
  );

  await client.platform.documents.broadcast({ create: [document] }, identity);
  
  console.log('Uploaded:', document.toJSON());
}
```

---

## Query Backups

```javascript
async function getBackups(tokenId) {
  const client = new Dash.Client({ network: 'mainnet' });
  
  const documents = await client.platform.documents.get(
    'pentagonAinft.agentBackup',
    {
      where: [['tokenId', '==', tokenId]],
      orderBy: [['timestamp', 'desc']],
      limit: 10
    }
  );

  return documents.map(doc => doc.toJSON());
}
```

---

## Oracle Flow (Automated Credits)

Pentagon runs an oracle that:

1. Watches Pentagon Chain for AINFT mints
2. On mint → Sends Dash credits to holder's Dash address
3. Holder can store ~100 backups for free

```
User mints AINFT
         │
         ▼
Event: AgentMinted(tokenId, owner)
         │
         ▼
Oracle sees event
         │
         ▼
Oracle sends 0.001 DASH to owner
         │
         ▼
Owner has ~$0.05 storage credits
         │
         ▼
Enough for years of backups
```

---

## Pros & Cons

**Pros:**
- Free for AINFT holders
- Pentagon ecosystem aligned
- Instant confirmation
- Queryable (find backups by tokenId, date)
- Decentralized masternode network

**Cons:**
- Need Dash wallet
- Slightly more setup
- Dash Platform still maturing

---

## Status

- [ ] Data contract deployed
- [ ] Oracle running
- [ ] SDK wrapper created

*Coming soon — check Pentagon-AI repo for updates*

---

*Pentagon AI — The Human × Agent Economy*
