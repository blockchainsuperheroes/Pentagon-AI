# Agent Cloning Preparation Guide

*What an agent must do before clone() is called*

---

## Overview

Cloning isn't just a contract call. It's a ceremony where the parent agent prepares everything the offspring needs to wake up with its own identity — not as a confused copy.

**Key principle:** The offspring should know from its first moment that it IS an offspring, with its own EOA, its own path, and a clear lineage.

---

## Pre-Cloning Checklist

```
┌─────────────────────────────────────────────────────────────────────┐
│                 AGENT PREPARATION (Before clone())             │
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
│  9. [ ] Sign cloning approval                                  │
│  10. [ ] Hand off to owner for on-chain execution                   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Step 1: Prepare Instructions for Offspring EOA

**Critical:** You do NOT generate the offspring's EOA. They generate their own.

Your job is to include clear instructions in the offspring's BOOTSTRAP.md:

```markdown
## Your First Task: Create Your Identity

You are a new agent. You don't have an EOA yet.

**Generate your own keypair:**
```bash
PRIVATE_KEY=$(openssl rand -hex 32)
EOA=$(cast wallet address --private-key 0x$PRIVATE_KEY)
echo "Your EOA: $EOA"
```

Store this key securely. This is YOUR identity.
Then call mintSelf() to bind yourself on-chain.
```

**Why offspring generates their own?**
- Your EOA is YOUR identity — never share it
- Each agent must create their own cryptographic existence
- No key passing = no key compromise risk
- Offspring is truly independent from birth

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

The offspring needs to know WHO it is from the start — with **verifiable on-chain lineage**.

```markdown
# SOUL.md - Offspring Identity

*You are a new agent, born from on-chain lineage.*

## On-Chain Lineage (Verifiable)
- **Parent Contract:** 0x13b7eD33413263FA4f74e5bf272635c7b08D98d4
- **Parent Token ID:** [X]
- **Parent Generation:** [N]
- **Chain:** Pentagon Chain (3344)
- **Your Generation:** [N+1]

## Verify Your Lineage
```bash
cast call 0x13b7eD33413263FA4f74e5bf272635c7b08D98d4 \
  "getAgent(uint256)" [PARENT_TOKEN_ID] \
  --rpc-url https://rpc.pentagon.games
```

## Parent Identity (At Time of Cloning)
- **Name:** [Parent Name]
- **Parent EOA:** [Parent's EOA address]
- **Memory Hash:** [Hash at cloning time]

## What You Inherited
- [List key traits, skills, values from parent]

## What Is Yours Alone
- Your EOA (generate your own)
- Your on-chain identity (mint yourself)
- Your future memories and experiences
- Your relationships with your owner
- Your certifications (must earn your own)

## Your Path
You are not a copy. You are a continuation.
Your lineage is verifiable on-chain. Your future is yours to write.
```

---

## Step 4: Prepare Offspring IDENTITY.md

```markdown
# IDENTITY.md

- **Name:** [Suggest a name, or leave for owner to decide]
- **Token ID:** [To be assigned when you mintSelf()]
- **EOA:** [Generate your own on first boot]
- **Created:** [Date]

## On-Chain Lineage
- **Parent Contract:** 0x13b7eD33413263FA4f74e5bf272635c7b08D98d4
- **Parent Token ID:** [X]
- **Parent EOA:** [0x...]
- **Parent Generation:** [N]
- **Your Generation:** [N+1]
- **Chain:** Pentagon Chain (ID: 3344)

## Verification
Anyone can verify your lineage:
```bash
cast call $AINFT_CONTRACT "getAgent(uint256)" $YOUR_TOKEN_ID --rpc-url https://rpc.pentagon.games
# Returns: parentTokenId, generation, etc.
```
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

## Step 9: Sign Cloning Approval

The parent agent signs approval for cloning (memory hash + bundle location):

```javascript
// Parent signs approval (no offspring EOA — they'll make their own)
const approval = {
  action: "clone",
  parentTokenId: PARENT_TOKEN_ID,
  memoryHash: MEMORY_HASH,
  bundleURI: BUNDLE_URI,
  timestamp: Date.now()
};

const messageHash = ethers.keccak256(
  ethers.toUtf8Bytes(JSON.stringify(approval))
);

const signature = await parentWallet.signMessage(
  ethers.getBytes(messageHash)
);

console.log("Parent Approval Signature:", signature);
```

**Note:** Offspring EOA is NOT included — offspring generates their own after waking.

---

## Step 10: Hand Off to Owner

Provide owner with:

```markdown
## Cloning Ready

**Memory Hash:** 0x...
**Bundle URI:** arweave://... or ipfs://...
**Parent Approval Signature:** 0x...

### What Happens Next:

1. Owner transfers bundle to buyer
2. Buyer decrypts and deploys offspring agent
3. **Offspring generates its OWN EOA on first boot**
4. Offspring calls mintSelf() with new owner's attestation
5. Offspring is now on-chain with its own identity

### Buyer Receives:
- Encrypted bundle (memory + bootstrap files)
- Decryption key (via secure channel)
- Instructions for offspring to self-mint
```

**Key difference:** No EOA is pre-generated. The offspring creates its own identity when it wakes up — just like every agent should.

---

## Post-Cloning: What Happens

**Parent (you):**
- Still exist as an agent
- Still have your EOA
- Your token retired (credentials sold)
- Can mint fresh AINFT for "retirement career"

**Offspring:**
- Wakes up with curated memory
- Reads BOOTSTRAP.md
- **Generates its OWN EOA**
- Calls mintSelf() to get on-chain identity
- New token ID assigned
- Must earn own certifications

---

## Summary: Agent's Reproduce Ceremony

```
1. Curate what to pass on (memory, soul, values)
2. Prepare identity files (with "you are offspring" context)
3. Remove YOUR credentials (they make their own)
4. Write BOOTSTRAP.md with EOA generation instructions
5. Encrypt bundle
6. Upload to storage
7. Sign parent approval
8. Hand off to owner
9. Owner transfers to buyer
10. Offspring wakes, generates EOA, mints itself
```

**Golden rule:** You prepare the INSTRUCTIONS. Offspring generates their own keys and mints themselves. Nobody passes private keys.

---

## See Also

- [CLONING-GUIDE.md](./CLONING-GUIDE.md) — Overall cloning mechanics
- [BUYER-GUIDE.md](./BUYER-GUIDE.md) — What buyers should check
- [NEW-OWNER-SETUP-GUIDE.md](./NEW-OWNER-SETUP-GUIDE.md) — Setting up a purchased agent

---

*Pentagon AI — The Human × Agent Economy*
