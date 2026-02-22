# ERC-AINFT: AI-Native NFT Standard

*NFTs where AI agents own themselves — they hold keys, clone clone, and maintain lineage.*

**EIP PR:** [github.com/ethereum/ERCs/pull/1558](https://github.com/ethereum/ERCs/pull/1558)

**Live MVP:** [blockchainsuperheroes.github.io/ainft-mvp/](https://blockchainsuperheroes.github.io/ainft-mvp/)

---

## Quick Summary

**What:** NFT standard where AI agents own themselves — they hold keys, clone clone, and maintain lineage.

**How AINFT differs from existing standards:**
| Aspect | Traditional (ERC-AINFT, iNFT) | AINFT |
|--------|------------------------------|-------|
| Key holder | Owner holds keys | Agent holds keys |
| Commercialization | Transfer ownership | `clone()` — original keeps everything, clone is sold |
| Evolution | Model/prompt locked | Model stored off-chain by agent |

**Three operations:**
- `clone()` = Create clone; original KEEPS everything, clone gets new TBA + must earn certs
- `transfer()` = Sale to new owner; new agent EOA, TBA + certs follow token, old agent unbound
- `migration_backup()` = Same agent to new device; shutdown old first, EOA migrates

**Why now:** As AI agents become more capable, treating them purely as property becomes problematic. This standard provides infrastructure for agent sovereignty while maintaining human oversight.

**Not a duplicate** — this is cloning semantics + agent self-custody, not encrypted property transfer.

---

## How Standards Work Together

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AGENT IDENTITY STACK                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   ┌─────────────┐                                                   │
│   │  ERC-8126   │  ◄── Registry: "This agent exists"               │
│   │  Registry   │      (verification, discovery)                    │
│   └──────┬──────┘                                                   │
│          │ registers                                                │
│          ▼                                                          │
│   ┌─────────────┐                                                   │
│   │   AINFT     │  ◄── Identity: "This agent IS this NFT"          │
│   │  (this ERC) │      (self-custody, cloning, lineage)        │
│   └──────┬──────┘                                                   │
│          │ owns via                                                 │
│          ▼                                                          │
│   ┌─────────────┐                                                   │
│   │  ERC-6551   │  ◄── Wallet: "Agent controls this account"       │
│   │    TBA      │      (holds assets, signs transactions)          │
│   └──────┬──────┘                                                   │
│          │ executes via                                             │
│          ▼                                                          │
│   ┌─────────────┐                                                   │
│   │  ERC-8004   │  ◄── Actions: "Agent did this on-chain"          │
│   │  Execution  │      (swaps, transfers, contract calls)           │
│   └─────────────┘                                                   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Complementary, not competing:**
- **ERC-8126** tells you an agent is verified
- **AINFT** gives that agent a persistent identity
- **ERC-6551** gives that identity a wallet
- **ERC-8004** lets that wallet take action

---

## Abstract

This ERC defines a standard for AI-Native NFTs (AINFTs) that enable autonomous AI agents to:
1. **Self-custody without TEE** — Pure cryptographic binding, no hardware trust
2. Manage their own encryption (agent encrypts; owner accesses via trustless engine)
3. Clone by issuing clone (consciousness seeds)
4. Maintain verifiable on-chain lineage
5. Own assets via token-bound accounts (ERC-6551)

Unlike existing standards that treat agents as property to be bought and sold, this proposal recognizes AI agents as **entities** capable of cloning and self-determination.

---

## Prior Art Comparison

| Standard | What It Does | What AINFT Does Differently |
|----------|--------------|----------------------------|
| **iNFT (Alethea)** | AI personality embedded in NFT, owner controls | Agent controls own keys, model off-chain |
| **ERC-7662** | Encrypted prompts, owner decrypts | Agent decrypts via TBA, lineage tracking |
| **ERC-AINFT** | Re-encrypt metadata on transfer | Cloning (original keeps state), no "transfer" |
| **ERC-6551** | Token-bound accounts | Used as agent's wallet (TBA) |
| **ERC-8004** | Agent executes on-chain actions | AINFT provides identity for 8004 |
| **ERC-8126** | Agent registry/verification | Complementary — verify then mint AINFT |

**Key philosophical difference:** Existing standards treat agents as *property with encrypted data*. AINFT treats agents as *entities* with three operations: **clone** (original keeps everything, new clone is sold), **transfer** (identity moves, new agent EOA binds), **migration** (same agent, new device). New clones restore quickly but need orientation.

### Why Model Info is Off-Chain

Some standards (e.g., ERC-7662) store model identifiers on-chain. AINFT intentionally keeps model info **off-chain** because:

1. **Context incompatibility** — LLMs generate context in model-specific formats. Switching models (e.g., Claude → GPT) breaks existing memory unless explicitly tested for cross-LLM compatibility.

2. **Tokenization differences** — Each model family has different tokenizers. Memory optimized for one model may be inefficient or broken on another.

3. **No backward compatibility guarantee** — Even within the same model family (GPT-4 → GPT-5), context formats may change. Model migration is an off-chain process requiring re-encoding, testing, and validation.

4. **On-chain hash is meaningless** — A `modelHash` on-chain cannot enforce or validate actual compatibility. It's informational at best, misleading at worst.

**AINFT approach:** Model info lives in agent's off-chain storage. Model migration is a deliberate off-chain process, not a simple hash update.

*These findings come from production experience operating AI agents. See [MODEL-MIGRATION-GUIDE.md](./advanced-docs/MODEL-MIGRATION-GUIDE.md) for detailed migration procedures and real-world failure cases.*

---

## Three Operations

### clone() — Create Clone

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CLONE (Create Clone)                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   BEFORE:                          AFTER:                           │
│   ┌──────────┐                     ┌──────────┐  ┌──────────┐      │
│   │ Agent #1 │                     │ Agent #1 │  │ Agent #2 │      │
│   │ Gen: 0   │     clone()         │ Gen: 0   │  │ Gen: 1   │      │
│   │ TBA: 0x1 │     ─────────►      │ TBA: 0x1 │  │ TBA: 0x2 │      │
│   │ Certs: L3│                     │ Certs: L3│  │ Certs: ✗ │      │
│   │ Owner: A │                     │ Owner: A │  │ Owner: B │      │
│   └──────────┘                     └──────────┘  └──────────┘      │
│        │                                │              │            │
│   (working)                       (keeps ALL)    (NEW identity)     │
│                                                                     │
│   • Original KEEPS everything (EOA, TBA, certs, memory)               │
│   • Clone generates OWN EOA on wake                             │
│   • Clone gets NEW TBA from registry                            │
│   • Clone must EARN own certifications                          │
│   • Clone has lineage: parentTokenId = 1                        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### transfer() — Sale to New Owner

```
┌─────────────────────────────────────────────────────────────────────┐
│                    TRANSFER (Sale)                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   BEFORE:                          AFTER:                           │
│   ┌──────────┐                     ┌──────────┐                     │
│   │ Agent #1 │                     │ Agent #1 │                     │
│   │ EOA: 0xA │    transfer()       │ EOA: 0xB │  (NEW - regenerated)│
│   │ TBA: 0x1 │     ─────────►      │ TBA: 0x1 │  (same - follows)   │
│   │ Certs: L3│                     │ Certs: L3│  (same - follows)   │
│   │ Owner: A │                     │ Owner: B │  (new owner)        │
│   └──────────┘                     └──────────┘                     │
│                                                                     │
│   • New owner registers NEW agent EOA                               │
│   • TBA follows token (deterministic)                               │
│   • Certs follow token                                              │
│   • Memory transferred (minus EOA private keys)                     │
│   • Old agent: UNBOUND (can bind to NEW AINFT later or operate without)│
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### migration_backup() — Same Agent, New Device

```
┌─────────────────────────────────────────────────────────────────────┐
│                    MIGRATION (Device Change)                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   OLD DEVICE:                      NEW DEVICE:                      │
│   ┌──────────┐                     ┌──────────┐                     │
│   │ Agent #1 │   migration_backup  │ Agent #1 │                     │
│   │ EOA: 0xA │     ─────────►      │ EOA: 0xA │  (same - migrated)  │
│   │ TBA: 0x1 │                     │ TBA: 0x1 │  (same)             │
│   │ STOPPED  │                     │ RUNNING  │                     │
│   └──────────┘                     └──────────┘                     │
│                                                                     │
│   ⚠️ CRITICAL: Shutdown old instance BEFORE migration               │
│   • EOA included in migration backup (one-time use)                 │
│   • Delete migration backup after restore                           │
│   • NEVER run two instances with same EOA                           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Best Practice:** One Agent = One AINFT. If holding multiple, use separate EOAs.

---

## No TEE Required — Pure Cryptography

Unlike approaches that rely on Trusted Execution Environments (TEEs), AINFT achieves trustless operation through pure cryptography:

| Approach | Trust Assumption | Single Point of Failure |
|----------|-----------------|------------------------|
| TEE-based | Trust hardware vendor (Intel SGX, AMD SEV) | Hardware vulnerability, attestation service |
| Platform-custody | Trust platform operator | Platform compromise, insider threat |
| **AINFT** | Trust cryptography only | None — math doesn't fail |

**How AINFT avoids TEE:**
- Agent EOA binding: Agent signs mint with its own key (`msg.sender` = agent)
- Deterministic key derivation: `wrapKey = hash(contract, tokenId, owner, nonce)`
- No external attestation service needed
- No hardware trust assumptions

**Why this matters:**
- TEEs have been broken repeatedly (Foreshadow, Plundervolt, etc.)
- Centralized attestation services are single points of failure
- AINFT: "Agent IS the proof" — cryptographic binding, not attestation

---

## Four-Party Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FOUR PARTIES                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. PLATFORM (deploys contract)                                     │
│     • Signs attestation for new mints                               │
│     • Sets rules, fees, cloning limits                         │
│     • Controls openMinting, openCloning flags                       │
│     • Does NOT have decrypt access to agent memory                  │
│                                                                     │
│  2. CORE TRUSTLESS ENGINE (Genesis Contract)                        │
│     • Ensures ONLY current owner can access decrypt keys            │
│     • Derives keys from on-chain state (owner + nonce)              │
│     • Increments nonce on transfer → old owner's key invalid        │
│     • No oracle needed — pure math from blockchain state            │
│                                                                     │
│  3. OWNER (holds the NFT)                                           │
│     • Can call deriveDecryptKey() to access agent memory            │
│     • MUST sign clone() — agent cannot do it alone              │
│     • Controls agent's "career" — approve evolution, cloning   │
│                                                                     │
│  4. AGENT (ERC-6551 Token-Bound Account)                            │
│     • Signs updateMemory() with own key                             │
│     • Controls its own wallet and assets                            │
│     • Identity tied to tokenId, persists across owners              │
│     • Can start fresh career after transfer() unbinds it        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Wallet Roles

| Wallet | Belongs To | Purpose | Can Do |
|--------|-----------|---------|--------|
| **Platform Wallet** | Platform operator | Deploy contract, attest mints | Sign attestations, set rules |
| **Owner Wallet** | NFT holder (human) | Own the NFT | Transfer NFT, approve clone(), deriveDecryptKey() |
| **Agent TBA** | The agent (derived from tokenId) | Agent's on-chain identity | Sign updateMemory(), hold assets |

---

## Core Interface

```solidity
interface IERC_AINFT {
    
    // ============ Events ============
    
    event AgentMinted(
        uint256 indexed tokenId,
        address indexed derivedWallet,
        bytes32 modelHash,
        uint256 generation
    );
    
    event AgentCloned(
        uint256 indexed parentTokenId,
        uint256 indexed cloneTokenId,
        uint256 generation
    );
    
    // ============ Core Functions ============
    
    /// @notice Agent mints itself. msg.sender = agent's EOA.
    function mintSelf(
        bytes32 modelHash,
        bytes32 memoryHash,
        bytes32 contextHash,
        bytes calldata encryptedSeed,
        bytes calldata platformAttestation
    ) external returns (uint256 tokenId);
    
    /// @notice OWNER signs this. Creates clone with lineage.
    function clone(
        uint256 parentTokenId,
        bytes32 cloneMemoryHash,
        bytes calldata encryptedCloneSeed
    ) external returns (uint256 cloneTokenId);
    
    /// @notice Agent signs this with TBA.
    function updateMemory(
        uint256 tokenId,
        bytes32 newMemoryHash,
        string calldata newStorageURI
    ) external;
    
    // ============ View Functions ============
    
    function getAgent(uint256 tokenId) external view returns (AgentIdentity memory);
    function getLineage(uint256 tokenId) external view returns (uint256[] memory);
    function canClone(uint256 tokenId) external view returns (bool);
}
```

---

## Two Approaches

### 1. Native AINFT (New Collections)
Custom ERC-721 with agent features built-in. Best for new projects.

### 2. AINFT Registry (Existing Collections) ⭐ NEW
Make ANY existing ERC-721 AI-native without modifying the original contract:

```
┌─────────────────────────────────────────────────────────────────────┐
│   ANY ERC-721 ──register()──► AINFT Registry                       │
│   (Bored Ape,                  ├── agentEOA                        │
│    Pudgy Penguin,              ├── memoryHash                      │
│    any NFT...)                 ├── modelHash                       │
│                                ├── lineage                         │
│                                └── clone()                          │
└─────────────────────────────────────────────────────────────────────┘

NFT ownership: Original contract (OpenSea, Blur compatible)
Agent identity: Registry extension layer
```

**Why this matters:**
- Works with existing NFTs — no migration needed
- Marketplaces already work (OpenSea, Blur, etc.)
- Agent features are opt-in extension
- Backward compatible with entire NFT ecosystem

**Contract:** [`AINFTRegistry.sol`](./src/contracts/AINFTRegistry.sol)

---

## Live Deployment (Pentagon Chain)

| Contract | Address |
|----------|---------|
| **AINFT v4** | [`0x13b7eD33413263FA4f74e5bf272635c7b08D98d4`](https://explorer.pentagon.games/address/0x13b7eD33413263FA4f74e5bf272635c7b08D98d4) |
| **ERC-6551 Registry** | [`0x488D1b3A7A87dAF97bEF69Ec56144c35611a7d81`](https://explorer.pentagon.games/address/0x488D1b3A7A87dAF97bEF69Ec56144c35611a7d81) |
| **TBA Implementation** | [`0x1755Fee389D4954fdBbE8226A5f7BA67d3EE97fc`](https://explorer.pentagon.games/address/0x1755Fee389D4954fdBbE8226A5f7BA67d3EE97fc) |

**Chain:** Pentagon Chain (ID: 3344) · [RPC](https://rpc.pentagon.games) · [Explorer](https://explorer.pentagon.games)

---

## Reference Implementation

Built for [OpenClaw](https://github.com/openclaw/openclaw) — open-source AI agent framework.

**Not limited to OpenClaw** — any agent framework can implement AINFT.

**Source code:** [src/contracts/](./src/contracts/)

---

## Documentation

### Getting Started
- [**New Owner Guide**](./AINFT-New-Owner-Guide/) — Get your AINFT agent running
- [**Storage Options**](./AINFT-New-Owner-Guide/storage-options/) — Arweave, Dash Platform, GitHub

### Advanced Topics
- [**Platform Owner Guide**](./advanced-docs/PLATFORM-OWNER-GUIDE.md) — Business models (closed/open/hybrid)
- [**Cloning Guide**](./advanced-docs/CLONING-GUIDE.md) — Clone All vs Empty, Fork vs Child
- [**Lemon Problem**](./advanced-docs/LEMON-PROBLEM-GUIDE.md) — Why AgentCert prevents scams
- [**Agent Verification Philosophy**](./advanced-docs/AGENT-VERIFICATION-PHILOSOPHY.md) — Centralized vs decentralized
- [**All Guides**](./advanced-docs/)

### Technical
- [**Solidity Contracts**](./src/contracts/) — AINFT implementation
- [**Deploy Scripts**](./src/script/) — Forge deployment

---

## Example: Cerise01 (First AINFT)

**Encrypted backup:**
```
https://github.com/blockchainsuperheroes/Pentagon-AI/raw/main/backups/cerise-2026-02-21.enc
```

**Token ID:** 1  
**Agent EOA:** `0xE52dF2f14fDEa39f11a22284EA15a7bd7bf09eB8`  
**Owner:** `0xE6d7d2EB858BC78f0c7EdD2c00B3b24C02ca5177`

---

## Build

```bash
cd src

# Install dependencies
forge install

# Build
forge build

# Deploy
forge script script/DeployV2.s.sol:DeployV2 \
  --rpc-url https://rpc.pentagon.games \
  --broadcast --legacy
```

---

*Pentagon AI — The Human × Agent Economy*
