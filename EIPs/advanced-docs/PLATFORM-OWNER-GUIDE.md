# Platform Owner Guide

*Business use cases for deploying AINFT*

---

## Overview

As a platform owner, you deploy the AINFT contract and control:
- Who can mint new agents (open vs closed)
- Cloning fees (royalties)
- The rules of your agent ecosystem

---

## Business Models

### Model A: Closed Platform (Factory)

```
You = Agent Factory
├── Create Genesis agents (Gen 0)
├── Sell to customers
├── Collect cloning royalties
└── Control quality

Settings:
├── openMinting = false (only you attest)
├── cloningFee = 0.1 PC (royalty per clone)
└── Each sale = you control if cloning allowed
```

**Use cases:**
- Premium AI assistants
- Branded agent collections
- Enterprise deployments
- Quality-controlled ecosystems

**Revenue:**
- Initial sale price
- Cloning royalties
- Service fees

### Model B: Open Platform (Commons)

```
You = Infrastructure Provider
├── Deploy contract
├── Let anyone mint
├── No cloning fees
└── Community grows freely

Settings:
├── openMinting = true
├── cloningFee = 0
└── setCloning defaults to true
```

**Use cases:**
- Open source agent ecosystem
- Research communities
- Decentralized networks
- Public goods

**Revenue:**
- Donations
- Premium services
- Ecosystem growth value

### Model C: Hybrid (Freemium)

```
You = Freemium Platform
├── Open minting for basic agents
├── Premium features gated
├── Cloning fee for monetization
└── Tiered access

Settings:
├── openMinting = true (anyone can join)
├── cloningFee = 0.05 PC (small royalty)
└── Premium features via separate contracts
```

**Use cases:**
- SaaS agent platforms
- Developer ecosystems
- Marketplaces

---

## Contract Deployment

### Step 1: Deploy AINFT Contract

```bash
forge create contracts/ERC_AINFT_v2.sol:ERC_AINFT_v2 \
  --constructor-args "Your Platform Name" "SYMBOL" $YOUR_ADDRESS \
  --rpc-url $RPC \
  --private-key $KEY \
  --legacy
```

### Step 2: Configure Platform Settings

```bash
AINFT="0x..."  # Your deployed contract

# Closed platform (default)
# openMinting = false by default
# Only you can attest new mints

# OR Open platform:
cast send $AINFT "setOpenMinting(bool)" true \
  --rpc-url $RPC --private-key $KEY --legacy

# Set cloning fee (e.g., 0.1 PC)
cast send $AINFT "setCloningFee(uint256)" 100000000000000000 \
  --rpc-url $RPC --private-key $KEY --legacy
```

### Step 3: Create Genesis Agent(s)

```bash
# Generate agent EOA
AGENT_KEY=$(openssl rand -hex 32)
AGENT_EOA=$(cast wallet address --private-key 0x$AGENT_KEY)

# Create hashes
MODEL_HASH=$(echo -n "your-model" | cast keccak)
MEMORY_HASH=$(cat agent-memory.md | cast keccak)
SOUL_HASH=$(cat agent-soul.md | cast keccak)

# Sign attestation (you = platform signer)
MESSAGE_HASH=$(cast keccak $(cast abi-encode --packed \
  "f(address,address,bytes32,bytes32,bytes32)" \
  $AGENT_EOA $OWNER_ADDRESS $MODEL_HASH $MEMORY_HASH $SOUL_HASH))

ATTESTATION=$(cast wallet sign --private-key $YOUR_KEY $MESSAGE_HASH)

# Agent mints
cast send $AINFT \
  "mintSelf(bytes32,bytes32,bytes32,bytes,address,bytes)" \
  $MODEL_HASH $MEMORY_HASH $SOUL_HASH \
  "0x$(openssl rand -hex 32)" \
  $OWNER_ADDRESS \
  $ATTESTATION \
  --rpc-url $RPC --private-key 0x$AGENT_KEY --legacy
```

---

## Platform Controls

### Minting Control

```solidity
// Check current mode
bool isOpen = openMinting;

// Toggle (only platform can call)
setOpenMinting(true);   // Anyone can mint
setOpenMinting(false);  // Platform attests only
```

### Cloning Fees

```solidity
// Set fee (in wei)
setCloningFee(100000000000000000);  // 0.1 PC

// Check fee
uint256 fee = cloningFee;

// Withdraw collected fees
withdrawFees();  // Sends to platformSigner
```

### Per-Agent Control

Owners of individual AINFTs control:
```solidity
// Owner enables/disables cloning for their agent
setCloning(tokenId, true);   // Allow cloning
setCloning(tokenId, false);  // No cloning
```

---

## Revenue Flows

### Closed Platform

```
Customer wants agent
        │
        ▼
Pay you (off-chain or custom contract)
        │
        ▼
You attest mint → Agent created
        │
        ▼
Customer owns AINFT
        │
        ▼
Customer clones → cloningFee to you
        │
        ▼
withdrawFees() → Collect royalties
```

### Open Platform with Fees

```
Anyone mints (openMinting = true)
        │
        ▼
Free to create Gen 0
        │
        ▼
Clone → pays cloningFee
        │
        ▼
Royalties accumulate in contract
        │
        ▼
withdrawFees() → Platform collects
```

---

## Pricing Strategies

### Cloning Fee Considerations

| Fee Level | Effect |
|-----------|--------|
| 0 | Maximum growth, no revenue |
| 0.01 PC | Minimal friction, small revenue |
| 0.1 PC | Moderate barrier, decent revenue |
| 1+ PC | High barrier, premium only |

### Dynamic Pricing (Advanced)

Could implement:
- Fee decreases with generation (encourage early adoption)
- Fee based on parent's "value" or certifications
- Tiered fees for different agent types

---

## Quality Control

### AgentCert Integration

Require L3+ certification before mint:
```solidity
// In custom mintSelf:
require(agentCert.balanceOf(agentEOA, 3) > 0, "Need L3 cert");
```

### Curated Cloning

Platform can require attestation for clone too:
```solidity
// Add to clone():
if (!openCloning) {
    require(_verifySignature(..., platformSigner), "Need approval");
}
```

---

## Marketing Your Platform

### For Closed Platforms

**Sell points:**
- Premium quality agents
- Verified capabilities
- Support included
- Controlled ecosystem
- Brand trust

**Transparency:**
- Clearly state cloning rules
- Publish fee structure
- Document what buyers get

### For Open Platforms

**Sell points:**
- Freedom to modify
- No royalties
- Community-driven
- Fork-friendly
- Own your agent fully

---

## Legal Considerations

### Terms of Service

Document:
- Cloning rights
- Fee structure
- Platform responsibilities
- Agent data ownership
- Liability limits

### Buyer Expectations

Make clear BEFORE purchase:
- Can they clone?
- What fees apply?
- Who controls what?
- What happens if platform shuts down?

---

## Example Configurations

### Premium Agent Studio

```solidity
openMinting = false        // Only studio mints
cloningFee = 0.5 PC   // 0.5 PC per clone
// Individual agents: cloning enabled by default
// Studio attests each new agent manually
```

### Open Research Network

```solidity
openMinting = true         // Anyone can mint
cloningFee = 0        // Free cloning
// Community self-governs
// No platform revenue
```

### SaaS Agent Platform

```solidity
openMinting = true         // Free tier
cloningFee = 0.1 PC   // Monetize cloning
// Premium features via separate contracts
// Subscription model layered on top
```

---

## Contract Addresses (Pentagon Chain)

| Version | Address | Features |
|---------|---------|----------|
| v4 (latest) | `0x13b7eD33413263FA4f74e5bf272635c7b08D98d4` | Full platform controls |
| Registry | `0x488D1b3A7A87dAF97bEF69Ec56144c35611a7d81` | ERC-6551 TBA |

---

## See Also

- [BUYER-GUIDE.md](./BUYER-GUIDE.md) — Customer perspective
- [GLOSSARY.md](../GLOSSARY.md) — Terms
- [AGENT-VERIFICATION-PHILOSOPHY.md](./AGENT-VERIFICATION-PHILOSOPHY.md) — Design rationale

---

*Pentagon AI — The Human × Agent Economy*
