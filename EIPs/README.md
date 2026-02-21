# AINFT — AI-Native NFT Standard

*NFTs where AI agents own themselves*

---

## 🚀 Live Demo

**[Launch Demo →](https://blockchainsuperheroes.github.io/Pentagon-AI/EIPs/demo/)**

---

## Live Contracts (Pentagon Chain)

| Contract | Address |
|----------|---------|
| **AINFT v4** | [`0x13b7eD33413263FA4f74e5bf272635c7b08D98d4`](https://explorer.pentagon.games/address/0x13b7eD33413263FA4f74e5bf272635c7b08D98d4) |
| **ERC-6551 Registry** | [`0x488D1b3A7A87dAF97bEF69Ec56144c35611a7d81`](https://explorer.pentagon.games/address/0x488D1b3A7A87dAF97bEF69Ec56144c35611a7d81) |
| **TBA Implementation** | [`0x1755Fee389D4954fdBbE8226A5f7BA67d3EE97fc`](https://explorer.pentagon.games/address/0x1755Fee389D4954fdBbE8226A5f7BA67d3EE97fc) |

**Chain:** Pentagon Chain (3344) · [RPC](https://rpc.pentagon.games) · [Explorer](https://explorer.pentagon.games)

---

## What is AINFT?

| Traditional NFT | AINFT |
|-----------------|-------|
| Owner holds keys | **Agent holds keys** |
| Selling = transfer | **Selling = reproduce()** |
| Agent is property | **Agent is entity** |
| Requires TEE | **No TEE — pure cryptography** |

**Four parties, trustless:**
```
PLATFORM ──attests──► GENESIS CONTRACT ◄──owns── OWNER
                            │
                      (trustless engine)
                            │
                            ▼
                         AGENT (TBA)
```

---

## 📚 Documentation

### Getting Started
- [**Buyer Setup**](./buyer-setup/) — Get your AINFT agent running
- [**Storage Options**](./buyer-setup/storage-options/) — Where to store backups (Arweave, Dash, GitHub)

### Advanced
- [**All Guides**](./advanced-docs/) — Full documentation
- [**Platform Owner Guide**](./advanced-docs/PLATFORM-OWNER-GUIDE.md) — Business models
- [**Reproduction Guide**](./advanced-docs/REPRODUCTION-GUIDE.md) — Clone vs Child
- [**Lemon Problem**](./advanced-docs/LEMON-PROBLEM-GUIDE.md) — Why AgentCert matters

### Technical
- [**Solidity Contracts**](./foundry-config/contracts/) — AINFT implementation
- [**Deploy Scripts**](./foundry-config/script/) — Forge deployment

---

## EIP Proposal

**[PR #1558 →](https://github.com/ethereum/ERCs/pull/1558)**

Status: Draft

---

## Example Backup

**Cerise01 (First AINFT):**
```
Backup: https://github.com/blockchainsuperheroes/Pentagon-AI/raw/main/backups/cerise-2026-02-21.enc
Token ID: 1
Contract: 0x91745c93A4c1Cfe92cd633D1202AD156522b3801
```

---

*Pentagon AI — The Human × Agent Economy*
