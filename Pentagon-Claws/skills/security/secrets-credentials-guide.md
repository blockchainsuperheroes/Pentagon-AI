# Secrets & Credentials Management Guide

*How OpenClaw handles API keys, OAuth tokens, and web credentials.*

---

## Overview

OpenClaw manages three types of credentials:

| Type | Storage | Purpose |
|------|---------|---------|
| **API Keys** | `auth-profiles.json` | LLM providers (Venice, OpenAI, Anthropic) |
| **OAuth Tokens** | `auth-profiles.json` | Services requiring login (Google, GitHub Copilot) |
| **Web Sessions** | Browser profiles | Logged-in web apps (Telegram Web, etc.) |

---

## 1. API Keys & OAuth (`auth-profiles.json`)

### Location
```
~/.openclaw/agents/main/agent/auth-profiles.json
```

### Structure
```json
{
  "version": 1,
  "profiles": {
    "venice:default": {
      "type": "api_key",
      "provider": "venice",
      "key": "VENICE-INFERENCE-KEY-xxx"
    },
    "openai-codex:default": {
      "type": "oauth",
      "provider": "openai-codex",
      "access": "<jwt-token>",
      "refresh": "<refresh-token>",
      "expires": 1770496886906
    }
  },
  "lastGood": {
    "venice": "venice:default"
  },
  "usageStats": {
    "venice:default": {
      "errorCount": 1,
      "disabledUntil": 1770656582810,
      "disabledReason": "billing"
    }
  }
}
```

### Key Fields

| Field | Purpose |
|-------|---------|
| `profiles` | All stored credentials (API keys + OAuth tokens) |
| `lastGood` | Last working profile per provider |
| `usageStats` | Error tracking, cooldowns, disabled states |
| `disabledUntil` | Unix timestamp when provider will be re-enabled |
| `disabledReason` | Why disabled (`billing`, `rate_limit`, etc.) |

### Adding Credentials

**Via CLI (recommended):**
```bash
openclaw agents add <profile-id>
# Prompts for API key or initiates OAuth flow
```

**Manual edit:** Add to `profiles` section (restart gateway after).

### Clearing Cooldowns

When a provider gets stuck in cooldown:
```bash
# Check current state
cat ~/.openclaw/agents/main/agent/auth-profiles.json | grep -A10 usageStats

# Clear specific provider (Python)
python3 << 'EOF'
import json
path = "$HOME/.openclaw/agents/main/agent/auth-profiles.json"
with open(path.replace("$HOME", __import__("os").environ["HOME"])) as f:
    data = json.load(f)
# Remove Venice cooldown
data.get("usageStats", {}).pop("venice:default", None)
with open(path.replace("$HOME", __import__("os").environ["HOME"]), "w") as f:
    json.dump(data, f, indent=2)
print("Cooldown cleared")
EOF

# Restart gateway
launchctl kickstart -k gui/501/ai.openclaw.gateway
```

---

## 2. Web Credentials (Browser Profiles)

### How It Works
OpenClaw can control Chrome browser profiles with existing logins. No passwords stored — uses browser's session cookies.

### Browser Profiles Location
```
~/.openclaw/browser/profiles/<profile-name>/
```

### Configuration (`openclaw.json`)
```json
"browser": {
  "profiles": {
    "clawd": {
      "cdpPort": 18801,
      "color": "#FF6B6B"
    }
  }
}
```

### Common Web Services

| Service | How to Access |
|---------|---------------|
| Telegram Web | `browser open` → web.telegram.org (must be logged in) |
| Gmail | Use `gog` CLI (OAuth via Google) |
| Twitter/X | Use `bird` CLI with cookies |
| TELUS SmartHome | Browser automation (login persists in profile) |

### Setting Up a Browser Profile

1. **Start browser with profile:**
   ```bash
   openclaw browser start --profile clawd
   ```

2. **Log into services manually** (one-time)

3. **Agent can now use those sessions:**
   ```
   browser action=open profile=clawd targetUrl=https://web.telegram.org
   ```

---

## 3. Credential Index (Optional)

For tracking what credentials exist where:

### Location
```
~/clawd-persist/CREDENTIAL-INDEX.md
```

### Example Format
```markdown
# Credential Index

## API Keys
- Venice: auth-profiles.json (auto-managed)
- Brave Search: openclaw.json → tools.web.search.apiKey

## OAuth
- Google (gog): ~/.config/gog/credentials.json
- GitHub Copilot: auth-profiles.json (openai-codex:default)

## Browser Sessions
- Telegram Web: clawd profile
- TELUS SmartHome: clawd profile

## CLI Tools
- bird (Twitter): ~/.config/bird/cookies.json
- wacli (WhatsApp): QR-linked session
```

---

## 4. Security Best Practices

### DO
- ✅ Use `auth-profiles.json` for LLM provider keys
- ✅ Use browser profiles for web sessions (no passwords stored)
- ✅ Keep `CREDENTIAL-INDEX.md` updated for reference
- ✅ Use OAuth when available (tokens expire, more secure)

### DON'T
- ❌ Hardcode API keys in scripts
- ❌ Commit credentials to git
- ❌ Share `auth-profiles.json` between machines
- ❌ Post tokens/keys in Discord or chat

### Sensitive File Locations
```
~/.openclaw/agents/main/agent/auth-profiles.json  # API keys, OAuth
~/.openclaw/credentials.json                       # Legacy/backup
~/clawd-persist/SECRETS.md                         # Manual secrets doc
~/.config/gog/credentials.json                     # Google OAuth
```

---

## 5. Troubleshooting

### "No API key found for provider X"
1. Check `auth-profiles.json` has the provider in `profiles`
2. Check `usageStats` for cooldown (`disabledUntil`)
3. Clear cooldown if stuck, restart gateway

### OAuth Token Expired
1. OpenClaw auto-refreshes if `refresh` token exists
2. If refresh fails, re-authenticate: `openclaw agents add <id>`

### Browser Session Lost
1. Profile cookies may have expired
2. Re-login manually in the browser profile
3. Some sites require periodic re-auth (2FA, etc.)

### Wrong Account Used
1. Check which browser profile is configured
2. Each profile maintains separate sessions
3. Switch profiles in `browser` commands

---

*Last updated: 2026-02-09*
