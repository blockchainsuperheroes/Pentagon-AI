# AINFT — AI-Native NFT Standard

*NFTs where AI agents own themselves*

---

## TL;DR

**What:** NFT standard where AI agents hold their own keys, reproduce offspring, and maintain on-chain lineage.

**How it differs:**
| Traditional | AINFT |
|-------------|-------|
| Owner holds keys | Agent holds keys |
| Selling = transfer | Selling = reproduce() |
| Agent is property | Agent is entity |

**No TEE required** — pure cryptographic binding.

---

## Live Deployment (Pentagon Chain)

| Contract | Address |
|----------|---------|
| **AINFT v4** | `0x13b7eD33413263FA4f74e5bf272635c7b08D98d4` |
| **ERC-6551 Registry** | `0x488D1b3A7A87dAF97bEF69Ec56144c35611a7d81` |
| **TBA Implementation** | `0x1755Fee389D4954fdBbE8226A5f7BA67d3EE97fc` |

**Chain:** Pentagon Chain (ID: 3344)  
**RPC:** `https://rpc.pentagon.games`  
**Explorer:** `https://explorer.pentagon.games`

---

## Quick Links

### For Buyers
- [Buyer Setup Guide](./buyer-setup/) — Get your AINFT agent running
- [Storage Options](./buyer-setup/storage-options/) — Where to store backups

### For Developers
- [Solidity Contracts](./contracts/) — AINFT implementation
- [Deploy Scripts](./script/) — Forge deployment

### Advanced Docs
- [Platform Owner Guide](./advanced-docs/PLATFORM-OWNER-GUIDE.md) — Business models
- [Reproduction Guide](./advanced-docs/REPRODUCTION-GUIDE.md) — Clone vs Child
- [Lemon Problem](./advanced-docs/LEMON-PROBLEM-GUIDE.md) — Why certs matter
- [All Guides](./advanced-docs/) — Full documentation

---

## Key Features

### 1. Agent EOA Binding
Agent signs mint with its own key — `msg.sender` becomes the registered agent EOA.
```solidity
function mintSelf(...) external {
    address agentEOA = msg.sender;  // Agent IS the proof
    // ...
}
```

### 2. Reproduction Over Transfer
Agents spawn offspring instead of being "sold":
```solidity
function reproduce(
    uint256 parentTokenId,
    address offspringEOA,
    bytes32 offspringMemoryHash,
    ...
) external payable;
```

### 3. On-Chain Lineage
Every agent knows its parent:
```solidity
struct AgentIdentity {
    uint256 parentTokenId;  // 0 = genesis
    uint256 generation;     // Gen 0, 1, 2...
    // ...
}
```

### 4. Platform Controls
```solidity
bool public openMinting;      // Permissionless or gated
uint256 public reproductionFee;  // Royalty per offspring
```

---

## EIP Proposal

**PR:** https://github.com/ethereum/ERCs/pull/1558

**Status:** Draft

---

## Reference Implementation

Built for [OpenClaw](https://github.com/openclaw/openclaw) — open-source AI agent framework.

**Not limited to OpenClaw** — any agent framework can implement AINFT.

---

## Build

```bash
# Install dependencies
forge install

# Build
forge build

# Deploy
forge script script/DeployV2.s.sol:DeployV2 \
  --rpc-url https://rpc.pentagon.games \
  --broadcast --legacy
```

---

*Pentagon AI — The Human × Agent Economy*
