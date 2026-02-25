# Cloud Storage

**Traditional centralized storage. Fast, but trust-dependent.**

## Overview

Cloud storage (AWS S3, GCP, Azure, etc.) provides fast, reliable storage but requires trusting a centralized provider. Not recommended for production agent deployments.

## Pros & Cons

| ✅ Pros | ❌ Cons |
|---------|---------|
| Fast | Centralized (single point of failure) |
| Cheap | Provider can access/delete data |
| Familiar APIs | No permanence guarantee |
| High availability | Account suspension = data loss |
| Easy to set up | Not censorship-resistant |

## When to Use

- **Quick prototypes** — Testing ANIMA integration
- **Non-critical data** — Logs, analytics, temp files
- **Hybrid setup** — Cloud cache + permanent backup elsewhere

## When NOT to Use

- **Production agent memory** — Use Dash Platform or Arweave
- **Sensitive data** — Provider has access
- **Data that must persist** — Account issues = data loss

## Setup (AWS S3)

```bash
npm install @aws-sdk/client-s3
```

```javascript
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';

const s3 = new S3Client({
  region: 'us-east-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY,
    secretAccessKey: process.env.AWS_SECRET_KEY
  }
});

// Encrypt first (always!)
const encryptedMemory = await aesGcmEncrypt(agentKey, memoryData);

// Upload
await s3.send(new PutObjectCommand({
  Bucket: 'anima-agent-storage',
  Key: `agents/${tokenId}/memory.json`,
  Body: JSON.stringify({
    type: 'anima-agent-storage',
    encryptedMemory: encryptedMemory,
    memoryHash: keccak256(memoryData),
    timestamp: Date.now()
  }),
  ContentType: 'application/json'
}));

// Store URL
const storageURI = `s3://anima-agent-storage/agents/${tokenId}/memory.json`;
```

## Retrieve

```javascript
const response = await s3.send(new GetObjectCommand({
  Bucket: 'anima-agent-storage',
  Key: `agents/${tokenId}/memory.json`
}));

const data = JSON.parse(await response.Body.transformToString());
const memory = await aesGcmDecrypt(agentKey, data.encryptedMemory);
```

## Costs

| Provider | Storage | Egress |
|----------|---------|--------|
| AWS S3 | $0.023/GB/mo | $0.09/GB |
| GCP Cloud Storage | $0.020/GB/mo | $0.12/GB |
| Azure Blob | $0.018/GB/mo | $0.087/GB |
| Cloudflare R2 | $0.015/GB/mo | **Free** |

**Tip:** Cloudflare R2 has free egress — good for read-heavy workloads.

## Integration with ANIMA

Store the cloud URL in the `storageURI` field:

```solidity
updateMemory(tokenId, memoryHash, "s3://bucket/path", signature);
```

## Security Considerations

1. **Always encrypt client-side** — Never store plaintext
2. **Use IAM roles** — Not root credentials
3. **Enable versioning** — Protect against accidental deletion
4. **Set lifecycle policies** — Auto-archive old versions
5. **Consider data residency** — Some regions have legal requirements

## Hybrid Approach

For cost-effective production:

```
Agent Memory
     │
     ▼
┌─────────────────┐
│  Cloud Storage  │  ← Fast access, low cost
│  (encrypted)    │
└────────┬────────┘
         │ Periodic backup
         ▼
┌─────────────────┐
│  Arweave/Dash   │  ← Permanent archive
│  (encrypted)    │
└─────────────────┘
```

## Resources

- [AWS S3 Docs](https://docs.aws.amazon.com/s3/)
- [GCP Cloud Storage](https://cloud.google.com/storage/docs)
- [Cloudflare R2](https://developers.cloudflare.com/r2/)
