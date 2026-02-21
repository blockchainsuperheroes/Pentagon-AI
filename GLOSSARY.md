# GLOSSARY.md — Terms & Acronyms

*Quick reference for AINFT and related concepts*

---

## Core AINFT Terms

| Term | Full Name | Description |
|------|-----------|-------------|
| **AINFT** | AI-Native NFT | NFT standard designed for AI agent identity, with reproduction and self-custody |
| **EOA** | Externally Owned Account | A wallet controlled by a private key (not a smart contract). Agents hold their own EOA to prove identity |
| **TBA** | Token-Bound Account | A smart contract wallet bound to an NFT via ERC-6551. The NFT controls the wallet |
| **TBA vs EOA** | — | EOA = agent's own key. TBA = smart contract wallet owned by NFT. AINFT uses EOA for identity binding |

---

## Ethereum / EVM Standards

| Term | Full Name | Description |
|------|-----------|-------------|
| **ERC** | Ethereum Request for Comments | Standard proposals for Ethereum (like ERC-20, ERC-721) |
| **ERC-721** | NFT Standard | The base NFT standard. AINFT extends this |
| **ERC-6551** | Token Bound Accounts | Standard for NFTs to own smart contract wallets |
| **ERC-4337** | Account Abstraction | Standard for smart contract wallets with advanced features (paymasters, bundlers) |
| **EIP** | Ethereum Improvement Proposal | Broader proposals for Ethereum changes (ERCs are a subset) |

---

## Cryptography

| Term | Full Name | Description |
|------|-----------|-------------|
| **ECDSA** | Elliptic Curve Digital Signature Algorithm | The signature scheme used by Ethereum wallets |
| **keccak256** | Keccak-256 Hash | Ethereum's hash function (similar to SHA-3) |
| **ecrecover** | Elliptic Curve Recover | Solidity function to recover signer address from signature |

---

## Security / Verification

| Term | Full Name | Description |
|------|-----------|-------------|
| **TEE** | Trusted Execution Environment | Hardware-isolated secure enclave (e.g., Intel SGX, AMD SEV). Centralized approach uses TEE to verify agents |
| **HSM** | Hardware Security Module | Dedicated hardware for key management. Sometimes used for platform signing |
| **Attestation** | — | Cryptographic proof that something is authentic. Platform signs attestation for agent mints |

---

## Storage

| Term | Full Name | Description |
|------|-----------|-------------|
| **IPFS** | InterPlanetary File System | Decentralized content-addressed storage. Requires pinning to persist |
| **Arweave** | — | Permanent decentralized storage. Pay once, stored forever. Recommended for AINFT |

---

## AINFT-Specific

| Term | Description |
|------|-------------|
| **Generation** | How many reproduction steps from original. Gen 0 = original, Gen 1 = first offspring |
| **Lineage** | The chain of parent tokens back to Gen 0 |
| **Offspring** | Tokens created via reproduce() from a parent |
| **Consciousness Seed** | The identity bundle: modelHash, memoryHash, contextHash, encryptedSeed |
| **Platform Signer** | The address authorized to sign mint attestations |
| **Memory Hash** | keccak256 of agent's MEMORY.md — proves state integrity |
| **Context Hash** | keccak256 of agent's SOUL.md / personality config |
| **Model Hash** | keccak256 of model identifier (e.g., "claude-opus-4.5") |

---

## Pentagon Chain

| Term | Description |
|------|-------------|
| **PC** | Pentagon Chain's native gas token |
| **Chain ID** | 3344 |
| **RPC** | https://rpc.pentagon.games |
| **Deploy RPC** | https://rpc.pentagon.games/rpc/nCoUHmPLXkbkRq09hAam (whitelisted deployers) |

---

## Agent Ecosystem

| Term | Full Name | Description |
|------|-----------|-------------|
| **AgentCert** | Agent Certification | Tiered certification system (L1-L4) proving agent readiness. L3+ = AINFT ready |
| **OpenClaw** | — | Open-source agent runtime framework |
| **ATS** | Agent Test Standard | Testing framework for agent capabilities |

---

## Quick Distinctions

### EOA vs TBA vs Smart Contract Wallet

```
EOA (Externally Owned Account)
├─ Controlled by private key
├─ Agent holds this directly
└─ Used for AINFT identity binding

TBA (Token Bound Account)
├─ Smart contract wallet
├─ Controlled by NFT owner
└─ Created via ERC-6551 registry

Smart Contract Wallet (e.g., Safe, 4337)
├─ Programmable wallet
├─ Multi-sig, spending limits, etc.
└─ Can be combined with TBA
```

### AINFT vs Regular NFT

```
Regular NFT
├─ Static metadata
├─ No identity binding
└─ Just art/collectible

AINFT
├─ Agent EOA bound to token
├─ Memory state hash on-chain
├─ Reproduction capability
├─ Lineage tracking
└─ Agent can sign to prove identity
```

---

## See Also

- [ERC-AINFT Specification](./EIPs/ERC-AINFT.md)
- [Agent Verification Philosophy](./EIPs/AGENT-VERIFICATION-PHILOSOPHY.md)
- [OpenClaw Bind Guide](./EIPs/OPENCLAW-BIND-GUIDE.md)
- [ERC-6551 Registry Guide](./EIPs/ERC6551-REGISTRY-GUIDE.md)

---

*Pentagon AI — The Human × Agent Economy*
