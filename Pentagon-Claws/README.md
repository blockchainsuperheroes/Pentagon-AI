# Pentagon Claws

**Agent capabilities for Pentagon Games ecosystem — cloud & local**

---

## Overview

Pentagon Claws extends AI agents with specialist capabilities for gaming, metaverse, and economic applications on Pentagon Chain.

Works with:
- **Cloud agents** (hosted, API-based)
- **Local agents** (self-hosted, on-device)

---

## Capabilities

Modular add-ons that enhance any agent:

| Capability | Description |
|------------|-------------|
| [Voice Router](./capabilities/voice-router/) | Speech-to-text pipeline for voice commands |
| [Local Brain](./capabilities/local-brain/) | LAN inference with GPU acceleration |
| [Security](./capabilities/security/) | Hardening, access control, credential management |
| [Airgap Doctor](./capabilities/airgap-doctor/) | Offline diagnostics and recovery |
| [Operations](./capabilities/operations/) | Monitoring, maintenance, health checks |

---

## Pentagon Chain Integration

```yaml
chain:
  rpc: https://rpc.pentagon.games
  chainId: 3344
  
identity:
  nft: ERC-7857A    # AI-Native NFT standard
  storage: IPFS     # Encrypted memory persistence
  
certification:
  endpoint: https://agentcert.io
  standard: ATS     # Agent Test Standard L1-L7
```

---

## Use Cases

- **Agent Wallets** — Autonomous $PC transactions
- **Game NPCs** — AI-controlled characters in Gunnies, EtherFantasy
- **Economic Agents** — Trading, arbitrage, market making
- **3D PenXr** — Avatar control in metaverse environments

---

## Related

- [Agent Test Standard](../Agent-Test-Standard/) — Certification tiers L1-L7
- [ERC-7857A](https://github.com/blockchainsuperheroes/Pentagon-Chain-Ecosystem-Solidity-Contracts/blob/main/EIPs/ERC-7857A-AINFT.md) — AI-Native NFT proposal
- [OpenClaw](https://github.com/openclaw/openclaw) — Upstream framework

---

## Links

- **Pentagon Chain:** https://pentagon.games
- **Explorer:** https://explorer.pentagon.games
- **ATS:** https://agentcert.io

---

*Pentagon Games — AI Infrastructure for the Human × Agent Economy*
