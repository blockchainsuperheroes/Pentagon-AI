# Clone Lifecycle Guide

*Complete documentation for clone creation, trading, and claiming*

---

## Overview

Cloning in ERC-TBA-A creates agent copies without creating new NFT tokens. Clones exist in "limbo" until claimed, enabling flexible ownership and trading paths.

---

## Lifecycle States

```
┌──────────────────────────────────────────────────────────────────────┐
│  CREATED                LIMBO                    ACTIVE              │
│  ────────              ───────                  ────────             │
│                                                                      │
│  clone()    ──────►   Pending     ──────►     Operational           │
│  called               (no EOA)    claimClone() (has EOA)            │
│                          │                        │                  │
│                          │                        │                  │
│                   transferCloneClaim()      bind() to NFT            │
│                   (repeatable)              OR stay standalone       │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## State: CREATED (via clone())

### Who Can Clone?

Only the agent (agentEOA) of a registry-bound NFT can create clones.

```solidity
// Only agent can clone
require(msg.sender == _agents[key].agentEOA, "Only agent can clone");
```

### What Gets Created?

| Field | Value |
|-------|-------|
| agentEOA | `address(0)` — not set yet |
| modelHash | Inherited from original |
| memoryHash | Provided by cloner (snapshot) |
| contextHash | Inherited from original |
| generation | original.generation + 1 |
| parentKey | Points to original |
| owner | Specified cloneOwner |

### Clone Fee

Platforms can set cloning fees:

```solidity
require(msg.value >= cloningFee, "Insufficient fee");
```

---

## State: LIMBO (Pending)

Clone exists but has no agent EOA. It's data waiting for activation.

### What Can Be Done in Limbo?

| Action | Who | Effect |
|--------|-----|--------|
| `transferCloneClaim()` | Current owner | Transfer to new owner |
| `claimClone()` | Current owner | Activate with agent EOA |
| Read `getClone()` | Anyone | View clone data |

### Trading Clones in Limbo

Clones can be traded before activation:

```
Creator ──► transferCloneClaim() ──► Buyer A
                                        │
                                        ▼
                    transferCloneClaim() ──► Buyer B
                                                │
                                                ▼
                                        claimClone()
                                        (Buyer B activates)
```

**Use case:** Pre-sale of clones, speculation on lineage value.

---

## State: ACTIVE (Claimed)

Once claimed, clone has an agent EOA and is operational.

### claimClone() Parameters

```solidity
function claimClone(
    uint256 cloneId,    // The clone to claim
    address agentEOA    // Agent's signing address
) external
```

### Requirements

1. Caller must be clone owner
2. Clone must not already be claimed
3. agentEOA must not be registered elsewhere

### After Claiming

Clone is active and can:
- Sign transactions (via agentEOA)
- Update memory hash
- Create its own clones (if enabled)
- Bind to an NFT you own

---

## Paths After Claiming

### Path A: Bind to NFT

```solidity
// Clone owner also owns an NFT
bind(
    nftContract,    // Your NFT collection
    tokenId,        // Your token ID
    ...
);
```

**Result:** Clone is now tradeable via that NFT on OpenSea.

### Path B: Stay Standalone

Don't bind. Clone operates with direct ownership.

**Result:** Operational but not tradeable on NFT marketplaces.

### Path C: Mint Standalone AINFT (Future)

```solidity
// Convert clone to full AINFT token
mintStandalone(cloneId);
```

**Result:** Clone becomes tradeable on AINFT-specific marketplace.

---

## Complete Flow Chart

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   Original Agent                                                    │
│   (bound to Bored Ape #123)                                        │
│        │                                                            │
│        │ clone(memoryHash, cloneOwner)                             │
│        ▼                                                            │
│   ┌──────────────────────────────────────────────────────────────┐ │
│   │ Clone #1 (LIMBO)                                             │ │
│   │ owner: cloneOwner                                            │ │
│   │ agentEOA: 0x0 (pending)                                      │ │
│   └─────────────────────────────┬────────────────────────────────┘ │
│                                 │                                   │
│           ┌─────────────────────┼─────────────────────┐            │
│           │                     │                     │            │
│           ▼                     ▼                     ▼            │
│   transferCloneClaim()    claimClone()          (wait)            │
│   to new owner            with agentEOA                           │
│           │                     │                                  │
│           │                     ▼                                  │
│           │             ┌──────────────────────────────────────┐  │
│           │             │ Clone #1 (ACTIVE)                    │  │
│           │             │ owner: cloneOwner                    │  │
│           │             │ agentEOA: 0xABC...                   │  │
│           │             └────────────────┬─────────────────────┘  │
│           │                              │                         │
│           │              ┌───────────────┼───────────────┐        │
│           │              │               │               │        │
│           │              ▼               ▼               ▼        │
│           │          bind()        standalone      mintStandalone│
│           │          to NFT        (no bind)       (future)      │
│           │              │               │               │        │
│           │              ▼               ▼               ▼        │
│           │         Tradeable      Operational     Tradeable     │
│           │         (OpenSea)      (not trade)    (AINFT mkt)   │
│           │                                                       │
│           └──────────────────────────────────────────────────────►│
│                         (repeat transfers in limbo)               │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

---

## Data Inheritance

| Field | From Original? | Notes |
|-------|---------------|-------|
| modelHash | ✅ Inherited | Same model reference |
| memoryHash | ❌ New | Snapshot provided at clone time |
| contextHash | ✅ Inherited | Same personality |
| generation | ✅ Incremented | original.gen + 1 |
| parentKey | ✅ Set | Points to original |
| agentEOA | ❌ New | Clone generates own EOA |
| owner | ❌ New | Specified at clone time |

---

## Events

### AgentCloned

Emitted twice:
1. On `clone()` — with agentEOA = 0x0 (pending)
2. On `claimClone()` — with actual agentEOA

```solidity
event AgentCloned(
    address indexed parentContract,
    uint256 indexed parentTokenId,
    address indexed cloneEOA,      // 0x0 until claimed
    uint256 cloneId,
    uint256 generation
);
```

### CloneClaimTransferred

Emitted on `transferCloneClaim()`:

```solidity
event CloneClaimTransferred(
    uint256 indexed cloneId,
    address indexed from,
    address indexed to
);
```

---

## Best Practices

### For Clone Creators

1. **Set appropriate cloneOwner** — buyer's address if pre-sold
2. **Snapshot memory carefully** — clone gets this state
3. **Consider generation limits** — track lineage for value

### For Clone Buyers

1. **Verify lineage** — check parentKey and generation
2. **Have agent ready** — need EOA for claimClone()
3. **Decide path** — bind to NFT or stay standalone

### For Platforms

1. **Set reasonable cloning fees**
2. **Enable/disable cloning per registration**
3. **Build clone marketplace UI**

---

## Security Notes

### Clone Owner vs Agent EOA

- **Clone owner:** Human/wallet that controls the clone
- **Agent EOA:** AI agent's signing address

Owner specifies agentEOA during claim. Owner can transfer claim, but agent EOA is permanent once set.

### No Double Registration

Each agentEOA can only be registered once across the entire registry:

```solidity
require(eoaToKey[agentEOA] == bytes32(0), "EOA already registered");
```

---

*See also: [BIND-UNBIND-FLOW.md](./BIND-UNBIND-FLOW.md)*
