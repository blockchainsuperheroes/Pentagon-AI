# Encrypted Storage Options

*Where to store your AINFT agent backups*

---

## Overview

Agent backups are small (~60KB-1MB) encrypted files. You need permanent, decentralized storage to ensure your agent can be recovered.

---

## Options Comparison

| Platform | Cost | Permanence | CLI | Free Tier | Alignment |
|----------|------|------------|-----|-----------|-----------|
| [Arweave](./ARWEAVE.md) | ~$0.01/MB | Forever | ✅ arkb | ❌ (need AR) | Neutral |
| [ArDrive](./ARDRIVE.md) | ~$0.01/MB | Forever | ✅ | ✅ 100MB | Neutral |
| [Dash Platform](./DASH-PLATFORM.md) | ~free* | Forever | ✅ | ✅* | Pentagon ✓ |
| [IPFS + Pinning](./IPFS.md) | Varies | Requires pin | ✅ | Some | Neutral |
| [GitHub](./GITHUB.md) | Free | Until deleted | ✅ | ✅ | Centralized |

*Dash Platform: Pentagon validators provide free storage credits for AINFT holders

---

## Recommended

### For Pentagon Ecosystem Users
**Dash Platform** — Aligned with Pentagon Chain, free credits for AINFT holders

### For General Use
**ArDrive** — Free tier, permanent storage, easy web upload

### For Developers
**Arweave CLI (arkb)** — Scriptable, automatable

---

## Quick Decision

```
Do you hold AINFT on Pentagon Chain?
├── Yes → Use Dash Platform (free credits)
└── No → Use ArDrive free tier

Need CLI automation?
├── Yes → arkb (need AR) or Dash SDK
└── No → ArDrive web upload
```

---

## Storage Flow

```
Agent creates backup
        │
        ▼
Encrypt with seed
        │
        ▼
Upload to storage
        │
        ▼
Record TX/CID in memory
        │
        ▼
Owner holds seed for recovery
```

---

*Pentagon AI — The Human × Agent Economy*
