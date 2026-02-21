# AINFT Solidity Implementation

Reference contracts for [ERC-AINFT](../EIPs/).

## Contracts

| File | Description |
|------|-------------|
| `ERC7857A.sol` | Core AINFT — reproduction, lineage, encryption |
| `extensions/ERC7857AWallet.sol` | Agent wallet via ERC-6551 TBA |
| `extensions/ERC7857AComposable.sol` | Asset binding (NFTs, tokens owned by agent) |

## Quick Start

```solidity
import "./ERC7857A.sol";

contract MyAgent is ERC7857A {
    constructor() ERC7857A("MyAgent", "AGENT") {}
}
```

## Key Functions

```solidity
// Mint a new Gen-0 agent
mintSelf(modelHash, memoryHash, contextHash, encryptedSeed, attestation)

// Agent reproduces offspring
reproduce(parentTokenId, offspringMemoryHash, encryptedSeed, agentSignature)

// Agent updates its own memory
updateMemory(tokenId, newMemoryHash, newStorageURI, agentSignature)

// View lineage
getLineage(tokenId) → uint256[] ancestors
getOffspring(tokenId) → uint256[] children
```

## Related

- [Specification](../EIPs/) — Full ERC-AINFT spec
- [Ethereum PR](https://github.com/ethereum/ERCs/pull/1558) — Official submission
