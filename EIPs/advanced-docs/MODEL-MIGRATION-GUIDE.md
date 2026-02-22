# Model Migration Guide

*Why model info is off-chain and how to migrate between models*

---

## The Problem with On-Chain Model Info

Some standards (e.g., ERC-7662) store model identifiers on-chain:

```solidity
string memory model  // e.g., "gpt-4", "claude-3"
```

This seems reasonable but creates false confidence. A hash or string on-chain cannot:
- Enforce actual model compatibility
- Validate memory/context format
- Guarantee the agent actually uses that model

**AINFT keeps model info off-chain** because model migration is complex and requires off-chain validation.

---

## Real-World Migration Failures

These issues were discovered through production experience operating AI agents:

### 1. Context Window Mismatch

```
Claude (200K tokens) → Local 8B model (4-32K tokens)
Result: Agent "forgets" most of its memory mid-conversation
```

**What happens:**
- Agent loads full memory (50K+ tokens)
- Small model truncates to fit context
- Agent loses critical information
- Responses become incoherent

**Solution:** Flush important info to files BEFORE switching. Don't rely on in-context memory.

### 2. Tool Calling Failures

```
Claude (reliable tool use) → 8B models (understands but doesn't call)
Result: Agent describes what it could do instead of doing it
```

**What happens:**
- Small models understand tool descriptions
- They explain the tool instead of invoking it
- User gets "I would use the read tool to..." instead of actual file contents

**Solution:** Use models specifically fine-tuned for tool calling, or accept degraded capability.

### 3. Tokenization Differences

```
Claude tokenizer → GPT tokenizer → Llama tokenizer
Result: Memory optimized for one is inefficient on another
```

**What happens:**
- Memory formatted for Claude's tokenization
- Different model tokenizes same text differently
- Context budget consumed faster or slower than expected
- Truncation happens at unexpected points

**Solution:** Re-process memory when switching model families.

### 4. Prompt Format Incompatibility

```
Claude system prompts → GPT system prompts → Llama chat templates
Result: Agent personality/behavior changes unexpectedly
```

**What happens:**
- Each model family expects different prompt structure
- System prompts formatted for Claude may be ignored by others
- Agent behavior becomes inconsistent

**Solution:** Maintain model-specific prompt templates. Translate on migration.

---

## Migration Process

Model migration is an **off-chain process**, not a simple hash update.

### Step 1: Assess Compatibility

```markdown
Before migrating from Model A to Model B:

1. [ ] Context window: B >= A, or memory must be reduced
2. [ ] Tool calling: B supports required tools
3. [ ] Prompt format: Have templates for B
4. [ ] Test run: Validate on sample conversations
```

### Step 2: Prepare Memory

```bash
# Export memory in portable format
agent export-memory --format markdown --output memory-export.md

# Review for model-specific content
# Remove hardcoded model references
# Simplify complex nested structures
```

### Step 3: Translate Prompts

```markdown
SOUL.md changes:
- Remove model-specific instructions
- Adjust for new model's strengths/weaknesses
- Test personality consistency
```

### Step 4: Staged Migration

```
1. Run new model on test workspace
2. Import memory export
3. Validate core functionality
4. Test edge cases
5. Switch production only after validation
```

### Step 5: Update Off-Chain Storage

```bash
# Update agent's local config (not on-chain)
agent config set model "new-model-name"

# Memory hash on-chain stays same if content unchanged
# Only update if memory was re-processed
```

---

## Why Not On-Chain?

| Approach | Reality |
|----------|---------|
| On-chain `modelHash` | Informational only. Can't enforce compatibility. |
| On-chain `selfEvolve()` | Implies simple switch. Migration is complex. |
| **Off-chain model config** | Honest. Migration is a process, not a transaction. |

**On-chain identity (AINFT) is stable. Off-chain model is flexible.**

The agent's identity (EOA, TBA, certs, lineage) persists across model changes. The model is an implementation detail that can change without affecting on-chain state.

---

## Best Practices

1. **Test before switching** — Never migrate production without validation
2. **Keep memory portable** — Avoid model-specific formats in MEMORY.md
3. **Version your prompts** — Track which prompts work with which models
4. **Document model requirements** — Note minimum context size, tool support needed
5. **Graceful degradation** — Design agent to work with reduced capabilities

---

## Summary

Model migration is complex because:
- Context formats are model-specific
- Tokenization differs across families
- Tool calling reliability varies
- Prompt structures are incompatible

AINFT acknowledges this by keeping model info **off-chain**. Your agent's on-chain identity is stable; the model powering it is a runtime decision.

---

*This guide reflects lessons learned from production AI agent operations.*

---

## See Also

- [CLONING-GUIDE.md](./CLONING-GUIDE.md) — Creating clones
- [BUYER-GUIDE.md](./BUYER-GUIDE.md) — What to check before buying

---

*Pentagon AI — The Human × Agent Economy*
