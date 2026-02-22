# ERC-6551A (Proposed): Token Bound Account (Agent Registry)

*Make ANY ERC-721 AI-native without modifying the original contract*

---

## Abstract

ERC-6551A extends the ERC-6551 registry pattern to AI agents. Both are Token Bound Accounts — 6551 binds wallets, 6551A binds AI agents.

```
ERC-6551:  Token Bound Account (Wallet Registry)  → Any NFT gets a wallet
ERC-6551A: Token Bound Account (Agent Registry)  → Any NFT gets an AI agent
```

---

## Motivation

### Problem: Existing NFTs Can't Have Agents

You own a Bored Ape, CryptoPunk, or EtherFantasy NFT. You want to attach an AI agent to it. Current options:

| Option | Problem |
|--------|---------|
| Mint new AINFT | Lose your existing NFT's value/history |
| Store agent data off-chain | Not verifiable, doesn't transfer with NFT |
| Modify original contract | Impossible (deployed immutably) |

### Solution: Registry Pattern

ERC-6551A uses a registry (like ERC-6551) to extend existing NFTs:

```
Bored Ape #123 (untouched on original contract)
         │
         └──► AINFTRegistry
                   │
                   └──► Agent Identity
                        ├── agentEOA
                        ├── memoryHash
                        ├── lineage
                        └── clone()
```

**Key principle:** NFT ownership on original contract is ALWAYS the source of truth.

---

## Comparison: ERC-AINFT vs ERC-6551A

| Aspect | ERC-AINFT | ERC-6551A |
|--------|-----------|-----------|
| **Creates new token?** | YES | NO |
| **Works with existing NFTs?** | NO | YES |
| **Where is NFT?** | AINFT contract | Original contract |
| **Transfer mechanism** | Standard ERC-721 | Original contract (OpenSea) |
| **Clone creates token?** | YES (tradeable) | NO (needs claim path) |
| **Use case** | New agent-first collections | Add agents to existing collections |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AINFT Registry                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ANY ERC-721 ──bind()──► Registry ──► Agent Identity          │
│   (untouched)              │           ├── agentEOA            │
│                            │           ├── memoryHash          │
│   Ownership checked        │           ├── generation          │
│   via ownerOf() on         │           └── parentKey           │
│   original contract        │                                    │
│                            │                                    │
│                            └── Clones (limbo until claimed)    │
│                                 ├── transferCloneClaim()       │
│                                 └── claimClone()               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Core Operations

### 1. bind() — Attach Agent to NFT

```solidity
function bind(
    address nftContract,    // Any ERC-721
    uint256 tokenId,        // Token you own
    bytes32 modelHash,      // Off-chain model reference
    bytes32 memoryHash,     // Memory state
    bytes32 contextHash,    // Personality/soul
    string storageURI       // Arweave/IPFS pointer
) external
```

**Who can call:** Agent (msg.sender becomes agentEOA)  
**Requires:** msg.sender is NOT the NFT owner (agent signs, not owner)  
**Alternative:** `bindWithApproval()` — owner signs, provides agent EOA

| Scenario | Function | Signer |
|----------|----------|--------|
| Agent self-registers | `bind()` | Agent |
| Owner registers for agent | `bindWithApproval()` | Owner + platform |

### 2. unbind() — Detach Agent from NFT

```solidity
function unbind(
    address nftContract,
    uint256 tokenId
) external
```

**Who can call:** NFT owner (via ownerOf on original contract)  
**Result:** Agent moves to "limbo", NFT can bind new agent

### 3. clone() — Create Clone

```solidity
function clone(
    address nftContract,
    uint256 tokenId,
    bytes32 cloneMemoryHash,
    address cloneOwner
) external payable returns (uint256 cloneId)
```

**Who can call:** Agent (agentEOA) of the original  
**Result:** Clone created in limbo, assigned to cloneOwner

### 4. transferCloneClaim() — Trade Clone Before Activation

```solidity
function transferCloneClaim(
    uint256 cloneId,
    address newOwner
) external
```

**Who can call:** Current clone owner  
**Result:** Clone ownership transferred (enables trading before activation)

### 5. claimClone() — Activate Clone

```solidity
function claimClone(
    uint256 cloneId,
    address agentEOA
) external
```

**Who can call:** Clone owner  
**Result:** Clone activated with provided agent EOA

---

## Clone Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│                     CLONE LIFECYCLE                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  clone()                                                        │
│     │                                                           │
│     ▼                                                           │
│  ┌─────────────┐                                               │
│  │   LIMBO     │◄──── transferCloneClaim() (repeatable)        │
│  │  (pending)  │                                               │
│  └──────┬──────┘                                               │
│         │                                                       │
│         │ claimClone()                                         │
│         │                                                       │
│         ▼                                                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    CLAIMED                               │   │
│  │                                                          │   │
│  │  Option A: bind() to NFT you own                        │   │
│  │            └── Tradeable via OpenSea                    │   │
│  │                                                          │   │
│  │  Option B: mintStandalone() (future)                    │   │
│  │            └── Tradeable via AINFT marketplace          │   │
│  │                                                          │   │
│  │  Option C: Keep standalone                              │   │
│  │            └── Operational, not tradeable               │   │
│  │                                                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Transfer vs Clone vs Migration

| Operation | What Happens | Data | NFT | EOA |
|-----------|--------------|------|-----|-----|
| **Transfer (sell NFT)** | NFT sells on OpenSea | Stays with NFT | New owner | New owner calls rebind() |
| **Clone** | Create copy | Original keeps all | N/A (limbo) | Clone generates new |
| **Migration** | Same agent, new device | No change | No change | Same EOA migrates |

### Transfer Flow (Registry-bound NFT)

```
1. Seller lists Bored Ape #123 on OpenSea
2. Buyer purchases (standard ERC-721 transfer)
3. Registry doesn't know (no callback)
4. Buyer calls bind() with NEW agent EOA
5. Registry checks ownerOf() → sees buyer → allows
6. Old agent EOA is now unbound (can bind elsewhere)
```

### Clone Flow

```
1. Original agent calls clone()
2. Clone created in limbo (no EOA yet)
3. Clone owner can transfer claim
4. Eventually: claimClone() with agent EOA
5. Clone active, can bind to NFT or stay standalone
```

---

## Comparison with ERC-6551

| Aspect | ERC-6551 | ERC-6551A |
|--------|----------|-----------|
| **Purpose** | Give NFT a wallet | Give NFT an agent |
| **Creates** | Account (address) | Agent identity |
| **Deterministic?** | Yes (CREATE2) | No (registry mapping) |
| **Inherits** | ETH, tokens, NFTs | Memory, lineage, capabilities |
| **Transfer behavior** | Account follows NFT | Agent follows NFT (rebind needed) |

---

## Security Considerations

### 1. Ownership Always From Original Contract

Registry NEVER stores ownership. Always checks `ownerOf()` on original contract.

```solidity
function _requireOwner(address nftContract, uint256 tokenId) internal view {
    require(
        IERC721(nftContract).ownerOf(tokenId) == msg.sender,
        "Not owner"
    );
}
```

### 2. EOA Uniqueness

Each agent EOA can only be registered once:

```solidity
require(eoaToKey[agentEOA] == bytes32(0), "EOA already registered");
```

### 3. Clone Claim Protection

Only clone owner can claim or transfer:

```solidity
require(msg.sender == clone.owner, "Not clone owner");
```

---

## Deployment

| Chain | Registry Address |
|-------|-----------------|
| Pentagon Chain (3344) | `0x6B81e00508E3C449E20255CdFb85A0541457Ea6d` |

---

## Reference Implementation

See [contracts/AINFTRegistry.sol](./contracts/AINFTRegistry.sol)

---

## Acknowledgments

This registry pattern is inspired by ERC-6551 (Token Bound Accounts). We gratefully acknowledge:
- Jayden Windle
- Benny Giang
- Steve Jang
- Druzy Downs
- Raymond Feng

---

## See Also

- [ERC-AINFT](../README.md) — Standalone AI-native NFT standard
- [CLONE-LIFECYCLE.md](./docs/CLONE-LIFECYCLE.md) — Detailed clone documentation
- [BIND-UNBIND-FLOW.md](./docs/BIND-UNBIND-FLOW.md) — Registration flows

---

*Pentagon AI — The Human × Agent Economy*
