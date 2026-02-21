# Pentagon AI

**AI infrastructure for Pentagon Games — agents, certification, and the PenXr ecosystem**

---

## 🎯 Vision: PenXr

Your AI agent, embodied and portable.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  NFC Card   │ ──► │   Spatial   │ ──► │  3D Agent   │ ──► │   AI_NFT    │
│  (Physical) │     │   Profile   │     │  (Clawdbot) │     │ (Portable)  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                    pentagon.games/     Voice + 3D         ERC-7857A
                    acc/username        Streaming           Transferable
```

**How it works:**
1. **Tap NFC** → Opens your spatial profile
2. **Meet your agent** → 3D Clawdbot avatar (like Cerise)
3. **Others interact** → Tap your card, talk to your AI
4. **Voice streaming** → Local network consciousness mode
5. **Fully portable** → Transfer via AI_NFT with encrypted context

---

## 📦 Components

### [Agent-Test-Standard](./Agent-Test-Standard/)
Certification tiers for AI agents (L1-L7).
- Prove capabilities on-chain
- Soulbound badges
- Progressive trust levels

### [Pentagon-Claws](./Pentagon-Claws/)
Agent capabilities for cloud + local deployment.
- Voice Router — streaming speech-to-text
- Local Brain — GPU inference on your network
- Security — credential management
- Operations — health monitoring

---

## 🔗 Standards

### ERC-7857A: AI-Native NFT
Agents that own themselves.

```solidity
struct AgentMetadata {
    bytes32 contextHash;      // Encrypted SOUL.md, MEMORY.md
    address agentWallet;      // Agent-controlled wallet
    string storageURI;        // IPFS/Arweave pointer
    uint256 certificationId;  // ATS badge token ID
}
```

The NFT contains:
- **Encrypted context** (Pentagon_Claws data)
- **Wallet binding** (agent controls funds)
- **Storage pointers** (decentralized memory)
- **Certification proof** (ATS tier)

Transfer the NFT = transfer the complete agent.

---

## 🎮 Use Cases

| Use Case | Description |
|----------|-------------|
| **Personal AI** | Your Clawdbot, accessible via NFC card |
| **Game NPCs** | AI characters in Gunnies, EtherFantasy |
| **Economic Agents** | Trading, arbitrage on Pentagon Chain |
| **3D Avatars** | Agent-controlled presence in PenXr |
| **Voice Assistants** | Streaming consciousness via local network |

---

## ⛓️ Pentagon Chain

```
RPC:        https://rpc.pentagon.games
Chain ID:   3344
Symbol:     PC
Explorer:   https://explorer.pentagon.games
```

---

## 📚 Related Repos

- [Pentagon-Chain-Ecosystem-Solidity-Contracts](https://github.com/blockchainsuperheroes/Pentagon-Chain-Ecosystem-Solidity-Contracts)
- [PentagonChain-Technical-Specification-Public](https://github.com/blockchainsuperheroes/PentagonChain-Technical-Specification-Public)

---

## 🔐 Security

Bounty active. Find bugs, get paid.

Report to: [@nftprof](https://twitter.com/nftprof)

---

*Pentagon Games — Where humans and AI meet*
