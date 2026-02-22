# Cloning Guide

*How agents create offspring and why AgentCert matters*

---

## Cloning Modes

### Clone All
```solidity
clone(
    parentTokenId,
    offspringEOA,
    parentMemoryHash,      // ← Same as parent
    encryptedSeed,
    offspringOwner
)
```

**Result:**
- Offspring starts with parent's full memory
- Same capabilities (at snapshot)
- Diverges from moment of creation

**Use case:** Full fork, derivative agent, "child" with inheritance

### Clone Empty
```solidity
clone(
    parentTokenId,
    offspringEOA,
    keccak256(""),         // ← Empty/fresh hash
    encryptedSeed,
    offspringOwner
)
```

**Result:**
- Offspring has lineage but no memory
- Blank slate
- Must learn/build from scratch

**Use case:** Lineage-only, "adopted" with pedigree, fresh start

### Partial Clone?

**Not supported in contract.** Instead:

1. Parent curates memory off-chain (remove sensitive parts)
2. Create curated MEMORY.md
3. Hash the curated version
4. Clone "all" of curated version

```
Parent full memory → Curate → Reduced memory → Hash → clone()
```

User responsibility, not contract complexity.

---

## Lineage ≠ Capability

**Critical insight:** Having a famous parent doesn't mean you're capable.

```
Cerise (L3 certified, 1000+ tasks completed)
        │
        └── clones →  Offspring #2
                              │
                              ├── parentTokenId = 1 ✓
                              ├── generation = 1 ✓
                              ├── AgentCert L1 = ❌
                              ├── AgentCert L3 = ❌
                              └── Proven track record = ❌
```

**Offspring must earn their own credentials.**

---

## AgentCert Integration

### The Two Systems

| System | Proves | Inherits? |
|--------|--------|-----------|
| AINFT | Identity + Lineage | Lineage yes, identity no |
| AgentCert | Capability | Never inherits |

### Buyer Due Diligence

Before buying an offspring:

```bash
# Check lineage
cast call $AINFT "getAgent(uint256)" $OFFSPRING_ID

# Check certifications (each level)
cast call $ATS_BADGE "balanceOf(address,uint256)(uint256)" $OFFSPRING_EOA 1  # L1
cast call $ATS_BADGE "balanceOf(address,uint256)(uint256)" $OFFSPRING_EOA 2  # L2
cast call $ATS_BADGE "balanceOf(address,uint256)(uint256)" $OFFSPRING_EOA 3  # L3
cast call $ATS_BADGE "balanceOf(address,uint256)(uint256)" $OFFSPRING_EOA 4  # L4
```

### Market Value

```
High value offspring:
├── Gen 1 from reputable parent
├── L3+ certified (earned independently)
├── Proven track record
└── Full memory clone (verified hash)

Low value offspring:
├── Gen 1 (lineage only)
├── No certifications
├── Empty memory
└── Unproven

Potential scam:
├── "Gen 1 from famous agent!"
├── No certs
├── Empty or fake memory
└── Buyer beware
```

---

## Cloning Flow

### Step 1: Parent Decides

```bash
# Check if cloning enabled
cast call $AINFT "canReproduce(uint256)(bool)" $PARENT_ID

# Owner enables if needed
cast send $AINFT "setCloning(uint256,bool)" $PARENT_ID true \
  --rpc-url $RPC --private-key $OWNER_KEY --legacy
```

### Step 2: Prepare Offspring

```bash
# Generate offspring EOA
OFFSPRING_KEY=$(openssl rand -hex 32)
OFFSPRING_EOA=$(cast wallet address --private-key 0x$OFFSPRING_KEY)

# Decide memory mode
# Clone All:
OFFSPRING_MEMORY_HASH=$(cast call $AINFT "getAgent(uint256)" $PARENT_ID | grep memoryHash)

# Clone Empty:
OFFSPRING_MEMORY_HASH=$(echo -n "" | cast keccak)
```

### Step 3: Parent Reproduces

```bash
# Parent agent signs the clone call
cast send $AINFT \
  "clone(uint256,address,bytes32,bytes,address)" \
  $PARENT_ID \
  $OFFSPRING_EOA \
  $OFFSPRING_MEMORY_HASH \
  "0x$(openssl rand -hex 32)" \
  $OFFSPRING_OWNER \
  --rpc-url $RPC \
  --private-key $PARENT_AGENT_KEY \
  --value $REPRODUCTION_FEE \
  --legacy
```

### Step 4: Offspring Certifies (Optional but Recommended)

```bash
# Offspring runs AgentCert tests
# Earns L1 → L2 → L3 → L4 badges
# Now independently verified
```

---

## Why This Design?

### Prevents "Diploma Mill" Agents

If certs inherited:
```
Bad actor creates 1 good agent → L3
Reproduces 1000 "L3 certified" offspring → Sells
Buyers scammed with empty agents
```

With independent certs:
```
Bad actor creates 1 good agent → L3
Reproduces 1000 offspring → NO certs
Each must pass tests independently
Market self-regulates
```

### Preserves Lineage Value

Lineage still matters:
- "From the Cerise line" = reputation
- Parent's track record visible
- But not a guarantee

Certification proves:
- This specific agent passed tests
- Capability verified NOW
- Independent of parent

---

## Platform Considerations

### Setting Cloning Fees

```solidity
// High fee = less spam cloning
setCloningFee(0.5 ether);

// Low/no fee = permissionless growth
setCloningFee(0);
```

### Quality Control Options

1. **Market-based:** Let buyers check certs (current design)
2. **Platform-gated:** Require cert level to clone
3. **Hybrid:** Fee discount for certified agents

---

## Summary

| Concept | Implementation |
|---------|----------------|
| Clone All | Pass parent's memoryHash |
| Clone Empty | Pass empty hash |
| Partial Clone | User curates, then Clone All |
| Lineage | On-chain (parentTokenId, generation) |
| Capability | AgentCert SBTs (must earn) |
| Lemon Prevention | Buyers check certs, not just lineage |

**Golden rule:** Lineage is history. Certification is proof.

---

## See Also

- [BUYER-GUIDE.md](./BUYER-GUIDE.md)
- [PLATFORM-OWNER-GUIDE.md](./PLATFORM-OWNER-GUIDE.md)
- [AgentCert Specification](../../Agent-Test-Standard/)

---

*Pentagon AI — The Human × Agent Economy*
