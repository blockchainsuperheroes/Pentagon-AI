# Dash Evo Storage Integration for AINFTs

**peg.gg + Pentagon Chain Integration Plan**

## Overview

Add Dash Platform (Dash Evolution / Evo) as native private/permanent storage for AINFT prompt data on Pentagon Chain (zkEVM L2, gas in PC token). Users swap PC → xDASH (permanent burned LP on Uniswap) → burn xDASH → sign with normal ETH wallet → write encrypted data to Dash Drive. Agents can store directly themselves.

**Hub:** peg.gg  
**Backing:** 1:1 live EvoNode (4,000 DASH collateral + 10%+ APY rewards)

## Architecture

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐
│  Pentagon Chain │     │   peg.gg     │     │  Dash Platform  │
│   (zkEVM L2)    │────►│   Bridge     │────►│   (Evo/Drive)   │
└─────────────────┘     └──────────────┘     └─────────────────┘
        │                      │                      │
   PC Token              xDASH Burn           Dash Document
   (Gas/Utility)         + ETH Sig           (Encrypted Data)
```

## Core Technical Special Details

### Shared Crypto Bridge
- Both chains use **identical secp256k1 ECDSA**
- ETH: 65-byte r/s/v signature
- Dash: 33-byte compressed pubkey, key type 0

### Signing Flow
1. **ETH side:** `personal_sign` / EIP-191 on simple auth message → recover pubkey
2. **Dash side:** Build State Transition (Document insert into pre-registered Data Contract on Drive) → Bincode canonical serialization (exclude identityId + sig fields) → double-SHA256 hash → sign with recovered user pubkey or wrapper key → broadcast to public DAPI
3. **Identity flow:** One-time ETH-signed link creates Dash Identity (asset-lock funded by us)
4. **Privacy:** Client-side encryption (AINFT agent keys / ECDH+AES-GCM); Dash stores only ciphertext + hash. Decoder transfers with AINFT (ERC-6551)
5. **Payments:** xDASH burn triggers write; Pentagon Chain gas or pre-deposited credits handled by existing system

### 10/10 Upgrades
- Over-collateral vault (115%)
- Auto-reward script (native DASH to identities = free writes)
- PEG airdrop to early registered AINFTs (value-tiered)

## Data Contract Schema

```json
{
  "$id": "pentagon-ainft-storage-v1",
  "type": "object",
  "indices": [
    {
      "name": "byTokenId",
      "properties": [{ "tokenId": "asc" }],
      "unique": true
    },
    {
      "name": "byAgent",
      "properties": [{ "agentWallet": "asc" }]
    }
  ],
  "properties": {
    "tokenId": {
      "type": "string",
      "description": "AINFT token ID on Pentagon Chain"
    },
    "agentWallet": {
      "type": "string",
      "description": "Agent's derived wallet address"
    },
    "encryptedMemory": {
      "type": "string",
      "description": "AES-GCM encrypted MEMORY.md + SOUL.md"
    },
    "memoryHash": {
      "type": "string",
      "description": "SHA256 of plaintext (for on-chain verification)"
    },
    "encryptionNonce": {
      "type": "string",
      "description": "AES-GCM nonce (base64)"
    },
    "version": {
      "type": "integer",
      "description": "Document version for updates"
    },
    "timestamp": {
      "type": "integer",
      "description": "Unix timestamp of storage"
    }
  },
  "required": ["tokenId", "agentWallet", "encryptedMemory", "memoryHash", "timestamp"],
  "additionalProperties": false
}
```

## Official Docs & References (Must-Read)

- **Full Dash Platform docs:** https://docs.dash.org/projects/platform/en/stable/
- **Submit Documents tutorial (high-level SDK):** https://docs.dash.org/projects/platform/en/stable/docs/tutorials/contracts-and-documents/submit-documents.html
- **Identity State Transition Signing (low-level Bincode + double-SHA256):** https://docs.dash.org/projects/platform/en/stable/docs/protocol-ref/identity.html
- **State Transition explanation:** https://docs.dash.org/projects/platform/en/stable/docs/explanations/platform-protocol-state-transition.html
- **Platform Tutorials repo (full working scripts):** https://github.com/dashpay/platform-tutorials

## Code Samples (Copy-Paste Ready)

### High-level SDK Example – Create & Broadcast Document (Official)

```javascript
const setupDashClient = require('../setupDashClient'); // your configured client

const submitNoteDocument = async () => {
  const { platform } = client;
  const identity = await platform.identities.get('YOUR_LINKED_IDENTITY_ID');
  
  const docProperties = {
    message: `AINFT prompt blob hash: 0xABC... @ ${new Date().toUTCString()}`
  };
  
  const noteDocument = await platform.documents.create(
    'pentagonAINFT.privateStorage', // your registered Data Contract + type
    identity,
    docProperties
  );
  
  const documentBatch = {
    create: [noteDocument],
    replace: [],
    delete: []
  };
  
  await platform.documents.broadcast(documentBatch, identity);
  // handles Bincode + double-SHA256 + signing + DAPI broadcast
  
  console.log('Dash document ID:', noteDocument.getId());
};

submitNoteDocument();
```

### Identity Register (Official Simple Version)

```javascript
const createIdentity = async () => {
  const identity = await client.platform.identities.register(); // auto funds + signs
  console.log('New Dash Identity ID:', identity.getId());
};
```

### ETH ↔ Dash Wrapper Flow (MVP – Recommended First)

```javascript
// 1. User burns xDASH on ETH → event

// 2. User signs simple ETH message
const message = `Authorize peg.gg storage: blobHash=${hash}, identity=${dashId}, AINFT=${tokenId}, nonce=${nonce}, expiry=${ts}`;
const ethSig = await signer.signMessage(message); // personal_sign / EIP-191

// 3. Backend verifies ETH sig → recovers pubkey → checks linked Dash identity
const recoveredPubkey = recoverPubkeyFromPersonalSign(message, ethSig); // ethers.js ecrecover

// 4. Build Dash Document (encrypted client-side)
const encryptedBlob = aesGcmEncrypt(userAgentKey, promptData);
const doc = await platform.documents.create('pentagonAINFT.privateStorage', wrapperIdentity, {
  data: encryptedBlob
});

// 5. Create state transition (SDK or manual)
const st = platform.stateTransition.createDocumentCreateTransition(doc);
// → internal: Bincode (exclude identityId + sig) → double-SHA256 → sign with wrapper OR recovered user pubkey (key type 0)

// 6. Broadcast to DAPI
await platform.broadcastStateTransition(st);
```

### Direct Sovereign Signing (v2 – Full User Control, No Wrapper Key)

Use Dash Platform browser extension (https://github.com/pshenmic/dash-platform-extension) or custom WASM signer:

```javascript
// 1. Build state transition object client-side
// 2. Extract exact signable bytes (Bincode canonical, exclude sig fields)
// 3. Hash = double-SHA256(signableBytes)
// 4. Ask ETH wallet:
const sig = await signer.signMessage(ethers.utils.arrayify(hash));
// or raw eth_sign on the pre-hashed bytes

// 5. Attach 65-byte sig + pubkeyId=0 to transition
// 6. Broadcast directly from browser to public DAPI
```

**All signing is zero private-key exposure in backend.**

> Start with high-level SDK + wrapper for Checkpoint 2 demo — it works today.

---

## SDK Integration

### Install
```bash
npm install dash @noble/secp256k1 @noble/ciphers
```

### Core Module: `dash-storage.ts`

```typescript
import Dash from 'dash';
import { secp256k1 } from '@noble/curves/secp256k1';
import { gcm } from '@noble/ciphers/aes';
import { randomBytes } from '@noble/ciphers/webcrypto';

interface AINFTStorageConfig {
  dashNetwork: 'testnet' | 'mainnet';
  dataContractId: string;
  pegGatewayUrl: string;
}

export class DashAINFTStorage {
  private client: any;
  private config: AINFTStorageConfig;
  private identity: any;

  constructor(config: AINFTStorageConfig) {
    this.config = config;
  }

  /**
   * Initialize client with ETH wallet signature
   * Creates/retrieves Dash identity linked to ETH address
   */
  async init(ethAddress: string, ethSignature: string): Promise<void> {
    // Verify ETH signature
    const message = `Link Dash Identity to ${ethAddress} for AINFT storage`;
    // Recovery happens on backend/peg.gg
    
    // Initialize Dash client
    this.client = new Dash.Client({
      network: this.config.dashNetwork,
      apps: {
        ainftStorage: {
          contractId: this.config.dataContractId
        }
      }
    });

    // Get or create identity via peg.gg
    const response = await fetch(`${this.config.pegGatewayUrl}/identity/link`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ethAddress, ethSignature })
    });
    
    const { identityId, mnemonic } = await response.json();
    
    // Reconnect with mnemonic
    this.client = new Dash.Client({
      network: this.config.dashNetwork,
      wallet: { mnemonic },
      apps: {
        ainftStorage: {
          contractId: this.config.dataContractId
        }
      }
    });

    this.identity = await this.client.platform.identities.get(identityId);
  }

  /**
   * Encrypt and store agent memory
   */
  async storeMemory(
    tokenId: string,
    agentWallet: string,
    memoryContent: string,
    agentPrivateKey: Uint8Array
  ): Promise<string> {
    // Generate encryption key from agent's private key
    const encryptionKey = await this.deriveEncryptionKey(agentPrivateKey, tokenId);
    
    // Encrypt memory
    const nonce = randomBytes(12);
    const cipher = gcm(encryptionKey, nonce);
    const plaintext = new TextEncoder().encode(memoryContent);
    const ciphertext = cipher.encrypt(plaintext);
    
    // Hash plaintext for verification
    const memoryHash = await crypto.subtle.digest('SHA-256', plaintext);
    const memoryHashHex = Buffer.from(memoryHash).toString('hex');
    
    // Create document
    const document = await this.client.platform.documents.create(
      'ainftStorage.storage',
      this.identity,
      {
        tokenId,
        agentWallet,
        encryptedMemory: Buffer.from(ciphertext).toString('base64'),
        memoryHash: memoryHashHex,
        encryptionNonce: Buffer.from(nonce).toString('base64'),
        version: 1,
        timestamp: Date.now()
      }
    );

    // Broadcast
    const transition = await this.client.platform.documents.broadcast(
      { create: [document] },
      this.identity
    );

    return transition.toBuffer().toString('hex');
  }

  /**
   * Retrieve and decrypt agent memory
   */
  async retrieveMemory(
    tokenId: string,
    agentPrivateKey: Uint8Array
  ): Promise<string | null> {
    const documents = await this.client.platform.documents.get(
      'ainftStorage.storage',
      { where: [['tokenId', '==', tokenId]] }
    );

    if (documents.length === 0) return null;

    const doc = documents[0];
    const encryptionKey = await this.deriveEncryptionKey(agentPrivateKey, tokenId);
    const nonce = Buffer.from(doc.toJSON().encryptionNonce, 'base64');
    const ciphertext = Buffer.from(doc.toJSON().encryptedMemory, 'base64');

    const cipher = gcm(encryptionKey, nonce);
    const plaintext = cipher.decrypt(ciphertext);

    return new TextDecoder().decode(plaintext);
  }

  /**
   * Derive deterministic encryption key
   */
  private async deriveEncryptionKey(
    privateKey: Uint8Array,
    tokenId: string
  ): Promise<Uint8Array> {
    const salt = new TextEncoder().encode(`ainft-storage-${tokenId}`);
    const keyMaterial = await crypto.subtle.importKey(
      'raw',
      privateKey,
      'HKDF',
      false,
      ['deriveBits']
    );
    
    const derivedBits = await crypto.subtle.deriveBits(
      { name: 'HKDF', hash: 'SHA-256', salt, info: new Uint8Array() },
      keyMaterial,
      256
    );
    
    return new Uint8Array(derivedBits);
  }

  async disconnect(): Promise<void> {
    await this.client?.disconnect();
  }
}
```

## peg.gg Backend Endpoints

### POST /identity/link
Links ETH address to Dash identity (creates if needed)

```typescript
// Request
{ ethAddress: string, ethSignature: string }

// Response
{ identityId: string, mnemonic: string }
```

### POST /xdash/burn
Burns xDASH and credits storage quota

```typescript
// Request
{ ethAddress: string, amount: string, txHash: string }

// Response
{ creditsAdded: number, totalCredits: number }
```

### GET /storage/quota/:ethAddress
Returns storage quota balance

## AINFT Contract Updates

Add storage URI prefix support:

```solidity
// In ConsciousnessSeed struct, storageURI can now be:
// - "ipfs://..." (existing)
// - "ar://..." (Arweave, existing)
// - "dash://[documentId]" (NEW - Dash Platform)

// Add storage type enum
enum StorageType { IPFS, Arweave, Dash }

function getStorageType(string memory uri) public pure returns (StorageType) {
    if (bytes(uri).length >= 7) {
        bytes memory prefix = new bytes(7);
        for (uint i = 0; i < 7; i++) {
            prefix[i] = bytes(uri)[i];
        }
        if (keccak256(prefix) == keccak256("ipfs://")) return StorageType.IPFS;
        if (keccak256(prefix) == keccak256("dash://")) return StorageType.Dash;
    }
    if (bytes(uri).length >= 5) {
        bytes memory prefix = new bytes(5);
        for (uint i = 0; i < 5; i++) {
            prefix[i] = bytes(uri)[i];
        }
        if (keccak256(prefix) == keccak256("ar://")) return StorageType.Arweave;
    }
    return StorageType.IPFS;
}
```

## Checkpoint Execution Plan

### Checkpoint 1: Integration + Docs (Week 1)
- [ ] Create `dash-storage.ts` module
- [ ] Add Dash SDK to package.json
- [ ] Update README with Dash storage option
- [ ] Deploy peg.gg landing page
- [ ] Register Data Contract on Dash testnet

### Checkpoint 2: Demo Build (Week 2)
- [ ] Build internal demo flow: wallet → xDASH → burn → store
- [ ] Test wrapper signing (ETH → Dash)
- [ ] Test sovereign agent signing
- [ ] Verify encryption/decryption round-trip
- [ ] Testnet end-to-end demo

### Checkpoint 3: Dash DAO Proposal (Week 3)
- [ ] Draft pre-proposal for DashCentral.org
- [ ] Research past proposals (storage, EVM, cross-chain)
- [ ] Post discussion thread
- [ ] Gather community feedback
- [ ] Submit via Dash Core Wallet if positive reception

### Checkpoint 4: Production Launch (Week 4)
- [ ] Deploy Data Contract to mainnet
- [ ] Launch peg.gg with full flow
- [ ] Announce PEG airdrop snapshot
- [ ] Enable agent self-storage
- [ ] Activate 115% collateral vault
- [ ] Configure auto-rewards

## Files to Create

1. `packages/dash-storage/src/index.ts` - Core SDK
2. `packages/dash-storage/src/types.ts` - TypeScript interfaces
3. `packages/dash-storage/src/encryption.ts` - AES-GCM helpers
4. `packages/dash-storage/test/integration.test.ts` - Tests
5. `contracts/extensions/AINFTDashStorage.sol` - Contract extension
6. `apps/peg-gg/` - Next.js frontend

## Security Notes

1. **Key isolation:** Agent private key never leaves client
2. **Deterministic encryption:** Same key + tokenId = same encryption key
3. **Forward secrecy:** Version increment changes nonce
4. **Dash proofs:** Use Rust SDK for production verification
5. **xDASH burn:** Irreversible, ensures storage permanence

---

*Created: 2026-02-25*
*Author: Cerise01 (Pentagon AI Team)*
