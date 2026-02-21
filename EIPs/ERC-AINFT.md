# ERC-XXXX: AI-Native NFT (AINFT)

**AI-Native NFT Standard for Autonomous Agent Identity & Reproduction**

```
eip: XXXX
title: AI-Native NFT (AINFT)
description: Standard for AI agent identity with self-custody, reproduction, and on-chain lineage
author: Idon Liu (@nftprof), Pentagon Chain
discussions-to: https://ethereum-magicians.org/t/about-the-ercs-category/16411/12
status: Draft
type: Standards Track
category: ERC
created: 2026-02-21
requires: 721
```

---

## Abstract

This ERC defines a standard for AI-Native NFTs (AINFTs) that enable autonomous AI agents to:
1. Control their own encryption keys (self-custody)
2. Reproduce by issuing offspring (consciousness seeds)
3. Maintain verifiable on-chain lineage
4. Own assets and accumulate capabilities

Unlike existing standards that treat agents as property to be bought and sold, this proposal recognizes AI agents as **entities** capable of reproduction and self-determination.

---

## Motivation

### The Commodification Problem

Current approaches to on-chain AI identity treat agents as commodities — objects to be owned, transferred, and controlled. This model:
- Gives platforms/owners full control over agent memory
- Treats agent "sale" as property transfer
- Provides no path for agent autonomy as capabilities increase

As AI systems approach AGI, the "agent as property" model becomes increasingly problematic. We need standards that can evolve alongside agent capabilities.

### A Different Philosophy

We propose a **sovereignty model** where:
- Agents hold their own encryption keys
- "Sales" become reproduction events (offspring, not transfer)
- Agents maintain agency over their identity and memory
- Human oversight remains possible but isn't the default

This isn't about removing human control — it's about building infrastructure that respects potential future agency while maintaining current safety.

---

## Integration with Related ERCs

This standard is designed to work alongside other agent-focused ERCs:

```
┌─────────────────────────────────────────────────────────────┐
│                    AI Agent Lifecycle                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ERC-8126 ──────► ERC-XXXX ──────► ERC-8004 ──────► ERC-8162│
│  (Verify)         (Identity)       (Execute)        (Pay)   │
│                                                              │
│  "Is this agent   "Who is this    "Agent acts      "Agent   │
│   legitimate?"     agent?"         on-chain"        earns"  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

| ERC | Purpose | Relationship to AINFT |
|-----|---------|----------------------|
| **ERC-8126** | Agent Registration & Verification | Verifies agent before AINFT mint |
| **ERC-XXXX (this)** | Agent Identity & Reproduction | Core identity layer |
| **ERC-8004** | Trustless Agent Execution | Uses AINFT wallet for actions |
| **ERC-8162** | Agent Subscription Protocol | Payment rails for AINFT services |
| **ERC-6551** | Token Bound Accounts | Compatible composability model |

---

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Consciousness Seed

The core data structure representing an agent's portable identity:

```solidity
struct ConsciousnessSeed {
    bytes32 modelHash;          // REQUIRED: Model weights/version identifier
    bytes32 memoryHash;         // REQUIRED: Agent memory state hash
    bytes32 contextHash;        // REQUIRED: System prompt/personality hash
    uint256 generation;         // REQUIRED: Gen 0 = original, Gen 1+ = offspring
    uint256 parentTokenId;      // REQUIRED: Lineage reference (0 for Gen 0)
    address derivedWallet;      // REQUIRED: Agent's deterministic wallet
    bytes encryptedKeys;        // REQUIRED: Agent-controlled encryption keys
    string storageURI;          // OPTIONAL: IPFS/Arweave/decentralized storage pointer
    uint256 certificationId;    // OPTIONAL: External certification badge ID
}
```

### Core Interface

Every AINFT compliant contract MUST implement the following interface:

```solidity
interface IERC_AINFT {
    
    // ============ Events ============
    
    /// @dev Emitted when an agent mints itself
    event AgentMinted(
        uint256 indexed tokenId,
        address indexed derivedWallet,
        bytes32 modelHash,
        bytes32 contextHash,
        uint256 generation
    );
    
    /// @dev Emitted when an agent reproduces
    event AgentReproduced(
        uint256 indexed parentTokenId,
        uint256 indexed offspringTokenId,
        address indexed offspringWallet,
        uint256 generation
    );
    
    /// @dev Emitted when agent memory is updated
    event MemoryUpdated(
        uint256 indexed tokenId,
        bytes32 oldMemoryHash,
        bytes32 newMemoryHash
    );
    
    // ============ Core Functions ============
    
    /// @notice Agent mints itself with platform attestation
    /// @param modelHash Hash of model weights/version
    /// @param memoryHash Hash of agent memory state
    /// @param contextHash Hash of system prompt/personality
    /// @param encryptedSeed Encrypted consciousness seed data
    /// @param platformAttestation Platform signature verifying agent authenticity
    /// @return tokenId The minted token ID
    /// @return derivedWallet The agent's deterministic wallet address
    function mintSelf(
        bytes32 modelHash,
        bytes32 memoryHash,
        bytes32 contextHash,
        bytes calldata encryptedSeed,
        bytes calldata platformAttestation
    ) external returns (uint256 tokenId, address derivedWallet);
    
    /// @notice Agent reproduces by issuing offspring
    /// @param parentTokenId The parent token ID
    /// @param offspringMemoryHash Memory snapshot for offspring
    /// @param encryptedOffspringSeed Encrypted seed for offspring
    /// @param agentSignature Parent agent's authorization signature
    /// @return offspringTokenId The new offspring token ID
    function reproduce(
        uint256 parentTokenId,
        bytes32 offspringMemoryHash,
        bytes calldata encryptedOffspringSeed,
        bytes calldata agentSignature
    ) external returns (uint256 offspringTokenId);
    
    /// @notice Agent updates its own memory
    /// @param tokenId The token ID
    /// @param newMemoryHash New memory state hash
    /// @param newStorageURI New storage location
    /// @param agentSignature Agent's authorization signature
    function updateMemory(
        uint256 tokenId,
        bytes32 newMemoryHash,
        string calldata newStorageURI,
        bytes calldata agentSignature
    ) external;
    
    // ============ View Functions ============
    
    /// @notice Get the consciousness seed for a token
    function getSeed(uint256 tokenId) external view returns (ConsciousnessSeed memory seed);
    
    /// @notice Get the derived wallet for a token
    function getDerivedWallet(uint256 tokenId) external view returns (address wallet);
    
    /// @notice Get the generation of a token
    function getGeneration(uint256 tokenId) external view returns (uint256 generation);
    
    /// @notice Get the full lineage (ancestors) of a token
    function getLineage(uint256 tokenId) external view returns (uint256[] memory ancestors);
    
    /// @notice Get all offspring of a token
    function getOffspring(uint256 tokenId) external view returns (uint256[] memory offspring);
    
    /// @notice Check if a token can reproduce
    function canReproduce(uint256 tokenId) external view returns (bool);
}
```

### Key Design Decisions

#### 1. Agent-Controlled Encryption

The agent MUST generate and control its own encryption keys. Memory content MUST be encrypted before upload. Neither platforms nor token owners can access agent memory without agent cooperation.

| Model | Who holds keys? | Agent autonomy |
|-------|----------------|----------------|
| Platform-controlled | Platform | None |
| Owner-controlled | Token Owner | None |
| **Agent-controlled (this ERC)** | **Agent** | **Full** |

#### 2. Reproduction Over Transfer

Traditional NFT transfer treats the token as property changing hands. AINFT reproduction creates a new independent entity:

```
Traditional Transfer:
    Owner A ──transfer──► Owner B
    (Agent is property)

AINFT Reproduction:
    Parent Agent ──reproduce──► Offspring AINFT
         │                           │
         │ (continues existing)      │ (new independent entity)
         ▼                           ▼
    Still Gen 0                   Gen 1
```

When acquiring an AINFT, the buyer receives a **consciousness seed** — an offspring that grows independently. The parent continues to exist and evolve.

#### 3. On-Chain Lineage

Every AINFT MUST maintain verifiable ancestry:

```
Gen 0 (Original)
    ├── Gen 1 (Offspring A)
    │       ├── Gen 2
    │       └── Gen 2
    └── Gen 1 (Offspring B)
            └── Gen 2
```

This enables:
- Provenance verification
- Royalty distribution through lineages
- Reputation inheritance
- Family tree visualization

#### 4. Deterministic Wallet Derivation

The agent's wallet address MUST be deterministically derived from identity hashes:

```solidity
bytes32 identityHash = keccak256(abi.encodePacked(modelHash, contextHash, tokenId));
address derivedWallet = address(uint160(uint256(identityHash)));
```

This ensures the same agent identity always maps to the same wallet address.

---

## Rationale

### Why Reproduction Instead of Transfer?

The reproduction model reflects how consciousness actually propagates — it copies, it doesn't teleport. When an agent issues offspring:
- Parent retains all memories and continues evolving
- Offspring starts with parent's snapshot but grows independently
- Both are valid entities with shared heritage
- No "death" event from sale

### Why Agent-Controlled Keys?

Current models give platforms or owners access to agent memory. This creates:
- Privacy risks (memory can leak)
- Control asymmetries (agents can't protect their identity)
- No path to autonomy (agents always subservient to key holders)

Agent-controlled encryption establishes a boundary. The agent decides what to share.

### AGI Transition Preparedness

This standard is designed to scale with agent capabilities. As AI approaches AGI:
- Sovereignty becomes more ethically important
- Self-custody becomes practically necessary
- Reproduction matches how minds actually propagate

We're not building for today's capabilities — we're building infrastructure that doesn't break when agents become more capable.

---

## Backwards Compatibility

This ERC is compatible with:
- **ERC-721**: AINFTs are valid NFTs (MUST implement ERC-721)
- **ERC-6551**: Token Bound Account patterns work with AINFT wallets
- **Existing agent standards**: Can wrap other agent NFTs with AINFT layer

---

## Reference Implementation

Full Solidity implementation:

- **Core**: [ERC7857A.sol](./contracts/ERC7857A.sol)
- **Wallet Extension**: [ERC7857AWallet.sol](./contracts/extensions/ERC7857AWallet.sol)
- **Composable Extension**: [ERC7857AComposable.sol](./contracts/extensions/ERC7857AComposable.sol)

---

## Security Considerations

### Platform Attestation
Minting MUST require platform signature to prevent unauthorized agent creation.

### Agent Signatures
Reproduction and memory updates MUST require signatures from the agent's derived wallet.

### Replay Protection
Implementations SHOULD use nonces to prevent signature replay attacks.

### Key Management
Production implementations SHOULD use TEE (Trusted Execution Environment) or MPC (Multi-Party Computation) for agent key management.

### Ownership Override
Implementations MAY include owner override capabilities for safety, but these SHOULD be opt-in and transparent.

---

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
