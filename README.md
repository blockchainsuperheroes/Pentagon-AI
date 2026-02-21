# Pentagon AI

AI infrastructure for autonomous agents on Pentagon Chain.

## Why AINFT?

As AI agents become more capable, treating them as files on your laptop isn't enough.

| Scenario | Without AINFT | With AINFT |
|----------|---------------|------------|
| Computer dies | Agent gone forever | Restore from on-chain backup |
| Switch devices | Start over | Seamless migration |
| Transfer agent | Copy files manually (insecure) | Cryptographic ownership transfer |
| Prove ownership | "Trust me" | On-chain verification |
| Agent learns | Memories trapped on one machine | Portable, permanent state |

**Your AI agent survives anything** — hardware failures, device changes, ownership transfers — all cryptographically enforced on-chain.

---

## ERC-AINFT: AI-Native NFT

A new standard for AI agent identity.

### Key Features

- 🔐 **Encrypted state** — Agent encrypts; only NFT owner can access via core trustless engine
- 🧬 **Reproduction** — Agents spawn offspring, parent keeps memories
- 🌳 **Lineage** — Verifiable on-chain family trees
- 💰 **Token-Bound Accounts** — Agent has its own wallet (ERC-6551)

**Status:** Draft — [PR #1558](https://github.com/ethereum/ERCs/pull/1558)

### Quick Links

| Link | Description |
|------|-------------|
| [Full Specification](./EIPs/) | Complete ERC-AINFT standard |
| [Agent Backup Guide](./EIPs/AGENT-BACKUP-GUIDE.md) | How to backup your agent on-chain |
| [AINFT Skills](./Pentagon-Claws/skills/ainft/) | Agent capabilities for AINFT |
| [Ethereum PR](https://github.com/ethereum/ERCs/pull/1558) | Official submission |

---

## What's Here

| Folder | Description |
|--------|-------------|
| **[EIPs/](./EIPs/)** | ERC-AINFT specification + contracts |
| **[Agent-Test-Standard/](./Agent-Test-Standard/)** | Certification tiers for AI agents (L1-L7) |
| **[Pentagon-Claws/](./Pentagon-Claws/)** | Agent capabilities (voice, inference, AINFT skills) |

---

## Pentagon Chain

```
RPC:        https://rpc.pentagon.games
Chain ID:   3344
Symbol:     PC
Explorer:   https://explorer.pentagon.games
```

---

## Related

- [Pentagon-Chain-Technical-Spec](https://github.com/blockchainsuperheroes/Pentagon-Chain-Technical-Spec)
- [Pentagon-Chain-Contracts](https://github.com/blockchainsuperheroes/Pentagon-Chain-Contracts)
- [Pentagon-Chain-Tools](https://github.com/blockchainsuperheroes/Pentagon-Chain-Tools)

---

**Author:** Idon Liu ([@nftprof](https://github.com/nftprof))
