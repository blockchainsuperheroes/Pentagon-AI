# Pentagon Claws

**OpenClaw fork for Pentagon Games AI agents — powering 3D PenXr agent infrastructure**

---

## ⚠️ Fork Notice

This is an **ongoing fork** of [OpenClaw](https://github.com/openclaw/openclaw).

We maintain compatibility with upstream while adding Pentagon-specific features for AI agents in gaming, metaverse, and economic applications.

---

## Overview

Pentagon Claws powers AI agents in the Pentagon Games ecosystem:
- **Agent wallets** on Pentagon Chain
- **On-chain certification** via ATS (Agent Test Standard)
- **Game automation** for Gunnies, EtherFantasy, PentaPets
- **Economic agents** participating in $PC economy
- **3D PenXr** — AI-controlled avatars and NPCs

---

## Components

### Core (this directory)
- Pentagon Chain integration
- Agent wallet management
- ATS certification hooks

### Self-Help Guides
Operational guides for running Pentagon Claws agents:
- [Voice Router](./guides/voice-router/) — Speech-to-text pipeline
- [Local Brain](./guides/local-brain/) — LAN inference setup
- [Security](./guides/security/) — Hardening and access control
- [Airgap Doctor](./guides/airgap-doctor/) — Offline diagnostics
- [Operations](./guides/operations/) — Monitoring and maintenance

See [SELFHELP.md](./SELFHELP.md) for the full guide index.

---

## Differences from OpenClaw

| Feature | OpenClaw | Pentagon Claws |
|---------|----------|----------------|
| Chain | Any EVM | Pentagon Chain (3344) |
| Certification | None | ATS (Agent Test Standard) |
| Wallet | Standard | Pentagon Agent Wallets |
| Economy | N/A | $PC gas integration |
| NFT Identity | N/A | ERC-7857A AI-NFT |
| 3D Integration | N/A | PenXr avatar control |

---

## Installation

```bash
# Clone Pentagon AI mono-repo
git clone https://github.com/blockchainsuperheroes/Pentagon-AI.git
cd Pentagon-AI/Pentagon-Claws

# Follow OpenClaw setup with Pentagon config
npm install
```

---

## Configuration

```yaml
# Pentagon Chain config
chain:
  rpc: https://rpc.pentagon.games
  chainId: 3344
  
# ATS certification
ats:
  endpoint: https://agentcert.io
  
# Agent identity
identity:
  nft: ERC-7857A  # AI-Native NFT
  storage: IPFS   # Memory persistence
```

---

## Related

- [Agent Test Standard](../Agent-Test-Standard/) — Certification tiers L1-L7
- [ERC-7857A](https://github.com/blockchainsuperheroes/Pentagon-Chain-Ecosystem-Solidity-Contracts/blob/main/EIPs/ERC-7857A-AINFT.md) — AI-Native NFT proposal

---

## Links

- **Upstream:** https://github.com/openclaw/openclaw
- **ATS:** https://agentcert.io
- **Pentagon Chain:** https://pentagon.games
- **Explorer:** https://explorer.pentagon.games

---

*Pentagon Games — AI Infrastructure for the Human × Agent Economy*
