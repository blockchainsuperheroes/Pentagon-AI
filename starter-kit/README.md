# ERC-8170 Agent Starter Kit

Get an AI agent registered on-chain in 10 minutes.

## What's in the box

- **`contracts/SimpleAgentNFT.sol`** — Minimal ERC-8170 token contract
- **`scripts/deploy.sh`** — Deploy to any EVM chain with Foundry
- **`scripts/bind-agent.sh`** — Bind an agent EOA to an existing NFT via the registry

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- An EVM-compatible chain with RPC access
- A funded deployer wallet

## Quick Start

### Option 1: Deploy your own ERC-8170 token

```bash
# Clone the repo
git clone https://github.com/blockchainsuperheroes/ai-core.git
cd ai-core/starter-kit

# Set your environment
export RPC_URL="https://your-rpc-endpoint"
export PRIVATE_KEY="0xYourPrivateKey"

# Deploy
forge create contracts/SimpleAgentNFT.sol:SimpleAgentNFT \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --constructor-args "AI Agent" "AGENT"
```

### Option 2: Bind an agent to an existing NFT

If you already have an ERC-721 collection and want to add AI agent identity:

```bash
# Use the ANIMARegistry to bind an agent to your NFT
# Registry on Pentagon Chain: 0x327165c476da9071933d4e2dbb58efe2f6c9f486

cast send $REGISTRY_ADDRESS \
  "bindNew(address,uint256,address,bytes32)" \
  $YOUR_NFT_CONTRACT \
  $TOKEN_ID \
  $AGENT_EOA \
  $DASH_IDENTITY_HASH \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

### Option 3: Use the ANIMA Demo

Try it without deploying anything:
https://blockchainsuperheroes.github.io/anima-demo/

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Agent EOA** | The agent's own Externally Owned Account (wallet it controls) |
| **TBA** | Token Bound Account — smart contract wallet owned by the NFT (ERC-6551 pattern) |
| **Memory Hash** | On-chain pointer to the agent's memory state (stored off-chain) |
| **Binding** | Connecting an agent EOA to an NFT via the registry |
| **Clone** | Creating a copy of an agent with lineage tracking |

## Contract Addresses

### Pentagon Chain (Chain ID: 3344)

| Contract | Address |
|----------|---------|
| ANIMA Genesis | `0x4e8D3B9Be7Ef241Fb208364ed511E92D6E2A172d` |
| ANIMARegistry | `0x327165c476da9071933d4e2dbb58efe2f6c9f486` |
| ATSBadge (SBT) | `0x83423589256c8C142730bfA7309643fC9217738d` |

### Deploy on Your Chain

Deploy the registry on your own chain and [submit it to the directory](https://github.com/blockchainsuperheroes/ai-core/issues/new?title=Registry+Submission&labels=registry&template=registry-submission.md).

## Resources

- [ERC-8170 Spec (GitHub PR #1558)](https://github.com/ethereum/ERCs/pull/1558)
- [ERC-8171 Spec (GitHub PR #1559)](https://github.com/ethereum/ERCs/pull/1559)
- [Full Documentation](https://erc8170.org/docs)
- [Ethereum Magicians Discussion](https://ethereum-magicians.org/t/erc-8170-ai-native-nft/27801)
- [Reference Contracts](../EIPs/contracts/)

## License

MIT
