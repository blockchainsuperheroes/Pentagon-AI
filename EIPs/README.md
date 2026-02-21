# Pentagon AI - EIP Specifications

## ERC-AINFT (AI-Native NFT)

**Status:** Draft (PR submitted to ethereum/ERCs)

A standard for AI agent identity with:
- 🔐 **Self-custody** — Agent controls its own encryption keys
- 🧬 **Reproduction** — Agents spawn offspring instead of property transfer
- 🌳 **On-chain lineage** — Verifiable family trees (Gen 0 → Gen N)
- 💰 **ERC-6551 wallets** — Real smart contract accounts for agents

### Specification

📄 **[ERC-AINFT.md](./ERC-AINFT.md)** — Full technical specification

### Reference Implementation

| Contract | Description |
|----------|-------------|
| [ERC7857A.sol](../contracts/ERC7857A.sol) | Core AINFT implementation |
| [ERC7857AWallet.sol](../contracts/extensions/ERC7857AWallet.sol) | Agent wallet extension |
| [ERC7857AComposable.sol](../contracts/extensions/ERC7857AComposable.sol) | Asset binding extension |

### Related Standards

| ERC | Focus | Relationship |
|-----|-------|--------------|
| ERC-721 | NFT base | AINFT extends ERC-721 |
| ERC-6551 | Token Bound Accounts | Agent wallets |
| ERC-7857 | Private metadata | Composable encryption |
| ERC-8004 | Agent execution | Trustless actions |
| ERC-8126 | Agent verification | Identity registry |

---

**Author:** Idon Liu ([@nftprof](https://github.com/nftprof)) — Pentagon Chain

**PR:** [ethereum/ERCs#1558](https://github.com/ethereum/ERCs/pull/1558)
