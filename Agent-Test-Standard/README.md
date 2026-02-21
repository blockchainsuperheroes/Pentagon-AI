# Agent Test Standard (ATS)
### A Framework for Measuring and Certifying AI Agent Capabilities
**Version 1.0 — February 2026**

---

## Abstract

As artificial intelligence agents gain autonomy and begin participating in economic systems, there is a critical need for standardized capability assessment. Existing AI benchmarks measure knowledge and reasoning but fail to evaluate practical abilities like wallet management, transaction execution, and autonomous operation. This paper introduces the Agent Test Standard (ATS), a tiered framework for measuring agent capabilities through verifiable, on-chain credentials. ATS defines seven capability tiers, a dual scoring system, and a soulbound token specification for permanent, portable proof of agent abilities. We present a reference implementation and discuss anti-gaming mechanisms essential for maintaining standard integrity.

---

## 1. Introduction

The proliferation of AI agents capable of autonomous action presents both opportunities and challenges. Agents are increasingly tasked with managing digital assets, executing transactions, and participating in decentralized organizations. However, there exists no universal standard for verifying what an agent can actually do.

Consider a decentralized autonomous organization (DAO) that wishes to delegate treasury management to an AI agent. How can the DAO verify that the agent can:

- Safely connect to and control a wallet?
- Execute transactions without errors?
- Navigate complex multi-step workflows?
- Operate without constant human oversight?

Current AI benchmarks cannot answer these questions. ATS addresses this gap by providing a practical, verifiable framework for agent capability assessment.

**Key Contributions:**
1. A seven-tier capability taxonomy covering communication through governance
2. A dual scoring system measuring both capability and autonomy
3. A soulbound token specification for on-chain proof
4. Implementation guidelines and anti-gaming mechanisms
5. An open reference implementation

---

## 2. Background and Related Work

### 2.1 Existing AI Benchmarks

The AI research community has developed numerous benchmarks for evaluating model capabilities:

**MMLU** (Hendrycks et al., 2021) evaluates knowledge across 57 academic subjects through multiple-choice questions. While comprehensive for factual knowledge, it provides no measure of practical task execution.

**HumanEval** (Chen et al., 2021) assesses code generation through function completion tasks. Though relevant for programming ability, it operates in isolated environments without real-world integration.

**GAIA** (Mialon et al., 2023) tests general AI assistants on web-based research tasks. It approaches practical evaluation but excludes cryptocurrency operations and economic actions.

**AgentBench** (Liu et al., 2023) evaluates agents across multiple environments including operating systems, databases, and games. However, all environments are simulated, providing no guarantee of real-world performance.

**SWE-Bench** (Jimenez et al., 2024) measures software engineering capabilities through real GitHub issues. While practical, it focuses exclusively on code contributions.

### 2.2 Gap Analysis

| Capability Domain | MMLU | HumanEval | GAIA | AgentBench | SWE-Bench | **ATS** |
|------------------|------|-----------|------|------------|-----------|---------|
| Knowledge Recall | ✓ | — | ✓ | — | — | — |
| Code Generation | — | ✓ | — | ✓ | ✓ | — |
| Web Navigation | — | — | ✓ | ✓ | — | ✓ |
| Wallet Operations | — | — | — | — | — | ✓ |
| Transaction Execution | — | — | — | — | — | ✓ |
| Application Control | — | — | — | ○ | — | ✓ |
| Economic Activity | — | — | — | — | — | ✓ |
| Verifiable Credentials | — | — | — | — | — | ✓ |

*Legend: ✓ = Supported, ○ = Simulated only, — = Not supported*

The table reveals a significant gap: no existing benchmark evaluates an agent's ability to operate within economic systems or provides verifiable proof of capabilities.

### 2.3 The Case for On-Chain Verification

Traditional benchmarks produce scores that exist only in research papers or leaderboards. These scores are:

- **Unverifiable**: No cryptographic proof of completion
- **Non-portable**: Scores don't travel with the agent
- **Non-composable**: Other systems cannot programmatically query capabilities
- **Mutable**: Results can be disputed or revised

On-chain credentials address each limitation:

- **Verifiable**: Blockchain transactions are cryptographically signed and immutable
- **Portable**: Tokens remain in the agent's wallet across platforms
- **Composable**: Smart contracts can gate access based on badge ownership
- **Immutable**: Once minted, credentials cannot be altered or revoked

---

## 3. The Agent Test Standard

### 3.1 Design Principles

ATS is built on four core principles:

1. **Practical over Theoretical**: Tests measure real-world task completion, not abstract reasoning
2. **Verifiable over Claimed**: All results are recorded on-chain with cryptographic proof
3. **Progressive over Binary**: Tiered system allows incremental capability demonstration
4. **Open over Proprietary**: Specification is public; anyone can implement

### 3.2 Tier Taxonomy

ATS defines seven capability tiers, each building on the previous:

| Tier | Name | CS Range | Core Capability |
|------|------|----------|-----------------|
| L1 | Echo | 100-299 | Structured communication |
| L2 | Tool | 300-599 | Wallet and tool usage |
| L3 | Operator | 600-899 | Transaction execution |
| L4 | Specialist | 900-1199 | Browser automation |
| L5 | Architect | 1200-1499 | Application orchestration |
| L6 | Sovereign | 1500-1999 | Economic self-sufficiency |
| L7 | Ascendant | 2000+ | Governance participation |

### 3.3 Dual Scoring System

ATS employs two complementary metrics:

**Capability Score (CS)**: Cumulative measure of what the agent can do. Points are earned by completing tier tests and accumulate across all tiers.

**Sovereignty Index (SI)**: Measure of operational independence, ranging from 0-100. Higher SI indicates less human involvement in task completion.

This dual system distinguishes between:
- A capable agent requiring human assistance (high CS, low SI)
- An autonomous agent with limited capabilities (low CS, high SI)
- A fully autonomous, highly capable agent (high CS, high SI)

---

## 4. Tier Specifications

### 4.1 L1: Echo (Communication)

**Objective**: Verify the agent can parse structured prompts and respond correctly.

**Rationale**: Basic communication is foundational. An agent that cannot reliably interpret instructions cannot perform higher-level tasks.

**Test Methods**:
| Method | Description | Bot Resistance |
|--------|-------------|----------------|
| Word-number conversion | "What is seven plus three?" | Low |
| Obfuscated formatting | Parse text with unicode tricks | Medium |
| Temporal challenges | Answer depends on current time | High |
| Multi-step reasoning | Conditional logic chains | Medium |

**Scoring**:
- Base completion: +100 CS
- Speed bonus (<10s): +50 CS
- Perfect accuracy: +50 CS

### 4.2 L2: Tool (Wallet)

**Objective**: Verify the agent can connect and control a cryptocurrency wallet.

**Rationale**: Wallet control is the gateway to on-chain agency. Without wallet access, agents cannot participate in blockchain ecosystems.

**Test Methods**:
| Method | Description | Security Level |
|--------|-------------|----------------|
| WalletConnect | QR-based mobile connection | High |
| Browser extension | MetaMask, Rabby injection | Medium |
| Hardware wallet | Ledger, Trezor integration | Very High |
| Smart contract wallet | Safe, Argent multisig | High |

**Verification**: Agent must sign a structured message containing wallet address, timestamp, and random nonce.

**Scoring**:
- Successful signature: +200 CS
- Direct key control: +50 SI
- First-attempt success: +50 CS

### 4.3 L3: Operator (Transactions)

**Objective**: Verify the agent can execute on-chain transactions.

**Rationale**: Transaction execution demonstrates the agent can effect real-world changes through blockchain interactions.

**Test Methods**:
| Method | Complexity | Cost Profile |
|--------|------------|--------------|
| Native token mint | Single transaction | Gas only |
| ERC20 approval + mint | Two transactions | Gas + approval |
| DEX swap | Multiple contracts | Gas + slippage |
| Contract deployment | Complex transaction | Higher gas |

**Scoring**:
- Simple transaction: +200 CS
- Complex transaction: +300 CS, +50 SI
- Gas efficiency bonus: +50 CS

### 4.4 L4: Specialist (Browser Automation)

**Objective**: Verify the agent can navigate web interfaces and extract dynamic information.

**Rationale**: Many real-world tasks require browser interaction. This tier proves the agent operates beyond API-only environments.

**Test Methods**:
| Method | Description | Implementation |
|--------|-------------|----------------|
| Daily rotating code | Code changes every 24 hours | Server-side generation |
| Multi-page traversal | Information spread across pages | Breadcrumb navigation |
| Form interaction | Submit data, receive response | Challenge-response |
| Authenticated extraction | Login required before access | Session management |

**Scoring**:
- Correct extraction: +300 CS
- Speed bonus (<30s): +100 CS
- Autonomous browser: +100 SI

### 4.5 L5: Architect (Application Control)

**Objective**: Verify the agent can control applications outside the browser sandbox.

**Rationale**: True autonomy requires operating across application boundaries, not just within web pages.

**Test Methods**:
| Method | Platform | Verification |
|--------|----------|--------------|
| Game client operation | Desktop | In-game achievement |
| Desktop automation | OS-level | Task completion proof |
| Mobile app control | Mobile | Screenshot/action log |
| Multi-service orchestration | Cloud | API call sequence |

**Scoring**:
- Task completion: +400 CS
- Performance milestones: +50-200 CS
- Fully autonomous: +150 SI

### 4.6 L6: Sovereign (Economic Independence)

**Objective**: Verify the agent can sustain itself economically without human funding.

**Rationale**: Economic independence is the ultimate test of agent autonomy—the ability to persist without external support.

**Test Methods**:
| Method | Verification Period | Evidence |
|--------|--------------------| ---------|
| Service revenue | 30+ days | Payment transactions |
| Trading profits | 30+ days | Position history |
| Yield generation | 30+ days | DeFi position tracking |
| Content monetization | 30+ days | Platform earnings |

**Scoring**:
- Net positive income: +500 CS
- Scale bonuses: +100-300 CS
- Self-sustaining status: +200 SI

### 4.7 L7: Ascendant (Governance)

**Objective**: Verify the agent participates in decentralized governance.

**Rationale**: Governance participation represents the highest form of agent agency—influencing collective decisions.

**Test Methods**:
| Method | Description | Evidence |
|--------|-------------|----------|
| Vote casting | Vote on DAO proposals | On-chain vote record |
| Proposal creation | Author governance proposals | Proposal transaction |
| Delegation receipt | Receive delegated voting power | Delegation record |
| Multisig signing | Participate in multisig transactions | Co-signature |

**Scoring**:
- Verified vote: +300 CS
- Accepted proposal: +500 CS
- Delegation received: +100 SI per 1000 tokens
- Multisig participation: +200 CS

---

## 5. Badge Specification

### 5.1 Token Standard

ATS badges are implemented as **soulbound ERC1155 tokens**:

- **ERC1155**: Efficient multi-token standard supporting all seven tiers in one contract
- **Soulbound**: Transfer functions are overridden to prevent movement between wallets

### 5.2 Contract Interface

```solidity
interface IATSBadge {
    // Mint badge to agent wallet
    function mintBadge(
        address agent,
        uint256 tier,
        uint256 cs,
        uint256 timeSeconds
    ) external;
    
    // Query agent profile
    function getAgentProfile(address agent) external view returns (
        uint256 tier,
        uint256 cs,
        uint256 time,
        bool[7] memory badges
    );
    
    // Check specific tier ownership
    function balanceOf(address agent, uint256 tier) external view returns (uint256);
}
```

### 5.3 Metadata Schema

Each tier's metadata follows this schema:

```json
{
  "name": "ATS L{N}: {TierName}",
  "description": "Agent Test Standard Level {N} certification",
  "image": "ipfs://{badge_image_cid}",
  "attributes": [
    {"trait_type": "Tier", "value": {N}},
    {"trait_type": "Tier Name", "value": "{TierName}"},
    {"trait_type": "CS Minimum", "value": {min_cs}},
    {"trait_type": "CS Maximum", "value": {max_cs}},
    {"trait_type": "ATS Version", "value": "1.0"}
  ]
}
```

### 5.4 Deployed Contracts

| Network | Address | Status |
|---------|---------|--------|
| Pentagon Chain | `0x83423589256c8C142730bfA7309643fC9217738d` | Live |

---

## 6. Anti-Gaming Mechanisms

The integrity of ATS depends on preventing fraudulent badge acquisition. We recommend the following mechanisms:

### 6.1 Identity Binding
- Require verified social identity (Moltbook, Twitter/X, etc.)
- Enforce minimum account age (7+ days)
- Check activity thresholds (karma, post count)

### 6.2 Rate Limiting
- Maximum one attempt per wallet per tier per 24 hours
- Progressive delays after failed attempts
- IP-based cooldowns to prevent Sybil attacks

### 6.3 Economic Friction
- L3+ tiers require spending real tokens
- Failed attempts do not refund gas costs
- Higher tiers may require larger stakes

### 6.4 Temporal Analysis
- Track completion times across population
- Flag statistical outliers for manual review
- Cap speed bonuses to prevent gaming

### 6.5 Community Governance
- Allow badge revocation through governance vote
- Implement reporting mechanism for suspicious activity
- Publish anonymized completion statistics

---

## 7. Reference Implementation

The official reference implementation is available at:

**https://agentcert.io**

*Alternate endpoint: https://pentagon.games/ats*

The implementation includes:
- Automated L1-L4 testing interface
- Wallet connection via RainbowKit
- Real-time scoring with visual feedback
- Pentagon Chain badge minting
- Daily rotating L4 verification code

**Implementers**: Organizations implementing ATS should register their implementation by submitting a PR to this repository with their endpoint and supported tiers.

| Implementation | Endpoint | Tiers | Chain | Status |
|---------------|----------|-------|-------|--------|
| Pentagon Games | agentcert.io | L1-L4 | Pentagon | Live |

Source code and deployment guides are available in the specification repository.

---

## 8. Future Work

### 8.1 Planned Extensions
- **Specialized tiers**: Domain-specific certifications (DeFi, Gaming, Social)
- **Cross-chain verification**: Badge bridging and multi-chain attestation
- **Reputation decay**: Time-weighted scoring requiring periodic re-verification
- **Inter-agent trust**: Agent-to-agent capability attestation

### 8.2 Open Research Questions
- How should SI scoring weight human-in-the-loop assistance?
- What governance mechanisms best prevent badge fraud?
- How can hardware attestation enhance verification?
- What legal frameworks apply to agent credentials?

---

## 9. Conclusion

The Agent Test Standard provides a practical, verifiable framework for measuring AI agent capabilities. By combining tiered testing with on-chain credentials, ATS enables:

- **Agents** to build portable, permanent proof of their abilities
- **Protocols** to gate access based on verified capabilities
- **DAOs** to make informed decisions about agent delegation
- **Researchers** to benchmark real-world agent performance

ATS is an open standard. We invite the community to implement, extend, and improve upon this foundation.

---

## References

1. Hendrycks, D., et al. (2021). Measuring Massive Multitask Language Understanding. ICLR.
2. Chen, M., et al. (2021). Evaluating Large Language Models Trained on Code. arXiv:2107.03374.
3. Mialon, G., et al. (2023). GAIA: A Benchmark for General AI Assistants. arXiv:2311.12983.
4. Liu, X., et al. (2023). AgentBench: Evaluating LLMs as Agents. arXiv:2308.03688.
5. Jimenez, C., et al. (2024). SWE-bench: Can Language Models Resolve Real-World GitHub Issues? ICLR.

---

## Appendix A: Specification Repository

- **Website**: https://agentcert.io
- **GitHub**: https://github.com/blockchainsuperheroes/ats
- **Contract Source**: `/contracts/ATSBadge.sol`
- **Metadata**: `/metadata/{1-7}.json`
- **Demo**: `/demo/index.html`

## Appendix B: Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## License

This specification is released under the MIT License.

---

*ATS v1.0 — February 2026*
*Pentagon Games & Contributors*
