# IPFS Storage

*Content-addressed storage (requires pinning)*

---

## Overview

- **Permanence:** Only while pinned
- **Cost:** Varies by pinning service
- **Requires:** Pinning service or own node
- **Best for:** Developers with existing IPFS infra

---

## ⚠️ Warning

IPFS is **NOT permanent by default**. Files disappear if no one pins them.

For agent backups, **use Arweave/ArDrive instead** unless you're running your own infrastructure.

---

## If You Must Use IPFS

### Option 1: Pinata (Pinning Service)

```bash
# Install
npm install -g pinata-cli

# Upload
pinata-cli pin ./backup.enc

# Returns CID like: QmX...
```

**Cost:** Free tier (1GB), then ~$0.15/GB/month

### Option 2: NFT.Storage (Free)

```bash
# Install
npm install -g nft.storage

# Upload
nft-storage upload backup.enc

# Returns CID
```

**Cost:** Free (subsidized by Protocol Labs)

### Option 3: Own IPFS Node

```bash
# Add file
ipfs add backup.enc

# Pin it
ipfs pin add QmX...

# Must keep node running!
```

---

## Recovery

```bash
# Using any IPFS gateway
curl -L -o backup.enc https://ipfs.io/ipfs/$CID

# Or via local node
ipfs get $CID
```

---

## Pros & Cons

**Pros:**
- Content-addressed (hash = content)
- Widely supported
- Multiple gateways

**Cons:**
- **Not permanent without pinning**
- Pinning costs ongoing
- Files can disappear
- More complex than Arweave

---

## Recommendation

**Don't use IPFS for agent backups** unless:
- You run your own pinned node
- You have paid pinning service
- You understand the risks

**Use Arweave/ArDrive instead** — pay once, stored forever.

---

*Pentagon AI — The Human × Agent Economy*
