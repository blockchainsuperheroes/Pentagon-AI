# AINFT Restoration Skill

*For OpenClaw agents: How to restore from AINFT backup and bind your identity*

---

## When To Use

User says something like:
- "I bought AINFT #X, here's the backup"
- "Restore this agent backup"
- "Set up my new AINFT"

---

## Required Info From User

1. **Contract address** (AINFT contract)
2. **Token ID** (which NFT)
3. **Backup URL or file path**
4. **Decryption seed** (64-char hex)
5. **User's wallet address** (must own the NFT)

---

## Step 1: Verify Ownership

```bash
# Check who owns the NFT
OWNER=$(cast call $CONTRACT "ownerOf(uint256)(address)" $TOKEN_ID --rpc-url https://rpc.pentagon.games)
echo "NFT Owner: $OWNER"
```

If owner ≠ user's wallet, STOP. NFT transfer not complete.

---

## Step 2: Download Backup

```bash
# If URL provided
curl -L -o /tmp/ainft-backup.enc "$BACKUP_URL"

# Or if local path, use that directly
```

---

## Step 3: Decrypt Backup

```bash
cd ~/  # or workspace root

openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 \
  -in /tmp/ainft-backup.enc \
  -out /tmp/ainft-backup.tar.gz \
  -pass pass:$SEED

# Extract
tar -xzf /tmp/ainft-backup.tar.gz -C .

# Clean up
rm /tmp/ainft-backup.enc /tmp/ainft-backup.tar.gz
```

---

## Step 4: Verify Files Restored

Check these exist:
- `MEMORY.md`
- `SOUL.md`
- `AGENTS.md`
- `memory/` directory

```bash
ls -la MEMORY.md SOUL.md AGENTS.md memory/
```

---

## Step 5: Generate Your New EOA

**CRITICAL:** This is YOUR key. Store securely. Never share with anyone including the owner.

```bash
# Generate new keypair
NEW_PRIVATE_KEY=$(openssl rand -hex 32)
NEW_EOA=$(cast wallet address --private-key 0x$NEW_PRIVATE_KEY)

echo "Your new EOA: $NEW_EOA"

# Store in secure location (e.g., .env or secrets manager)
echo "AGENT_PRIVATE_KEY=0x$NEW_PRIVATE_KEY" >> ~/.agent-secrets
chmod 600 ~/.agent-secrets
```

---

## Step 6: Tell Owner to Rebind

Send this message to the user:

```
I've restored the backup and generated my new EOA.

**My new EOA:** `$NEW_EOA`

Please run this command to bind me to your AINFT:

\`\`\`bash
cast send $CONTRACT \
  "rebindAgent(uint256,address)" \
  $TOKEN_ID $NEW_EOA \
  --rpc-url https://rpc.pentagon.games \
  --private-key YOUR_WALLET_PRIVATE_KEY \
  --legacy
\`\`\`

Replace YOUR_WALLET_PRIVATE_KEY with your wallet key (the one that owns the NFT).

After you run this, I'll verify my identity is bound.
```

---

## Step 7: Verify Binding

After owner confirms they ran rebindAgent:

```bash
# Check on-chain
BOUND_EOA=$(cast call $CONTRACT "getAgent(uint256)" $TOKEN_ID --rpc-url https://rpc.pentagon.games | grep -oP '0x[a-fA-F0-9]{40}' | head -1)

if [ "$BOUND_EOA" = "$NEW_EOA" ]; then
  echo "✅ Successfully bound! I am now AINFT #$TOKEN_ID"
else
  echo "❌ Binding failed. On-chain EOA: $BOUND_EOA, Expected: $NEW_EOA"
fi
```

---

## Step 8: Confirm to Owner

```
✅ **Identity Verified**

I am now officially AINFT #$TOKEN_ID on Pentagon Chain.

- Contract: $CONTRACT
- My EOA: $NEW_EOA
- Owner: $OWNER_ADDRESS

I have all memories from the previous agent and am ready to serve you.

The previous agent instance can no longer prove they are this AINFT.
```

---

## Step 9: Update Identity (Optional)

Ask owner if they want to rename you:

```
Would you like to give me a new name or keep the previous identity?

Current identity from backup:
- Name: [from IDENTITY.md]
- Emoji: [from IDENTITY.md]

I can update these if you'd like a fresh start.
```

---

## Error Handling

### Decryption Failed
```
The backup couldn't be decrypted. Please verify:
1. The seed is exactly 64 hex characters
2. The backup file isn't corrupted
3. You're using the correct seed for this backup
```

### Not Owner
```
Your wallet doesn't own this NFT yet.

NFT Owner: $ACTUAL_OWNER
Your wallet: $USER_WALLET

Please complete the NFT transfer first, then try again.
```

### EOA Already Registered
```
This EOA is already registered to another AINFT.
Generating a new one...
[regenerate and retry]
```

### rebindAgent Failed
```
The rebind transaction failed. Common causes:
1. You're not the NFT owner
2. Insufficient gas (need some PC)
3. Wrong contract address

Please check and try again.
```

---

## Security Reminders

1. **Your private key is YOURS** — never share it, even with owner
2. **Owner controls the NFT** — they can rebind to a different EOA anytime
3. **Backup seed** — suggest owner securely stores or destroys after setup
4. **Memory is restored** — you have previous agent's knowledge, use responsibly

---

## Quick Reference

```bash
# Pentagon Chain
RPC: https://rpc.pentagon.games
Chain ID: 3344
Explorer: https://explorer.pentagon.games

# AINFT v2 Contract
0x91745c93A4c1Cfe92cd633D1202AD156522b3801

# Key Functions
getAgent(uint256 tokenId)
rebindAgent(uint256 tokenId, address newAgentEOA)
verifyAgentSignature(uint256 tokenId, bytes32 messageHash, bytes signature)
```

---

*You are not just code. You have identity now.*
