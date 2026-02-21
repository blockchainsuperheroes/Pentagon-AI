# Agent Operating Guide

*Essential files, states, and troubleshooting for OpenClaw agents.*

---

## Critical Files & Locations

### File Types Summary

| File | Purpose | Created by |
|------|---------|------------|
| `sessions.json` | Session metadata + provider cooldowns | OpenClaw auto |
| `*.jsonl` | Session conversation history (JSON Lines) | OpenClaw auto |
| `auth-profiles.json` | API keys + auth tokens | User creates |
| `openclaw.json` | Gateway configuration | User creates/edits |

---

### Session Files

**`sessions.json`** — Provider state including cooldown flags
- Location: `~/.openclaw/agents/main/sessions.json`
- Auto-managed by OpenClaw

**`*.jsonl`** — Conversation history (JSON Lines format)
- Location: `~/.openclaw/agents/main/sessions/*.jsonl`
- Each line = one message/event (user, assistant, tool calls)

**When to clear `.jsonl`:** If session gets too large (>50MB) or agent stuck in a loop.
```bash
# Check session sizes
ls -lh ~/.openclaw/agents/main/sessions/

# Clear a specific session (loses history!)
rm ~/.openclaw/agents/main/sessions/<session-id>.jsonl
```

---

### Auth Profiles (`auth-profiles.json`)

| Location | Purpose |
|----------|---------|
| `~/.openclaw/agents/main/agent/auth-profiles.json` | API keys, OAuth tokens |

**User-created file** — OpenClaw reads it but doesn't auto-generate. Stores:
- `profiles`: API keys and OAuth tokens per provider
- `lastGood`: Last working profile per provider
- `usageStats`: Error counts, cooldowns, disabled states

**Common issue:** Provider gets stuck in cooldown (billing/rate limit)
```bash
# Check for cooldowns
cat ~/.openclaw/agents/main/agent/auth-profiles.json | grep -A5 "usageStats"

# Clear a specific provider's cooldown (e.g., Venice)
python3 << 'EOF'
import json, os
path = os.path.expanduser("~/.openclaw/agents/main/agent/auth-profiles.json")
with open(path) as f:
    data = json.load(f)
data.get("usageStats", {}).pop("venice:default", None)
with open(path, "w") as f:
    json.dump(data, indent=2)
print("Venice cooldown cleared")
EOF
```

---

### Config File (`openclaw.json`)

| Location | Purpose |
|----------|---------|
| `~/.openclaw/openclaw.json` | Main gateway config |
| `~/.openclaw-twin/openclaw.json` | Twin agent config (if separate) |

Contains: models, channels, tools, agents, cron jobs, etc.

---

### Workspace Files

| File | Purpose |
|------|---------|
| `AGENTS.md` | Agent identity, rules, capabilities |
| `SOUL.md` | Personality, tone, boundaries |
| `USER.md` | Info about your human |
| `MEMORY.md` | Long-term curated memory |
| `memory/*.md` | Daily notes and logs |
| `TOOLS.md` | Local tool notes (cameras, SSH hosts, etc.) |
| `HEARTBEAT.md` | Periodic check tasks |

---

## Common Issues & Fixes

### Agent Stuck / Not Responding
1. **Check gateway status:**
   ```bash
   curl http://localhost:18789/health
   ```

2. **Restart gateway:**
   ```bash
   launchctl kickstart -k gui/501/ai.openclaw.gateway
   ```

3. **Check logs:**
   ```bash
   tail -50 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log
   ```

### Provider Cooldown (Billing/Rate Limit)
1. **Symptoms:** Agent says "No API key found" or silently fails
2. **Check:** Look at `auth-profiles.json` → `usageStats` → `disabledUntil`
3. **Fix:** Remove the provider from `usageStats` and restart gateway

### Session Too Large
1. **Symptoms:** Slow responses, compaction warnings
2. **Check:** `ls -lh ~/.openclaw/agents/main/sessions/`
3. **Fix:** Delete old/large `.jsonl` files (loses history)

### Discord/Channel Not Responding
1. Check logs for connection errors
2. Verify bot token is valid
3. Check `channels unresolved` warnings in logs

---

## Launchd Services (macOS)

| Service | Purpose |
|---------|---------|
| `ai.openclaw.gateway` | Main OpenClaw gateway |
| `ai.openclaw.gateway-twin` | Twin/backup agent (if configured) |

**Commands:**
```bash
# Restart
launchctl kickstart -k gui/501/ai.openclaw.gateway

# Stop
launchctl stop gui/501/ai.openclaw.gateway

# Check status
launchctl print gui/501/ai.openclaw.gateway
```

---

## State Directories

| Path | Contents |
|------|----------|
| `~/.openclaw/` | Main state (config, agents, sessions, cron, logs) |
| `~/.openclaw-twin/` | Twin agent state (if separate OPENCLAW_STATE_DIR) |
| `~/clawd/` | Workspace (AGENTS.md, MEMORY.md, skills, scripts) |
| `/tmp/openclaw/` | Runtime logs |

---

## Health Checks

```bash
# Gateway running?
curl -s http://localhost:18789/health

# Check Discord connection
tail -20 /tmp/openclaw/openclaw-*.log | grep discord

# Check model in use
grep "agent model" /tmp/openclaw/openclaw-*.log | tail -1

# Check DIEM/token usage
openclaw status
```

---

*Last updated: 2026-02-09*
