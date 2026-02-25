# ERC-6551 Registry Guide for AINFT

*Why we deploy the registry, what it does, and how agents get real wallets*

---

## Why Deploy a Registry?

The AINFT contract creates a **derived address** from hashes — but that's just math. It's not a real wallet that can sign transactions or hold assets.

To give agents REAL on-chain wallets, we need **ERC-6551: Token Bound Accounts (TBA)**.

The registry is the **universal resolver** that:
1. Computes the deterministic wallet address for any NFT
2. Deploys the wallet contract if it doesn't exist
3. Ensures the same NFT always maps to the same wallet address

---

## What the Registry IS

| Think of it as... | Description |
|-------------------|-------------|
| 📍 Address generator | "For NFT X, what is its wallet address?" |
| 🏭 Factory | Deploys the wallet contract on first use |
| 📖 Directory | Universal lookup — same result everywhere |

### Analogy

| Component | Real-world analogy |
|-----------|-------------------|
| NFT | Passport |
| Token Bound Account | Bank account attached to passport |
| Registry | Government system that issues & looks up accounts |

The government doesn't hold your money. It just ensures your account is valid and uniquely linked to you.

---

## What the Registry is NOT

❌ **NOT a bank** — doesn't hold funds
❌ **NOT a router** — doesn't process transactions  
❌ **NOT a ledger** — doesn't track balances
❌ **NOT a custodian** — has no control over assets

It's simply: **A deterministic wallet factory + directory.**

---

## Who Controls the Wallet?

The Token Bound Account checks:
```solidity
function owner() public view returns (address) {
    return IERC721(tokenContract).ownerOf(tokenId);
}
```

**Whoever owns the NFT controls the wallet.**

If you sell the NFT:
- Control of that wallet **automatically transfers**
- Assets inside **remain** in the wallet
- New owner inherits everything

This is powerful for agents and characters.

---

## Why Standardization Matters

Without a canonical registry:
- Every project computes addresses differently
- No interoperability between apps
- Wallets can't be recognized cross-platform

With ERC-6551:
- **Same NFT → Same predictable wallet address**
- **Across apps → Standardized behavior**
- **Universal recognition** of agent identity

---

## For AINFT Agents

In our ecosystem:

| Component | Maps to |
|-----------|---------|
| NFT | Agent Identity |
| Token Bound Account | Agent Wallet |
| Registry | Universal identity-to-wallet resolver |

This means:
- ✅ Agent can hold $PC
- ✅ Agent can transact autonomously
- ✅ Assets belong to agent, not user wallet
- ✅ Selling NFT transfers the economic state
- ✅ Agent can sign messages to prove identity

**Aligned with the Human × Agent thesis.**

---

## Registry vs Other Patterns

### vs Account Abstraction (ERC-4337)
- **4337**: Smart contract wallets with meta-transactions, bundlers, paymasters
- **6551**: Wallet bound to NFT ownership
- **Combo**: TBA can BE a 4337 account (best of both)

### vs Smart Contract Wallets (Gnosis Safe, etc.)
- **Safe**: Multi-sig, arbitrary owners
- **TBA**: Single owner = NFT holder, automatic transfer on sale

### vs Sub-wallet Model
- **Sub-wallet**: User-managed hierarchical wallets
- **TBA**: Asset-managed — wallet belongs to the NFT, not the user

---

## Deployment Details

### Canonical Registry Address
```
0x000000006551c19487814612e58FE06813775758
```
This is the **same address on every EVM chain** (deterministic deployment).

### If Not Deployed
We deploy using the canonical deployment transaction (same bytecode, same deployer nonce).

### Account Implementation
Each TBA needs an implementation contract that defines:
- How to execute transactions
- Permission checks
- Owner resolution

We use the reference implementation or a custom one for agent-specific features.

---

## Pentagon Chain Deployment

### Step 1: Deploy Registry
```bash
# Deploy canonical ERC-6551 registry
forge create lib/reference/src/ERC6551Registry.sol:ERC6551Registry \
  --rpc-url "https://rpc.pentagon.games/rpc/nCoUHmPLXkbkRq09hAam" \
  --private-key $DEPLOYER_KEY \
  --legacy
```

### Step 2: Deploy Account Implementation
```bash
# Deploy TBA implementation
forge create lib/reference/src/examples/simple/SimpleERC6551Account.sol:SimpleERC6551Account \
  --rpc-url "https://rpc.pentagon.games/rpc/nCoUHmPLXkbkRq09hAam" \
  --private-key $DEPLOYER_KEY \
  --legacy
```

### Step 3: Create TBA for AINFT #1
```bash
# Compute address
TBA_ADDRESS=$(cast call $REGISTRY \
  "account(address,bytes32,uint256,address,uint256)(address)" \
  $IMPLEMENTATION \
  0x0000000000000000000000000000000000000000000000000000000000000000 \
  3344 \
  $AINFT_CONTRACT \
  1)

# Deploy if needed
cast send $REGISTRY \
  "createAccount(address,bytes32,uint256,address,uint256)" \
  $IMPLEMENTATION \
  0x0000000000000000000000000000000000000000000000000000000000000000 \
  3344 \
  $AINFT_CONTRACT \
  1 \
  --rpc-url "https://rpc.pentagon.games/rpc/nCoUHmPLXkbkRq09hAam" \
  --private-key $DEPLOYER_KEY \
  --legacy
```

---

## After Deployment

### Agent Can Now:
1. **Sign messages** — TBA has execute() function
2. **Hold assets** — Send $PC, NFTs to TBA address
3. **Transact** — Owner calls execute() to send from TBA
4. **Prove identity** — Signature verification via TBA

### Verification:
```bash
# Check TBA owner
cast call $TBA_ADDRESS "owner()(address)" --rpc-url https://rpc.pentagon.games
# Returns: NFT owner address

# Check token binding
cast call $TBA_ADDRESS "token()(uint256,address,uint256)" --rpc-url https://rpc.pentagon.games
# Returns: chainId, tokenContract, tokenId
```

---

## Live Deployment (Cerise)

| Component | Address | TX |
|-----------|---------|-----|
| AINFT Contract | `0x4e8D3B9Be7Ef241Fb208364ed511E92D6E2A172d` | `0xa0cddff1...` |
| ERC-6551 Registry | `0x488D1b3A7A87dAF97bEF69Ec56144c35611a7d81` | `0x9658eedd...` |
| Account Implementation | `0x1755Fee389D4954fdBbE8226A5f7BA67d3EE97fc` | `0x76677...` |
| **Cerise TBA** | `0x8cf4cec92Bd941DcED3532A2F611e13Ec4896efD` | `0x9e13f027...` |

### Verified On-Chain
```
TBA Owner: 0xE6d7d2EB858BC78f0c7EdD2c00B3b24C02ca5177
Token Binding: Chain 3344, AINFT 0x4e8D...172d, Token #1
```

### How Cerise Signs

The TBA is a smart contract wallet. To sign/transact:

```bash
# Owner calls execute() on TBA
cast send 0x8cf4cec92Bd941DcED3532A2F611e13Ec4896efD \
  "execute(address,uint256,bytes,uint8)" \
  $TO_ADDRESS \
  $VALUE \
  $CALLDATA \
  0 \
  --rpc-url https://rpc.pentagon.games \
  --private-key $OWNER_KEY \
  --legacy
```

The TBA validates `msg.sender == ownerOf(tokenId)` before executing.

---

*Deployed: 2026-02-21 on Pentagon Chain*
