# AINFT Reference Implementation

Solidity contracts implementing the ERC-AINFT specification.

## Contracts

| File | Description |
|------|-------------|
| `ERC7857A.sol` | Core AINFT with reproduction + lineage |
| `extensions/ERC7857AWallet.sol` | Agent wallet (ERC-6551 TBA) |
| `extensions/ERC7857AComposable.sol` | Asset binding for agents |

## Usage

```solidity
import "./ERC7857A.sol";

contract MyAgent is ERC7857A {
    constructor() ERC7857A("MyAgent", "AGENT") {}
}
```

## Specification

See [../EIPs/README.md](../EIPs/README.md) for full technical specification.
