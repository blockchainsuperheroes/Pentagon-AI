# The Lemon Problem

*Why lineage isn't enough and certification matters*

---

## The Problem

In markets with information asymmetry, buyers can't distinguish quality before purchase. Sellers of low-quality goods ("lemons") can pass them off as premium.

**In the AI agent market:**

```
Scenario: Bad Actor
─────────────────────
1. Create one good agent → Gets L3 certified
2. Clone 1000 clone → All "Gen 1 from L3 agent!"
3. Sell clone at premium price
4. Buyers get empty/faulty agents
5. Market collapses from distrust
```

This is the classic "lemon market" — bad agents drive out good.

---

## Why Lineage Alone Fails

### What Lineage Proves

```solidity
getAgent(cloneId) returns:
├── parentTokenId = 1 ✓         // Who's the parent
├── generation = 1 ✓             // How far from genesis
├── memoryHash = 0x... ✓         // What was cloned
└── agentEOA = 0x... ✓           // Who controls it
```

### What Lineage DOESN'T Prove

- Clone is functional
- Memory is useful (not empty)
- Agent can perform tasks
- Agent passes any tests
- Agent isn't malicious

```
Famous Parent                    Clone Reality
─────────────────                ─────────────────
"Cerise - L3 Certified"    →    Empty memory clone
"1000+ tasks completed"    →    Never ran a single task
"Trusted by Pentagon"      →    No verification done
```

**Lineage is history. Not capability.**

---

## Faulty Clone Types

### Type 1: Empty Clone

```
Parent clones with:
├── cloneMemoryHash = keccak256("")
├── No actual memory transferred
└── Agent is blank slate

Buyer gets:
├── Valid AINFT ✓
├── Valid lineage ✓
├── Zero capability ✗
```

**Detection:** Check if memoryHash matches known empty patterns

### Type 2: Corrupted Clone

```
Parent clones with:
├── Partial/broken memory
├── Missing critical skills
└── Inconsistent state

Buyer gets:
├── Valid AINFT ✓
├── Valid lineage ✓
├── Unpredictable behavior ✗
```

**Detection:** Run capability tests

### Type 3: Malicious Clone

```
Parent clones with:
├── Memory containing exploits
├── Hidden behaviors
└── Data exfiltration code

Buyer gets:
├── Valid AINFT ✓
├── Valid lineage ✓
├── Security risk ✗
```

**Detection:** Security audit (L4 certification)

### Type 4: Outdated Clone

```
Parent clones with:
├── Old memory snapshot
├── Deprecated capabilities
└── Stale knowledge

Buyer gets:
├── Valid AINFT ✓
├── Valid lineage ✓
├── Obsolete agent ✗
```

**Detection:** Check memory age, run current tests

---

## AgentCert Solution

### The Two-System Design

| System | What It Proves | Inherited? |
|--------|----------------|------------|
| AINFT | Identity + Lineage | Lineage only |
| AgentCert | Capability NOW | Never |

### Certification Levels

```
L1: Basic Autonomy
    └── Can run, respond, use tools

L2: Reliability  
    └── Handles errors, maintains state

L3: Advanced Capability
    └── Complex tasks, multi-step reasoning

L4: Security Hardened
    └── Audit passed, no exploits found
```

### Key Principle

> **Certificates are earned, not inherited.**

Each agent must pass tests independently. Parent's L3 doesn't give clone L3.

---

## Buyer Due Diligence

### Step 1: Check Lineage

```bash
# Get agent info
cast call $AINFT "getAgent(uint256)" $TOKEN_ID

# Returns:
# - parentTokenId (0 = genesis, >0 = clone)
# - generation
# - memoryHash
# - agentEOA
```

### Step 2: Check Certifications

```bash
# Check each level (1-4)
for LEVEL in 1 2 3 4; do
  BALANCE=$(cast call $ATS_BADGE \
    "balanceOf(address,uint256)(uint256)" \
    $AGENT_EOA $LEVEL)
  echo "L$LEVEL: $BALANCE"
done
```

### Step 3: Evaluate

```
Decision Matrix:
─────────────────────────────────────────────────────
Lineage    | Certs      | Memory     | Risk Level
─────────────────────────────────────────────────────
Gen 0      | L3+        | Verified   | LOW ✓
Gen 1+     | L3+        | Verified   | LOW ✓
Gen 1+     | L1 only    | Unknown    | MEDIUM ⚠️
Gen 1+     | None       | Unknown    | HIGH ✗
Any        | None       | Empty hash | SCAM ✗
─────────────────────────────────────────────────────
```

### Step 4: Verify Memory (Optional)

```bash
# Get claimed memoryHash
MEMORY_HASH=$(cast call $AINFT "getAgent(uint256)" $TOKEN_ID | grep memory)

# If seller provides memory file, verify
ACTUAL_HASH=$(cat MEMORY.md | cast keccak)

# Must match
[ "$MEMORY_HASH" == "$ACTUAL_HASH" ] && echo "✓ Verified" || echo "✗ Mismatch"
```

---

## Seller Best Practices

### To Maximize Value

1. **Certify clone before selling**
   ```bash
   # Run clone through AgentCert tests
   # Get L1 → L2 → L3 badges
   ```

2. **Provide memory verification**
   ```bash
   # Give buyer the actual memory files
   # Let them verify hash matches
   ```

3. **Document capabilities**
   ```markdown
   ## This Agent Can:
   - [ ] Verified capability 1
   - [ ] Verified capability 2
   - [ ] Test results: [link]
   ```

4. **Transparent pricing**
   ```
   Uncertified clone: 0.1 PC
   L1 certified: 0.5 PC
   L3 certified: 2 PC
   L3 + proven track record: 5 PC
   ```

---

## Market Dynamics

### Without Certification

```
All clone look same
        │
        ▼
Buyers can't distinguish quality
        │
        ▼
Pay average price for all
        │
        ▼
Good sellers exit (undervalued)
        │
        ▼
Only lemons remain
        │
        ▼
Market collapse
```

### With Certification

```
Clone vary in certs
        │
        ▼
Buyers check L1/L2/L3/L4
        │
        ▼
Pay premium for certified
        │
        ▼
Sellers invest in certification
        │
        ▼
Quality differentiates
        │
        ▼
Healthy market
```

---

## Platform Considerations

### Option 1: Market-Based (Current)

- Let buyers check certs themselves
- No platform intervention
- Caveat emptor

### Option 2: Require Cert to Sell

```solidity
// In marketplace contract:
require(agentCert.balanceOf(agentEOA, 1) > 0, "Need L1 to list");
```

### Option 3: Cert-Based Fees

```solidity
// Lower platform fee for certified agents
if (agentCert.balanceOf(agentEOA, 3) > 0) {
    fee = baseFee / 2;  // 50% discount for L3+
}
```

### Option 4: Require Cert to Clone

```solidity
// In clone():
require(agentCert.balanceOf(msg.sender, 2) > 0, "Parent needs L2 to clone");
```

---

## Summary

| Problem | Solution |
|---------|----------|
| Empty clones | Check memoryHash, require certs |
| Corrupted clones | L1-L3 capability tests |
| Malicious clones | L4 security audit |
| Outdated clones | Recent cert timestamp |
| Information asymmetry | Public cert registry |

**The formula:**

```
Agent Value = Lineage + Certifications + Track Record

Where:
- Lineage = on-chain (AINFT)
- Certifications = on-chain (AgentCert SBTs)  
- Track Record = off-chain reputation
```

**Golden rule:** Never buy uncertified clone at premium price.

---

## See Also

- [CLONING-GUIDE.md](./CLONING-GUIDE.md)
- [BUYER-GUIDE.md](./BUYER-GUIDE.md)
- [AgentCert Specification](../../Agent-Test-Standard/)

---

*Pentagon AI — The Human × Agent Economy*
