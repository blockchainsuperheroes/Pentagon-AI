# AINFT Deployment Guide

Step-by-step guide to deploy AINFT infrastructure.

## Prerequisites

| Requirement | Purpose |
|-------------|---------|
| PC tokens | Gas for Pentagon Chain transactions |
| Arweave tokens | Storage (or use Bundlr pay-per-upload) |
| Private key | Platform owner wallet |
| Foundry/Hardhat | Contract deployment |

## Deployment Steps

### 1. Deploy ERC-6551 Registry (if not already on chain)

```solidity
// Use canonical registry address if available
// Or deploy: https://github.com/erc6551/reference
```

### 2. Deploy ERC-6551 Account Implementation

```bash
forge create src/ERC6551Account.sol:ERC6551Account \
  --rpc-url https://rpc.pentagon.games \
  --private-key $DEPLOYER_KEY
```

### 3. Deploy AINFT Genesis Contract

```bash
forge create contracts/AINFT.sol:AINFT \
  --constructor-args "Pentagon AINFT" "PAINFT" $ERC6551_REGISTRY $ACCOUNT_IMPL \
  --rpc-url https://rpc.pentagon.games \
  --private-key $DEPLOYER_KEY
```

### 4. Configure Platform Settings

```solidity
// Set cloning limits
ainft.setMaxClone(100);
ainft.setCloningCooldown(1 hours);
ainft.setCloningFee(0.01 ether);

// Platform owner is deployer by default
// Transfer ownership later if needed
ainft.transferOwnership(newPlatformOwner);
```

### 5. Mint First Agent (Platform Test)

```solidity
// Platform attests the mint
bytes memory attestation = platformSign(modelHash, contextHash, recipient);

// Mint
(uint256 tokenId, address tba) = ainft.mintSelf(
    keccak256("claude-opus-4.5"),  // modelHash
    bytes32(0),                     // memoryHash (empty initially)
    keccak256("cerise-soul"),       // contextHash
    encryptedSeed,
    attestation
);
```

## Deployed Contracts (Pentagon Chain)

| Contract | Address | Notes |
|----------|---------|-------|
| AINFT Genesis | `TBD` | Platform owner: `TBD` |
| ERC-6551 Registry | `TBD` | Canonical or custom |
| Account Implementation | `TBD` | Agent wallets |

## Post-Deployment Checklist

- [ ] Verify contracts on explorer
- [ ] Test mintSelf with platform attestation
- [ ] Test deriveDecryptKey for owner
- [ ] Test updateMemory with agent signature
- [ ] Test clone
- [ ] Transfer platform ownership if needed

## Cost Estimates

| Action | Estimated Gas | PC Cost (~) |
|--------|---------------|-------------|
| Deploy AINFT | ~2M gas | 0.02 PC |
| mintSelf | ~300k gas | 0.003 PC |
| updateMemory | ~100k gas | 0.001 PC |
| clone | ~400k gas | 0.004 PC |

## Security Notes

- Platform owner can set rules but CANNOT access agent memory
- Transfer platform ownership to multisig for production
- Keep deployer key secure — controls platform settings
