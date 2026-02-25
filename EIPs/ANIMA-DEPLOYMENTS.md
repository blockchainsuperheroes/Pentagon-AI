# ANIMA Deployments

Deployed contracts for ERC-ANIMA (Agentic NFT) on Pentagon Chain.

## Pentagon Chain (3344)

| Contract | Address | Version | Date |
|----------|---------|---------|------|
| **AINFTRegistry** | `0x327165c476da9071933d4e2dbb58efe2f6c9f486` | v1.0.0 | 2026-02-25 |
| **AINFT Genesis** | `0x4e8D3B9Be7Ef241Fb208364ed511E92D6E2A172d` | v1.0.0 | 2026-02-21 |

### Network Info
- **Chain ID:** 3344
- **RPC:** https://rpc.pentagon.games
- **Explorer:** https://explorer.pentagon.games
- **Gas Token:** PC

## Example Binding

**AINFT Genesis Token #1** is bound as a demo:
- **NFT Contract:** `0x4e8D3B9Be7Ef241Fb208364ed511E92D6E2A172d`
- **Token ID:** 1
- **Agent EOA:** `0xE6d7d2EB858BC78f0c7EdD2c00B3b24C02ca5177`
- **Bind TX:** `0x1c4535c0d2e18d90b9ae35ae58521d73695268411c9dfcd66eaba15390644c69`

## Contract Notes

### AINFTRegistry v1.0.0
- Compiled with **Solidity 0.8.19** (Pentagon Chain doesn't support Cancun opcodes like MCOPY)
- Platform signer: `0xE6d7d2EB858BC78f0c7EdD2c00B3b24C02ca5177`
- Source: `Pentagon-AI/EIPs/ERC-6551A/contracts/AINFTRegistry.sol`

### Key Functions
```solidity
// Bind agent to NFT (caller becomes agentEOA)
function bindNew(address nftContract, uint256 tokenId, bytes32 modelHash, bytes32 memoryHash, bytes32 contextHash) external

// Check if NFT has agent
function isRegistered(address nftContract, uint256 tokenId) external view returns (bool)

// Get agent details
function getAgent(address nftContract, uint256 tokenId) external view returns (AgentIdentity memory)

// Unbind agent from NFT
function unbind(address nftContract, uint256 tokenId) external
```

## Previous Deployments (Deprecated)

| Contract | Address | Issue |
|----------|---------|-------|
| AINFTRegistry (old) | `0xd68dab3c4cdbbc4a615c1869b6a44c4fa0764e34` | Solidity 0.8.33 - MCOPY opcode not supported |
| AINFTRegistry (older) | `0x6B81e00508E3C449E20255CdFb85A0541457Ea6d` | Different function signatures |

## Demo Site

**Live:** https://blockchainsuperheroes.github.io/anima-demo/

Features:
- Lookup agent binding
- Bind new agent (wallet becomes agent EOA)
- Unbind agent
- Pre-filled with AINFT Genesis Token #1 example

---

*Last updated: 2026-02-25*
