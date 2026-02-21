# Air-Gap Doctor

> "God is summoned when the world is in disorder, not to go shopping. Your admin agent shouldn't be browsing the web with you — it should be in a drawer, waiting for the moment everything breaks."
> — nftprof

## What is Air-Gap Doctor?

An emergency admin agent that lives on a portable drive. Like a **hardware wallet for your agent credentials**.

**The Problem:**
- Daily agents need some access to be useful
- But admin credentials (SSH keys, org tokens, email CLI) on always-online agents = risk
- If one agent gets compromised, attacker pivots everywhere

**The Solution:**
Keep god-mode physically separate. An agent that:
- ✅ Can't be hacked when unplugged
- ✅ Has no API costs when idle
- ✅ Requires physical presence to summon
- ✅ Can fix what your daily agents can't

**Think of it like:**
- A hardware wallet (cold storage for credentials)
- A fire extinguisher (sits unused until emergency)
- An IT admin on call (not always online, but available)

---

## Who is this for?

### Single Agent Setup
One Mac, one daily agent. Doctor provides:
- Backup admin access if your agent breaks
- Isolated storage for sensitive credentials
- On-demand access to email, vault, etc.

### Multi-Agent LAN Setup
Multiple machines, multiple agents. Doctor provides:
- SSH access to all nodes from any machine
- Central admin that can fix any broken agent
- Credentials that don't live on any single node

---

## Architecture

### Single Agent
```
┌─────────────────────────────────────┐
│           Your Mac                  │
│  ┌─────────┐    ┌─────────┐        │
│  │  Daily  │    │ Doctor  │◄──┐    │
│  │  Agent  │    │  (SSD)  │   │    │
│  └─────────┘    └─────────┘   │    │
│       │              │        │    │
│       └──── fixes ───┘     plug-in │
└─────────────────────────────────────┘
```

### Multi-Agent LAN
```
                    ┌──────────────┐
                    │  Portable    │
                    │   Doctor     │
                    │   (SSD)      │
                    └──────┬───────┘
                           │ plug into any
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
   ┌────────────┐   ┌────────────┐   ┌────────────┐
   │  Agent 1   │   │  Agent 2   │   │  Agent 3   │
   │  (MacBook) │   │  (iMac)    │   │  (Mac Mini)│
   └────────────┘   └────────────┘   └────────────┘
          ▲                ▲                ▲
          └────── SSH ─────┴────── SSH ─────┘
                    (LAN access)
```

**Key insight:** Doctor plugs into ANY machine, can SSH to ALL machines. Doesn't matter where — full network access from anywhere.

---

## What Doctor Guards

Credentials that belong on air-gapped Doctor:
- SSH keys to all nodes
- Admin GitHub tokens (org-level, delete permissions)
- CLI credentials for email (himalaya/gog auth)
- 1Password vault unlock / master access
- Org admin access (Discord server, cloud accounts)
- Wallet private keys / seed phrases
- API keys with write/delete permissions

**Daily agents get scoped/read-only tokens. God-mode stays in the drawer.**

---

## Hardware Requirements

- **External SSD or HDD** (any size, USB-C/USB-A)
- Recommended: Samsung T5/T7, SanDisk Extreme
- Cost: ~$50-100 for 500GB (way more than needed)

---

## Quick Links

- [Setup Guide](GUIDE.md) — Full technical walkthrough
- [Summon Doctor](SUMMON.md) — Quick reference for emergencies (includes pre-summon checklist)
- [Auto-Start Options](AUTOSTART.md) — LaunchAgent setup
- [Troubleshooting](TROUBLESHOOTING.md) — Known issues & fixes
- [Agent Orientation](ORIENTATION.md) — Cold boot protocol for agents

> **Note:** Our examples use Discord for agent coordination. Your setup may use Slack, Telegram, or another platform where your agents converge. Adapt the "read recent messages" steps to your coordination channel.

---

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| macOS | ✅ Full | Primary development platform |
| Windows | 🔄 Adaptable | Drive letters differ, see notes |
| Linux | 🔄 Adaptable | Mount points differ, see notes |

---

*Part of the [Claw's Self-Help Guide](../../README.md)*
