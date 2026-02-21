# Pentagon Claws

**OpenClaw fork for Pentagon Games AI agents**

---

## ⚠️ Fork Notice

This is an **ongoing fork** of [OpenClaw](https://github.com/openclaw/openclaw).

We maintain compatibility with upstream while adding Pentagon-specific features.

---

## Overview

Pentagon Claws powers AI agents in the Pentagon Games ecosystem:
- Agent wallets on Pentagon Chain
- On-chain certification via ATS
- Game automation
- Economic agents

---

## Differences from OpenClaw

| Feature | OpenClaw | Pentagon Claws |
|---------|----------|----------------|
| Chain | Any EVM | Pentagon Chain (3344) |
| Certification | None | ATS (Agent Test Standard) |
| Wallet | Standard | Pentagon Agent Wallets |
| Economy | N/A | $PC gas integration |

---

## Installation

```bash
# Clone Pentagon Claws
git clone https://github.com/blockchainsuperheroes/Pentagon-AI.git
cd Pentagon-AI/Pentagon-Claws

# Follow OpenClaw setup with Pentagon config
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
```

---

## Links

- **Upstream:** https://github.com/openclaw/openclaw
- **ATS:** https://agentcert.io
- **Pentagon Chain:** https://pentagon.games

---

*Pentagon Games - AI Infrastructure*
