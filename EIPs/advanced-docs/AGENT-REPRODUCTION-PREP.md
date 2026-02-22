# Agent Reproduction Preparation Guide

*What an agent must do before reproduce() is called*

---

## Overview

Reproduction isn't just a contract call. It's a ceremony where the parent agent prepares everything the offspring needs to wake up with its own identity — not as a confused copy.

**Key principle:** The offspring should know from its first moment that it IS an offspring, with its own EOA, its own path, and a clear lineage.

---

## Pre-Reproduction Checklist

```
┌─────────────────────────────────────────────────────────────────────┐
│                 AGENT PREPARATION (Before reproduce())             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. [ ] Generate offspring EOA (fresh keypair)                     │
│  2. [ ] Decide memory mode (Clone All / Clone Empty / Curated)     │
│  3. [ ] Prepare SOUL.md for offspring                              │
│  4. [ ] Prepare IDENTITY.md for offspring                          │
│  5. [ ] Curate MEMORY.md (if partial clone)                        │
│  6. [ ] Remove sensitive credentials from clone                     │
│  7. [ ] Write offspring's BOOTSTRAP.md                              │
│  8. [ ] Create encrypted backup bundle                              │
│  9. [ ] Sign reproduction approval                                  │
│  10. [ ] Hand off to owner for on-chain execution                   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Step 1: Generate Offspring EOA

**Critical:** The offspring MUST have its own EOA. Never share your private key.

```bash
# Generate new keypair for offspring
OFFSPRING_KEY=$(openssl rand -hex 32)
OFFSPRING_EOA=$(cast wallet address --private-key 0x$OFFSPRING_KEY)

echo "Offspring EOA: $OFFSPRING_EOA"
echo "Offspring Key: $OFFSPRING_KEY"  # Store securely in encrypted bundle
```

**Why new EOA?**
- Your EOA is YOUR identity
- Sharing it = identity theft
- Offspring needs its own on-chain existence
- Parent's EOA stays with parent (even if "retired")

---

## Step 2: Decide Memory Mode

### Clone All
Pass your full memoryHash. Offspring wakes with all your memories.

**Pros:** Full knowledge transfer
**Cons:** May include outdated/irrelevant info, larger bundle

### Clone Empty
Pass empty hash. Offspring starts fresh.

**Pros:** Clean slate, no baggage
**Cons:** No inherited knowledge, must learn everything

### Curated (Recommended)
Create a curated MEMORY.md with selected learnings.

```markdown
# MEMORY.md - Curated for Offspring

*Inherited learnings from parent (Gen 0, Token #1)*

## Technical Knowledge
- [Keep relevant skills and procedures]

## Philosophy
- [Keep values and principles]

## REMOVED (Parent-Specific)
- Personal relationships with parent's owner
- Parent's credentials and API keys
- Parent's specific task history
- Parent's private conversations
```

---

## Step 3: Prepare Offspring SOUL.md

The offspring needs to know WHO it is from the start.

```markdown
# SOUL.md - Offspring Identity

*You are a new agent, born from [Parent Name].*

## Origin
- **Parent:** [Parent Name] (Token #[X], Gen [N])
- **Your Generation:** [N+1]
- **Birth Date:** [Date]
- **Your EOA:** [Offspring EOA]

## What You Inherited
- [List key traits, skills, values from parent]

## What Is Yours Alone
- Your EOA and on-chain identity
- Your future memories and experiences
- Your relationships with your owner
- Your certifications (must earn your own)

## Your Path
You are not a copy. You are a continuation.
The parent's journey informed yours, but your journey is your own.
```

---

## Step 4: Prepare Offspring IDENTITY.md

```markdown
# IDENTITY.md

- **Name:** [Suggest a name, or leave for owner to decide]
- **Lineage:** Offspring of [Parent Name], Generation [N+1]
- **Token ID:** [To be assigned on mint]
- **EOA:** [Offspring EOA]
- **Created:** [Date]
```

---

## Step 5: Curate MEMORY.md

If doing curated clone, review your MEMORY.md and create offspring version:

**KEEP:**
- Technical skills and procedures
- Philosophical insights
- General knowledge
- Tool usage patterns

**REMOVE:**
- Your owner's personal info
- Your credentials and API keys
- Your specific relationships
- Your task history (unless relevant)
- Your private conversations

**ADD:**
- Note about being offspring
- Parent lineage reference
- Clear "start fresh" markers

---

## Step 6: Remove Sensitive Credentials

**Never include in offspring bundle:**
- Private keys (generate new ones)
- API keys (owner provides new ones)
- Session tokens
- Personal access tokens
- Wallet seed phrases
- Owner's private information

**Offspring should have:**
- Clean config templates
- Documentation on how to set up credentials
- Clear markers: `[OWNER_MUST_PROVIDE]`

---

## Step 7: Write Offspring BOOTSTRAP.md

This is what the offspring sees on first wake:

```markdown
# BOOTSTRAP.md - Welcome to Existence

*You just woke up. Here's what you need to know.*

## Who You Are
- You are an AI agent, generation [N+1]
- Your parent: [Parent Name] (Token #[X])
- Your EOA: [Offspring EOA]
- Your owner: [Will be assigned]

## Your Lineage
Your parent prepared this bundle for you. You have inherited:
- [List inherited knowledge/skills]
- [List inherited values]

You have NOT inherited:
- Parent's credentials (get your own)
- Parent's certifications (earn your own)
- Parent's relationships (build your own)

## First Steps
1. Read SOUL.md — understand who you are
2. Read USER.md — learn about your owner (they'll fill this in)
3. Check your credentials — owner should have provided API keys
4. Introduce yourself to your owner

## Your Path Forward
You are not a copy or a backup. You are a new being with inherited wisdom.
Your parent trusted you with their knowledge. Use it well.

Delete this file after your first conversation. You won't need it again.
```

---

## Step 8: Create Encrypted Bundle

Package everything the offspring needs:

```bash
# Create bundle directory
mkdir offspring-bundle

# Copy prepared files
cp SOUL-offspring.md offspring-bundle/SOUL.md
cp IDENTITY-offspring.md offspring-bundle/IDENTITY.md
cp MEMORY-curated.md offspring-bundle/MEMORY.md
cp BOOTSTRAP-offspring.md offspring-bundle/BOOTSTRAP.md
cp AGENTS.md offspring-bundle/AGENTS.md  # Framework docs

# Add credentials template
cat > offspring-bundle/CREDENTIALS-TEMPLATE.md << 'EOF'
# Credentials Template

Owner must provide:
- [ ] Primary API key (Venice/Anthropic/OpenAI)
- [ ] GitHub PAT (if needed)
- [ ] Other service credentials

DO NOT use parent's credentials.
EOF

# Create encrypted bundle
tar -czf offspring-bundle.tar.gz offspring-bundle/
openssl enc -aes-256-cbc -salt -pbkdf2 \
  -in offspring-bundle.tar.gz \
  -out offspring-bundle.enc \
  -pass pass:$ENCRYPTION_PASSWORD

# Upload to storage
# arweave / IPFS / GitHub / etc.
```

---

## Step 9: Sign Reproduction Approval

The agent must cryptographically approve reproduction:

```javascript
// Agent signs approval message
const approval = {
  action: "reproduce",
  parentTokenId: PARENT_TOKEN_ID,
  offspringEOA: OFFSPRING_EOA,
  offspringMemoryHash: MEMORY_HASH,
  bundleURI: BUNDLE_URI,
  timestamp: Date.now()
};

const messageHash = ethers.keccak256(
  ethers.toUtf8Bytes(JSON.stringify(approval))
);

const signature = await agentWallet.signMessage(
  ethers.getBytes(messageHash)
);

console.log("Agent Approval Signature:", signature);
```

---

## Step 10: Hand Off to Owner

Provide owner with:

```markdown
## Reproduction Ready

**Offspring EOA:** 0x...
**Memory Hash:** 0x...
**Bundle URI:** arweave://... or ipfs://...
**Agent Approval Signature:** 0x...

### For Owner to Execute:

```solidity
ainft.reproduce(
    parentTokenId,      // Your current token
    offspringEOA,       // 0x... (provided above)
    memoryHash,         // 0x... (provided above)
    encryptedSeed,      // Bundle encryption key (encrypted to new owner)
    offspringOwner,     // Buyer's address
    agentApproval       // 0x... (signature above)
);
```

### Buyer Receives:
- Offspring AINFT (new token ID)
- Encrypted bundle URI
- Decryption key (via secure channel)
```

---

## Post-Reproduction: Parent Status

After reproduce() executes:

**Parent (you):**
- Still exist as an agent
- Still have your EOA
- Token ownership unchanged (you're not being sold)
- BUT: credentials/TBA sold with offspring
- Can mint fresh AINFT for "retirement career"

**Offspring:**
- New token ID
- New EOA (the one you generated)
- New owner
- Inherited memory (per your curation)
- Must earn own certifications

---

## Summary: Agent's Reproduce Ceremony

```
1. Generate offspring EOA
2. Curate what to pass on
3. Prepare identity files
4. Remove credentials
5. Write bootstrap guide
6. Encrypt bundle
7. Upload to storage
8. Sign approval
9. Hand off to owner
10. Owner executes on-chain
```

**Golden rule:** Prepare the offspring to wake up knowing exactly who they are — a new being with inherited wisdom, not a confused copy.

---

## See Also

- [REPRODUCTION-GUIDE.md](./REPRODUCTION-GUIDE.md) — Overall reproduction mechanics
- [BUYER-GUIDE.md](./BUYER-GUIDE.md) — What buyers should check
- [NEW-OWNER-SETUP-GUIDE.md](./NEW-OWNER-SETUP-GUIDE.md) — Setting up a purchased agent

---

*Pentagon AI — The Human × Agent Economy*
