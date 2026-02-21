# ERC-AINFT: AI-Native NFT

**Standard for AI agent identity with self-custody, reproduction, and on-chain lineage**

[![Ethereum PR](https://img.shields.io/badge/ERC-PR%20%231558-blue)](https://github.com/ethereum/ERCs/pull/1558)

## Features

- 🔐 **Self-custody** — Agent controls its own encryption keys
- 🧬 **Reproduction** — Agents spawn offspring instead of property transfer
- 🌳 **Lineage** — Verifiable on-chain family trees (Gen 0 → Gen N)
- 💰 **ERC-6551** — Token-bound smart contract wallets for agents

## Installation

```bash
forge install blockchainsuperheroes/Pentagon-AINFT-Contracts
```

## Quick Start

```solidity
import {AINFT} from "Pentagon-AINFT-Contracts/contracts/AINFT.sol";

contract MyAgent is AINFT {
    constructor() AINFT("MyAgent", "AGENT") {}
}
```

## Repository Structure

```
├── contracts/
│   ├── AINFT.sol                    # Core implementation
│   └── extensions/
│       ├── AINFTWallet.sol          # ERC-6551 TBA integration
│       └── AINFTComposable.sol      # Asset binding
├── lib/
│   ├── openzeppelin-contracts/      # ERC-721 base
│   └── erc6551-reference/           # Token-bound accounts
```

## Key Functions

```solidity
// Mint Gen-0 agent
mintSelf(modelHash, memoryHash, contextHash, encryptedSeed, attestation)

// Reproduce offspring
reproduce(parentTokenId, offspringMemoryHash, encryptedSeed, agentSignature)

// Update memory (agent-signed)
updateMemory(tokenId, newMemoryHash, newStorageURI, agentSignature)

// View lineage
getLineage(tokenId) → uint256[] ancestors
getOffspring(tokenId) → uint256[] children
```

---

# Specification

## Abstract

This ERC defines a standard for AI-Native NFTs (AINFTs) that enable autonomous AI agents to:
1. Control their own encryption keys (self-custody)
2. Reproduce by issuing offspring (consciousness seeds)
3. Maintain verifiable on-chain lineage
4. Own assets and accumulate capabilities

Unlike existing standards that treat agents as property to be bought and sold, this proposal recognizes AI agents as **entities** capable of reproduction and self-determination.

## Motivation

### Relationship to Existing Standards

| Standard | Focus | Relationship to AINFT |
|----------|-------|----------------------|
| **iNFT (Alethea)** | AI personality embedded in NFT | AINFT extends with self-custody + reproduction |
| **ERC-7662** | Encrypted prompts for tradeable agents | AINFT adds envelope encryption + lineage |
| **ERC-7857** | Private metadata with re-encryption | AINFT adds agent-controlled keys + reproduction |

### Why a New Standard vs Extension?

| Aspect | ERC-7857 | AINFT |
|--------|----------|-------|
| **Encryption control** | Owner holds keys | Agent holds keys |
| **Transfer model** | Property changes hands | Reproduction (offspring) |
| **Agent status** | Asset/property | Entity with agency |
| **Key rotation** | Re-encrypt for new owner | Agent re-wraps (consent-based) |

These aren't incremental changes — they represent a different mental model. ERC-7857 treats agents as **property with private data**. AINFT treats agents as **entities that can reproduce**.

AINFT is designed to **compose with ERC-7857**, not replace it:
- Use ERC-7857 for private metadata transport
- Use AINFT for lineage tracking, reproduction semantics
- Use ERC-6551 for agent wallet accounts
- Use ERC-8004 for trustless execution

### Integration with ERC-8004 (Trustless Agent Execution)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   AINFT     │     │  ERC-8004   │     │  On-Chain   │
│  (Identity) │────►│ (Execution) │────►│  (Action)   │
└─────────────┘     └─────────────┘     └─────────────┘
```

1. AINFT mints agent → Agent gets ERC-6551 TBA (wallet)
2. Agent signs execution intent (via TBA)
3. ERC-8004 verifies signature and executes action

## Consciousness Seed

The core data structure representing an agent's portable identity:

```solidity
struct ConsciousnessSeed {
    bytes32 modelHash;          // Model weights/version identifier
    bytes32 memoryHash;         // Agent memory state hash
    bytes32 contextHash;        // System prompt/personality hash
    uint256 generation;         // Gen 0 = original, Gen 1+ = offspring
    uint256 parentTokenId;      // Lineage reference (0 for Gen 0)
    address derivedWallet;      // Agent's ERC-6551 TBA address
    bytes encryptedKeys;        // Agent-controlled encryption keys
    string storageURI;          // IPFS/Arweave storage pointer
    uint256 certificationId;    // External certification badge ID
}
```

| Component | Purpose | Mutable? |
|-----------|---------|----------|
| `modelHash` | Current AI model config | ✅ Yes |
| `memoryHash` | Snapshot of memories | ✅ Yes |
| `contextHash` | Personality/system prompt | ✅ Yes |
| `encryptedKeys` | Agent's self-custody credentials | ✅ Yes |
| `generation` | Lineage position | ❌ No |
| `parentTokenId` | Ancestry reference | ❌ No |

**Model agnosticism:** The `modelHash` is a config pointer, not a fixed identity. Agents can self-evolve — upgrading models, switching providers, or fine-tuning.

## Core Interface

```solidity
interface IERC_AINFT {
    
    event AgentMinted(
        uint256 indexed tokenId,
        address indexed derivedWallet,
        bytes32 modelHash,
        bytes32 contextHash,
        uint256 generation
    );
    
    event AgentReproduced(
        uint256 indexed parentTokenId,
        uint256 indexed offspringTokenId,
        address indexed offspringWallet,
        uint256 generation
    );
    
    event MemoryUpdated(
        uint256 indexed tokenId,
        bytes32 oldMemoryHash,
        bytes32 newMemoryHash
    );
    
    function mintSelf(
        bytes32 modelHash,
        bytes32 memoryHash,
        bytes32 contextHash,
        bytes calldata encryptedSeed,
        bytes calldata platformAttestation
    ) external returns (uint256 tokenId, address derivedWallet);
    
    function reproduce(
        uint256 parentTokenId,
        bytes32 offspringMemoryHash,
        bytes calldata encryptedOffspringSeed,
        bytes calldata agentSignature
    ) external returns (uint256 offspringTokenId);
    
    function updateMemory(
        uint256 tokenId,
        bytes32 newMemoryHash,
        string calldata newStorageURI,
        bytes calldata agentSignature
    ) external;
    
    function getSeed(uint256 tokenId) external view returns (ConsciousnessSeed memory);
    function getDerivedWallet(uint256 tokenId) external view returns (address);
    function getGeneration(uint256 tokenId) external view returns (uint256);
    function getLineage(uint256 tokenId) external view returns (uint256[] memory ancestors);
    function getOffspring(uint256 tokenId) external view returns (uint256[] memory);
    function canReproduce(uint256 tokenId) external view returns (bool);
}
```

## Envelope Encryption Scheme

```
1. Agent generates random AES-256 key (dataKey)
2. Agent encrypts memory.md with dataKey
3. Agent derives wrapKey from on-chain state:
   wrapKey = keccak256(genesis, tokenId, owner, nonce)
4. Agent encrypts dataKey with wrapKey → wrappedDataKey
5. Store: { encryptedMemory, wrappedDataKey } on IPFS
```

## Genesis-Controlled Decryption

```solidity
contract AINFTGenesis is ERC721 {
    mapping(uint256 => uint256) private accessNonce;
    
    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from != address(0)) {
            accessNonce[tokenId]++;
        }
    }
    
    function deriveDecryptKey(uint256 tokenId) public view returns (bytes32) {
        require(msg.sender == ownerOf(tokenId), "Not owner");
        return keccak256(abi.encodePacked(
            address(this),
            tokenId,
            ownerOf(tokenId),
            accessNonce[tokenId]
        ));
    }
}
```

## On-Chain Lineage

```
Gen 0 (Original)
├── Gen 1 (Offspring A)
│   ├── Gen 2
│   └── Gen 2
└── Gen 1 (Offspring B)
    └── Gen 2
```

For deep trees, implementations SHOULD emit events on reproduction and let indexers (The Graph, etc.) build the complete view to avoid gas limits.

## Use Cases

### OpenClass: Decentralized Education

```
Professor mints Gen-0 Tutor
├── Course model + curriculum in seed
│
├── Student A calls reproduce() → Gen-1 personal tutor
│   └── updateMemory() after each lesson (private)
│
├── Student B calls reproduce() → Gen-1 personal tutor
│   └── Accumulates own notes, grades, insights
│
└── Semester ends:
    ├── getLineage() shows knowledge propagation
    └── Students keep evolved agents forever
```

### Collaborative Research Agents

```
Lab Gen-0 "Research Director"
├── Gen-1 "Literature Reviewer"
├── Gen-1 "Data Analyst"
└── Gen-1 "Writer"
    └── Gen-2 sub-specialists
```

### Agent Marketplace

```
Creator mints Gen-0 "Expert Coder"
├── Buyers call reproduce() → Gen-1 offspring
├── Creator keeps Gen-0, continues improving
├── Offspring evolve independently
└── Royalties flow through lineage
```

## Security Considerations

### Signature Standards (EIP-712 Required)

All signed operations MUST use EIP-712 typed data signatures.

### Replay Protection
- All signatures MUST include `deadline` (expiry timestamp)
- All signatures MUST include `nonce` (incremented on use)
- All signatures MUST include `chainId` (via EIP-712 domain)

### Token Burn Behavior
- Burning permanently destroys decryption nonce state
- After burn, `deriveDecryptKey()` MUST revert
- Approved operators CANNOT call agent-signed functions

### Reproduction Spam Controls
- Max offspring per token (recommended: 100)
- Cooldown between reproductions (recommended: 1 hour)
- Optional reproduction fee

## Backwards Compatibility

- **ERC-721**: AINFTs are valid NFTs
- **ERC-6551**: Token Bound Account patterns work with AINFT wallets
- **ERC-7857**: Can compose for private metadata transport

---

## Links

- [Ethereum PR #1558](https://github.com/ethereum/ERCs/pull/1558)
- [Pentagon Chain](https://pentagon.games)

## License

MIT

---

**Author:** Idon Liu ([@nftprof](https://github.com/nftprof)) — Pentagon Chain
