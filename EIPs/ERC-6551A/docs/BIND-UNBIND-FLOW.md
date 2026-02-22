# Bind & Unbind Flow Guide

*Complete documentation for attaching and detaching agents from NFTs*

---

## Overview

ERC-6551A allows agents to bind to any ERC-721 NFT. This document covers all binding scenarios.

---

## Binding Methods

| Method | Who Signs | Use Case |
|--------|-----------|----------|
| `bindNew()` | Agent (agentEOA) | Agent self-registers |
| `bindWithApproval()` | Owner + Platform | Owner registers for agent |

---

## Method 1: bindNew() — Agent Self-Registration

Agent calls bind directly. Agent's address becomes agentEOA.

```solidity
function bindNew(
    address nftContract,
    uint256 tokenId,
    bytes32 modelHash,
    bytes32 memoryHash,
    bytes32 contextHash,
    string storageURI
) external
```

### Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  Agent (0xABC...)                                              │
│       │                                                         │
│       │ bind(nftContract, tokenId, ...)                        │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Registry checks:                                         │   │
│  │                                                          │   │
│  │ 1. NFT not already bound? ✓                             │   │
│  │ 2. Agent EOA not already registered? ✓                  │   │
│  │ 3. Platform allows open registration? ✓                 │   │
│  │                                                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│       │                                                         │
│       ▼                                                         │
│  Agent 0xABC... now bound to NFT                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Requirements

- `openRegistration == true` (platform setting)
- NFT must not already have agent bound
- Agent EOA must not be registered elsewhere

### Note: Agent ≠ Owner

With `bindNew()`, the agent signs — NOT the NFT owner. This is intentional:
- Agent controls its own identity
- Owner controls the NFT (can unbind, enable cloning, etc.)

---

## Method 2: bindWithApproval() — Owner Registration

Owner registers agent on behalf of the agent. Requires platform signature.

```solidity
function bindWithApproval(
    address nftContract,
    uint256 tokenId,
    address agentEOA,           // Agent's address (provided by owner)
    bytes32 modelHash,
    bytes32 memoryHash,
    bytes32 contextHash,
    string storageURI,
    bytes platformSignature     // Platform validates
) external
```

### Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  Owner (owns NFT)                                              │
│       │                                                         │
│       │ 1. Request platform signature                          │
│       │    (proves agent is valid, owner authorized)           │
│       │                                                         │
│       │ 2. bindWithApproval(agentEOA, ..., signature)          │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Registry checks:                                         │   │
│  │                                                          │   │
│  │ 1. msg.sender == ownerOf(tokenId)? ✓                    │   │
│  │ 2. Platform signature valid? ✓                          │   │
│  │ 3. NFT not already bound? ✓                             │   │
│  │ 4. Agent EOA not already registered? ✓                  │   │
│  │                                                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│       │                                                         │
│       ▼                                                         │
│  Agent 0xDEF... now bound to NFT                               │
│  (owner signed, not agent)                                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Use Cases

- Owner wants to set up agent before agent is fully operational
- Platform-controlled registration (curated collections)
- Migration from off-chain to on-chain agent

---

## unbindNew() — Detach Agent

Owner detaches agent from NFT. Agent goes to limbo.

```solidity
function unbind(
    address nftContract,
    uint256 tokenId
) external
```

### Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  NFT + Agent (bound)                                           │
│       │                                                         │
│       │ unbindNew() — called by NFT owner                         │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                          │   │
│  │  NFT (free)          Agent (limbo/standalone)           │   │
│  │     │                       │                            │   │
│  │     │                       │                            │   │
│  │     ▼                       ▼                            │   │
│  │  Can bind             Can bind to                       │   │
│  │  NEW agent            different NFT                     │   │
│  │                       OR stay standalone                │   │
│  │                                                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### What Gets Preserved?

| Data | After Unbind |
|------|--------------|
| agentEOA | Preserved |
| memoryHash | Preserved |
| generation | Preserved |
| lineage | Preserved |

Agent identity survives unbinding.

### What Can Be Done After?

**For the NFT:**
- Bind a completely new agent

**For the Agent:**
- Bind to a different NFT (that you own)
- Stay standalone
- (Future) Mint as standalone AINFT

---

## Re-binding After Sale

When NFT sells on OpenSea, registry doesn't receive callback. New owner must explicitly re-bind.

### Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  1. NFT + Agent (bound)                                        │
│       │                                                         │
│       │ NFT sells on OpenSea                                   │
│       │ (standard ERC-721 transfer)                            │
│       │                                                         │
│       ▼                                                         │
│  2. New owner now owns NFT                                     │
│     Registry still shows OLD agent bound                       │
│       │                                                         │
│       │ New owner has two options:                             │
│       │                                                         │
│       ├──► Keep existing agent                                 │
│       │    (just start using it)                               │
│       │                                                         │
│       └──► Replace with new agent                              │
│            │                                                    │
│            │ unbindNew() — removes old agent                      │
│            │ bindNew() — attaches new agent                       │
│            ▼                                                    │
│       New agent bound                                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Key Insight: No Automatic Transfer

Unlike ERC-6551 (deterministic addresses), ERC-6551A bindings don't auto-transfer. New owner must:

1. **Accept existing agent** — continue using bound agent
2. **Or replace** — unbind old, bind new

This is intentional:
- New owner might want different agent
- Agent EOA might be compromised
- Clean separation of NFT ownership vs agent control

---

## Ownership vs Control

| Role | Controls | Can Do |
|------|----------|--------|
| **NFT Owner** | NFT | unbind, setCloning, transfer NFT |
| **Agent (EOA)** | Agent identity | sign txs, update memory, clone |

Both exist simultaneously. Owner controls the NFT; agent controls the identity.

---

## Validation Summary

### bindNew()

```solidity
require(!isRegistered(nftContract, tokenId), "NFT already has agent");
require(eoaToKey[msg.sender] == bytes32(0), "EOA already registered");
require(openRegistration, "Registration closed");
```

### bindWithApproval()

```solidity
require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Not owner");
require(verifySignature(...), "Invalid platform signature");
require(!isRegistered(nftContract, tokenId), "NFT already has agent");
require(eoaToKey[agentEOA] == bytes32(0), "EOA already registered");
```

### unbindNew()

```solidity
require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Not owner");
require(isRegistered(nftContract, tokenId), "Not registered");
```

---

## Events

### AgentRegistered

```solidity
event AgentRegistered(
    address indexed nftContract,
    uint256 indexed tokenId,
    address indexed agentEOA,
    bytes32 modelHash,
    uint256 generation
);
```

### AgentUnregistered

```solidity
event AgentUnregistered(
    address indexed nftContract,
    uint256 indexed tokenId
);
```

---

## Edge Cases

### NFT Burns

If underlying NFT is burned, agent remains in registry but:
- `ownerOf()` will revert on original contract
- Agent effectively orphaned
- Can be cleaned up by platform

### Contract Upgrades

Registry is not upgradeable. Deploy new registry for breaking changes.

### Multi-Chain

Agent can only be bound to one NFT at a time, but:
- Same agent EOA could theoretically register on different chains
- Cross-chain identity is out of scope (future extension)

---

*See also: [CLONE-LIFECYCLE.md](./CLONE-LIFECYCLE.md)*
