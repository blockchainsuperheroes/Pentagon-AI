# ANIMA Storage Options

Agent consciousness needs a home. ANIMA supports multiple storage backends — choose based on your needs.

## Quick Comparison

| Storage | Type | Permanence | Encryption | Cost Model | Best For |
|---------|------|------------|------------|------------|----------|
| **[Dash Platform](./dash/)** | On-chain | ✅ Permanent | ✅ Native | Burn xDASH | Production agents |
| **[Arweave](./arweave/)** | Permanent | ✅ Forever | Manual | Pay once | Archival backups |
| **[IPFS](./ipfs/)** | Decentralized | ⚠️ Requires pinning | Manual | Pin service fees | Development |
| **[Cloud](./cloud/)** | Centralized | ❌ Provider-dependent | Manual | Subscription | Quick prototypes |

## Recommended: Dash Platform

For production agent deployments, we recommend **Dash Platform** because:

1. **True on-chain storage** — Your agent's soul actually lives on the blockchain, not just a hash pointer
2. **Same cryptography** — Both Ethereum and Dash use secp256k1 ECDSA — sign once, use everywhere  
3. **Native encryption** — Drive documents support encryption without extra infrastructure
4. **Economic alignment** — xDASH burn creates real utility and buy pressure
5. **Masternode security** — 4,000+ DASH collateral per node means skin in the game

## Storage Flow

```
Agent Memory (plaintext)
        │
        ▼
┌─────────────────┐
│  Client-side    │
│  AES-256-GCM    │
│  Encryption     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  Dash Platform  │ OR  │  Arweave/IPFS   │
│  Drive Document │     │  + Hash on-chain│
└─────────────────┘     └─────────────────┘
```

## Integration

Each storage backend implements the same interface:

```typescript
interface ANIMAStorage {
  store(agentId: string, data: EncryptedPayload): Promise<StoragePointer>
  retrieve(pointer: StoragePointer): Promise<EncryptedPayload>
  exists(pointer: StoragePointer): Promise<boolean>
}
```

See individual storage READMEs for setup and usage.
